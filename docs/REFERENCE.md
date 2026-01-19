# API Reference

This document provides a detailed reference for the Ring WebView library API.

## WebView Class

The `WebView` class is the core of the library, providing all the necessary methods to create and manage a webview window.

### `new WebView()`

Creates a new `WebView` instance. The constructor is now parameter-less and uses a global configuration list for setup.

#### Global Configuration

The `WebView` class relies on a global list named `aWebViewConfig` for its initial settings. You can modify this list before creating a `WebView` instance to customize its behavior.

-   **`aWebViewConfig[:debug]`**: (Boolean) Set to `true` (default) to enable debug mode.
-   **`aWebViewConfig[:window]`**: (Pointer) A native window handle to use as the parent. Defaults to `NULL`.

> **Note:** When a `WebView` instance is created, the `init()` method is called automatically. As part of this process, `bindMany(NULL)` is invoked. If a global list named `aBindList` exists and is a valid list, all bindings defined in `aBindList` will be registered automatically during initialization.

---

### `run()`

Runs the main event loop for the webview. This is a blocking call that will not return until the webview window is closed. It also calls `destroy()` automatically when the loop ends.

---

### `destroy()`

Destroys the webview instance and frees all associated resources. After calling this, the `WebView` object becomes unusable.

---

### `terminate()`

Stops the webview event loop and closes the window. This provides a way to programmatically close the webview window from Ring code.

---

### `setTitle(title)`

Sets the title of the webview window.

-   **`title`**: (String) The title to display.

---

### `setSize(width, height, hint)`

Sets the size of the webview window.

-   **`width`**: (Number) The width of the window.
-   **`height`**: (Number) The height of the window.
-   **`hint`**: (Constant) A size hint that controls the resizing behavior. See **Size Hints** below.

---

### `navigate(url)`

Navigates the webview to a new URL.

-   **`url`**: (String) The URL to load.

---

### `setHtml(html)`

Sets the HTML content of the webview directly.

-   **`html`**: (String) The HTML content to display.

---

### `bind(p1, p2)`

Binds a Ring function or a Ring object's methods to JavaScript.

-   **Function Binding**: `bind(jsName, ringFuncName)`
    -   `jsName` (String): The name of the function to expose in JavaScript (e.g., `myFunc`).
    -   `ringFuncName` (String | FuncPtr): The name of the Ring function or a function pointer.
-   **Object Method Binding**: `bind(oObject, aMethods)`
    -   `oObject` (Object): The Ring object instance whose methods will be bound.
    -   `aMethods` (List): A list of method pairs to bind. Each pair should be a list containing two strings: `["jsFunctionName", "objectMethodName"]`.

---

### `bindMany(aList)`

Binds multiple Ring functions or object methods to JavaScript in a single call.

-   **`aList`**: (List, optional) A list where each item defines a binding.
    -   For function binding, an item is a list of two elements: `["jsFunctionName", "ringFunctionName"]`.
    -   For object method binding, an item is a list containing the object and a list of method pairs: `[oObject, [["jsMethod1", "ringMethod1"], ...]]`.
    -   If `aList` is `NULL`, it uses the global `aBindList`.

---

### `unbind(jsName)`

Removes a previously created JavaScript-to-Ring binding. After unbinding, calls from JavaScript to `jsName` will no longer invoke the Ring function.

-   **`jsName`**: (String) The name of the JavaScript function to unbind.

---

### `injectJS(js)`

Injects and executes JavaScript code when the webview is first initialized or when a new HTML page is loaded (e.g., after `setHtml()` or `navigate()`). This is useful for setting up global JavaScript variables or functions before the page content fully loads.

-   **`js`**: (String) The JavaScript code to execute.

---

### `evalJS(js)`

Evaluates a string of JavaScript code in the currently loaded webview content. This is typically used to manipulate the DOM or trigger JavaScript functions from Ring after the page has loaded.

-   **`js`**: (String) The JavaScript code to evaluate.

---

### `dispatch(cCode)`

Dispatches a Ring code snippet to be executed on the main UI thread of the webview. This is crucial for performing UI-related operations from Ring functions that might be running on a different thread (e.g., callbacks).

-   **`cCode`**: (String) The Ring code to execute. This should typically be a function call (e.g., `"myFunction()"`) that performs UI updates.

