/*
 * ring_webview.c
 * This file is part of the Ring WebView library.
 * Author: Youssef Saeed (ysdragon) <youssefelkholey@gmail.com>
 */


#include "ring.h"

#include "webview/version.h"
#include "webview/webview.h"

#if defined(_WIN32) || defined(_WIN64)
#define WEBVIEW_PLATFORM_WINDOWS
#include <windows.h>
#elif defined(__APPLE__)
#define WEBVIEW_PLATFORM_MACOS
#include "ring_webview_macos.h"
#elif defined(__linux__) || defined(__FreeBSD__)
#define WEBVIEW_PLATFORM_UNIX
#include <adwaita.h>
#include <gtk/gtk.h>
#include <webkit/webkit.h>
#endif

typedef struct RingWebView
{
	webview_t webview;
	RingState *pMainRingState;
	int bRunning;
#ifdef WEBVIEW_PLATFORM_UNIX
	GdkDevice *pLastDevice;
	GdkSurface *pLastSurface;
	int nLastButton;
	guint32 nLastTime;
	double dLastX;
	double dLastY;
	gboolean bHasClickData;
#endif
	char *cOnClose;
	char *cOnResize;
	char *cOnFocus;
	char *cOnDomReady;
	char *cOnLoad;
	char *cOnNavigate;
	char *cOnTitle;
} RingWebView;

typedef struct RingWebViewBind
{
	RingState *pMainRingState;
	char *cFunc;
} RingWebViewBind;

typedef struct RingWebViewDispatch
{
	RingState *pRingState;
	char *cCode;
} RingWebViewDispatch;

/* ============================================================================
 * Internal Helper Functions
 * ============================================================================ */

static char *ring_webview_string_strdup(void *pState, const char *cStr)
{
	char *cString;
	unsigned int x, nSize;
	nSize = strlen(cStr);
	cString = (char *)ring_state_malloc(pState, nSize + RING_ONE);
	if (cString == NULL)
	{
		return NULL;
	}
	RING_MEMCPY(cString, cStr, nSize);
	cString[nSize] = '\0';
	return cString;
}

// The C callback that webview will call from JavaScript
void ring_webview_bind_callback(const char *id, const char *req, void *arg)
{
	RingWebViewBind *pBind = (RingWebViewBind *)arg;
	if (!pBind || !pBind->pMainRingState || !pBind->cFunc)
	{
		return;
	}

	RingState *pRingState = pBind->pMainRingState;
	VM *pVM = pRingState->pVM;
	if (pVM == NULL)
	{
		return;
	}

	// Mutex Lock
	ring_vm_mutexlock(pVM);

	// Save current stack and call state.
	int nSP_before = pVM->nSP;
	int nFuncSP_before = pVM->nFuncSP;
	int nCallListSize_before = RING_VM_FUNCCALLSCOUNT;

	// Validate parameters before calling Ring function
	if (id == NULL || req == NULL)
	{
		ring_vm_mutexunlock(pVM);
		return;
	}

	// Load the function by name.
	if (!ring_vm_loadfunc2(pVM, pBind->cFunc, RING_FALSE))
	{
		// Function not found; clean up and return.
		pVM->nSP = nSP_before;
		pVM->nFuncSP = nFuncSP_before;
		ring_vm_mutexunlock(pVM);
		return;
	}

	// Push function arguments onto the stack.
	RING_VM_STACK_PUSHCVALUE2(id, strlen(id));
	RING_VM_STACK_PUSHCVALUE2(req, strlen(req));

	// Finalize call setup (jump PC to Ring function).
	ring_vm_call2(pVM);

	// Run VM until function returns.
	while (RING_VM_FUNCCALLSCOUNT > nCallListSize_before)
	{
		ring_vm_fetch(pVM);
	}

	// Restore stack pointer to discard any return value.
	pVM->nSP = nSP_before;
	pVM->nFuncSP = nFuncSP_before;

	// Mutex Unlock
	ring_vm_mutexunlock(pVM);
}

// Custom free function for the bind object to be used by the GC
void ring_webview_bind_free(void *pState, void *pPointer)
{
	RingWebViewBind *pBind = (RingWebViewBind *)pPointer;
	if (pBind)
	{
		if (pBind->cFunc)
		{
			ring_state_free(pState, pBind->cFunc);
			pBind->cFunc = NULL;
		}
		ring_state_free(pState, pPointer);
	}
}

// The C callback that webview will call on the main thread for dispatch
void ring_webview_dispatch_callback(webview_t w, void *arg)
{
	if (arg == NULL)
	{
		return;
	}

	RingWebViewDispatch *pDispatch = (RingWebViewDispatch *)arg;
	RingState *pRingState = pDispatch->pRingState;

	// Use the main VM from RingState
	if (pRingState == NULL || pRingState->pVM == NULL)
	{
		return;
	}

	// Execute the Ring code using the main VM
	ring_vm_runcodefromthread(pRingState->pVM, pDispatch->cCode);

	// Free the allocated memory
	ring_state_free(pRingState, pDispatch->cCode);
	ring_state_free(pRingState, pDispatch);
}

// Helper to destroy webview and free resources to avoid duplication.
void ring_webview_destroy_internal(RingWebView *pRingWebView)
{
	if (pRingWebView && pRingWebView->webview)
	{
		webview_destroy(pRingWebView->webview);
		pRingWebView->webview = NULL;
	}
}

