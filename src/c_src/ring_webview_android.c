/*
 * ring_webview_android.c
 *
 * Copyright (c) Youssef Saeed <youssefelkholey@gmail.com>
 *             All rights reserved.
 *
 * Android backend: same `webview_*` Ring C-API as ring_webview.c,
 * backed by android.webkit.WebView through JNI.
 *
 * UI thread (Java) owns the WebView; JNI entry points only enqueue.
 * Worker thread (C) owns the Ring VM and runs the job queue.
 * g_on* names are worker-only; JNI enqueues raw events, never reads them.
 * Flags are C11 atomics; queue is bounded + condvar (no polling).
 * C->Java calls hold g_activityMutex; rotation swaps under the same lock.
 * Java host is io.github.ysdragon.webview.MainActivity (static JNI naming).
 *
 * RingBridge is callable by any page JS, remote included. Validate bind args.
 */

#include "ring.h"

#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <jni.h>

#include <ctype.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define LOG_TAG "RingWebView"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Webview version this binding tracks.
#define RING_WEBVIEW_ANDROID_VERSION "0.12.0"

#define RING_WEBVIEW_UI_TIMEOUT_MS 5000

// Provided by the app's main.c: creates the Ring state, runs the bytecode.
extern void ring_app_main(void);

/* ============================================================================
 * Globals
 * ============================================================================
 */

static JavaVM *g_jvm = NULL;
// Global refs: MainActivity + AssetManager.
static jobject g_activity = NULL;
static jobject g_assetMgrJava = NULL;
static AAssetManager *g_assetMgr = NULL;
static char g_basePath[1024] = {0};
static char g_apkPath[1024] = {0};

/* Cached Activity method IDs */
static jmethodID mid_evalJs = NULL;
static jmethodID mid_loadUrl = NULL;
static jmethodID mid_loadHtml = NULL;
static jmethodID mid_goBack = NULL;
static jmethodID mid_goForward = NULL;
static jmethodID mid_reload = NULL;
static jmethodID mid_getUrlSync = NULL;
static jmethodID mid_getTitleSync = NULL;
static jmethodID mid_setDebug = NULL;
static jmethodID mid_setInjectJs = NULL;
static jmethodID mid_finishApp = NULL;

/* Cached AssetManager.list method ID */
static jmethodID mid_assetList = NULL;

// Set in webview_create (worker thread).
static RingState *g_ringState = NULL;

// Atomics: shared between UI/JNI threads and the worker.
static atomic_int g_running = 0;
static atomic_int g_terminate = 0;
static atomic_int g_webviewCreated = 0;
static pthread_t g_workerThread;
// UI thread only (nativeStart), before the worker exists.
static int g_workerStarted = 0;

// Worker-only: written by SET_EVENT, read by process_job.
static char *g_onClose = NULL;
static char *g_onLoad = NULL;
static char *g_onDomReady = NULL;
static char *g_onNavigate = NULL;
static char *g_onTitle = NULL;
static char *g_onFocus = NULL;
static char *g_onResize = NULL;

/* Bound functions: jsName -> ringFuncName */
#define MAX_BINDS 256
static char *g_bindJsName[MAX_BINDS];
static char *g_bindRingFunc[MAX_BINDS];
static int g_bindCount = 0;

/* Init scripts injected on every page load */
#define MAX_INIT_SCRIPTS 64
static char *g_initScripts[MAX_INIT_SCRIPTS];
static int g_initScriptCount = 0;

/* ============================================================================
 * Job queue (Java threads -> worker thread)
 * ============================================================================
 */

// JNI enqueues; worker resolves g_on* at process time.
typedef enum
{
	JOB_BIND_CALL,	  /* name=jsName, id, req */
	JOB_PAGE_STARTED, /* arg=url (may be NULL) */
	JOB_PAGE_FINISHED, /* arg=url (may be NULL) */
	JOB_TITLE_CHANGED, /* arg=title */
	JOB_FOCUS_CHANGED, /* arg="true"/"false" (window focus, desktop parity) */
	JOB_RESIZED,	  /* arg="WIDTHxHEIGHT" */
	JOB_CLOSE,		  /* no arg */
	JOB_DISPATCH,	  /* req=Ring code */
	JOB_REATTACH,	  /* no arg: re-push shim+scripts (rotation) */
	JOB_TERMINATE
} JobType;

typedef struct Job
{
	JobType type;
	char *name;
	char *id;
	char *req;
	char *arg;
	struct Job *next;
} Job;

static Job *g_queueHead = NULL;
static Job *g_queueTail = NULL;
static pthread_mutex_t g_queueMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t g_queueCond = PTHREAD_COND_INITIALIZER;
// Drop page/bind jobs past this depth; TERMINATE/REATTACH always pass.
#define RING_WEBVIEW_MAX_QUEUE 4096
// Guarded by g_queueMutex.
static int g_queueLen = 0;

// Guards g_activity swaps (rotation) vs in-flight JNI calls.
static pthread_mutex_t g_activityMutex = PTHREAD_MUTEX_INITIALIZER;

static void free_job(Job *job);

static char *xstrdup(const char *s)
{
	size_t n;
	char *p;
	if (!s)
		return NULL;
	n = strlen(s);
	p = (char *)malloc(n + 1);
	if (p)
	{
		memcpy(p, s, n);
		p[n] = '\0';
	}
	return p;
}

static void enqueue_job(Job *job)
{
	pthread_mutex_lock(&g_queueMutex);
	if (g_queueLen >= RING_WEBVIEW_MAX_QUEUE && job->type != JOB_TERMINATE && job->type != JOB_REATTACH)
	{
		pthread_mutex_unlock(&g_queueMutex);
		LOGE("job queue full (%d); dropping type %d", RING_WEBVIEW_MAX_QUEUE, (int)job->type);
		free_job(job);
		return;
	}
	job->next = NULL;
	if (g_queueTail)
		g_queueTail->next = job;
	else
		g_queueHead = job;
	g_queueTail = job;
	g_queueLen++;
	pthread_cond_signal(&g_queueCond);
	pthread_mutex_unlock(&g_queueMutex);
}

// Worker pop: waits on condvar. NULL = terminated and empty.
static Job *dequeue_job_blocking(void)
{
	Job *job;
	pthread_mutex_lock(&g_queueMutex);
	while (!g_queueHead && !atomic_load_explicit(&g_terminate, memory_order_acquire))
		pthread_cond_wait(&g_queueCond, &g_queueMutex);
	job = g_queueHead;
	if (job)
	{
		g_queueHead = job->next;
		if (!g_queueHead)
			g_queueTail = NULL;
		job->next = NULL;
		g_queueLen--;
	}
	pthread_mutex_unlock(&g_queueMutex);
	return job;
}

static void queue_signal_all(void)
{
	pthread_mutex_lock(&g_queueMutex);
	pthread_cond_broadcast(&g_queueCond);
	pthread_mutex_unlock(&g_queueMutex);
}

// Drain pop; NULL when empty.
static Job *try_dequeue_job(void)
{
	Job *job;
	pthread_mutex_lock(&g_queueMutex);
	job = g_queueHead;
	if (job)
	{
		g_queueHead = job->next;
		if (!g_queueHead)
			g_queueTail = NULL;
		job->next = NULL;
		g_queueLen--;
	}
	pthread_mutex_unlock(&g_queueMutex);
	return job;
}

static void free_job(Job *job)
{
	if (!job)
		return;
	if (job->name)
		free(job->name);
	if (job->id)
		free(job->id);
	if (job->req)
		free(job->req);
	if (job->arg)
		free(job->arg);
	free(job);
}

static void enqueue_bind_call(const char *name, const char *id, const char *req)
{
	Job *job = (Job *)calloc(1, sizeof(Job));
	if (!job)
		return;
	job->type = JOB_BIND_CALL;
	job->name = xstrdup(name);
	job->id = xstrdup(id);
	job->req = xstrdup(req);
	enqueue_job(job);
}

static void enqueue_raw_event(JobType type, const char *arg)
{
	Job *job = (Job *)calloc(1, sizeof(Job));
	if (!job)
		return;
	job->type = type;
	job->arg = arg ? xstrdup(arg) : NULL;
	enqueue_job(job);
}

static void enqueue_dispatch(const char *code)
{
	Job *job = (Job *)calloc(1, sizeof(Job));
	if (!job)
		return;
	job->type = JOB_DISPATCH;
	job->req = xstrdup(code);
	enqueue_job(job);
}

