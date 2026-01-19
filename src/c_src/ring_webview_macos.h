#ifndef RING_WEBVIEW_MACOS_H
#define RING_WEBVIEW_MACOS_H

#include "webview/webview.h"

#ifdef __cplusplus
extern "C"
{
#endif

	int ring_webview_macos_set_decorated(webview_t w, int decorated);
	int ring_webview_macos_set_opacity(webview_t w, double opacity);
	int ring_webview_macos_set_always_on_top(webview_t w, int onTop);
	int ring_webview_macos_minimize(webview_t w);
	int ring_webview_macos_maximize(webview_t w);
	int ring_webview_macos_restore(webview_t w);
	int ring_webview_macos_is_maximized(webview_t w);
	int ring_webview_macos_start_drag(webview_t w);
	int ring_webview_macos_set_position(webview_t w, int x, int y);
	void ring_webview_macos_get_position(webview_t w, int *x, int *y);
	void ring_webview_macos_get_size(webview_t w, int *width, int *height);
	int ring_webview_macos_focus(webview_t w);
	int ring_webview_macos_hide(webview_t w);
	int ring_webview_macos_show(webview_t w);

#ifdef __cplusplus
}
#endif

#endif