static void ring_webview_call_event(RingWebView *pRingWebView, const char *cCallback, const char *cArg)
{
	if (!pRingWebView || !pRingWebView->pMainRingState || !cCallback)
		return;

	if (!pRingWebView->bRunning)
		return;

	RingState *pRingState = pRingWebView->pMainRingState;
	VM *pVM = pRingState->pVM;
	if (!pVM)
		return;

	ring_vm_mutexlock(pVM);

	int nSP_before = pVM->nSP;
	int nFuncSP_before = pVM->nFuncSP;
	int nCallListSize_before = RING_VM_FUNCCALLSCOUNT;

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
	{
		ring_vm_fetch(pVM);
	}

	pVM->nSP = nSP_before;
	pVM->nFuncSP = nFuncSP_before;

	ring_vm_mutexunlock(pVM);
}

/* ============================================================================
 * Platform-specific Helpers (Windows)
 * ============================================================================ */

#ifdef WEBVIEW_PLATFORM_WINDOWS
static HWND ring_webview_get_hwnd(RingWebView *pRingWebView)
{
	if (!pRingWebView || !pRingWebView->webview)
		return NULL;
	return (HWND)webview_get_window(pRingWebView->webview);
}

static BOOL CALLBACK ring_webview_monitor_enum_proc(HMONITOR hMonitor, HDC hdcMonitor, LPRECT lprcMonitor,
													LPARAM dwData)
{
	(void)hdcMonitor;
	(void)lprcMonitor;
	List *pList = (List *)dwData;
	MONITORINFOEXW mi;
	mi.cbSize = sizeof(mi);
	if (GetMonitorInfoW(hMonitor, (LPMONITORINFO)&mi))
	{
		char name[64];
		WideCharToMultiByte(CP_UTF8, 0, mi.szDevice, -1, name, sizeof(name), NULL, NULL);

		List *pScreenList = ring_list_newlist_gc(NULL, pList);
		ring_list_addstring_gc(NULL, pScreenList, name);
		ring_list_adddouble_gc(NULL, pScreenList, (double)mi.rcMonitor.left);
		ring_list_adddouble_gc(NULL, pScreenList, (double)mi.rcMonitor.top);
		ring_list_adddouble_gc(NULL, pScreenList, (double)(mi.rcMonitor.right - mi.rcMonitor.left));
		ring_list_adddouble_gc(NULL, pScreenList, (double)(mi.rcMonitor.bottom - mi.rcMonitor.top));
	}
	return TRUE;
}
#endif

/* ============================================================================
 * Platform-specific Helpers (Linux/FreeBSD)
 * ============================================================================ */

#ifdef WEBVIEW_PLATFORM_UNIX
static GtkWindow *ring_webview_get_gtk_window(RingWebView *pRingWebView)
{
	if (!pRingWebView || !pRingWebView->webview)
		return NULL;
	return GTK_WINDOW(webview_get_window(pRingWebView->webview));
}

static void ring_webview_on_click(GtkGestureClick *gesture, gint n_press, gdouble x, gdouble y, gpointer user_data)
{
	(void)n_press;
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (!pRingWebView)
		return;

	GtkEventController *controller = GTK_EVENT_CONTROLLER(gesture);
	GdkEvent *event = gtk_event_controller_get_current_event(controller);
	if (!event)
		return;

	GtkWidget *widget = gtk_event_controller_get_widget(controller);
	GtkNative *native = gtk_widget_get_native(widget);
	GdkSurface *surface = gtk_native_get_surface(native);

	pRingWebView->pLastDevice = gdk_event_get_device(event);
	pRingWebView->pLastSurface = surface;
	pRingWebView->nLastButton = (int)gdk_button_event_get_button(event);
	pRingWebView->nLastTime = gdk_event_get_time(event);
	pRingWebView->dLastX = x;
	pRingWebView->dLastY = y;
	pRingWebView->bHasClickData = TRUE;
}

static void ring_webview_setup_drag_handler(RingWebView *pRingWebView)
{
	if (!pRingWebView || !pRingWebView->webview)
		return;

	GtkWidget *webview_widget =
		(GtkWidget *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET);
	if (!webview_widget)
		return;

	GtkGesture *gesture = gtk_gesture_click_new();
	gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(gesture), 0);
	g_signal_connect(gesture, "pressed", G_CALLBACK(ring_webview_on_click), pRingWebView);
	gtk_widget_add_controller(webview_widget, GTK_EVENT_CONTROLLER(gesture));

	pRingWebView->bHasClickData = FALSE;
}

static void ring_webview_on_load_changed(WebKitWebView *web_view, WebKitLoadEvent load_event, gpointer user_data)
{
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (!pRingWebView)
		return;

	if (load_event == WEBKIT_LOAD_FINISHED && pRingWebView->cOnLoad)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnLoad, "finished");
	}
	else if (load_event == WEBKIT_LOAD_STARTED && pRingWebView->cOnLoad)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnLoad, "started");
	}

	if (load_event == WEBKIT_LOAD_FINISHED && pRingWebView->cOnDomReady)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnDomReady, NULL);
	}
}

static void ring_webview_on_title_changed(GObject *object, GParamSpec *pspec, gpointer user_data)
{
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (!pRingWebView || !pRingWebView->cOnTitle)
		return;

	WebKitWebView *web_view = WEBKIT_WEB_VIEW(object);
	const char *title = webkit_web_view_get_title(web_view);
	if (title)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnTitle, title);
	}
}

static void ring_webview_on_uri_changed(GObject *object, GParamSpec *pspec, gpointer user_data)
{
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (!pRingWebView || !pRingWebView->cOnNavigate)
		return;

	WebKitWebView *web_view = WEBKIT_WEB_VIEW(object);
	const char *uri = webkit_web_view_get_uri(web_view);
	if (uri)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnNavigate, uri);
	}
}