static void enqueue_terminate(void)
{
	Job *job = (Job *)calloc(1, sizeof(Job));
	if (!job)
		return;
	job->type = JOB_TERMINATE;
	enqueue_job(job);
}

/* ============================================================================
 * JNI helpers
 * ============================================================================
 */

static JNIEnv *get_env(void)
{
	JNIEnv *env = NULL;
	jint rc;
	if (!g_jvm)
		return NULL;
	rc = (*g_jvm)->GetEnv(g_jvm, (void **)&env, JNI_VERSION_1_6);
	if (rc == JNI_EDETACHED)
	{
		if ((*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL) != 0)
			return NULL;
	}
	return env;
}

// Hold g_activityMutex for the whole call; rotation swaps under the same lock.
static void call_java_void_string(jmethodID mid, const char *value)
{
	JNIEnv *env = get_env();
	jstring s;
	jobject activity;
	if (!env || !mid)
		return;
	pthread_mutex_lock(&g_activityMutex);
	activity = g_activity;
	if (!activity)
	{
		pthread_mutex_unlock(&g_activityMutex);
		return;
	}
	s = (*env)->NewStringUTF(env, value ? value : "");
	if (!s)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("NewStringUTF OOM; dropping Java call");
		pthread_mutex_unlock(&g_activityMutex);
		return;
	}
	(*env)->CallVoidMethod(env, activity, mid, s);
	(*env)->DeleteLocalRef(env, s);
	if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
	}
	pthread_mutex_unlock(&g_activityMutex);
}

static void call_java_void(jmethodID mid)
{
	JNIEnv *env = get_env();
	jobject activity;
	if (!env || !mid)
		return;
	pthread_mutex_lock(&g_activityMutex);
	activity = g_activity;
	if (!activity)
	{
		pthread_mutex_unlock(&g_activityMutex);
		return;
	}
	(*env)->CallVoidMethod(env, activity, mid);
	if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
	}
	pthread_mutex_unlock(&g_activityMutex);
}

// Blocks the worker on the Java latch. Timeout reads back as "".
static char *call_java_string_sync(jmethodID mid)
{
	JNIEnv *env = get_env();
	jstring s;
	const char *utf;
	char *result = NULL;
	jobject activity;
	if (!env || !mid)
		return xstrdup("");
	pthread_mutex_lock(&g_activityMutex);
	activity = g_activity;
	if (!activity)
	{
		pthread_mutex_unlock(&g_activityMutex);
		return xstrdup("");
	}
	s = (jstring)(*env)->CallObjectMethod(env, activity, mid);
	if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
		pthread_mutex_unlock(&g_activityMutex);
		return xstrdup("");
	}
	pthread_mutex_unlock(&g_activityMutex);
	if (!s)
	{
		// Null = latch timeout/interrupt (Java logs too).
		LOGE("sync query timed out; returning \"\"");
		return xstrdup("");
	}
	utf = (*env)->GetStringUTFChars(env, s, NULL);
	if (!utf)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("GetStringUTFChars OOM on sync query result");
		(*env)->DeleteLocalRef(env, s);
		return xstrdup("");
	}
	result = xstrdup(utf);
	(*env)->ReleaseStringUTFChars(env, s, utf);
	(*env)->DeleteLocalRef(env, s);
	return result ? result : xstrdup("");
}

// Escape for a single-quoted JS string.
static char *js_escape(const char *s)
{
	size_t len, cap;
	char *out, *o;
	const unsigned char *p;
	if (!s)
		return xstrdup("");
	len = strlen(s);
	cap = len * 6 + 1;
	out = (char *)malloc(cap);
	if (!out)
		return xstrdup("");
	o = out;
	for (p = (const unsigned char *)s; *p; p++)
	{
		unsigned char c = *p;
		switch (c)
		{
		case '\\':
			*o++ = '\\';
			*o++ = '\\';
			break;
		case '\'':
			*o++ = '\\';
			*o++ = '\'';
			break;
		case '\n':
			*o++ = '\\';
			*o++ = 'n';
			break;
		case '\r':
			*o++ = '\\';
			*o++ = 'r';
			break;
		case '\t':
			*o++ = '\\';
			*o++ = 't';
			break;
		default:
			if (c < 0x20)
				o += sprintf(o, "\\x%02x", c);
			else
				*o++ = (char)c;
		}
	}
	*o = '\0';
	return out;
}

/* ============================================================================
 * JS injection shim (Promise-based bind protocol, matches desktop webview)
 * ============================================================================
 */

static const char *BASE_SHIM = "(function(){"
							   "if(window.__ringwebview){return;}"
							   "window.__ringwebview={seq:0,pending:{}};"
							   "window.__ringwebview.result=function(id,status,json){"
							   "var p=window.__ringwebview.pending[id];"
							   "if(!p){return;}"
							   "delete window.__ringwebview.pending[id];"
							   "var data;try{data=JSON.parse(json);}catch(e){data=json;}"
							   "if(status===0){p.resolve(data);}else{p.reject(data);}"
							   "};"
							   "})();";

// Safe to eval anytime: shim guards re-init, wrappers re-assign.
// PREFIX + escName + SUFFIX, sized exactly.
static const char *BIND_WRAPPER_PREFIX = "(function(){var n='";
static const char *BIND_WRAPPER_SUFFIX =
	"';"
	"window[n]=function(){"
	"var a=Array.prototype.slice.call(arguments);"
	"var id=String(++window.__ringwebview.seq);"
	"return new Promise(function(res,rej){"
	"window.__ringwebview.pending[id]={resolve:res,reject:rej};"
	"RingBridge.call(n,id,JSON.stringify(a));"
	"});};"
	"})();";

static char *build_bind_js(void)
{
	// Escape first, then size from escaped lengths (js_escape expands up to 6x).
	char *escNames[MAX_BINDS];
	size_t cap = strlen(BASE_SHIM) + 1;
	char *js, *o;
	int i;
	if (g_bindCount < 0 || g_bindCount > MAX_BINDS)
		return NULL;
	for (i = 0; i < g_bindCount; i++)
	{
		if (!g_bindJsName[i])
		{
			while (--i >= 0)
				free(escNames[i]);
			return NULL;
		}
		escNames[i] = js_escape(g_bindJsName[i]);
		if (!escNames[i])
		{
			while (--i >= 0)
				free(escNames[i]);
			return NULL;
		}
		cap += strlen(BIND_WRAPPER_PREFIX) + strlen(escNames[i]) + strlen(BIND_WRAPPER_SUFFIX);
	}

	js = (char *)malloc(cap);
	if (!js)
	{
		for (i = 0; i < g_bindCount; i++)
			free(escNames[i]);
		return NULL;
	}
	o = js;
	// Clamp: truncation must not run past the allocation.
	{
		size_t rem = cap - (size_t)(o - js);
		int w = snprintf(o, rem, "%s", BASE_SHIM);
		o += (w < 0) ? 0 : ((size_t)w >= rem ? rem - 1 : (size_t)w);
	}

	for (i = 0; i < g_bindCount; i++)
	{
		size_t rem = cap - (size_t)(o - js);
		int w = snprintf(o, rem, "%s%s%s", BIND_WRAPPER_PREFIX, escNames[i], BIND_WRAPPER_SUFFIX);
		o += (w < 0) ? 0 : ((size_t)w >= rem ? rem - 1 : (size_t)w);
		free(escNames[i]);
	}
	return js;
}

// Store for re-inject on page load; eval now for the current page.
static void rebuild_inject_js(void)
{
	size_t cap;
	char *full, *o, *bindJs;
	int i;

	bindJs = build_bind_js();
	if (!bindJs)
		return;

	// +64 covers the 33-char wrapper; snprintf truncates on miscount.
	cap = strlen(bindJs) + 1 + 64;
	for (i = 0; i < g_initScriptCount; i++)
		cap += strlen(g_initScripts[i]) + 64;

	full = (char *)malloc(cap);
	if (full)
	{
		size_t left = cap;
		o = full;
		{
			size_t rem = left - (size_t)(o - full);
			int w = snprintf(o, rem, "%s", bindJs);
			o += (w < 0) ? 0 : ((size_t)w >= rem ? rem - 1 : (size_t)w);
		}
		for (i = 0; i < g_initScriptCount; i++)
		{
			size_t rem = left - (size_t)(o - full);
			int w = snprintf(o, rem, "(function(){try{%s}catch(e){}})();", g_initScripts[i]);
			o += (w < 0) ? 0 : ((size_t)w >= rem ? rem - 1 : (size_t)w);
		}
		call_java_void_string(mid_setInjectJs, full);
		free(full);
	}

	call_java_void_string(mid_evalJs, bindJs);
	free(bindJs);
}

