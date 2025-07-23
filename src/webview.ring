# This file is part of the Ring WebView library.

Class WebView

	_pWebView
	_bindings = []
	_isDestroyed = false

	/**
	 * Initializes the WebView instance.
	 * @param debug Enable debug mode if true.
	 * @param window Native window handle or NULL.
	 */
	func init(debug, window)
		self._pWebView = webview_create(debug, window)
		if isNull(self._pWebView) or not isPointer(self._pWebView)
			raise("Failed to create webview instance.")
		ok

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
	 * Binds a Ring function to a JavaScript function name.
	 * @param jsName JavaScript function name.
	 * @param ringFuncName Ring function name.
	 * @return Binding result pointer.
	 */
	func bind(jsName, ringFuncName)
		if self.isDestroyed()
			return
		ok

		aBindResult = webview_bind(self._pWebView, jsName, ringFuncName)

		if isPointer(aBindResult)
			add(self._bindings, aBindResult)
		ok
		return aBindResult

	/**
	 * Binds multiple Ring functions to JavaScript function names.
	 * @param aList A list of [jsName, ringFuncName] pairs.
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