---

### `getWindow()`

Returns a native handle to the webview window. The type of handle returned depends on the underlying platform.

---

### `getNativeHandle(kind)`

Returns a native handle of a specific kind, providing more granular access to the underlying webview components.

-   **`kind`**: (Constant) The type of handle to retrieve. See **Native Handle Kinds** below.

---

### `wreturn(id, result, json)`

Returns a result back to a JavaScript function that initiated a `bind()` call. This allows Ring to send data or acknowledge completion to the JavaScript frontend.

-   **`id`**: (Number) The callback ID received from the `bind()` call (first argument to the Ring function).
-   **`result`**: (Number) The status code for the operation. Use `WEBVIEW_ERROR_OK` for success. Other `WEBVIEW_ERROR_` constants can indicate specific issues.
-   **`json`**: (String) A JSON string containing the data to return to JavaScript. This will be the resolved value of the JavaScript `Promise`.

---

### `isDestroyed()`

Checks if the webview instance has already been destroyed and its resources released.

---

## Window Management Methods

> **Platform Limitations (Linux/FreeBSD with GTK4/Wayland):**
> - `setPosition()`, `getPosition()`: Not supported (Wayland security model)
> - `setAlwaysOnTop()`: Not supported (no GTK4 equivalent)
> - `setClickThrough()`: Not supported (Windows only)
>
> These methods return `0` (failure) on unsupported platforms. Windows and macOS support all features.

### `setDecorated(decorated)`

Enables or disables window decorations (title bar, borders).

-   **`decorated`**: (Boolean) `true` to show decorations, `false` for frameless window.
-   **Returns**: `1` on success, `0` on failure.

---

### `setOpacity(opacity)`

Sets the window transparency level.

-   **`opacity`**: (Number) Value between `0.0` (fully transparent) and `1.0` (fully opaque).
-   **Returns**: `1` on success, `0` on failure.

---

### `setAlwaysOnTop(onTop)`

Sets whether the window should stay above all other windows.

-   **`onTop`**: (Boolean) `true` to keep on top, `false` for normal behavior.
-   **Returns**: `1` on success, `0` on failure.

---

### `minimize()`

Minimizes the window to the taskbar/dock.

-   **Returns**: `1` on success, `0` on failure.

---

### `maximize()`

Maximizes the window to fill the screen.

-   **Returns**: `1` on success, `0` on failure.

---

### `restore()`

Restores the window from minimized or maximized state.

-   **Returns**: `1` on success, `0` on failure.

---

### `isMaximized()`

Checks if the window is currently maximized.

-   **Returns**: `1` if maximized, `0` if not.

---

### `startDrag()`

Initiates window dragging. Call this from a mouse-down event handler on your custom title bar.

-   **Returns**: `1` on success, `0` on failure.

> **Note**: Works on all platforms (Windows, Linux/GTK4, macOS).

---

### `setPosition(x, y)`

Moves the window to the specified screen coordinates.

-   **`x`**: (Number) The x-coordinate.
-   **`y`**: (Number) The y-coordinate.
-   **Returns**: `1` on success, `0` on failure.

---

### `getPosition()`

Gets the current window position.

-   **Returns**: A list `[x, y]` containing the window coordinates.

---

### `getSize()`

Gets the current window size.

-   **Returns**: A list `[width, height]` containing the window dimensions.

---

### `focus()`

Brings the window to the front and gives it focus.

-   **Returns**: `1` on success, `0` on failure.

---

### `hide()`

Hides the window without destroying it.

-   **Returns**: `1` on success, `0` on failure.

---

### `show()`

Shows a previously hidden window.

-   **Returns**: `1` on success, `0` on failure.

---

### `startResize(edge)`

Initiates window resizing from the specified edge. Call this from a mouse-down event handler on your custom resize borders.

-   **`edge`**: (Constant) The edge to resize from. See **Edge Constants** below.
-   **Returns**: `1` on success, `0` on failure.

> **Note**: Not supported on macOS. Works on Windows and Linux/GTK4.

---

### `setFullscreen(fullscreen)`

Enables or disables fullscreen mode.

-   **`fullscreen`**: (Boolean) `true` for fullscreen, `false` for windowed mode.
-   **Returns**: `1` on success, `0` on failure.

