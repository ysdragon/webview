# Navigate to a URL using Ring WebView
# This example demonstrates how to create a simple webview that navigates to a specific URL.

load "webview.ring"

# Create a new WebView instance.
# Parameters: debug mode (1 for on, 0 for off), parent window handle (NULL for a new window).
oWebView = new WebView(1, NULL)

# Configure the WebView properties using the object-oriented approach.
oWebView {
    # Set the title of the webview window.
    setTitle("Ring Webview Test")
    # Set the size of the webview window (width, height, hint).
    # WEBVIEW_HINT_NONE means no size constraint.
    setSize(800, 600, WEBVIEW_HINT_NONE)
    # Navigate the webview to a specific URL.
    navigate("https://ring-lang.github.io")

    # Run the webview event loop.
    # This is a blocking call that keeps the window open until it's closed by the user.
    run()

    # No need to explicitly destroy the webview instance here,
    # as when closing braces are reached, the webview instance is automatically destroyed.
}

see "Webview closed." + nl