static gboolean ring_webview_on_close_request(GtkWindow *window, gpointer user_data)
{
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (pRingWebView && pRingWebView->cOnClose)
	{
		ring_webview_call_event(pRingWebView, pRingWebView->cOnClose, NULL);
	}
	return FALSE;
}

static void ring_webview_on_focus_changed(GtkWindow *window, GParamSpec *pspec, gpointer user_data)
{
	RingWebView *pRingWebView = (RingWebView *)user_data;
	if (!pRingWebView || !pRingWebView->cOnFocus)
		return;

	gboolean focused = gtk_window_is_active(window);
	ring_webview_call_event(pRingWebView, pRingWebView->cOnFocus, focused ? "true" : "false");
}

static void ring_webview_setup_event_handlers(RingWebView *pRingWebView)
{
	if (!pRingWebView || !pRingWebView->webview)
		return;

	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	GtkWindow *window =
		(GtkWindow *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);

	if (web_view)
	{
		g_signal_connect(web_view, "load-changed", G_CALLBACK(ring_webview_on_load_changed), pRingWebView);
		g_signal_connect(web_view, "notify::title", G_CALLBACK(ring_webview_on_title_changed), pRingWebView);
		g_signal_connect(web_view, "notify::uri", G_CALLBACK(ring_webview_on_uri_changed), pRingWebView);
	}

	if (window)
	{
		g_signal_connect(window, "close-request", G_CALLBACK(ring_webview_on_close_request), pRingWebView);
		g_signal_connect(window, "notify::is-active", G_CALLBACK(ring_webview_on_focus_changed), pRingWebView);
	}
}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
static gboolean ring_webview_suppress_context_menu(WebKitWebView *web_view, WebKitContextMenu *context_menu,
												   GdkEvent *event, WebKitHitTestResult *hit_test_result,
												   gpointer user_data)
{
	(void)web_view;
	(void)context_menu;
	(void)event;
	(void)hit_test_result;
	(void)user_data;
	return TRUE;
}
#endif

#define RING_WEBVIEW_SET_EVENT_FUNC(funcname, member)                                                                  \
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
		RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");                               \
		if (!pRingWebView || !pRingWebView->webview)                                                                   \
		{                                                                                                              \
			RING_API_ERROR("Invalid webview pointer");                                                                 \
			return;                                                                                                    \
		}                                                                                                              \
		if (pRingWebView->member)                                                                                      \
		{                                                                                                              \
			ring_state_free(pRingWebView->pMainRingState, pRingWebView->member);                                       \
		}                                                                                                              \
		pRingWebView->member = ring_webview_string_strdup(pRingWebView->pMainRingState, RING_API_GETSTRING(2));        \
		RING_API_RETNUMBER(1);                                                                                         \
	}

// Custom free function for the RingWebView object, called by the GC.
void ring_webview_free(void *pState, void *pPointer)
{
	RingWebView *pRingWebView = (RingWebView *)pPointer;
	ring_webview_destroy_internal(pRingWebView);
	ring_state_free(pState, pPointer);
}

/* ============================================================================
 * Core WebView Functions
 * ============================================================================ */

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

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	const char *cCodeToRun = RING_API_GETSTRING(2);

	RingWebViewDispatch *pDispatch =
		(RingWebViewDispatch *)ring_state_malloc(pRingWebView->pMainRingState, sizeof(RingWebViewDispatch));
	if (pDispatch == NULL)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}
	// Use the main RingState stored when webview was created
	pDispatch->pRingState = pRingWebView->pMainRingState;
	pDispatch->cCode = ring_webview_string_strdup(pRingWebView->pMainRingState, cCodeToRun);
	if (pDispatch->cCode == NULL)
	{
		ring_state_free(pRingWebView->pMainRingState, pDispatch);
		RING_API_ERROR(RING_OOM);
		return;
	}

	webview_error_t result = webview_dispatch(pRingWebView->webview, ring_webview_dispatch_callback, pDispatch);

	// Free memory if dispatch fails to avoid leaks.
	if (result != WEBVIEW_ERROR_OK)
	{
		ring_state_free(pRingWebView->pMainRingState, pDispatch->cCode);
		ring_state_free(pRingWebView->pMainRingState, pDispatch);
	}

	RING_API_RETNUMBER(result);
}

RING_FUNC(ring_webview_bind)
{
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

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	const char *js_name = RING_API_GETSTRING(2);
	const char *ring_func_name = RING_API_GETSTRING(3);

	RingWebViewBind *pBind = (RingWebViewBind *)RING_API_MALLOC(sizeof(RingWebViewBind));
	if (pBind == NULL)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}

	// Use the main RingState stored when webview was created
	pBind->pMainRingState = pRingWebView->pMainRingState;
	pBind->cFunc = ring_webview_string_strdup(RING_API_STATE, ring_func_name);
	if (pBind->cFunc == NULL)
	{
		RING_API_FREE(pBind);
		RING_API_ERROR(RING_OOM);
		return;
	}
	// Ring function names are stored in lowercase internally
	ring_general_lower(pBind->cFunc);

	webview_error_t result = webview_bind(pRingWebView->webview, js_name, ring_webview_bind_callback, pBind);

	if (result == WEBVIEW_ERROR_OK)
	{
		// Return a managed C pointer.
		RING_API_RETMANAGEDCPOINTER(pBind, "webview_bind_t", ring_webview_bind_free);
	}
	else
	{
		// Failure: free the allocated memory and return the error code.
		ring_webview_bind_free(RING_API_STATE, pBind);
		RING_API_RETNUMBER(result);
	}
}

RING_FUNC(ring_webview_unbind)
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

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	const char *js_name = RING_API_GETSTRING(2);

	webview_error_t result = webview_unbind(pRingWebView->webview, js_name);
	RING_API_RETNUMBER(result);
}