---

### `isFullscreen()`

Checks if the window is currently in fullscreen mode.

-   **Returns**: `1` if fullscreen, `0` if windowed.

---

### `setResizable(resizable)`

Enables or disables window resizing by the user.

-   **`resizable`**: (Boolean) `true` to allow resizing, `false` to prevent it.
-   **Returns**: `1` on success, `0` on failure.

---

### `isResizable()`

Checks if the window is currently resizable.

-   **Returns**: `1` if resizable, `0` if not.

---

### `setMinSize(width, height)`

Sets the minimum size constraint for the window.

-   **`width`**: (Number) Minimum width in pixels.
-   **`height`**: (Number) Minimum height in pixels.
-   **Returns**: `1` on success, `0` on failure.

---

### `setMaxSize(width, height)`

Sets the maximum size constraint for the window.

-   **`width`**: (Number) Maximum width in pixels.
-   **`height`**: (Number) Maximum height in pixels.
-   **Returns**: `1` on success, `0` on failure.

---

### `setBackgroundColor(r, g, b, a)`

Sets the background color of the webview. Useful for transparent windows or matching your app's theme before content loads.

-   **`r`**: (Number) Red component (0-255).
-   **`g`**: (Number) Green component (0-255).
-   **`b`**: (Number) Blue component (0-255).
-   **`a`**: (Number) Alpha component (0-255). 0 = transparent, 255 = opaque.
-   **Returns**: `1` on success, `0` on failure.

---

## Navigation Methods

### `back()`

Navigates back in the browsing history.

-   **Returns**: `1` on success, `0` on failure.

---

### `forward()`

Navigates forward in the browsing history.

-   **Returns**: `1` on success, `0` on failure.

---

### `reload()`

Reloads the current page.

-   **Returns**: `1` on success, `0` on failure.

---

### `getUrl()`

Gets the URL of the currently loaded page.

-   **Returns**: (String) The current URL, or empty string if not available.

---

### `getPageTitle()`

Gets the title of the currently loaded page.

-   **Returns**: (String) The page title, or empty string if not available.

---

## Developer Tools

### `setDevTools(enabled)`

Shows or hides the developer tools (inspector).

-   **`enabled`**: (Boolean) `true` to show dev tools, `false` to hide.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**:
> - **Windows**: Dev tools open in a separate window.
> - **Linux/WebKitGTK**: Dev tools open in a separate window.
> - **macOS**: Dev tools open in a separate window (requires debug mode).

---

### `setContextMenu(enabled)`

Enables or disables the default browser context menu (right-click menu).

-   **`enabled`**: (Boolean) `true` to allow context menu, `false` to suppress it.
-   **Returns**: `1` on success, `0` on failure.

> **Note**: When disabled, you can implement your own custom context menu via JavaScript.

---

### `setIcon(iconPath)`

Sets the window icon from a file.

-   **`iconPath`**: (String) Path to the icon file (PNG, ICO, etc.).
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**:
> - **Windows**: Supports .ico files.
> - **Linux/GTK**: Supports PNG and other common image formats.

---

### `isFocused()`

Checks if the window currently has focus.

-   **Returns**: `1` if focused, `0` if not.

---

### `isVisible()`

Checks if the window is currently visible.

-   **Returns**: `1` if visible, `0` if hidden.

---

### `closeWindow()`

Programmatically closes the window.

-   **Returns**: `1` on success, `0` on failure.

---

### `setForceDark(enabled)`

Forces dark mode for the application UI.

-   **`enabled`**: (Boolean) `true` to force dark mode, `false` for system default.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently only supported on Linux with libadwaita.

---

### `isForceDark()`

Checks if dark mode is forced.

-   **Returns**: `1` if dark mode is forced, `0` if not.

---

### `getScreens()`

Gets information about all connected monitors/screens.

-   **Returns**: A list of lists. Each inner list contains:
    -   `[1]`: Screen/monitor name (String)
    -   `[2]`: X position (Number)
    -   `[3]`: Y position (Number)
    -   `[4]`: Width in pixels (Number)
    -   `[5]`: Height in pixels (Number)

---

### `setClickThrough(enabled)`

Enables or disables click-through mode (mouse events pass through the window).

