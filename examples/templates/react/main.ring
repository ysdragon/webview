# Ring WebView + React Template
# Demonstrates a Vite+bun React frontend bundled to a single HTML file,
# loaded into Ring WebView with two-way data binding.

load "webview.ring"

# Global state shared with the bound JavaScript functions.
oWebView = NULL
nCount = 0

func main
	cDistFile = "frontend/dist/index.html"
      
	# The frontend must be built first (see README.md).
	if not fexists(cDistFile)
		see "Error: " + cDistFile + " not found." + nl
		see "Build the frontend first:" + nl
		see "  cd frontend && bun install && bun run build" + nl
		see "Then run again from this directory: ring main.ring" + nl
		return
	ok

	# Create and configure the WebView window.
	oWebView = new WebView()
	oWebView {
		setTitle("Ring WebView + React Template")
		setSize(440, 480, WEBVIEW_HINT_NONE)

		# Bind functions callable from JavaScript.
		# Each returns the current count; the Promise resolves with it.
		bind("increment", func (id, req) {
			nCount++
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, string(nCount))
		})
		bind("decrement", func (id, req) {
			nCount--
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, string(nCount))
		})
		bind("getInitialCount", func (id, req) {
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, string(nCount))
		})

		# Load the single-file build output and run the event loop.
		setHtml(read(cDistFile))
		run()
	}