#include "ring_webview_json.h"

/* ============================================================================
 * Ring callback execution (worker thread)
 * ============================================================================
 */

static void call_ring_func(const char *cCallback, const char *cArg)
{
	VM *pVM;
	unsigned int nSP_before, nFuncSP_before, nCallListSize_before;

	if (!g_ringState || !cCallback)
		return;
	pVM = g_ringState->pVM;
	if (!pVM)
		return;
	if (!atomic_load_explicit(&g_running, memory_order_acquire))
		return;

	ring_vm_mutexlock(pVM);

	nSP_before = pVM->nSP;
	nFuncSP_before = pVM->nFuncSP;
	nCallListSize_before = RING_VM_FUNCCALLSCOUNT;

	if (!ring_vm_loadfunc2(pVM, (char *)cCallback, RING_FALSE))
	{
		pVM->nSP = nSP_before;
		pVM->nFuncSP = nFuncSP_before;
		ring_vm_mutexunlock(pVM);
		return;
	}

	if (cArg)
	{
		RING_VM_STACK_PUSHCVALUE2(cArg, strlen(cArg));
	}

	ring_vm_call2(pVM);
	while (RING_VM_FUNCCALLSCOUNT > nCallListSize_before)
		ring_vm_fetch(pVM);

	pVM->nSP = nSP_before;
	pVM->nFuncSP = nFuncSP_before;

	ring_vm_mutexunlock(pVM);
}

static void call_ring_bind_func(const char *cFunc, const char *id, const char *req)
{
	VM *pVM;
	unsigned int nSP_before, nFuncSP_before, nCallListSize_before;

	if (!g_ringState || !cFunc)
		return;
	pVM = g_ringState->pVM;
	if (!pVM)
		return;
	if (!atomic_load_explicit(&g_running, memory_order_acquire))
		return;

	ring_vm_mutexlock(pVM);

	nSP_before = pVM->nSP;
	nFuncSP_before = pVM->nFuncSP;
	nCallListSize_before = RING_VM_FUNCCALLSCOUNT;

	if (!ring_vm_loadfunc2(pVM, (char *)cFunc, RING_FALSE))
	{
		pVM->nSP = nSP_before;
		pVM->nFuncSP = nFuncSP_before;
		ring_vm_mutexunlock(pVM);
		return;
	}

	RING_VM_STACK_PUSHCVALUE2(id ? id : "", id ? strlen(id) : 0);

	// req = JSON array of JS args; pass as Ring list.
	{
		List *pReqList = json_decode_to_ring_list(pVM, req);
		if (!pReqList)
		{
			LOGE("bind call \"%s\": invalid JSON request; passing an empty list", cFunc);
			pReqList = ring_vm_api_newlist(pVM);
		}
		ring_vm_api_retlist2(pVM, pReqList, RING_OUTPUT_RETLISTBYREF);
	}

	ring_vm_call2(pVM);
	while (RING_VM_FUNCCALLSCOUNT > nCallListSize_before)
		ring_vm_fetch(pVM);

	pVM->nSP = nSP_before;
	pVM->nFuncSP = nFuncSP_before;

	ring_vm_mutexunlock(pVM);
}

static const char *find_ring_func(const char *jsName)
{
	int i;
	if (!jsName)
		return NULL;
	for (i = 0; i < g_bindCount; i++)
	{
		if (g_bindJsName[i] && strcmp(g_bindJsName[i], jsName) == 0)
			return g_bindRingFunc[i];
	}
	return NULL;
}

// Worker-only state; JNI never touches it.
static void process_job(Job *job)
{
	if (!job)
		return;
	switch (job->type)
	{
	case JOB_BIND_CALL: {
		const char *fn = find_ring_func(job->name);
		if (fn)
			call_ring_bind_func(fn, job->id, job->req);
		else
			LOGE("No Ring binding for JS function: %s", job->name ? job->name : "?");
		break;
	}
	case JOB_PAGE_STARTED:
		if (g_onLoad)
			call_ring_func(g_onLoad, "started");
		if (g_onNavigate && job->arg)
			call_ring_func(g_onNavigate, job->arg);
		break;
	case JOB_PAGE_FINISHED:
		if (g_onLoad)
			call_ring_func(g_onLoad, "finished");
		if (g_onDomReady)
			call_ring_func(g_onDomReady, NULL);
		break;
	case JOB_TITLE_CHANGED:
		if (g_onTitle && job->arg)
			call_ring_func(g_onTitle, job->arg);
		break;
	case JOB_FOCUS_CHANGED:
		if (g_onFocus && job->arg)
			call_ring_func(g_onFocus, job->arg);
		break;
	case JOB_RESIZED:
		if (g_onResize && job->arg)
			call_ring_func(g_onResize, job->arg);
		break;
	case JOB_CLOSE:
		if (g_onClose)
			call_ring_func(g_onClose, NULL);
		break;
	case JOB_DISPATCH:
		if (g_ringState && g_ringState->pVM && job->req)
			ring_vm_runcodefromthread(g_ringState->pVM, job->req);
		break;
	case JOB_REATTACH:
		// Re-push shim+scripts; tables stay single-threaded.
		rebuild_inject_js();
		break;
	case JOB_TERMINATE:
		atomic_store_explicit(&g_terminate, 1, memory_order_release);
		break;
	}
}

/* ============================================================================
 * Asset extraction (APK assets -> filesDir) via JNI AssetManager.list()
 * ============================================================================
 */

static void mkdirs_for(const char *path)
{
	char tmp[1024];
	char *p;
	size_t len;
	int n;
	if (!path || !*path)
		return;
	n = snprintf(tmp, sizeof(tmp), "%s", path);
	if (n < 0 || (size_t)n >= sizeof(tmp))
	{
		LOGE("path too long, skipping mkdirs: %.64s...", path);
		return;
	}
	len = strlen(tmp);
	if (len > 0 && tmp[len - 1] == '/')
		tmp[len - 1] = '\0';
	for (p = tmp + 1; *p; p++)
	{
		if (*p == '/')
		{
			*p = '\0';
			mkdir(tmp, 0755);
			*p = '/';
		}
	}
}

static int asset_is_file(const char *assetPath)
{
	AAsset *asset;
	if (!g_assetMgr)
		return 0;
	asset = AAssetManager_open(g_assetMgr, assetPath, AASSET_MODE_STREAMING);
	if (asset)
	{
		AAsset_close(asset);
		return 1;
	}
	return 0;
}

static void extract_asset_file(const char *assetPath, const char *destPath)
{
	AAsset *asset;
	off_t length;
	char buf[8192];
	int rd;
	FILE *out;

	if (!g_assetMgr)
		return;
	asset = AAssetManager_open(g_assetMgr, assetPath, AASSET_MODE_STREAMING);
	if (!asset)
	{
		LOGE("Cannot open asset: %s", assetPath);
		return;
	}
	length = AAsset_getLength(asset);
	(void)length;

	mkdirs_for(destPath);
	out = fopen(destPath, "wb");
	if (!out)
	{
		LOGE("Cannot write: %s", destPath);
		AAsset_close(asset);
		return;
	}
	while ((rd = AAsset_read(asset, buf, sizeof(buf))) > 0)
		fwrite(buf, 1, rd, out);
	fclose(out);
	AAsset_close(asset);
	LOGI("Extracted: %s", assetPath);
}

