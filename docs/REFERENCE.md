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

### `bind(jsName, ringFuncName)`

Binds a Ring function to a JavaScript function, allowing it to be called from the webview. When the JavaScript function `jsName` is called, the `ringFuncName` in Ring will be invoked.

-   **`jsName`**: (String) The name of the function to expose in JavaScript (e.g., `window.myFunction`).
-   **`ringFuncName`**: (String or Function Pointer) The name of the Ring function to call, or an anonymous function (e.g., `:myRingFunction` or `func(id, req) { ... }`). The Ring function receives two arguments:
    -   `id`: (Number) A unique callback ID used for `wreturn()`.
    -   `req`: (String) A JSON string containing the arguments passed from JavaScript. This string needs to be parsed in Ring (e.g., using `json2list()`).

---

### `bindMany(aList)`

Binds multiple Ring functions to JavaScript functions in a single call. This is a convenient alternative to calling `bind()` multiple times.

-   **`aList`**: (List, optional) A list of binding pairs, where each pair is a list containing `[jsName, ringFuncName]`.
    -   If `aList` is not provided (or is `NULL`), the method will look for a global variable named `aBindList` and use it if it exists and is a list. This allows you to define your bindings in a central location.

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