-   **`enabled`**: (Boolean) `true` to enable click-through, `false` to disable.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently only supported on Windows.

---

### `isClickThrough()`

Checks if click-through mode is enabled.

-   **Returns**: `1` if enabled, `0` if not.

---

## Event Callbacks

Event callbacks allow you to respond to various window and webview events. Pass the name of a Ring function to be called when the event occurs.

### `onClose(callback)`

Sets a callback to be called when the window close is requested.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cData)` - `cData` is empty string.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onResize(callback)`

Sets a callback to be called when the window is resized.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cData)` - `cData` contains size info.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onFocus(callback)`

Sets a callback to be called when the window gains or loses focus.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cFocused)` - `cFocused` is `"true"` or `"false"`.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onDomReady(callback)`

Sets a callback to be called when the DOM is ready (page finished loading).

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cData)` - `cData` is empty string.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onLoad(callback)`

Sets a callback to be called when a page load starts or finishes.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cState)` - `cState` is `"started"` or `"finished"`.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onNavigate(callback)`

Sets a callback to be called when navigation occurs.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cUrl)` - `cUrl` is the new URL.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

### `onTitle(callback)`

Sets a callback to be called when the page title changes.

-   **`callback`**: (String) Name of the Ring function to call.
-   **Callback signature**: `func myCallback(cTitle)` - `cTitle` is the new page title.
-   **Returns**: `1` on success, `0` on failure.

> **Platform Notes**: Currently implemented on Linux/FreeBSD (GTK4). Windows/macOS pending.

---

## Global Functions

These functions are available globally and do not require a `WebView` instance.

### `webview_version()`

Returns a string representing the version of the underlying WebView library.

---

## Constants

The following constants are available for use with the `WebView` class methods and global functions.

### Size Hints

-   `WEBVIEW_HINT_NONE`: The window can be resized freely.
-   `WEBVIEW_HINT_MIN`: The window has a minimum size, but can be enlarged.
-   `WEBVIEW_HINT_MAX`: The window has a maximum size, but can be made smaller.
-   `WEBVIEW_HINT_FIXED`: The window size cannot be changed by the user.

### Native Handle Kinds

-   `WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW`: Represents the main window handle.
-   `WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET`: Represents a widget or view handle within the window.
-   `WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER`: Represents the underlying browser engine controller.

### Error Codes

These constants are used as the `result` parameter in `wreturn()`.

-   `WEBVIEW_ERROR_OK`: Operation completed successfully.
-   `WEBVIEW_ERROR_UNSPECIFIED`: An unspecified error occurred.
-   `WEBVIEW_ERROR_INVALID_ARGUMENT`: A function was called with an invalid argument.
-   `WEBVIEW_ERROR_INVALID_STATE`: The webview is in an invalid state for the requested operation.
-   `WEBVIEW_ERROR_CANCELED`: The operation was canceled.
-   `WEBVIEW_ERROR_MISSING_DEPENDENCY`: A required dependency is missing.
-   `WEBVIEW_ERROR_DUPLICATE`: An attempt was made to create a duplicate resource.
-   `WEBVIEW_ERROR_NOT_FOUND`: A requested resource was not found.

### Version Constants
-   `WEBVIEW_VERSION_MAJOR`: The major version number (e.g., 0).
-   `WEBVIEW_VERSION_MINOR`: The minor version number (e.g., 12).
-   `WEBVIEW_VERSION_PATCH`: The patch version number (e.g., 0).

### Edge Constants

Used with `startResize(edge)` to specify which edge or corner to resize from.

-   `WEBVIEW_EDGE_TOP`: Resize from top edge.
-   `WEBVIEW_EDGE_BOTTOM`: Resize from bottom edge.
-   `WEBVIEW_EDGE_LEFT`: Resize from left edge.
-   `WEBVIEW_EDGE_RIGHT`: Resize from right edge.
-   `WEBVIEW_EDGE_TOP_LEFT`: Resize from top-left corner.
-   `WEBVIEW_EDGE_TOP_RIGHT`: Resize from top-right corner.
-   `WEBVIEW_EDGE_BOTTOM_LEFT`: Resize from bottom-left corner.
-   `WEBVIEW_EDGE_BOTTOM_RIGHT`: Resize from bottom-right corner.