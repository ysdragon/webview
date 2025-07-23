# Local html example using Ring WebView

load "webview.ring"

# Optional Configuration for the WebView instance.
cWebViewConfig = [
	:debug = true  # Enable debug mode
]

# Create a new WebView instance.
oWebView = new WebView()

# Configure the WebView properties using the object-oriented approach.
oWebView {
	# Set the title of the webview window.
	setTitle("Ring Webview Local UI Test")
	# Set the size of the webview window (width, height, hint).
	# WEBVIEW_HINT_NONE means no size constraint.
	setSize(900, 800, WEBVIEW_HINT_NONE)
	# Navigate the webview to a local HTML file.
	# Prepend "file://" to the absolute path for local file access.
	navigate("file://" + currentdir() + "/assets/index.html")

	# Run the webview event loop.
	run()
}

see "Webview closed." + nl