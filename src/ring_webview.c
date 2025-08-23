/*
 * ring_webview.c
 * This file is part of the Ring WebView library.
 * Author: Youssef Saeed (ysdragon) <youssefelkholey@gmail.com>
 */

#include "ring.h"

#include "webview/webview.h"
#include "webview/version.h"

// Helper structure for webview_bind
typedef struct RingWebViewBind
{
	VM *pVM;
	char *cFunc;
} RingWebViewBind;

// Helper structure for webview_dispatch
typedef struct RingWebViewDispatch
{
	VM *pVM;
	char *cCode;
} RingWebViewDispatch;

// Duplicate a C string using ring_state_malloc and return the new string
static char *ring_webview_string_strdup(void *pState, const char *cStr)
{
	char *cString;
	unsigned int x, nSize;
	nSize = strlen(cStr);
	cString = (char *)ring_state_malloc(pState, nSize + RING_ONE);
	RING_MEMCPY(cString, cStr, nSize);
	cString[nSize] = '\0';
	return cString;
}

// The C callback that webview will call from JavaScript
void ring_webview_bind_callback(const char *id, const char *req, void *arg)
{
	RingWebViewBind *pBind = (RingWebViewBind *)arg;
	if (!pBind || !pBind->pVM || !pBind->cFunc)
	{
		return;
	}

	VM *pVM = pBind->pVM;
	RingState *pRingState = pVM->pRingState;

	// Mutex Lock
	ring_vm_mutexlock(pVM);

	// Save current stack and call state.
	int nSP_before = pVM->nSP;
	int nFuncSP_before = pVM->nFuncSP;
	int nCallListSize_before = RING_VM_FUNCCALLSCOUNT;

	// Load the function by name.
	if (!ring_vm_loadfunc2(pVM, pBind->cFunc, RING_FALSE))
	{
		// Function not found; clean up and return.
		pVM->nSP = nSP_before;
		pVM->nFuncSP = nFuncSP_before;
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

	// Execute the Ring code
	ring_vm_runcodefromthread(pDispatch->pVM, pDispatch->cCode);

	// Free the allocated memory
	ring_state_free(pDispatch->pVM->pRingState, pDispatch->cCode);
	ring_state_free(pDispatch->pVM->pRingState, pDispatch);
}

// Helper to destroy webview and free resources to avoid duplication.
void ring_webview_destroy_internal(webview_t *pWebView)
{
	if (pWebView && *pWebView)
	{
		webview_destroy(*pWebView);
		*pWebView = NULL;
	}
}

// Custom free function for the webview_t object, called by the GC.
void ring_webview_free(void *pState, void *pPointer)
{
	webview_t *pWebView = (webview_t *)pPointer;
	ring_webview_destroy_internal(pWebView);
	ring_state_free(pState, pPointer);
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

	webview_t w = *(webview_t *)RING_API_GETCPOINTER(1, "webview_t");
	const char *cCodeToRun = RING_API_GETSTRING(2);

	RingWebViewDispatch *pDispatch = (RingWebViewDispatch *)RING_API_MALLOC(sizeof(RingWebViewDispatch));
	if (pDispatch == NULL)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}
	pDispatch->pVM = (VM *)pPointer;
	pDispatch->cCode = ring_webview_string_strdup(RING_API_STATE, cCodeToRun);
	if (pDispatch->cCode == NULL)
	{
		RING_API_FREE(pDispatch);
		RING_API_ERROR(RING_OOM);
		return;
	}

	webview_error_t result = webview_dispatch(w, ring_webview_dispatch_callback, pDispatch);

	// Free memory if dispatch fails to avoid leaks.
	if (result != WEBVIEW_ERROR_OK)
	{
		ring_state_free(RING_API_STATE, pDispatch->cCode);
		ring_state_free(RING_API_STATE, pDispatch);
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

	webview_t w = *(webview_t *)RING_API_GETCPOINTER(1, "webview_t");
	const char *js_name = RING_API_GETSTRING(2);
	const char *ring_func_name = RING_API_GETSTRING(3);

	RingWebViewBind *pBind = (RingWebViewBind *)RING_API_MALLOC(sizeof(RingWebViewBind));
	if (pBind == NULL)
	{
		RING_API_ERROR(RING_OOM);
		return;
	}

	pBind->pVM = (VM *)pPointer;
	pBind->cFunc = ring_webview_string_strdup(RING_API_STATE, ring_func_name);
	if (pBind->cFunc == NULL)
	{
		RING_API_FREE(pBind);
		RING_API_ERROR(RING_OOM);
		return;
	}

	webview_error_t result = webview_bind(w, js_name, ring_webview_bind_callback, pBind);

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

	webview_t w = *(webview_t *)RING_API_GETCPOINTER(1, "webview_t");
	const char *js_name = RING_API_GETSTRING(2);

	// Note: This only unbinds the JS function; the RingWebViewBind object is not freed.
	webview_error_t result = webview_unbind(w, js_name);
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

	webview_t *pValue;
	pValue = (webview_t *)RING_API_MALLOC(sizeof(webview_t));
	*pValue = webview_create((int)RING_API_GETNUMBER(1), pWindow);

	RING_API_RETMANAGEDCPOINTER(pValue, "webview_t", ring_webview_free);
}

RING_FUNC(ring_webview_destroy)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}

	webview_t *pWebView = (webview_t *)RING_API_GETCPOINTER(1, "webview_t");
	ring_webview_destroy_internal(pWebView);
	RING_API_SETNULLPOINTER(1);
}

RING_FUNC(ring_webview_run)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	webview_run(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"));
}

RING_FUNC(ring_webview_terminate)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	webview_terminate(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"));
}

RING_FUNC(ring_webview_get_window)
{
	if (RING_API_PARACOUNT != 1)
	{
		RING_API_ERROR(RING_API_MISS1PARA);
		return;
	}
	RING_API_RETCPOINTER(webview_get_window(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t")), "void");
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
	RING_API_RETCPOINTER(webview_get_native_handle(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), (webview_native_handle_kind_t)(int)RING_API_GETNUMBER(2)), "void");
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
	webview_set_title(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2));
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
	webview_set_size(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), (int)RING_API_GETNUMBER(2), (int)RING_API_GETNUMBER(3), (webview_hint_t)(int)RING_API_GETNUMBER(4));
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
	webview_navigate(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2));
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
	webview_set_html(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2));
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
	webview_init(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2));
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
	webview_eval(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2));
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
	webview_return(*(webview_t *)RING_API_GETCPOINTER(1, "webview_t"), RING_API_GETSTRING(2), (int)RING_API_GETNUMBER(3), RING_API_GETSTRING(4));
}

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

RING_LIBINIT
{
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
	RING_API_REGISTER("get_webview_hint_none", ring_get_webview_hint_none);
	RING_API_REGISTER("get_webview_hint_min", ring_get_webview_hint_min);
	RING_API_REGISTER("get_webview_hint_max", ring_get_webview_hint_max);
	RING_API_REGISTER("get_webview_hint_fixed", ring_get_webview_hint_fixed);
	RING_API_REGISTER("get_webview_native_handle_kind_ui_window", ring_get_webview_native_handle_kind_ui_window);
	RING_API_REGISTER("get_webview_native_handle_kind_ui_widget", ring_get_webview_native_handle_kind_ui_widget);
	RING_API_REGISTER("get_webview_native_handle_kind_browser_controller", ring_get_webview_native_handle_kind_browser_controller);
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
}