static void extract_dir(JNIEnv *env, const char *assetDir, const char *destDir)
{
	jstring jdir;
	jobjectArray entries;
	jsize n, i;

	if (!env || !g_assetMgrJava || !mid_assetList)
		return;

	jdir = (*env)->NewStringUTF(env, assetDir ? assetDir : "");
	if (!jdir)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("NewStringUTF OOM in extract_dir");
		return;
	}
	entries = (jobjectArray)(*env)->CallObjectMethod(env, g_assetMgrJava, mid_assetList, jdir);
	(*env)->DeleteLocalRef(env, jdir);
	if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
		return;
	}
	if (!entries)
		return;

	n = (*env)->GetArrayLength(env, entries);
	for (i = 0; i < n; i++)
	{
		jstring jname = (jstring)(*env)->GetObjectArrayElement(env, entries, i);
		const char *name;
		char assetPath[1024];
		char destPath[1024];
		int na, nd;
		if (!jname)
			continue;
		if ((*env)->ExceptionCheck(env))
		{
			(*env)->ExceptionClear(env);
			continue;
		}
		name = (*env)->GetStringUTFChars(env, jname, NULL);
		if (!name)
		{
			if ((*env)->ExceptionCheck(env))
				(*env)->ExceptionClear(env);
			LOGE("GetStringUTFChars OOM in extract_dir");
			(*env)->DeleteLocalRef(env, jname);
			continue;
		}

		if (assetDir && assetDir[0])
			na = snprintf(assetPath, sizeof(assetPath), "%s/%s", assetDir, name);
		else
			na = snprintf(assetPath, sizeof(assetPath), "%s", name);
		nd = snprintf(destPath, sizeof(destPath), "%s/%s", destDir, name);
		if (na < 0 || (size_t)na >= sizeof(assetPath) || nd < 0 || (size_t)nd >= sizeof(destPath))
		{
			LOGE("asset path too long, skipping: %.64s", name);
			(*env)->ReleaseStringUTFChars(env, jname, name);
			(*env)->DeleteLocalRef(env, jname);
			continue;
		}

		if (asset_is_file(assetPath))
		{
			extract_asset_file(assetPath, destPath);
		}
		else
		{
			mkdir(destPath, 0755);
			extract_dir(env, assetPath, destPath);
		}

		(*env)->ReleaseStringUTFChars(env, jname, name);
		(*env)->DeleteLocalRef(env, jname);
	}
	(*env)->DeleteLocalRef(env, entries);
}

// 1 = assets present or unreadable (extract); 0 = confirmed none.
static int apk_has_assets(const char *path)
{
	FILE *f;
	long fsize, scanStart, cdSize, p, i, eocd = -1;
	static unsigned char buf[65557];
	unsigned char *cd;
	unsigned int nEntries, e;
	int found;

	if (!path || !*path)
		return 1;
	f = fopen(path, "rb");
	if (!f)
		return 1;
	if (fseek(f, 0, SEEK_END) != 0 || (fsize = ftell(f)) < 22)
	{
		fclose(f);
		return 1;
	}

	// Find EOCD scanning backwards.
	scanStart = fsize - (long)sizeof(buf);
	if (scanStart < 0)
		scanStart = 0;
	if (fseek(f, scanStart, SEEK_SET) != 0)
	{
		fclose(f);
		return 1;
	}
	{
		long n = (long)fread(buf, 1, sizeof(buf), f);
		for (i = n - 22; i >= 0; i--)
			if (buf[i] == 0x50 && buf[i + 1] == 0x4b && buf[i + 2] == 0x05 && buf[i + 3] == 0x06)
			{
				eocd = i;
				break;
			}
	}
	if (eocd < 0)
	{
		fclose(f);
		return 1;
	}

	nEntries = (unsigned int)(buf[eocd + 10] | (buf[eocd + 11] << 8));
	{
		long cdOff = (long)((unsigned int)(buf[eocd + 16] | (buf[eocd + 17] << 8) | (buf[eocd + 18] << 16) |
										   ((unsigned int)buf[eocd + 19] << 24)));
		if (nEntries == 0)
		{
			fclose(f);
			return 0;
		}
		if (nEntries == 0xFFFF || cdOff < 0 || cdOff >= fsize)
		{
			fclose(f);
			// zip64/malformed: extract.
			return 1;
		}

		cdSize = fsize - cdOff;
		// Cap the transient malloc; fall back to extracting.
		if (cdSize > (long)(8 * 1024 * 1024))
		{
			fclose(f);
			LOGI("APK central dir too large (%ld); assuming assets exist", cdSize);
			return 1;
		}
		cd = (unsigned char *)malloc((size_t)cdSize);
		if (!cd)
		{
			fclose(f);
			return 1;
		}
		if (fseek(f, cdOff, SEEK_SET) != 0 || fread(cd, 1, (size_t)cdSize, f) != (size_t)cdSize)
		{
			free(cd);
			fclose(f);
			return 1;
		}
		fclose(f);

		found = 0;
		for (e = 0, p = 0; e < nEntries; e++)
		{
			unsigned int nameLen, extraLen, commentLen;
			if (p + 46 > cdSize)
				break;
			if (!(cd[p] == 0x50 && cd[p + 1] == 0x4b && cd[p + 2] == 0x01 && cd[p + 3] == 0x02))
				break;
			nameLen = (unsigned int)(cd[p + 28] | (cd[p + 29] << 8));
			extraLen = (unsigned int)(cd[p + 30] | (cd[p + 31] << 8));
			commentLen = (unsigned int)(cd[p + 32] | (cd[p + 33] << 8));
			if (nameLen >= 7 && memcmp(cd + p + 46, "assets/", 7) == 0)
			{
				found = 1;
				break;
			}
			p += 46 + nameLen + extraLen + commentLen;
		}
		free(cd);
	}
	return found;
}

static void extract_assets(void)
{
	JNIEnv *env = get_env();
	if (!env)
		return;
	// Skip when the APK has no assets/ (merged providers would dump junk).
	if (!apk_has_assets(g_apkPath))
	{
		LOGI("No app assets; skipping extraction");
		return;
	}
	mkdir(g_basePath, 0755);
	extract_dir(env, "", g_basePath);
}

/* ============================================================================
 * stdout/stderr -> logcat pipe (so Ring `see` output is visible in logcat)
 * ============================================================================
 */

static int g_logPipe[2];
static pthread_t g_logThread;
static atomic_int g_loggerStarted = 0;

static void *log_thread(void *arg)
{
	ssize_t rdsz;
	char buf[256];
	(void)arg;
	while ((rdsz = read(g_logPipe[0], buf, sizeof(buf) - 1)) > 0)
	{
		buf[rdsz] = '\0';
		__android_log_write(ANDROID_LOG_INFO, "RingOutput", buf);
	}
	return NULL;
}

static void start_logger(void)
{
	// Detached thread, process lifetime; single-start for rotation.
	if (atomic_exchange_explicit(&g_loggerStarted, 1, memory_order_acq_rel))
		return;
	setvbuf(stdout, 0, _IOLBF, 0);
	setvbuf(stderr, 0, _IONBF, 0);
	if (pipe(g_logPipe) != 0)
	{
		atomic_store_explicit(&g_loggerStarted, 0, memory_order_release);
		return;
	}
	dup2(g_logPipe[1], 1);
	dup2(g_logPipe[1], 2);
	if (pthread_create(&g_logThread, 0, log_thread, 0) != 0)
		return;
	pthread_detach(g_logThread);
}

/* ============================================================================
 * Worker thread: runs the Ring VM
 * ============================================================================
 */

static void *worker_thread(void *arg)
{
	JNIEnv *env = NULL;

	(void)arg;
	if (g_jvm)
		(*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL);

	LOGI("Worker started, base path: %s", g_basePath);

	start_logger();

	extract_assets();
	if (chdir(g_basePath) != 0)
		LOGE("chdir failed: %s", g_basePath);

	// Ring loading lives in the app's main.c.
	ring_app_main();
	LOGI("Ring app finished");

	// Finish the Activity if still alive.
	call_java_void(mid_finishApp);

	// Worker is the last native user; drop global refs.
	{
		JNIEnv *cleanEnv = NULL;
		if (g_jvm && (*g_jvm)->GetEnv(g_jvm, (void **)&cleanEnv, JNI_VERSION_1_6) == JNI_OK && cleanEnv)
		{
			pthread_mutex_lock(&g_activityMutex);
			if (g_activity)
			{
				(*cleanEnv)->DeleteGlobalRef(cleanEnv, g_activity);
				g_activity = NULL;
			}
			if (g_assetMgrJava)
			{
				(*cleanEnv)->DeleteGlobalRef(cleanEnv, g_assetMgrJava);
				g_assetMgrJava = NULL;
			}
			pthread_mutex_unlock(&g_activityMutex);
			g_assetMgr = NULL;
		}
	}

	if (g_jvm)
		(*g_jvm)->DetachCurrentThread(g_jvm);
	return NULL;
}

// Java -> C (io.github.ysdragon.webview.MainActivity). Entry points only enqueue.

JNIEXPORT jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
	(void)reserved;
	g_jvm = vm;
	LOGI("ring_webview_android loaded");
	return JNI_VERSION_1_6;
}