RING_FUNC(ring_webview_version)
{
	if (RING_API_PARACOUNT != 0)
	{
		RING_API_ERROR(RING_API_BADPARACOUNT);
		return;
	}
	RING_API_RETSTRING(WEBVIEW_VERSION_NUMBER);
}

RING_FUNC(ring_webview_create)
{
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

	void *pWindow = NULL;
	if (RING_API_ISPOINTER(2))
	{
		pWindow = RING_API_GETCPOINTER(2, "void");
	}

	RingWebView *pRingWebView;
	pRingWebView = (RingWebView *)RING_API_MALLOC(sizeof(RingWebView));
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}
	pRingWebView->webview = webview_create((int)RING_API_GETNUMBER(1), pWindow);
	if (pRingWebView->webview == NULL)
	{
		RING_API_FREE(pRingWebView);
		RING_API_ERROR("Failed to create webview instance");
		return;
	}
	pRingWebView->pMainRingState = RING_API_STATE;
	pRingWebView->bRunning = 0;
	pRingWebView->cOnClose = NULL;
	pRingWebView->cOnResize = NULL;
	pRingWebView->cOnFocus = NULL;
	pRingWebView->cOnDomReady = NULL;
	pRingWebView->cOnLoad = NULL;
	pRingWebView->cOnNavigate = NULL;
	pRingWebView->cOnTitle = NULL;

#ifdef WEBVIEW_PLATFORM_UNIX
	ring_webview_setup_drag_handler(pRingWebView);
	ring_webview_setup_event_handlers(pRingWebView);
#endif

	RING_API_RETMANAGEDCPOINTER(pRingWebView, "webview_t", ring_webview_free);
}

RING_FUNC(ring_webview_destroy)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	ring_webview_destroy_internal(pRingWebView);
	RING_API_SETNULLPOINTER(1);
}

RING_FUNC(ring_webview_run)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	pRingWebView->bRunning = 1;
	webview_run(pRingWebView->webview);
}

RING_FUNC(ring_webview_terminate)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_terminate(pRingWebView->webview);
}

RING_FUNC(ring_webview_get_window)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RING_API_RETCPOINTER(webview_get_window(pRingWebView->webview), "void");
}

RING_FUNC(ring_webview_get_native_handle)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RING_API_RETCPOINTER(
		webview_get_native_handle(pRingWebView->webview, (webview_native_handle_kind_t)(int)RING_API_GETNUMBER(2)),
		"void");
}

