#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include "webview/webview.h"

int ring_webview_macos_set_decorated(webview_t w, int decorated)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    if (decorated) {
        window.styleMask |= (NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | 
                            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable);
    } else {
        window.styleMask &= ~(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | 
                             NSWindowStyleMaskMiniaturizable);
        window.styleMask |= NSWindowStyleMaskBorderless;
    }
    
    return 1;
}

int ring_webview_macos_set_opacity(webview_t w, double opacity)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    [window setAlphaValue:opacity];
    return 1;
}

int ring_webview_macos_set_always_on_top(webview_t w, int onTop)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    if (onTop) {
        [window setLevel:NSFloatingWindowLevel];
    } else {
        [window setLevel:NSNormalWindowLevel];
    }
    
    return 1;
}

int ring_webview_macos_minimize(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    [window miniaturize:nil];
    return 1;
}

int ring_webview_macos_maximize(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    if (![window isZoomed]) {
        [window zoom:nil];
    }
    return 1;
}

int ring_webview_macos_restore(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    if ([window isMiniaturized]) {
        [window deminiaturize:nil];
    }
    if ([window isZoomed]) {
        [window zoom:nil];
    }
    return 1;
}

int ring_webview_macos_is_maximized(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    return [window isZoomed] ? 1 : 0;
}

int ring_webview_macos_start_drag(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    NSEvent *currentEvent = [NSApp currentEvent];
    if (currentEvent) {
        [window performWindowDragWithEvent:currentEvent];
    }
    return 1;
}

int ring_webview_macos_set_position(webview_t w, int x, int y)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    NSScreen *screen = [NSScreen mainScreen];
    CGFloat screenHeight = screen.frame.size.height;
    NSRect frame = window.frame;
    CGFloat flippedY = screenHeight - y - frame.size.height;
    
    [window setFrameOrigin:NSMakePoint(x, flippedY)];
    return 1;
}

void ring_webview_macos_get_position(webview_t w, int *x, int *y)
{
    *x = 0;
    *y = 0;
    
    if (!w) return;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return;
    
    NSScreen *screen = [NSScreen mainScreen];
    CGFloat screenHeight = screen.frame.size.height;
    NSRect frame = window.frame;
    
    *x = (int)frame.origin.x;
    *y = (int)(screenHeight - frame.origin.y - frame.size.height);
}

void ring_webview_macos_get_size(webview_t w, int *width, int *height)
{
    *width = 0;
    *height = 0;
    
    if (!w) return;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return;
    
    NSRect frame = window.frame;
    *width = (int)frame.size.width;
    *height = (int)frame.size.height;
}

int ring_webview_macos_focus(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    return 1;
}

int ring_webview_macos_hide(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    [window orderOut:nil];
    return 1;
}

int ring_webview_macos_show(webview_t w)
{
    if (!w) return 0;
    
    NSWindow *window = (__bridge NSWindow *)webview_get_window(w);
    if (!window) return 0;
    
    [window makeKeyAndOrderFront:nil];
    return 1;
}