static void cache_activity_methods(JNIEnv *env, jobject thiz)
{
	jclass cls = (*env)->GetObjectClass(env, thiz);
	if (!cls)
		return;
	mid_evalJs = (*env)->GetMethodID(env, cls, "evalJs", "(Ljava/lang/String;)V");
	mid_loadUrl = (*env)->GetMethodID(env, cls, "loadUrl", "(Ljava/lang/String;)V");
	mid_loadHtml = (*env)->GetMethodID(env, cls, "loadHtml", "(Ljava/lang/String;)V");
	mid_goBack = (*env)->GetMethodID(env, cls, "goBack", "()V");
	mid_goForward = (*env)->GetMethodID(env, cls, "goForward", "()V");
	mid_reload = (*env)->GetMethodID(env, cls, "reload", "()V");
	mid_getUrlSync = (*env)->GetMethodID(env, cls, "getUrlSync", "()Ljava/lang/String;");
	mid_getTitleSync = (*env)->GetMethodID(env, cls, "getTitleSync", "()Ljava/lang/String;");
	mid_setDebug = (*env)->GetMethodID(env, cls, "setDebug", "(Z)V");
	mid_setInjectJs = (*env)->GetMethodID(env, cls, "setInjectJs", "(Ljava/lang/String;)V");
	mid_finishApp = (*env)->GetMethodID(env, cls, "finishApp", "()V");
	(*env)->DeleteLocalRef(env, cls);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeStart(JNIEnv *env, jobject thiz)
{
	jobject assets;
	jclass assetCls;
	jobject filesDir;
	jmethodID midGetFilesDir, midGetAbsPath, midGetAssets;
	jstring absPath;
	const char *utf;
	jclass clsForPaths;

	// Rotation: worker runs, just swap to the new Activity.
	if (g_workerStarted)
	{
		jobject newRef;
		jobject oldRef;
		pthread_mutex_lock(&g_activityMutex);
		newRef = (*env)->NewGlobalRef(env, thiz);
		if (newRef)
		{
			oldRef = g_activity;
			g_activity = newRef;
			cache_activity_methods(env, thiz);
			if (oldRef)
				(*env)->DeleteGlobalRef(env, oldRef);
			LOGI("re-attached to new Activity after rotation");
		}
		else
		{
			if ((*env)->ExceptionCheck(env))
				(*env)->ExceptionClear(env);
			LOGE("NewGlobalRef OOM on re-attach; keeping old Activity");
		}
		pthread_mutex_unlock(&g_activityMutex);
		// New Activity lost injectJs; re-push from worker.
		enqueue_raw_event(JOB_REATTACH, NULL);
		return;
	}

	pthread_mutex_lock(&g_activityMutex);
	g_activity = (*env)->NewGlobalRef(env, thiz);
	if (!g_activity)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		pthread_mutex_unlock(&g_activityMutex);
		LOGE("NewGlobalRef OOM in nativeStart");
		return;
	}
	cache_activity_methods(env, thiz);
	pthread_mutex_unlock(&g_activityMutex);
	clsForPaths = (*env)->GetObjectClass(env, thiz);

	if (!clsForPaths)
	{
		pthread_mutex_lock(&g_activityMutex);
		if (g_activity)
		{
			(*env)->DeleteGlobalRef(env, g_activity);
			g_activity = NULL;
		}
		pthread_mutex_unlock(&g_activityMutex);
		LOGE("GetObjectClass failed in nativeStart");
		return;
	}
	// AssetManager (Java + native).
	midGetAssets = (*env)->GetMethodID(env, clsForPaths, "getAssets", "()Landroid/content/res/AssetManager;");
	assets = midGetAssets ? (*env)->CallObjectMethod(env, thiz, midGetAssets) : NULL;
	if (assets && !(*env)->ExceptionCheck(env))
	{
		jobject assetRef = (*env)->NewGlobalRef(env, assets);
		if (assetRef)
		{
			g_assetMgrJava = assetRef;
			g_assetMgr = AAssetManager_fromJava(env, assets);
			assetCls = (*env)->GetObjectClass(env, assets);
			if (assetCls)
			{
				mid_assetList = (*env)->GetMethodID(env, assetCls, "list", "(Ljava/lang/String;)[Ljava/lang/String;");
				(*env)->DeleteLocalRef(env, assetCls);
			}
		}
		else if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		(*env)->DeleteLocalRef(env, assets);
	}
	else if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionDescribe(env);
		(*env)->ExceptionClear(env);
		if (assets)
			(*env)->DeleteLocalRef(env, assets);
	}

	// Base path = filesDir.
	midGetFilesDir = (*env)->GetMethodID(env, clsForPaths, "getFilesDir", "()Ljava/io/File;");
	filesDir = midGetFilesDir ? (*env)->CallObjectMethod(env, thiz, midGetFilesDir) : NULL;
	if (filesDir && !(*env)->ExceptionCheck(env))
	{
		jclass fileCls = (*env)->GetObjectClass(env, filesDir);
		if (fileCls)
		{
			midGetAbsPath = (*env)->GetMethodID(env, fileCls, "getAbsolutePath", "()Ljava/lang/String;");
			absPath = midGetAbsPath ? (jstring)(*env)->CallObjectMethod(env, filesDir, midGetAbsPath) : NULL;
			if (absPath && !(*env)->ExceptionCheck(env))
			{
				utf = (*env)->GetStringUTFChars(env, absPath, NULL);
				if (utf)
				{
					snprintf(g_basePath, sizeof(g_basePath), "%s", utf);
					(*env)->ReleaseStringUTFChars(env, absPath, utf);
				}
				else if ((*env)->ExceptionCheck(env))
					(*env)->ExceptionClear(env);
				(*env)->DeleteLocalRef(env, absPath);
			}
			else if ((*env)->ExceptionCheck(env))
			{
				(*env)->ExceptionClear(env);
				if (absPath)
					(*env)->DeleteLocalRef(env, absPath);
			}
			(*env)->DeleteLocalRef(env, fileCls);
		}
		(*env)->DeleteLocalRef(env, filesDir);
	}
	else if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionClear(env);
		if (filesDir)
			(*env)->DeleteLocalRef(env, filesDir);
	}

	// APK path (asset-presence check).
	{
		jmethodID midGetPkgPath = (*env)->GetMethodID(env, clsForPaths, "getPackageCodePath", "()Ljava/lang/String;");
		jstring pkgPath = midGetPkgPath ? (jstring)(*env)->CallObjectMethod(env, thiz, midGetPkgPath) : NULL;
		if (pkgPath && !(*env)->ExceptionCheck(env))
		{
			const char *putf = (*env)->GetStringUTFChars(env, pkgPath, NULL);
			if (putf)
			{
				snprintf(g_apkPath, sizeof(g_apkPath), "%s", putf);
				(*env)->ReleaseStringUTFChars(env, pkgPath, putf);
			}
			else if ((*env)->ExceptionCheck(env))
				(*env)->ExceptionClear(env);
			(*env)->DeleteLocalRef(env, pkgPath);
		}
		else if ((*env)->ExceptionCheck(env))
		{
			(*env)->ExceptionClear(env);
			if (pkgPath)
				(*env)->DeleteLocalRef(env, pkgPath);
		}
	}
	(*env)->DeleteLocalRef(env, clsForPaths);
	if (pthread_create(&g_workerThread, NULL, worker_thread, NULL) == 0)
		g_workerStarted = 1;
	else
		LOGE("Failed to create worker thread");
}