RING_FUNC(ring_webview_set_title)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_set_title(pRingWebView->webview, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_set_size)
{
	if (RING_API_PARACOUNT != 4)
	{
		RING_API_ERROR(RING_API_MISS4PARA);
		return;
	}
	if (!RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	if (!RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	if (!RING_API_ISNUMBER(4))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_set_size(pRingWebView->webview, (int)RING_API_GETNUMBER(2), (int)RING_API_GETNUMBER(3),
					 (webview_hint_t)(int)RING_API_GETNUMBER(4));
}

RING_FUNC(ring_webview_navigate)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_navigate(pRingWebView->webview, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_set_html)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_set_html(pRingWebView->webview, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_init)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_init(pRingWebView->webview, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_eval)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_eval(pRingWebView->webview, RING_API_GETSTRING(2));
}

RING_FUNC(ring_webview_return)
{
	if (RING_API_PARACOUNT != 4)
	{
		RING_API_ERROR(RING_API_MISS4PARA);
		return;
	}
	if (!RING_API_ISSTRING(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	if (!RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	if (!RING_API_ISSTRING(4))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (pRingWebView == NULL)
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}
	webview_return(pRingWebView->webview, RING_API_GETSTRING(2), (int)RING_API_GETNUMBER(3), RING_API_GETSTRING(4));
}

/* ============================================================================
 * Window Management Functions
 * ============================================================================ */

RING_FUNC(ring_webview_set_decorated)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int decorated = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		LONG style = GetWindowLong(hwnd, GWL_STYLE);
		if (decorated)
		{
			style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
			style &= ~WS_POPUP;
		}
		else
		{
			style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
			style |= WS_POPUP;
		}
		SetWindowLong(hwnd, GWL_STYLE, style);
		SetWindowPos(hwnd, NULL, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_set_decorated(window, decorated ? TRUE : FALSE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_set_decorated(pRingWebView->webview, decorated))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_opacity)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	double opacity = RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

	if (opacity < 0.0)
		opacity = 0.0;
	if (opacity > 1.0)
		opacity = 1.0;

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
		SetWindowLong(hwnd, GWL_EXSTYLE, exStyle | WS_EX_LAYERED);
		BYTE alpha = (BYTE)(opacity * 255);
		SetLayeredWindowAttributes(hwnd, 0, alpha, LWA_ALPHA);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_widget_set_opacity(GTK_WIDGET(window), opacity);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_set_opacity(pRingWebView->webview, opacity))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_always_on_top)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int onTop = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		SetWindowPos(hwnd, onTop ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	(void)pRingWebView;
	(void)onTop;
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_set_always_on_top(pRingWebView->webview, onTop))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_minimize)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ShowWindow(hwnd, SW_MINIMIZE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_minimize(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_minimize(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_maximize)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ShowWindow(hwnd, SW_MAXIMIZE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_maximize(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_maximize(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_restore)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ShowWindow(hwnd, SW_RESTORE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_unmaximize(window);
		gtk_window_present(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_restore(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_maximized)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		RING_API_RETNUMBER(IsZoomed(hwnd) ? 1 : 0);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		RING_API_RETNUMBER(gtk_window_is_maximized(window) ? 1 : 0);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	RING_API_RETNUMBER(ring_webview_macos_is_maximized(pRingWebView->webview));
	return;
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_start_drag)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ReleaseCapture();
		SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	if (pRingWebView->bHasClickData && pRingWebView->pLastSurface)
	{
		gdk_toplevel_begin_move(GDK_TOPLEVEL(pRingWebView->pLastSurface), pRingWebView->pLastDevice,
								pRingWebView->nLastButton, pRingWebView->dLastX, pRingWebView->dLastY,
								pRingWebView->nLastTime);
		RING_API_RETNUMBER(1);
		return;
	}
	RING_API_RETNUMBER(0);
	return;
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_start_drag(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_position)
{
	if (RING_API_PARACOUNT != 3)
	{
		RING_API_ERROR(RING_API_MISS3PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2) || !RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int x = (int)RING_API_GETNUMBER(2);
	int y = (int)RING_API_GETNUMBER(3);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		SetWindowPos(hwnd, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	(void)pRingWebView;
	(void)x;
	(void)y;
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_set_position(pRingWebView->webview, x, y))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_get_position)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

	int x = 0, y = 0;

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		RECT rect;
		if (GetWindowRect(hwnd, &rect))
		{
			x = rect.left;
			y = rect.top;
		}
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	(void)pRingWebView;
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	ring_webview_macos_get_position(pRingWebView->webview, &x, &y);
#endif

	List *pList = RING_API_NEWLIST;
	ring_list_adddouble_gc(RING_API_STATE, pList, x);
	ring_list_adddouble_gc(RING_API_STATE, pList, y);
	RING_API_RETLIST(pList);
}

RING_FUNC(ring_webview_get_size)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

	int width = 0, height = 0;

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		RECT rect;
		if (GetWindowRect(hwnd, &rect))
		{
			width = rect.right - rect.left;
			height = rect.bottom - rect.top;
		}
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_get_default_size(window, &width, &height);
		if (width <= 0 || height <= 0)
		{
			width = gtk_widget_get_width(GTK_WIDGET(window));
			height = gtk_widget_get_height(GTK_WIDGET(window));
		}
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	ring_webview_macos_get_size(pRingWebView->webview, &width, &height);
#endif

	List *pList = RING_API_NEWLIST;
	ring_list_adddouble_gc(RING_API_STATE, pList, width);
	ring_list_adddouble_gc(RING_API_STATE, pList, height);
	RING_API_RETLIST(pList);
}

RING_FUNC(ring_webview_focus)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		SetForegroundWindow(hwnd);
		SetFocus(hwnd);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_present(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_focus(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_hide)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ShowWindow(hwnd, SW_HIDE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_widget_set_visible(GTK_WIDGET(window), FALSE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_hide(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_show)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		ShowWindow(hwnd, SW_SHOW);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_widget_set_visible(GTK_WIDGET(window), TRUE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	if (ring_webview_macos_show(pRingWebView->webview))
	{
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_start_resize)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int edge = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		WPARAM wParam = 0;
		switch (edge)
		{
		case 1:
			wParam = WMSZ_TOP;
			break;
		case 2:
			wParam = WMSZ_BOTTOM;
			break;
		case 4:
			wParam = WMSZ_LEFT;
			break;
		case 8:
			wParam = WMSZ_RIGHT;
			break;
		case 6:
			wParam = WMSZ_BOTTOMLEFT;
			break;
		case 10:
			wParam = WMSZ_BOTTOMRIGHT;
			break;
		case 5:
			wParam = WMSZ_TOPLEFT;
			break;
		case 9:
			wParam = WMSZ_TOPRIGHT;
			break;
		default:
			wParam = WMSZ_BOTTOMRIGHT;
		}
		ReleaseCapture();
		SendMessage(hwnd, WM_SYSCOMMAND, SC_SIZE | wParam, 0);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	if (pRingWebView->bHasClickData && pRingWebView->pLastSurface)
	{
		GdkSurfaceEdge gdkEdge;
		switch (edge)
		{
		case 1:
			gdkEdge = GDK_SURFACE_EDGE_NORTH;
			break;
		case 2:
			gdkEdge = GDK_SURFACE_EDGE_SOUTH;
			break;
		case 4:
			gdkEdge = GDK_SURFACE_EDGE_WEST;
			break;
		case 8:
			gdkEdge = GDK_SURFACE_EDGE_EAST;
			break;
		case 6:
			gdkEdge = GDK_SURFACE_EDGE_SOUTH_WEST;
			break;
		case 10:
			gdkEdge = GDK_SURFACE_EDGE_SOUTH_EAST;
			break;
		case 5:
			gdkEdge = GDK_SURFACE_EDGE_NORTH_WEST;
			break;
		case 9:
			gdkEdge = GDK_SURFACE_EDGE_NORTH_EAST;
			break;
		default:
			gdkEdge = GDK_SURFACE_EDGE_SOUTH_EAST;
		}
		gdk_toplevel_begin_resize(GDK_TOPLEVEL(pRingWebView->pLastSurface), gdkEdge, pRingWebView->pLastDevice,
								  pRingWebView->nLastButton, pRingWebView->dLastX, pRingWebView->dLastY,
								  pRingWebView->nLastTime);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	(void)edge;
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_fullscreen)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int fullscreen = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		static WINDOWPLACEMENT g_wpPrev = {sizeof(g_wpPrev)};
		static DWORD g_dwStyle = 0;
		if (fullscreen)
		{
			MONITORINFO mi = {sizeof(mi)};
			g_dwStyle = GetWindowLong(hwnd, GWL_STYLE);
			if (GetWindowPlacement(hwnd, &g_wpPrev) &&
				GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY), &mi))
			{
				SetWindowLong(hwnd, GWL_STYLE, g_dwStyle & ~WS_OVERLAPPEDWINDOW);
				SetWindowPos(hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
							 mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
							 SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
			}
		}
		else
		{
			SetWindowLong(hwnd, GWL_STYLE, g_dwStyle);
			SetWindowPlacement(hwnd, &g_wpPrev);
			SetWindowPos(hwnd, NULL, 0, 0, 0, 0,
						 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
		}
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		if (fullscreen)
			gtk_window_fullscreen(window);
		else
			gtk_window_unfullscreen(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	(void)fullscreen;
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_fullscreen)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		RING_API_RETNUMBER(gtk_window_is_fullscreen(window) ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_resizable)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int resizable = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		LONG style = GetWindowLong(hwnd, GWL_STYLE);
		if (resizable)
			style |= WS_THICKFRAME | WS_MAXIMIZEBOX;
		else
			style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
		SetWindowLong(hwnd, GWL_STYLE, style);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_window_set_resizable(window, resizable ? TRUE : FALSE);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_MACOS
	(void)resizable;
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_resizable)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = ring_webview_get_hwnd(pRingWebView);
	if (hwnd)
	{
		LONG style = GetWindowLong(hwnd, GWL_STYLE);
		RING_API_RETNUMBER((style & WS_THICKFRAME) ? 1 : 0);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		RING_API_RETNUMBER(gtk_window_get_resizable(window) ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(1);
}

RING_FUNC(ring_webview_set_min_size)
{
	if (RING_API_PARACOUNT != 3)
	{
		RING_API_ERROR(RING_API_MISS3PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2) || !RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int width = (int)RING_API_GETNUMBER(2);
	int height = (int)RING_API_GETNUMBER(3);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window = ring_webview_get_gtk_window(pRingWebView);
	if (window)
	{
		gtk_widget_set_size_request(GTK_WIDGET(window), width, height);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)width;
	(void)height;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_max_size)
{
	if (RING_API_PARACOUNT != 3)
	{
		RING_API_ERROR(RING_API_MISS3PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2) || !RING_API_ISNUMBER(3))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int width = (int)RING_API_GETNUMBER(2);
	int height = (int)RING_API_GETNUMBER(3);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

	(void)width;
	(void)height;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_background_color)
{
	if (RING_API_PARACOUNT != 5)
	{
		RING_API_ERROR("Bad parameter count - expected 5 (webview, r, g, b, a)");
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2) || !RING_API_ISNUMBER(3) || !RING_API_ISNUMBER(4) ||
		!RING_API_ISNUMBER(5))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int r = (int)RING_API_GETNUMBER(2);
	int g = (int)RING_API_GETNUMBER(3);
	int b = (int)RING_API_GETNUMBER(4);
	int a = (int)RING_API_GETNUMBER(5);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		GdkRGBA color = {.red = r / 255.0f, .green = g / 255.0f, .blue = b / 255.0f, .alpha = a / 255.0f};
		webkit_web_view_set_background_color(web_view, &color);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)r;
	(void)g;
	(void)b;
	(void)a;
	RING_API_RETNUMBER(0);
}

/* ============================================================================
 * Navigation & WebView Features
 * ============================================================================ */

RING_FUNC(ring_webview_back)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		webkit_web_view_go_back(web_view);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_forward)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		webkit_web_view_go_forward(web_view);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_reload)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		webkit_web_view_reload(web_view);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_dev_tools)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int enabled = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		WebKitSettings *settings = webkit_web_view_get_settings(web_view);
		webkit_settings_set_enable_developer_extras(settings, enabled ? TRUE : FALSE);
		if (enabled)
		{
			WebKitWebInspector *inspector = webkit_web_view_get_inspector(web_view);
			webkit_web_inspector_show(inspector);
		}
		else
		{
			WebKitWebInspector *inspector = webkit_web_view_get_inspector(web_view);
			webkit_web_inspector_close(inspector);
		}
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)enabled;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_get_url)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		const char *uri = webkit_web_view_get_uri(web_view);
		if (uri)
		{
			RING_API_RETSTRING(uri);
			return;
		}
	}
#endif

	RING_API_RETSTRING("");
}

