# This file is part of the Ring WebView library.


/*
 * aWebViewConfig: Global configuration for the WebView class.
 * Fields:
 *   :debug   - (Boolean) Enable debug mode for the WebView (default: true).
 *   :window  - (Pointer/NULL) Native window handle to associate with the WebView (default: NULL).
 *               Set to NULL to let the library create its own window.
 */
aWebViewConfig = [
	:debug = true,
	:window = NULL
]

/*
 * Internal global list to store objects for method bindings (used by eval in bind()).
*/
__aWebViewObjects = []

/**
 * Class WebView: Represents a webview instance for displaying HTML content.
 * Provides methods for binding Ring functions to JavaScript, navigating URLs,
 * and managing the webview lifecycle.
 */
Class WebView

	_pWebView
	_bindings = []
	_isDestroyed = false

	/**
	 * Initializes the WebView instance using global configuration.
	 */
	func init
		self._pWebView = webview_create(aWebViewConfig[:debug], aWebViewConfig[:window])
		if isNull(self._pWebView) or not isPointer(self._pWebView)
			raise("Failed to create webview instance.")
		ok

		# Automatically bind global `aBindList` if it exists.
		bindMany(NULL)

	/**
	 * Checks if the webview has been destroyed.
	 * @return true if destroyed, false otherwise.
	 */
	func isDestroyed()
		return self._isDestroyed

	/**
	 * Runs the webview event loop (blocking call).
	 * Destroys the webview after the loop ends.
	 */
	func run()
		if self.isDestroyed()
			return
		ok
		webview_run(self._pWebView)
		# After run() finishes, the window is closed, so we must destroy.
		self.destroy()

	/**
	 * Destroys the webview instance and releases resources.
	 */
	func destroy()
		if self.isDestroyed()
			return
		ok

		self._isDestroyed = true

		webview_destroy(self._pWebView)

		self._pWebView = NULL
		self._bindings = []
		
	func terminate()
		if self.isDestroyed()
			return
		ok
		webview_terminate(self._pWebView)

	/**
	 * Dispatches code to run on the main thread.
	 * @param cCode Code to execute.
	 * @return Result of dispatch.
	 */
	func dispatch(cCode)
		if self.isDestroyed()
			return
		ok

		return webview_dispatch(self._pWebView, cCode)

	/**
	 * Binds a Ring function or object methods to JavaScript.
	 *
	 * For simple functions:
	 *   bind(jsName, ringFuncName)
	 *
	 * For object methods:
	 *   bind(oObject, aMethods)
	 *
	 * @param p1 For functions, the JS name. For objects, the Ring object.
	 * @param p2 For functions, the Ring function name. For objects, a list of method pairs.
	 * @return Binding result pointer for simple functions, or nothing for objects.
	 */
	func bind(p1, p2)
		if self.isDestroyed()
			return
		ok

		# Check for object binding
		if isObject(p1) and isList(p2)
			oObject = p1
			aMethods = p2

			# Store object and get its index
			nObjectIndex = find(__aWebViewObjects, oObject)

			if nObjectIndex = 0
				add(__aWebViewObjects, ref(oObject))
				nObjectIndex = len(__aWebViewObjects)
			ok

			for aMethodInfo in aMethods
				if isList(aMethodInfo) and len(aMethodInfo) = 2 and isString(aMethodInfo[1]) and isString(aMethodInfo[2])
					cJSName = aMethodInfo[1]
					cMethodName = aMethodInfo[2]

					# Create wrapper function
					cFunc = eval(print2str(`
						return func (id, req) { __aWebViewObjects[#{nObjectIndex}].#{cMethodName}(id,req) }
					`))

					# Bind the generated function
					self.bind(cJSName, cFunc)
				else
					see "Warning: Invalid method definition." + nl
				ok
			next
		else
			# Simple function binding
			jsName = p1
			ringFuncName = p2
			aBindResult = webview_bind(self._pWebView, jsName, ringFuncName)

			if isPointer(aBindResult)
				add(self._bindings, aBindResult)
			ok
			return aBindResult
		ok

	/**
	 * Binds multiple Ring functions or object methods to JavaScript.
	 *
	 * This function accepts a list containing a mix of binding types:
	 * - For simple functions: `["jsFunctionName", "ringFunctionName"]`
	 * - For object methods: `[ringObject, [["jsFunctionName", "methodName"], ...]]`
	 *
	 * If `aList` is `NULL`, the function will attempt to use a global list
	 * named `aBindList` as the source of bindings.
	 *
	 * @param aList A list of bindings. If `NULL`, uses the global `aBindList`.
	 */
	func bindMany(aList)
		if self.isDestroyed()
			return
		ok

		if isNull(aList)
			if isGlobal("aBindList")
				aList = aBindList
			else
				return # No bindings to process
			ok
		ok

		if isList(aList)
			for aItem in aList
				if isList(aItem) and len(aItem) = 2
					self.bind(aItem[1], aItem[2])
				ok
			next
		ok

	/**
	 * Unbinds a JavaScript function name.
	 * @param jsName JavaScript function name.
	 * @return Result of unbind.
	 */
	func unbind(jsName)
		if self.isDestroyed()
			return
		ok
		
		return webview_unbind(self._pWebView, jsName)

	/**
	 * Gets the native window handle.
	 * @return Native window handle.
	 */
	func getWindow()
		if self.isDestroyed()
			return
		ok

		return webview_get_window(self._pWebView)

	/**
	 * Gets the native handle of a specific kind.
	 * @param kind Type of native handle.
	 * @return Native handle.
	 */
	func getNativeHandle(kind)
		if self.isDestroyed()
			return
		ok

		return webview_get_native_handle(self._pWebView, kind)

	/**
	 * Sets the window title.
	 * @param title Window title string.
	 */
	func setTitle(title)
		if self.isDestroyed()
			return
		ok

		webview_set_title(self._pWebView, title)

	/**
	 * Sets the window size.
	 * @param width Window width.
	 * @param height Window height.
	 * @param hint Size hint.
	 */
	func setSize(width, height, hint)
		if self.isDestroyed()
			return
		ok

		webview_set_size(self._pWebView, width, height, hint)

	/**
	 * Navigates to a URL.
	 * @param url URL to navigate to.
	 */
	func navigate(url)
		if self.isDestroyed()
			return
		ok

		webview_navigate(self._pWebView, url)

	/**
	 * Sets the HTML content of the webview.
	 * @param html HTML string.
	 */
	func setHtml(html)
		if self.isDestroyed()
			return
		ok

		webview_set_html(self._pWebView, html)

	/**
	 * Injects JavaScript code to run on initialization.
	 * @param js JavaScript code string.
	 */
	func injectJS(js)
		if self.isDestroyed()
			return
		ok

		webview_init(self._pWebView, js)

	/**
	 * Evaluates JavaScript code in the webview.
	 * @param js JavaScript code string.
	 */
	func evalJS(js)
		if self.isDestroyed()
			return
		ok

		webview_eval(self._pWebView, js)

	/**
	 * Returns a result to a JavaScript callback.
	 * @param id Callback id.
	 * @param result Result value e.g. WEBVIEW_ERROR_OK.
	 * @param json JSON string.
	 */
	func wreturn(id, result, json)
		if self.isDestroyed()
			return
		ok

		webview_return(self._pWebView, id, result, json)

	/**
	 * Enables or disables window decorations (title bar, borders).
	 * @param decorated True to show decorations, false for frameless window.
	 * @return 1 on success, 0 on failure.
	 */
	func setDecorated(decorated)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_decorated(self._pWebView, decorated)

	/**
	 * Sets the window transparency level.
	 * @param opacity Value between 0.0 (transparent) and 1.0 (opaque).
	 * @return 1 on success, 0 on failure.
	 */
	func setOpacity(opacity)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_opacity(self._pWebView, opacity)

	/**
	 * Sets whether the window should stay above all other windows.
	 * @param onTop True to keep on top, false for normal behavior.
	 * @return 1 on success, 0 on failure. Not supported on Linux/GTK4.
	 */
	func setAlwaysOnTop(onTop)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_always_on_top(self._pWebView, onTop)

	/**
	 * Minimizes the window to the taskbar/dock.
	 * @return 1 on success, 0 on failure.
	 */
	func minimize()
		if self.isDestroyed()
			return 0
		ok
		return webview_minimize(self._pWebView)

	/**
	 * Maximizes the window to fill the screen.
	 * @return 1 on success, 0 on failure.
	 */
	func maximize()
		if self.isDestroyed()
			return 0
		ok
		return webview_maximize(self._pWebView)

	/**
	 * Restores the window from minimized or maximized state.
	 * @return 1 on success, 0 on failure.
	 */
	func restore()
		if self.isDestroyed()
			return 0
		ok
		return webview_restore(self._pWebView)

	/**
	 * Checks if the window is currently maximized.
	 * @return 1 if maximized, 0 if not.
	 */
	func isMaximized()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_maximized(self._pWebView)

	/**
	 * Initiates window dragging. Call from a mouse-down event on custom title bar.
	 * @return 1 on success, 0 on failure.
	 */
	func startDrag()
		if self.isDestroyed()
			return 0
		ok
		return webview_start_drag(self._pWebView)

	/**
	 * Moves the window to the specified screen coordinates.
	 * @param x The x-coordinate.
	 * @param y The y-coordinate.
	 * @return 1 on success, 0 on failure. Not supported on Linux/Wayland.
	 */
	func setPosition(x, y)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_position(self._pWebView, x, y)

	/**
	 * Gets the current window position.
	 * @return A list [x, y] containing the window coordinates.
	 */
	func getPosition()
		if self.isDestroyed()
			return [0, 0]
		ok
		return webview_get_position(self._pWebView)

	/**
	 * Gets the current window size.
	 * @return A list [width, height] containing the window dimensions.
	 */
	func getSize()
		if self.isDestroyed()
			return [0, 0]
		ok
		return webview_get_size(self._pWebView)

	/**
	 * Brings the window to the front and gives it focus.
	 * @return 1 on success, 0 on failure.
	 */
	func focus()
		if self.isDestroyed()
			return 0
		ok
		return webview_focus(self._pWebView)

	/**
	 * Hides the window without destroying it.
	 * @return 1 on success, 0 on failure.
	 */
	func hide()
		if self.isDestroyed()
			return 0
		ok
		return webview_hide(self._pWebView)

	/**
	 * Shows a previously hidden window.
	 * @return 1 on success, 0 on failure.
	 */
	func show()
		if self.isDestroyed()
			return 0
		ok
		return webview_show(self._pWebView)

	/**
	 * Initiates window resizing from the specified edge.
	 * @param edge The edge constant (e.g., WEBVIEW_EDGE_RIGHT).
	 * @return 1 on success, 0 on failure.
	 */
	func startResize(edge)
		if self.isDestroyed()
			return 0
		ok
		return webview_start_resize(self._pWebView, edge)

	/**
	 * Enables or disables fullscreen mode.
	 * @param fullscreen True for fullscreen, false for windowed mode.
	 * @return 1 on success, 0 on failure.
	 */
	func setFullscreen(fullscreen)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_fullscreen(self._pWebView, fullscreen)

	/**
	 * Checks if the window is currently in fullscreen mode.
	 * @return 1 if fullscreen, 0 if windowed.
	 */
	func isFullscreen()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_fullscreen(self._pWebView)

	/**
	 * Enables or disables window resizing by the user.
	 * @param resizable True to allow resizing, false to prevent it.
	 * @return 1 on success, 0 on failure.
	 */
	func setResizable(resizable)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_resizable(self._pWebView, resizable)

	/**
	 * Checks if the window is currently resizable.
	 * @return 1 if resizable, 0 if not.
	 */
	func isResizable()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_resizable(self._pWebView)

	/**
	 * Sets the minimum size constraint for the window.
	 * @param width Minimum width in pixels.
	 * @param height Minimum height in pixels.
	 * @return 1 on success, 0 on failure.
	 */
	func setMinSize(width, height)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_min_size(self._pWebView, width, height)

	/**
	 * Sets the maximum size constraint for the window.
	 * @param width Maximum width in pixels.
	 * @param height Maximum height in pixels.
	 * @return 1 on success, 0 on failure.
	 */
	func setMaxSize(width, height)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_max_size(self._pWebView, width, height)

	/**
	 * Sets the background color of the webview.
	 * @param r Red component (0-255).
	 * @param g Green component (0-255).
	 * @param b Blue component (0-255).
	 * @param a Alpha component (0-255). 0 = transparent, 255 = opaque.
	 * @return 1 on success, 0 on failure.
	 */
	func setBackgroundColor(r, g, b, a)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_background_color(self._pWebView, r, g, b, a)

	/**
	 * Navigates back in the browsing history.
	 * @return 1 on success, 0 on failure.
	 */
	func back()
		if self.isDestroyed()
			return 0
		ok
		return webview_back(self._pWebView)

	/**
	 * Navigates forward in the browsing history.
	 * @return 1 on success, 0 on failure.
	 */
	func forward()
		if self.isDestroyed()
			return 0
		ok
		return webview_forward(self._pWebView)

	/**
	 * Reloads the current page.
	 * @return 1 on success, 0 on failure.
	 */
	func reload()
		if self.isDestroyed()
			return 0
		ok
		return webview_reload(self._pWebView)

	/**
	 * Shows or hides the developer tools (inspector).
	 * @param enabled True to show dev tools, false to hide.
	 * @return 1 on success, 0 on failure.
	 */
	func setDevTools(enabled)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_dev_tools(self._pWebView, enabled)

	/**
	 * Gets the URL of the currently loaded page.
	 * @return The current URL string, or empty string if not available.
	 */
	func getUrl()
		if self.isDestroyed()
			return ""
		ok
		return webview_get_url(self._pWebView)

	/**
	 * Gets the title of the currently loaded page.
	 * @return The page title string, or empty string if not available.
	 */
	func getPageTitle()
		if self.isDestroyed()
			return ""
		ok
		return webview_get_title(self._pWebView)

	/**
	 * Enables or disables the default browser context menu (right-click menu).
	 * @param enabled True to allow context menu, false to suppress it.
	 * @return 1 on success, 0 on failure.
	 */
	func setContextMenu(enabled)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_context_menu(self._pWebView, enabled)

	/**
	 * Sets the window icon from a file.
	 * @param iconPath Path to the icon file (PNG, ICO, etc.).
	 * @return 1 on success, 0 on failure.
	 */
	func setIcon(iconPath)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_icon(self._pWebView, iconPath)

	/**
	 * Checks if the window currently has focus.
	 * @return 1 if focused, 0 if not.
	 */
	func isFocused()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_focused(self._pWebView)

	/**
	 * Checks if the window is currently visible.
	 * @return 1 if visible, 0 if hidden.
	 */
	func isVisible()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_visible(self._pWebView)

	/**
	 * Programmatically closes the window.
	 * @return 1 on success, 0 on failure.
	 */
	func closeWindow()
		if self.isDestroyed()
			return 0
		ok
		return webview_close(self._pWebView)

	/**
	 * Forces dark mode for the application UI.
	 * @param enabled True to force dark mode, false for system default.
	 * @return 1 on success, 0 on failure. Only supported on Linux with libadwaita.
	 */
	func setForceDark(enabled)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_force_dark(self._pWebView, enabled)

	/**
	 * Checks if dark mode is forced.
	 * @return 1 if dark mode is forced, 0 if not.
	 */
	func isForceDark()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_force_dark(self._pWebView)

	/**
	 * Gets information about all connected monitors/screens.
	 * @return A list of lists. Each: [name, x, y, width, height].
	 */
	func getScreens()
		if self.isDestroyed()
			return []
		ok
		return webview_get_screens(self._pWebView)

	/**
	 * Enables or disables click-through mode (mouse events pass through).
	 * @param enabled True to enable click-through, false to disable.
	 * @return 1 on success, 0 on failure. Only supported on Windows.
	 */
	func setClickThrough(enabled)
		if self.isDestroyed()
			return 0
		ok
		return webview_set_click_through(self._pWebView, enabled)

	/**
	 * Checks if click-through mode is enabled.
	 * @return 1 if enabled, 0 if not.
	 */
	func isClickThrough()
		if self.isDestroyed()
			return 0
		ok
		return webview_is_click_through(self._pWebView)

	/**
	 * Sets a callback for when the window close is requested.
	 * @param callback Name of the Ring function: func name(cData).
	 * @return 1 on success, 0 on failure.
	 */
	func onClose(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_close(self._pWebView, callback)

	/**
	 * Sets a callback for when the window is resized.
	 * @param callback Name of the Ring function: func name(cData).
	 * @return 1 on success, 0 on failure.
	 */
	func onResize(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_resize(self._pWebView, callback)

	/**
	 * Sets a callback for when the window gains or loses focus.
	 * @param callback Name of the Ring function: func name(cFocused) where cFocused is "true" or "false".
	 * @return 1 on success, 0 on failure.
	 */
	func onFocus(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_focus(self._pWebView, callback)

	/**
	 * Sets a callback for when the DOM is ready.
	 * @param callback Name of the Ring function: func name(cData).
	 * @return 1 on success, 0 on failure.
	 */
	func onDomReady(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_dom_ready(self._pWebView, callback)

	/**
	 * Sets a callback for when a page load starts or finishes.
	 * @param callback Name of the Ring function: func name(cState) where cState is "started" or "finished".
	 * @return 1 on success, 0 on failure.
	 */
	func onLoad(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_load(self._pWebView, callback)

	/**
	 * Sets a callback for when navigation occurs.
	 * @param callback Name of the Ring function: func name(cUrl).
	 * @return 1 on success, 0 on failure.
	 */
	func onNavigate(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_navigate(self._pWebView, callback)

	/**
	 * Sets a callback for when the page title changes.
	 * @param callback Name of the Ring function: func name(cTitle).
	 * @return 1 on success, 0 on failure.
	 */
	func onTitle(callback)
		if self.isDestroyed()
			return 0
		ok
		return webview_on_title(self._pWebView, callback)