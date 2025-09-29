# This example demonstrates how to use the `inject()`, `eval()`, and `bind()` (callback) functions
# of the Ring WebView library to interact between Ring code and JavaScript running in the webview.

load "webview.ring"
load "simplejson.ring"

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
			--accent-green: #4ade80;
			--accent-yellow: #facc15;
			--accent-red: #f87171;
			--output-bg: rgba(255, 255, 255, 0.05);
		}

		body {
			font-family: "Inter", sans-serif;
			background-color: var(--bg-color);
			color: var(--text-primary);
			margin: 0;
			height: 100vh;
			overflow: auto;
			display: flex;
			flex-direction: column;
			justify-content: flex-start;
			align-items: center;
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

		.main-card {
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			border-radius: 15px;
			padding: 30px;
			max-width: 800px;
			width: 90%;
			box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			position: relative;
			z-index: 1;
			margin: 20px 0;
		}

		h1 {
			color: var(--text-primary);
			margin-bottom: 25px;
			font-size: 2.2em;
			text-align: center;
			text-shadow: 1px 1px 3px rgba(0, 0, 0, 0.2);
		}

		.section {
			background-color: rgba(255, 255, 255, 0.03);
			padding: 20px;
			border-radius: 12px;
			margin-bottom: 25px;
			border: 1px solid var(--border-color);
		}

		.section h2 {
			margin-top: 0;
			color: var(--text-primary);
			font-size: 1.4em;
			border-bottom: 1px solid var(--border-color);
			padding-bottom: 12px;
			margin-bottom: 18px;
		}

		.input-group {
			display: flex;
			flex-wrap: wrap;
			gap: 12px;
			margin-bottom: 15px;
			align-items: center;
		}

		.input-group label {
			flex-shrink: 0;
			font-weight: 500;
			color: var(--text-secondary);
			min-width: 100px;
		}

		.input-group input[type="text"] {
			flex-grow: 1;
			padding: 12px 15px;
			border-radius: 8px;
			border: 1px solid var(--border-color);
			background-color: rgba(255, 255, 255, 0.05);
			color: var(--text-primary);
			font-size: 1em;
			min-width: 200px;
			transition: border-color 0.2s ease;
		}

		.input-group input:focus {
			outline: none;
			border-color: var(--accent-cyan);
		}

		.input-group button {
			background-color: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 8px;
			padding: 12px 20px;
			font-size: 1em;
			font-weight: 500;
			cursor: pointer;
			transition: all 0.2s ease-in-out;
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
		}

		.input-group button:hover {
			transform: translateY(-2px);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			background-color: #2563eb;
		}

		.output {
			background-color: var(--output-bg);
			border: 1px solid var(--border-color);
			padding: 15px;
			border-radius: 8px;
			min-height: 50px;
			white-space: pre-wrap;
			word-break: break-all;
			font-family: "Fira Code", monospace;
			font-size: 0.9em;
			color: var(--text-secondary);
			margin-top: 15px;
		}

		.output.error {
			color: var(--accent-red);
			border-color: rgba(248, 113, 113, 0.3);
		}

		.note {
			font-size: 0.85em;
			color: var(--text-secondary);
			margin-top: 10px;
			font-style: italic;
		}
	</style>
</head>

<body>
	<div class="background-container">
		<div class="aurora">
			<div class="aurora-shape1"></div>
			<div class="aurora-shape2"></div>
		</div>
	</div>

	<div class="main-card">
		<h1><i class="fa-solid fa-code"></i> Ring WebView Inject, Eval, Callback Demo</h1>

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
				<input type="text" id="initInput"
					value="window.myInjectedVar = `Injected!`; console.log(`Init JS executed!`);">
				<button onclick="initJs()">Initialize JS</button>
			</div>
			<div id="initOutput" class="output"></div>
			<div class="note">Executes JS code before page load. Works best on initial load or after setHtml.</div>
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
				updateOutput("evalOutput", "JavaScript evaluated.");
			} catch (e) {
				updateOutput("evalOutput", "Error evaluating JS: " + e, true);
			}
		}

		async function initJs() {
			const jsInitCode = document.getElementById("initInput").value;
			try {
				await window.ring_initJs(jsInitCode);
				updateOutput("initOutput", "JS init code sent. It will execute when the next page loads or when setHtml is called.");
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

	see "Demo finished. Program exiting." + nl

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles calls from JavaScript's `window.ring_echo()`.
func handle_echo(id, req)
	cMessage = json_decode(req)[1] # Extract the message from the JSON request.
	see "Ring: `handle_echo` received message: '" + cMessage + "'" + nl
	# Return a success status and an echoed message back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Echo: ' + cMessage + '"')

# Handles calls from JavaScript's `window.ring_evalJs()`.
func handle_evalJs(id, req)
	cJsCode = json_decode(req)[1] # Extract the JavaScript code string.
	see "Ring: `handle_evalJs` executing JavaScript: '" + cJsCode + "'" + nl
	oWebView.evalJS(cJsCode) # Execute the JavaScript code in the webview.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles calls from JavaScript's `window.ring_initJs()`.
func handle_initJs(id, req)
	cJsInitCode = json_decode(req)[1] # Extract the JavaScript initialization code.
	see "Ring: `handle_initJs` injecting JavaScript for initialization: '" + cJsInitCode + "'" + nl
	oWebView.injectJS(cJsInitCode) # Inject the JavaScript code into the webview.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.