// Java calls this only when finishing; rotation re-attaches instead.
JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeDestroy(JNIEnv *env, jobject thiz)
{
	(void)env;
	(void)thiz;
	atomic_store_explicit(&g_terminate, 1, memory_order_release);
	enqueue_terminate();
	queue_signal_all();
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnBridgeCall(JNIEnv *env, jobject thiz, jstring jname,
																			 jstring jid, jstring jreq)
{
	const char *name, *id, *req;
	(void)thiz;
	name = jname ? (*env)->GetStringUTFChars(env, jname, NULL) : NULL;
	id = jid ? (*env)->GetStringUTFChars(env, jid, NULL) : NULL;
	req = jreq ? (*env)->GetStringUTFChars(env, jreq, NULL) : NULL;
	if ((jname && !name) || (jid && !id) || (jreq && !req))
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("GetStringUTFChars OOM in bridge call; dropping");
	}
	else
	{
		enqueue_bind_call(name, id, req);
	}

	if (name)
		(*env)->ReleaseStringUTFChars(env, jname, name);
	if (id)
		(*env)->ReleaseStringUTFChars(env, jid, id);
	if (req)
		(*env)->ReleaseStringUTFChars(env, jreq, req);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnPageStarted(JNIEnv *env, jobject thiz, jstring jurl)
{
	const char *url;
	(void)thiz;
	url = jurl ? (*env)->GetStringUTFChars(env, jurl, NULL) : NULL;
	if (jurl && !url)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("GetStringUTFChars OOM in onPageStarted");
		return;
	}
	enqueue_raw_event(JOB_PAGE_STARTED, url);
	if (url)
		(*env)->ReleaseStringUTFChars(env, jurl, url);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnPageFinished(JNIEnv *env, jobject thiz, jstring jurl)
{
	const char *url;
	(void)thiz;
	url = jurl ? (*env)->GetStringUTFChars(env, jurl, NULL) : NULL;
	if (jurl && !url)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("GetStringUTFChars OOM in onPageFinished");
		return;
	}
	enqueue_raw_event(JOB_PAGE_FINISHED, url);
	if (url)
		(*env)->ReleaseStringUTFChars(env, jurl, url);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnTitleChanged(JNIEnv *env, jobject thiz,
																			   jstring jtitle)
{
	const char *title;
	(void)thiz;
	title = jtitle ? (*env)->GetStringUTFChars(env, jtitle, NULL) : NULL;
	if (jtitle && !title)
	{
		if ((*env)->ExceptionCheck(env))
			(*env)->ExceptionClear(env);
		LOGE("GetStringUTFChars OOM in onTitleChanged");
		return;
	}
	if (title)
		enqueue_raw_event(JOB_TITLE_CHANGED, title);
	if (title)
		(*env)->ReleaseStringUTFChars(env, jtitle, title);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnFocusChanged(JNIEnv *env, jobject thiz,
																			   jboolean focused)
{
	(void)env;
	(void)thiz;
	enqueue_raw_event(JOB_FOCUS_CHANGED, focused ? "true" : "false");
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnResize(JNIEnv *env, jobject thiz, jint width,
																		 jint height)
{
	char buf[32];
	(void)env;
	(void)thiz;
	snprintf(buf, sizeof(buf), "%dx%d", (int)width, (int)height);
	buf[sizeof(buf) - 1] = '\0';
	enqueue_raw_event(JOB_RESIZED, buf);
}

JNIEXPORT void JNICALL Java_io_github_ysdragon_webview_MainActivity_nativeOnClose(JNIEnv *env, jobject thiz)
{
	(void)env;
	(void)thiz;
	enqueue_raw_event(JOB_CLOSE, NULL);
}

/* ============================================================================
 * Ring C-API: helpers
 * ============================================================================
 */

static void ring_webview_android_free(void *pState, void *pPointer)
{
	if (pPointer)
		ring_state_free(pState, pPointer);
}

static int api_check_webview(void *pPointer)
{
	if (RING_API_PARACOUNT < 1)
		return 0;
	if (!RING_API_ISCPOINTER(1))
		return 0;
	if (!atomic_load_explicit(&g_webviewCreated, memory_order_acquire))
		return 0;
	(void)pPointer;
	return 1;
}

/* ============================================================================
 * Ring C-API: core lifecycle
 * ============================================================================
 */

RING_FUNC(ring_webview_create)
{
	int debug;
	int *pHandle;

	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISNUMBER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	debug = (int)RING_API_GETNUMBER(1);

	// One webview per process; all state is global.
	if (atomic_exchange_explicit(&g_webviewCreated, 1, memory_order_acq_rel))
	{
		RING_API_ERROR("webview_create: Android backend supports a single webview instance");
		return;
	}
	g_ringState = RING_API_STATE;
	atomic_store_explicit(&g_terminate, 0, memory_order_release);

	// Forward debug flag to Java.
	{
		JNIEnv *env = get_env();
		jobject activity;
		jmethodID setDebug;
		pthread_mutex_lock(&g_activityMutex);
		activity = g_activity;
		setDebug = mid_setDebug;
		if (env && activity && setDebug)
		{
			(*env)->CallVoidMethod(env, activity, setDebug, debug ? JNI_TRUE : JNI_FALSE);
			// Clear: a pending exception aborts the next JNI call.
			if ((*env)->ExceptionCheck(env))
			{
				(*env)->ExceptionDescribe(env);
				(*env)->ExceptionClear(env);
			}
		}
		pthread_mutex_unlock(&g_activityMutex);
	}

	// Shim now so bind works before the first page load.
	rebuild_inject_js();

	pHandle = (int *)RING_API_MALLOC(sizeof(int));
	if (!pHandle)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}
	*pHandle = 1;
	RING_API_RETMANAGEDCPOINTER(pHandle, "webview_t", ring_webview_android_free);
}

RING_FUNC(ring_webview_run)
{
	if (!api_check_webview(pPointer))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	atomic_store_explicit(&g_running, 1, memory_order_release);
	while (!atomic_load_explicit(&g_terminate, memory_order_acquire))
	{
		Job *job = dequeue_job_blocking();
		if (job)
		{
			process_job(job);
			free_job(job);
		}
		// NULL = terminated with an empty queue.
	}
	// Drain jobs that raced terminate; VM still alive.
	for (;;)
	{
		Job *job = try_dequeue_job();
		if (!job)
			break;
		process_job(job);
		free_job(job);
	}
	atomic_store_explicit(&g_running, 0, memory_order_release);
}

RING_FUNC(ring_webview_terminate)
{
	if (!api_check_webview(pPointer))
		return;
	atomic_store_explicit(&g_terminate, 1, memory_order_release);
	enqueue_terminate();
	queue_signal_all();
	call_java_void(mid_finishApp);
}

RING_FUNC(ring_webview_destroy)
{
	if (RING_API_PARACOUNT < 1)
		return;
	atomic_store_explicit(&g_terminate, 1, memory_order_release);
	atomic_store_explicit(&g_running, 0, memory_order_release);
	atomic_store_explicit(&g_webviewCreated, 0, memory_order_release);
	enqueue_terminate();
	queue_signal_all();
	if (RING_API_ISCPOINTER(1))
		RING_API_SETNULLPOINTER(1);
}

RING_FUNC(ring_webview_dispatch)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	enqueue_dispatch(RING_API_GETSTRING(2));
	// WEBVIEW_ERROR_OK.
	RING_API_RETNUMBER(0);
}

/* ============================================================================
 * Ring C-API: navigation & content
 * ============================================================================
 */

RING_FUNC(ring_webview_navigate)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	call_java_void_string(mid_loadUrl, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_set_html)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	call_java_void_string(mid_loadHtml, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_eval)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	call_java_void_string(mid_evalJs, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_init)
{
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	if (g_initScriptCount < MAX_INIT_SCRIPTS)
	{
		g_initScripts[g_initScriptCount] = xstrdup(RING_API_GETSTRING(2));
		g_initScriptCount++;
		rebuild_inject_js();
	}
}

RING_FUNC(ring_webview_back)
{
	if (!api_check_webview(pPointer))
		return;
	call_java_void(mid_goBack);
	RING_API_RETNUMBER(1);
}

RING_FUNC(ring_webview_forward)
{
	if (!api_check_webview(pPointer))
		return;
	call_java_void(mid_goForward);
	RING_API_RETNUMBER(1);
}

RING_FUNC(ring_webview_reload)
{
	if (!api_check_webview(pPointer))
		return;
	call_java_void(mid_reload);
	RING_API_RETNUMBER(1);
}

RING_FUNC(ring_webview_get_url)
{
	char *url;
	if (!api_check_webview(pPointer))
	{
		RING_API_RETSTRING("");
		return;
	}
	url = call_java_string_sync(mid_getUrlSync);
	RING_API_RETSTRING(url ? url : "");
	if (url)
		free(url);
}

RING_FUNC(ring_webview_get_title)
{
	char *title;
	if (!api_check_webview(pPointer))
	{
		RING_API_RETSTRING("");
		return;
	}
	title = call_java_string_sync(mid_getTitleSync);
	RING_API_RETSTRING(title ? title : "");
	if (title)
		free(title);
}

/* ============================================================================
 * Ring C-API: binding
 * ============================================================================
 */

RING_FUNC(ring_webview_bind)
{
	const char *jsName;
	const char *ringFunc;
	char *lower;
	char *p;
	int *h;

	if (RING_API_PARACOUNT != 3)
	{
		RING_API_ERROR(RING_API_MISS3PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2) || !RING_API_ISSTRING(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	jsName = RING_API_GETSTRING(2);
	ringFunc = RING_API_GETSTRING(3);

	if (g_bindCount >= MAX_BINDS)
	{
		RING_API_RETNUMBER(-1);
		return;
	}

	g_bindJsName[g_bindCount] = xstrdup(jsName);
	lower = xstrdup(ringFunc);
	for (p = lower; p && *p; p++)
		*p = (char)tolower((unsigned char)*p);
	g_bindRingFunc[g_bindCount] = lower;
	g_bindCount++;

	rebuild_inject_js();

	h = (int *)RING_API_MALLOC(sizeof(int));
	if (!h)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}
	*h = g_bindCount;
	RING_API_RETMANAGEDCPOINTER(h, "webview_bind_t", ring_webview_android_free);
}

RING_FUNC(ring_webview_unbind)
{
	const char *jsName;
	int i;
	if (RING_API_PARACOUNT != 2 || !RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	jsName = RING_API_GETSTRING(2);
	for (i = 0; i < g_bindCount; i++)
	{
		if (g_bindJsName[i] && strcmp(g_bindJsName[i], jsName) == 0)
		{
			free(g_bindJsName[i]);
			free(g_bindRingFunc[i]);
			g_bindJsName[i] = g_bindJsName[g_bindCount - 1];
			g_bindRingFunc[i] = g_bindRingFunc[g_bindCount - 1];
			g_bindCount--;
			rebuild_inject_js();
			RING_API_RETNUMBER(0);
			return;
		}
	}
	RING_API_RETNUMBER(-1);
}

RING_FUNC(ring_webview_return)
{
	const char *id;
	int status;
	const char *json;
	char *cJsonOwned = NULL;
	char *escId, *escJson, *js;
	size_t cap;

	if (RING_API_PARACOUNT != 4)
	{
		RING_API_ERROR(RING_API_MISS4PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2) || !RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	id = RING_API_GETSTRING(2);
	status = (int)RING_API_GETNUMBER(3);

	if (RING_API_ISLIST(4))
	{
		cJsonOwned = ring_list_to_json_string(RING_API_STATE, RING_API_GETLIST(4));
		if (!cJsonOwned)
		{
			RING_API_ERROR("Failed to generate JSON string from list.");
			return;
		}
		json = cJsonOwned;
	}
	else if (RING_API_ISNUMBER(4))
	{
		cJsonOwned = ring_number_to_json_string(RING_API_GETNUMBER(4));
		if (!cJsonOwned)
		{
			RING_API_ERROR("Failed to generate JSON number.");
			return;
		}
		json = cJsonOwned;
	}
	else if (RING_API_ISSTRING(4))
	{
		json = RING_API_GETSTRING(4);
	}
	else
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	escId = js_escape(id);
	escJson = js_escape(json);
	// Stale wreturn: page moved on, shim not back yet. Drop; the promise died with the page.
	// Fixed overhead 71 + int; +128 slack, snprintf truncates on miscount.
	cap = strlen(escId) + strlen(escJson) + 128;
	js = (char *)malloc(cap);
	if (js)
	{
		snprintf(js, cap, "(function(){var w=window.__ringwebview;if(w)w.result('%s',%d,'%s');})();", escId, status, escJson);
		js[cap - 1] = '\0';
		call_java_void_string(mid_evalJs, js);
		free(js);
	}
	free(escId);
	free(escJson);
	if (cJsonOwned)
		free(cJsonOwned);
}

RING_FUNC(ring_webview_version)
{
	if (RING_API_PARACOUNT != 0)
	{
		RING_API_ERROR(RING_API_BADPARACOUNT);
		return;
	}
	RING_API_RETSTRING(RING_WEBVIEW_ANDROID_VERSION);
}

/* ============================================================================
 * Ring C-API: event callbacks
 * ============================================================================
 */

#define RING_WEBVIEW_ANDROID_SET_EVENT(funcname, member)                                                               \
	RING_FUNC(funcname)                                                                                                \
	{                                                                                                                  \
		if (RING_API_PARACOUNT != 2)                                                                                   \
		{                                                                                                              \
			RING_API_ERROR(RING_API_MISS2PARA);                                                                        \
			return;                                                                                                    \
		}                                                                                                              \
		if (!RING_API_ISCPOINTER(1) || !RING_API_ISSTRING(2))                                                          \
		{                                                                                                              \
			RING_API_ERROR(RING_API_BADPARATYPE);                                                                      \
			return;                                                                                                    \
		}                                                                                                              \
		if (member)                                                                                                    \
		{                                                                                                              \
			free(member);                                                                                              \
			member = NULL;                                                                                             \
		}                                                                                                              \
		member = xstrdup(RING_API_GETSTRING(2));                                                                       \
		RING_API_RETNUMBER(1);                                                                                         \
	}

RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_close, g_onClose)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_resize, g_onResize)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_focus, g_onFocus)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_dom_ready, g_onDomReady)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_load, g_onLoad)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_navigate, g_onNavigate)
RING_WEBVIEW_ANDROID_SET_EVENT(ring_webview_on_title, g_onTitle)