RING_FUNC(ring_webview_get_title)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		const char *title = webkit_web_view_get_title(web_view);
		if (title)
		{
			RING_API_RETSTRING(title);
			return;
		}
	}
#endif

	RING_API_RETSTRING("");
}

RING_FUNC(ring_webview_set_context_menu)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int enabled = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	WebKitWebView *web_view = (WebKitWebView *)webview_get_native_handle(pRingWebView->webview,
																		 WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
	if (web_view)
	{
		static gulong handler_id = 0;

		if (!enabled && handler_id == 0)
		{
			handler_id =
				g_signal_connect(web_view, "context-menu", G_CALLBACK(ring_webview_suppress_context_menu), NULL);
		}
		else if (enabled && handler_id != 0)
		{
			g_signal_handler_disconnect(web_view, handler_id);
			handler_id = 0;
		}
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)enabled;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_icon)
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

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	const char *icon_path = RING_API_GETSTRING(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window =
		(GtkWindow *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (window)
	{
		GError *error = NULL;
		GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file(icon_path, &error);
		if (pixbuf)
		{
			GdkTexture *texture = gdk_texture_new_for_pixbuf(pixbuf);
			gtk_window_set_icon_name(window, NULL);
			g_object_unref(pixbuf);
			g_object_unref(texture);
			RING_API_RETNUMBER(1);
			return;
		}
		if (error)
			g_error_free(error);
	}
#endif

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		HICON hIcon = (HICON)LoadImageA(NULL, icon_path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE | LR_DEFAULTSIZE);
		if (hIcon)
		{
			SendMessage(hwnd, WM_SETICON, ICON_BIG, (LPARAM)hIcon);
			SendMessage(hwnd, WM_SETICON, ICON_SMALL, (LPARAM)hIcon);
			RING_API_RETNUMBER(1);
			return;
		}
	}
#endif

	(void)icon_path;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_focused)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window =
		(GtkWindow *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (window)
	{
		RING_API_RETNUMBER(gtk_window_is_active(window) ? 1 : 0);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		RING_API_RETNUMBER(GetForegroundWindow() == hwnd ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_visible)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window =
		(GtkWindow *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (window)
	{
		RING_API_RETNUMBER(gtk_widget_is_visible(GTK_WIDGET(window)) ? 1 : 0);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		RING_API_RETNUMBER(IsWindowVisible(hwnd) ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_close)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	GtkWindow *window =
		(GtkWindow *)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (window)
	{
		gtk_window_close(window);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		PostMessage(hwnd, WM_CLOSE, 0, 0);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_set_force_dark)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int enabled = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	AdwStyleManager *style_manager = adw_style_manager_get_default();
	if (style_manager)
	{
		adw_style_manager_set_color_scheme(style_manager,
										   enabled ? ADW_COLOR_SCHEME_FORCE_DARK : ADW_COLOR_SCHEME_DEFAULT);
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)enabled;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_force_dark)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_UNIX
	AdwStyleManager *style_manager = adw_style_manager_get_default();
	if (style_manager)
	{
		AdwColorScheme scheme = adw_style_manager_get_color_scheme(style_manager);
		RING_API_RETNUMBER(scheme == ADW_COLOR_SCHEME_FORCE_DARK ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_get_screens)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

	List *pList = RING_API_NEWLIST;

#ifdef WEBVIEW_PLATFORM_UNIX
	GdkDisplay *display = gdk_display_get_default();
	if (display)
	{
		GListModel *monitors = gdk_display_get_monitors(display);
		guint n_monitors = g_list_model_get_n_items(monitors);

		for (guint i = 0; i < n_monitors; i++)
		{
			GdkMonitor *monitor = (GdkMonitor *)g_list_model_get_item(monitors, i);
			if (monitor)
			{
				GdkRectangle rect;
				gdk_monitor_get_geometry(monitor, &rect);
				const char *model = gdk_monitor_get_model(monitor);

				List *pScreenList = ring_list_newlist_gc(((VM *)pPointer)->pRingState, pList);
				ring_list_addstring_gc(((VM *)pPointer)->pRingState, pScreenList, model ? model : "Unknown");
				ring_list_adddouble_gc(((VM *)pPointer)->pRingState, pScreenList, (double)rect.x);
				ring_list_adddouble_gc(((VM *)pPointer)->pRingState, pScreenList, (double)rect.y);
				ring_list_adddouble_gc(((VM *)pPointer)->pRingState, pScreenList, (double)rect.width);
				ring_list_adddouble_gc(((VM *)pPointer)->pRingState, pScreenList, (double)rect.height);
				g_object_unref(monitor);
			}
		}
	}
#endif

#ifdef WEBVIEW_PLATFORM_WINDOWS
	EnumDisplayMonitors(NULL, NULL, ring_webview_monitor_enum_proc, (LPARAM)pList);
#endif

	RING_API_RETLIST(pList);
}

RING_FUNC(ring_webview_set_click_through)
{
	if (RING_API_PARACOUNT != 2)
	{
		RING_API_ERROR(RING_API_MISS2PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1) || !RING_API_ISNUMBER(2))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	int enabled = (int)RING_API_GETNUMBER(2);

	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
		if (enabled)
		{
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle | WS_EX_TRANSPARENT | WS_EX_LAYERED);
		}
		else
		{
			SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle & ~(WS_EX_TRANSPARENT | WS_EX_LAYERED));
		}
		RING_API_RETNUMBER(1);
		return;
	}
#endif

	(void)enabled;
	RING_API_RETNUMBER(0);
}

