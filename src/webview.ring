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