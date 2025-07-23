# Unbind Example

load "webview.ring"
load "jsonlib.ring"

oWebView = NULL

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring WebView Unbind Example")
	# Set the window size (no size constraint).
	oWebView.setSize(600, 400, WEBVIEW_HINT_NONE)

	# Bind `myBoundFunction`: This is the function that will be unbound later.
	oWebView.bind("myBoundFunction", :handleMyBoundFunction)
	# Bind `unbindFunction`: This function, when called from JS, will trigger the unbinding.
	oWebView.bind("unbindFunction", :handleUnbindFunction)

	# Load the HTML content.
	loadHTML()

	see "Running the WebView main loop. Interact with the buttons in the UI." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	see "Cleaning up WebView resources and exiting." + nl
	oWebView.destroy()

# Function to load the HTML content.
func loadHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Unbind Example</title>
		<meta charset="UTF-8">
		<style>
			body { font-family: sans-serif; text-align: center; padding-top: 50px; background-color: #f0f0f0; }
			button { font-size: 1.2em; padding: 10px 20px; margin: 10px; cursor: pointer; }
			#status { margin-top: 20px; font-style: italic; color: #555; }
		</style>
	</head>
	<body>
		<h1>Webview Unbind Example</h1>
		<p>Click the first button. You should see a message in the console.<br>
		   Then, click the second button to unbind the function.<br>
		   After that, clicking the first button should do nothing.</p>

		<button onclick="callBoundFunction()">Call Bound Function</button>
		<button onclick="callUnbindFunction()">Unbind Function</button>

		<div id="status">Function 'myBoundFunction' is currently bound.</div>

		<script>
			async function callBoundFunction() {
				try {
					await window.myBoundFunction();
					console.log("Called myBoundFunction.");
				} catch (e) {
					console.error("Failed to call myBoundFunction. It might be unbound.", e);
					document.getElementById('status').textContent = "Call failed. The function is likely unbound.";
				}
			}

			async function callUnbindFunction() {
				try {
					await window.unbindFunction();
					console.log("Called unbindFunction.");
					document.getElementById('status').textContent = "Function 'myBoundFunction' has been unbound.";
				} catch (e) {
					console.error("Error calling unbindFunction:", e);
				}
			}
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers (Bound to JavaScript) ---

# This function is called by JavaScript via `window.myBoundFunction()`.
func handleMyBoundFunction(id, req)
	see "Ring: 'handleMyBoundFunction' was successfully called from JavaScript!" + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# This function is called by JavaScript via `window.unbindFunction()`.
# It demonstrates how to unbind a previously bound Ring function.
func handleUnbindFunction(id, req)
	see "Ring: Initiating unbind for 'myBoundFunction'..." + nl
	oWebView.unbind("myBoundFunction") # Unbind the specified function.
	see "Ring: 'myBoundFunction' has been unbound. Subsequent calls from JS will fail." + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.