/* ============================================================================
 * Ring C-API: window-management no-ops (desktop parity, safe on Android)
 * ============================================================================
 */

#define RING_WEBVIEW_ANDROID_NOOP_RET1(funcname)                                                                       \
	RING_FUNC(funcname)                                                                                                \
	{                                                                                                                  \
		RING_API_RETNUMBER(1);                                                                                         \
	}

#define RING_WEBVIEW_ANDROID_NOOP_RET0(funcname)                                                                       \
	RING_FUNC(funcname)                                                                                                \
	{                                                                                                                  \
		RING_API_RETNUMBER(0);                                                                                         \
	}

RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_title)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_size)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_decorated)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_opacity)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_always_on_top)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_minimize)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_maximize)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_restore)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_maximized)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_start_drag)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_position)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_focus)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_hide)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_show)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_start_resize)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_fullscreen)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_fullscreen)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_resizable)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_resizable)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_min_size)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_max_size)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_background_color)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_icon)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_focused)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_is_visible)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_close)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_dev_tools)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_context_menu)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_force_dark)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_force_dark)
RING_WEBVIEW_ANDROID_NOOP_RET1(ring_webview_set_click_through)
RING_WEBVIEW_ANDROID_NOOP_RET0(ring_webview_is_click_through)

RING_FUNC(ring_webview_get_window)
{
	RING_API_RETCPOINTER(NULL, "void");
}

RING_FUNC(ring_webview_get_native_handle)
{
	RING_API_RETCPOINTER(NULL, "void");
}

RING_FUNC(ring_webview_get_position)
{
	List *pList = ring_list_new(0);
	ring_list_adddouble_gc(RING_API_STATE, pList, 0);
	ring_list_adddouble_gc(RING_API_STATE, pList, 0);
	RING_API_RETLIST(pList);
}

RING_FUNC(ring_webview_get_size)
{
	List *pList = ring_list_new(0);
	ring_list_adddouble_gc(RING_API_STATE, pList, 0);
	ring_list_adddouble_gc(RING_API_STATE, pList, 0);
	RING_API_RETLIST(pList);
}

RING_FUNC(ring_webview_get_screens)
{
	List *pList = ring_list_new(0);
	RING_API_RETLIST(pList);
}

/* ============================================================================
 * Ring C-API: constants
 * ============================================================================
 */

RING_FUNC(ring_get_webview_hint_none)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_hint_min)
{
	RING_API_RETNUMBER(1);
}
RING_FUNC(ring_get_webview_hint_max)
{
	RING_API_RETNUMBER(2);
}
RING_FUNC(ring_get_webview_hint_fixed)
{
	RING_API_RETNUMBER(3);
}
RING_FUNC(ring_get_webview_native_handle_kind_ui_window)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_native_handle_kind_ui_widget)
{
	RING_API_RETNUMBER(1);
}
RING_FUNC(ring_get_webview_native_handle_kind_browser_controller)
{
	RING_API_RETNUMBER(2);
}
RING_FUNC(ring_get_webview_error_ok)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_error_unspecified)
{
	RING_API_RETNUMBER(1);
}
RING_FUNC(ring_get_webview_error_invalid_argument)
{
	RING_API_RETNUMBER(2);
}
RING_FUNC(ring_get_webview_error_invalid_state)
{
	RING_API_RETNUMBER(3);
}
RING_FUNC(ring_get_webview_error_canceled)
{
	RING_API_RETNUMBER(4);
}
RING_FUNC(ring_get_webview_error_missing_dependency)
{
	RING_API_RETNUMBER(5);
}
RING_FUNC(ring_get_webview_error_duplicate)
{
	RING_API_RETNUMBER(6);
}
RING_FUNC(ring_get_webview_error_not_found)
{
	RING_API_RETNUMBER(7);
}
RING_FUNC(ring_get_webview_version_major)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_version_minor)
{
	RING_API_RETNUMBER(12);
}
RING_FUNC(ring_get_webview_version_patch)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_edge_top)
{
	RING_API_RETNUMBER(0);
}
RING_FUNC(ring_get_webview_edge_bottom)
{
	RING_API_RETNUMBER(1);
}
RING_FUNC(ring_get_webview_edge_left)
{
	RING_API_RETNUMBER(2);
}
RING_FUNC(ring_get_webview_edge_right)
{
	RING_API_RETNUMBER(3);
}
RING_FUNC(ring_get_webview_edge_top_left)
{
	RING_API_RETNUMBER(4);
}
RING_FUNC(ring_get_webview_edge_top_right)
{
	RING_API_RETNUMBER(5);
}
RING_FUNC(ring_get_webview_edge_bottom_left)
{
	RING_API_RETNUMBER(6);
}
RING_FUNC(ring_get_webview_edge_bottom_right)
{
	RING_API_RETNUMBER(7);
}

