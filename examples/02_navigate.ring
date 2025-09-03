# Navigate to a URL using Ring WebView
# This example demonstrates how to create a simple webview that navigates to a specific URL.

load "webview.ring"

# Create a new WebView instance.
oWebView = new WebView()

# Configure the WebView properties.
oWebView {
    # Set the title of the webview window.
    setTitle("Ring Webview Navigate Example")
    # Set the size of the webview window (width, height, hint).
    # WEBVIEW_HINT_NONE means no size constraint.
    setSize(800, 600, WEBVIEW_HINT_NONE)
    # Navigate the webview to a specific URL.
    navigate("https://ring-lang.github.io")

    # Run the webview event loop.
    # This is a blocking call that keeps the window open until it's closed by the user.
    run()

    # No need to explicitly destroy the webview instance here.
    # The webview will be automatically cleaned up when the run() method exits.
}

see "Webview closed." + nl