RING_FUNC(ring_webview_is_click_through)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	if (!RING_API_ISCPOINTER(1))
	{
		RING_API_ERROR(RING_API_BADPARATYPE);
		return;
	}

	RingWebView *pRingWebView = (RingWebView *)RING_API_GETCPOINTER(1, "webview_t");
	if (!pRingWebView || !pRingWebView->webview)
	{
		RING_API_ERROR("Invalid webview pointer");
		return;
	}

#ifdef WEBVIEW_PLATFORM_WINDOWS
	HWND hwnd = (HWND)webview_get_native_handle(pRingWebView->webview, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
	if (hwnd)
	{
		LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
		RING_API_RETNUMBER((exStyle & WS_EX_TRANSPARENT) ? 1 : 0);
		return;
	}
#endif

	RING_API_RETNUMBER(0);
}

/* ============================================================================
 * Constants Functions
 * ============================================================================ */

RING_FUNC(ring_get_webview_hint_none)
{
	RING_API_RETNUMBER(WEBVIEW_HINT_NONE);
}

RING_FUNC(ring_get_webview_hint_min)
{
	RING_API_RETNUMBER(WEBVIEW_HINT_MIN);
}

RING_FUNC(ring_get_webview_hint_max)
{
	RING_API_RETNUMBER(WEBVIEW_HINT_MAX);
}

RING_FUNC(ring_get_webview_hint_fixed)
{
	RING_API_RETNUMBER(WEBVIEW_HINT_FIXED);
}

RING_FUNC(ring_get_webview_native_handle_kind_ui_window)
{
	RING_API_RETNUMBER(WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW);
}

RING_FUNC(ring_get_webview_native_handle_kind_ui_widget)
{
	RING_API_RETNUMBER(WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET);
}

