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
	oWebView.setSize(410, 410, WEBVIEW_HINT_NONE)

	# Bind `myBoundFunction`: This is the function that will be unbound later.
	oWebView.bind("myBoundFunction", :handleMyBoundFunction)
	# Bind `unbindFunction`: This function, when called from JS, will trigger the unbinding.
	oWebView.bind("unbindFunction", :handleUnbindFunction)

	# Load the HTML content.
	loadHTML()

	see "Running the WebView main loop. Interact with the buttons in the UI." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Function to load the HTML content.
func loadHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Unbind Example</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=500, initial-scale=1">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			:root {
				--bg-color: #000000;
				--panel-bg: rgba(30, 30, 32, 0.6);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
				--text-secondary: #a1a1aa;
				--accent-blue: #3b82f6;
				--accent-cyan: #22d3ee;
				--accent-purple: #c084fc;
			}
			body {
				font-family: 'Inter', sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				margin: 0;
				height: 100vh;
				overflow: hidden;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				position: relative;
			}
			.background-container {
				position: fixed;
				top: 0;
				left: 0;
				width: 100%;
				height: 100%;
				z-index: -1;
				overflow: hidden;
			}
			.aurora {
				position: relative;
				width: 100%;
				height: 100%;
				filter: blur(150px);
				opacity: 0.5;
			}
			.aurora-shape1 {
				position: absolute;
				width: 50vw;
				height: 50vh;
				background: radial-gradient(circle, var(--accent-cyan), transparent 60%);
				top: 5%;
				left: 5%;
			}
			.aurora-shape2 {
				position: absolute;
				width: 40vw;
				height: 40vh;
				background: radial-gradient(circle, var(--accent-purple), transparent 60%);
				bottom: 10%;
				right: 10%;
			}
			.container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				text-align: center;
				width: 90%;
				max-width: 480px;
				position: relative;
				z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				color: var(--text-primary);
				margin-bottom: 20px;
				font-size: 2em;
			}
			p {
				color: var(--text-secondary);
				margin-bottom: 30px;
				font-size: 1.08em;
			}
			.button-row {
				display: flex;
				flex-wrap: wrap;
				justify-content: center;
				gap: 15px;
				margin-bottom: 26px;
			}
			button {
				background-color: var(--accent-blue);
				color: white;
				border: none;
				border-radius: 8px;
				padding: 12px 25px;
				font-size: 1.1em;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0,0,0,0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0,0,0,0.3);
			}
			#status {
				font-size: 1.2em;
				color: var(--accent-cyan);
				min-height: 25px;
				margin-top: 20px;
			}
			@media (max-width: 600px) {
				.container {
					padding: 20px;
				}
				h1 {
					font-size: 1.5em;
				}
				button {
					width: 100%;
				}
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="container">
			<h1><i class="fa-solid fa-unlink"></i> Webview Unbind Example</h1>
			<p>
				Click the first button. You should see a message in the console.<br>
				Then, click the second button to unbind the function.<br>
				After that, clicking the first button should do nothing.
			</p>
			<div class="button-row">
				<button onclick="callBoundFunction()">Call Bound Function</button>
				<button onclick="callUnbindFunction()">Unbind Function</button>
			</div>
			<div id="status"></div>

			<script>
				async function callBoundFunction() {
					try {
						await window.myBoundFunction();
						document.getElementById('status').textContent = "Called 'myBoundFunction' successfully.";
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
		</div>
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