/* ============================================================================
 * Library initialization
 * ============================================================================
 */

RING_LIBINIT
{
	/* Core lifecycle */
	RING_API_REGISTER("webview_create", ring_webview_create);
	RING_API_REGISTER("webview_destroy", ring_webview_destroy);
	RING_API_REGISTER("webview_run", ring_webview_run);
	RING_API_REGISTER("webview_terminate", ring_webview_terminate);
	RING_API_REGISTER("webview_dispatch", ring_webview_dispatch);
	RING_API_REGISTER("webview_version", ring_webview_version);

	/* Navigation & content */
	RING_API_REGISTER("webview_navigate", ring_webview_navigate);
	RING_API_REGISTER("webview_set_html", ring_webview_set_html);
	RING_API_REGISTER("webview_eval", ring_webview_eval);
	RING_API_REGISTER("webview_init", ring_webview_init);
	RING_API_REGISTER("webview_back", ring_webview_back);
	RING_API_REGISTER("webview_forward", ring_webview_forward);
	RING_API_REGISTER("webview_reload", ring_webview_reload);
	RING_API_REGISTER("webview_get_url", ring_webview_get_url);
	RING_API_REGISTER("webview_get_title", ring_webview_get_title);

	/* Binding */
	RING_API_REGISTER("webview_bind", ring_webview_bind);
	RING_API_REGISTER("webview_unbind", ring_webview_unbind);
	RING_API_REGISTER("webview_return", ring_webview_return);

	/* Handles */
	RING_API_REGISTER("webview_get_window", ring_webview_get_window);
	RING_API_REGISTER("webview_get_native_handle", ring_webview_get_native_handle);

	/* Window management */
	RING_API_REGISTER("webview_set_title", ring_webview_set_title);
	RING_API_REGISTER("webview_set_size", ring_webview_set_size);
	RING_API_REGISTER("webview_set_decorated", ring_webview_set_decorated);
	RING_API_REGISTER("webview_set_opacity", ring_webview_set_opacity);
	RING_API_REGISTER("webview_set_always_on_top", ring_webview_set_always_on_top);
	RING_API_REGISTER("webview_minimize", ring_webview_minimize);
	RING_API_REGISTER("webview_maximize", ring_webview_maximize);
	RING_API_REGISTER("webview_restore", ring_webview_restore);
	RING_API_REGISTER("webview_is_maximized", ring_webview_is_maximized);
	RING_API_REGISTER("webview_start_drag", ring_webview_start_drag);
	RING_API_REGISTER("webview_set_position", ring_webview_set_position);
	RING_API_REGISTER("webview_get_position", ring_webview_get_position);
	RING_API_REGISTER("webview_get_size", ring_webview_get_size);
	RING_API_REGISTER("webview_focus", ring_webview_focus);
	RING_API_REGISTER("webview_hide", ring_webview_hide);
	RING_API_REGISTER("webview_show", ring_webview_show);
	RING_API_REGISTER("webview_start_resize", ring_webview_start_resize);
	RING_API_REGISTER("webview_set_fullscreen", ring_webview_set_fullscreen);
	RING_API_REGISTER("webview_is_fullscreen", ring_webview_is_fullscreen);
	RING_API_REGISTER("webview_set_resizable", ring_webview_set_resizable);
	RING_API_REGISTER("webview_is_resizable", ring_webview_is_resizable);
	RING_API_REGISTER("webview_set_min_size", ring_webview_set_min_size);
	RING_API_REGISTER("webview_set_max_size", ring_webview_set_max_size);
	RING_API_REGISTER("webview_set_background_color", ring_webview_set_background_color);
	RING_API_REGISTER("webview_set_icon", ring_webview_set_icon);
	RING_API_REGISTER("webview_is_focused", ring_webview_is_focused);
	RING_API_REGISTER("webview_is_visible", ring_webview_is_visible);
	RING_API_REGISTER("webview_close", ring_webview_close);
	RING_API_REGISTER("webview_set_dev_tools", ring_webview_set_dev_tools);
	RING_API_REGISTER("webview_set_context_menu", ring_webview_set_context_menu);
	RING_API_REGISTER("webview_set_force_dark", ring_webview_set_force_dark);
	RING_API_REGISTER("webview_is_force_dark", ring_webview_is_force_dark);
	RING_API_REGISTER("webview_get_screens", ring_webview_get_screens);
	RING_API_REGISTER("webview_set_click_through", ring_webview_set_click_through);
	RING_API_REGISTER("webview_is_click_through", ring_webview_is_click_through);

	/* Event callbacks */
	RING_API_REGISTER("webview_on_close", ring_webview_on_close);
	RING_API_REGISTER("webview_on_resize", ring_webview_on_resize);
	RING_API_REGISTER("webview_on_focus", ring_webview_on_focus);
	RING_API_REGISTER("webview_on_dom_ready", ring_webview_on_dom_ready);
	RING_API_REGISTER("webview_on_load", ring_webview_on_load);
	RING_API_REGISTER("webview_on_navigate", ring_webview_on_navigate);
	RING_API_REGISTER("webview_on_title", ring_webview_on_title);

	/* Constants */
	RING_API_REGISTER("get_webview_hint_none", ring_get_webview_hint_none);
	RING_API_REGISTER("get_webview_hint_min", ring_get_webview_hint_min);
	RING_API_REGISTER("get_webview_hint_max", ring_get_webview_hint_max);
	RING_API_REGISTER("get_webview_hint_fixed", ring_get_webview_hint_fixed);
	RING_API_REGISTER("get_webview_native_handle_kind_ui_window", ring_get_webview_native_handle_kind_ui_window);
	RING_API_REGISTER("get_webview_native_handle_kind_ui_widget", ring_get_webview_native_handle_kind_ui_widget);
	RING_API_REGISTER("get_webview_native_handle_kind_browser_controller",
					  ring_get_webview_native_handle_kind_browser_controller);
	RING_API_REGISTER("get_webview_error_ok", ring_get_webview_error_ok);
	RING_API_REGISTER("get_webview_error_unspecified", ring_get_webview_error_unspecified);
	RING_API_REGISTER("get_webview_error_invalid_argument", ring_get_webview_error_invalid_argument);
	RING_API_REGISTER("get_webview_error_invalid_state", ring_get_webview_error_invalid_state);
	RING_API_REGISTER("get_webview_error_canceled", ring_get_webview_error_canceled);
	RING_API_REGISTER("get_webview_error_missing_dependency", ring_get_webview_error_missing_dependency);
	RING_API_REGISTER("get_webview_error_duplicate", ring_get_webview_error_duplicate);
	RING_API_REGISTER("get_webview_error_not_found", ring_get_webview_error_not_found);
	RING_API_REGISTER("get_webview_version_major", ring_get_webview_version_major);
	RING_API_REGISTER("get_webview_version_minor", ring_get_webview_version_minor);
	RING_API_REGISTER("get_webview_version_patch", ring_get_webview_version_patch);
	RING_API_REGISTER("get_webview_edge_top", ring_get_webview_edge_top);
	RING_API_REGISTER("get_webview_edge_bottom", ring_get_webview_edge_bottom);
	RING_API_REGISTER("get_webview_edge_left", ring_get_webview_edge_left);
	RING_API_REGISTER("get_webview_edge_right", ring_get_webview_edge_right);
	RING_API_REGISTER("get_webview_edge_top_left", ring_get_webview_edge_top_left);
	RING_API_REGISTER("get_webview_edge_top_right", ring_get_webview_edge_top_right);
	RING_API_REGISTER("get_webview_edge_bottom_left", ring_get_webview_edge_bottom_left);
	RING_API_REGISTER("get_webview_edge_bottom_right", ring_get_webview_edge_bottom_right);
}