RING_FUNC(ring_get_webview_native_handle_kind_browser_controller)
{
	RING_API_RETNUMBER(WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER);
}

RING_FUNC(ring_get_webview_error_ok)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_OK);
}

RING_FUNC(ring_get_webview_error_unspecified)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_UNSPECIFIED);
}

RING_FUNC(ring_get_webview_error_invalid_argument)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_INVALID_ARGUMENT);
}

RING_FUNC(ring_get_webview_error_invalid_state)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_INVALID_STATE);
}

RING_FUNC(ring_get_webview_error_canceled)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_CANCELED);
}

RING_FUNC(ring_get_webview_error_missing_dependency)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_MISSING_DEPENDENCY);
}

RING_FUNC(ring_get_webview_error_duplicate)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_DUPLICATE);
}

RING_FUNC(ring_get_webview_error_not_found)
{
	RING_API_RETNUMBER(WEBVIEW_ERROR_NOT_FOUND);
}

RING_FUNC(ring_get_webview_version_major)
{
	RING_API_RETNUMBER(WEBVIEW_VERSION_MAJOR);
}

RING_FUNC(ring_get_webview_version_minor)
{
	RING_API_RETNUMBER(WEBVIEW_VERSION_MINOR);
}

RING_FUNC(ring_get_webview_version_patch)
{
	RING_API_RETNUMBER(WEBVIEW_VERSION_PATCH);
}

RING_FUNC(ring_get_webview_edge_top)
{
	RING_API_RETNUMBER(1);
}

RING_FUNC(ring_get_webview_edge_bottom)
{
	RING_API_RETNUMBER(2);
}

RING_FUNC(ring_get_webview_edge_left)
{
	RING_API_RETNUMBER(4);
}

RING_FUNC(ring_get_webview_edge_right)
{
	RING_API_RETNUMBER(8);
}

RING_FUNC(ring_get_webview_edge_top_left)
{
	RING_API_RETNUMBER(5);
}

RING_FUNC(ring_get_webview_edge_top_right)
{
	RING_API_RETNUMBER(9);
}

RING_FUNC(ring_get_webview_edge_bottom_left)
{
	RING_API_RETNUMBER(6);
}

RING_FUNC(ring_get_webview_edge_bottom_right)
{
	RING_API_RETNUMBER(10);
}

/* ============================================================================
 * Event Callback Functions
 * ============================================================================ */

RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_close, cOnClose)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_resize, cOnResize)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_focus, cOnFocus)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_dom_ready, cOnDomReady)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_load, cOnLoad)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_navigate, cOnNavigate)
RING_WEBVIEW_SET_EVENT_FUNC(ring_webview_on_title, cOnTitle)

/* ============================================================================
 * Library Initialization
 * ============================================================================ */

RING_LIBINIT
{
	// Core WebView Functions
	RING_API_REGISTER("webview_create", ring_webview_create);
	RING_API_REGISTER("webview_destroy", ring_webview_destroy);
	RING_API_REGISTER("webview_run", ring_webview_run);
	RING_API_REGISTER("webview_terminate", ring_webview_terminate);
	RING_API_REGISTER("webview_get_window", ring_webview_get_window);
	RING_API_REGISTER("webview_get_native_handle", ring_webview_get_native_handle);
	RING_API_REGISTER("webview_set_title", ring_webview_set_title);
	RING_API_REGISTER("webview_set_size", ring_webview_set_size);
	RING_API_REGISTER("webview_navigate", ring_webview_navigate);
	RING_API_REGISTER("webview_set_html", ring_webview_set_html);
	RING_API_REGISTER("webview_init", ring_webview_init);
	RING_API_REGISTER("webview_eval", ring_webview_eval);
	RING_API_REGISTER("webview_return", ring_webview_return);
	RING_API_REGISTER("webview_bind", ring_webview_bind);
	RING_API_REGISTER("webview_unbind", ring_webview_unbind);
	RING_API_REGISTER("webview_version", ring_webview_version);
	RING_API_REGISTER("webview_dispatch", ring_webview_dispatch);

	// Window Management Functions
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

	// Navigation & WebView Features
	RING_API_REGISTER("webview_back", ring_webview_back);
	RING_API_REGISTER("webview_forward", ring_webview_forward);
	RING_API_REGISTER("webview_reload", ring_webview_reload);
	RING_API_REGISTER("webview_set_dev_tools", ring_webview_set_dev_tools);
	RING_API_REGISTER("webview_get_url", ring_webview_get_url);
	RING_API_REGISTER("webview_get_title", ring_webview_get_title);
	RING_API_REGISTER("webview_set_context_menu", ring_webview_set_context_menu);
	RING_API_REGISTER("webview_set_force_dark", ring_webview_set_force_dark);
	RING_API_REGISTER("webview_is_force_dark", ring_webview_is_force_dark);
	RING_API_REGISTER("webview_get_screens", ring_webview_get_screens);
	RING_API_REGISTER("webview_set_click_through", ring_webview_set_click_through);
	RING_API_REGISTER("webview_is_click_through", ring_webview_is_click_through);

	// Event Callback Functions
	RING_API_REGISTER("webview_on_close", ring_webview_on_close);
	RING_API_REGISTER("webview_on_resize", ring_webview_on_resize);
	RING_API_REGISTER("webview_on_focus", ring_webview_on_focus);
	RING_API_REGISTER("webview_on_dom_ready", ring_webview_on_dom_ready);
	RING_API_REGISTER("webview_on_load", ring_webview_on_load);
	RING_API_REGISTER("webview_on_navigate", ring_webview_on_navigate);
	RING_API_REGISTER("webview_on_title", ring_webview_on_title);

	// Constants
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