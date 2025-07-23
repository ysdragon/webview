# This example demonstrates how to use the `inject()`, `eval()`, and `bind()` (callback) functions
# of the Ring WebView library to interact between Ring code and JavaScript running in the webview.

load "webview.ring"
load "jsonlib.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main()
	see "--- Ring WebView: Inject, Eval, and Bind/Callback Demo ---" + nl

	# Create a new webview window using the WebView class.
	see "1. Create a new WebView instance..." + nl
	oWebView = new WebView()

	see "   WebView instance successfully created." + nl

	# Set the title of the webview window.
	oWebView.setTitle("Ring WebView: Inject, Eval, Callback Demo")

	# Set the size of the webview window. `get_webview_hint_none()` means no size constraint.
	oWebView.setSize(800, 600, get_webview_hint_none())

	# Bind Ring functions to be callable from JavaScript.
	# When JavaScript calls `window.ring_echo()`, `handle_echo` in Ring will be executed.
	oWebView.bind("ring_echo", :handle_echo)
	oWebView.bind("ring_evalJs", :handle_evalJs)
	oWebView.bind("ring_initJs", :handle_initJs)

	# Define the HTML and inline JavaScript content for the webview.
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring WebView Inject/Eval/Callback Demo</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
		<style>
			body { font-family: sans-serif; margin: 0; padding: 20px; background-color: #f0f2f5; color: #333; }
			.container { max-width: 960px; margin: 0 auto; background-color: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
			h1 { color: #0056b3; text-align: center; margin-bottom: 30px; }
			.section { background-color: #e9ecef; padding: 15px; border-radius: 6px; margin-bottom: 20px; border: 1px solid #dee2e6; }
			.section h2 { margin-top: 0; color: #0056b3; font-size: 1.2em; border-bottom: 1px solid #ced4da; padding-bottom: 8px; margin-bottom: 15px; }
			.input-group { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 10px; align-items: center; }
			.input-group label { flex-shrink: 0; font-weight: bold; }
			.input-group input[type="text"], .input-group input[type="number"], .input-group textarea, .input-group select {
				flex-grow: 1; padding: 8px; border: 1px solid #ced4da; border-radius: 4px; font-size: 0.9em; min-width: 150px;
			}
			.input-group textarea { height: 80px; resize: vertical; }
			.input-group button { padding: 8px 15px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 0.9em; }
			.input-group button:hover { background-color: #0056b3; }
			.output { background-color: #f8f9fa; border: 1px solid #e9ecef; padding: 10px; border-radius: 4px; min-height: 30px; white-space: pre-wrap; word-break: break-all; font-family: monospace; font-size: 0.85em; }
			.output.error { color: red; }
			.note { font-size: 0.8em; color: #6c757d; margin-top: 5px; }
		</style>
	</head>
	<body>
		<div class="container">
			<h1>Ring WebView Inject, Eval, Callback Demo</h1>

			<div class="section">
				<h2><i class="fa-solid fa-handshake"></i> bind() & wreturn() (Callback)</h2>
				<div class="input-group">
					<label for="boundFuncInput">Message:</label>
					<input type="text" id="boundFuncInput" value="Hello from JS!">
					<button onclick="callBoundFunc()">Call Bound Function (ring_echo)</button>
				</div>
				<div id="boundFuncOutput" class="output"></div>
				<div class="note">This calls Ring function "ring_echo" with the message and expects a return.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-terminal"></i> eval()</h2>
				<div class="input-group">
					<label for="evalInput">JS Code:</label>
					<input type="text" id="evalInput" value="alert(`Evaluated from Ring!`);">
					<button onclick="evalJs()">Evaluate JS</button>
				</div>
				<div id="evalOutput" class="output"></div>
				<div class="note">This demonstrates Ring calling JS code.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-code-compare"></i> inject()</h2>
				<div class="input-group">
					<label for="initInput">JS Init Code:</label>
					<input type="text" id="initInput" value="window.myInjectedVar = `Injected!`; console.log(`Init JS executed!`);">
					<button onclick="initJs()">Initialize JS</button>
				</div>
				<div id="initOutput" class="output"></div>
				<div class="note">Executes JS code before page load. Works best on initial load or after set_html.</div>
			</div>

		</div>

		<script>
			function updateOutput(elementId, message, isError = false) {
				const outputDiv = document.getElementById(elementId);
				outputDiv.textContent = message;
				if (isError) {
					outputDiv.classList.add("error");
				} else {
					outputDiv.classList.remove("error");
				}
			}

			async function callBoundFunc() {
				const message = document.getElementById("boundFuncInput").value;
				try {
					const response = await window.ring_echo(message);
					updateOutput("boundFuncOutput", "Ring Response: " + response);
				} catch (e) {
					updateOutput("boundFuncOutput", "Error calling bound function (ring_echo): " + e, true);
				}
			}

			async function evalJs() {
				const jsCode = document.getElementById("evalInput").value;
				try {
					await window.ring_evalJs(jsCode);
					updateOutput("evalOutput", "JavaScript evaluated. Check browser console or alert for effects.");
				} catch (e) {
					updateOutput("evalOutput", "Error evaluating JS: " + e, true);
				}
			}

			async function initJs() {
				const jsInitCode = document.getElementById("initInput").value;
				try {
					await window.ring_initJs(jsInitCode);
					updateOutput("initOutput", "JS init code sent. It will execute when the next page loads or when set_html is called.");
				} catch (e) {
					updateOutput("initOutput", "Error initializing JS: " + e, true);
				}
			}
		</script>
	</body>
	</html>
	'
	# Load the defined HTML content into the webview.
	see "2. Loading custom HTML content into the webview..." + nl
	oWebView.setHtml(cHTML)
	see "   HTML content loaded." + nl

	# Run the webview's main event loop. This call is blocking and keeps the window open
	# until the user closes it.
	see "3. Running webview main loop. Interact with the GUI to test functionalities." + nl
	oWebView.run()

	# Clean up and destroy the webview instance.
	see "4. Destroying webview instance and cleaning up resources..." + nl
	oWebView.destroy()
	see "   Webview instance destroyed." + nl

	see "Demo finished. Program exiting." + nl

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles calls from JavaScript's `window.ring_echo()`.
func handle_echo(id, req)
	cMessage = json2list(req)[1][1] # Extract the message from the JSON request.
	see "Ring: `handle_echo` received message: '" + cMessage + "'" + nl
	# Return a success status and an echoed message back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Echo: ' + cMessage + '"')

# Handles calls from JavaScript's `window.ring_evalJs()`.
func handle_evalJs(id, req)
	cJsCode = json2list(req)[1][1] # Extract the JavaScript code string.
	see "Ring: `handle_evalJs` executing JavaScript: '" + cJsCode + "'" + nl
	oWebView.evalJS(cJsCode) # Execute the JavaScript code in the webview.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles calls from JavaScript's `window.ring_initJs()`.
func handle_initJs(id, req)
	cJsInitCode = json2list(req)[1][1] # Extract the JavaScript initialization code.
	see "Ring: `handle_initJs` injecting JavaScript for initialization: '" + cJsInitCode + "'" + nl
	oWebView.injectJS(cJsInitCode) # Inject the JavaScript code into the webview.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.