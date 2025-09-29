# Synchronized Counter Example
# This example demonstrates how to create a synchronized counter application using Ring and WebView.

load "webview.ring"

# Global variables
oWebView = NULL
nCount = 0
aBindList = [
	["incrementFromRingInternal", :incrementFromRingInternal],
	["decrementFromRingInternal", :decrementFromRingInternal]
]

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the title of the webview window.
	oWebView.setTitle("Ring Counter Sync")
	# Set the size of the webview window. WEBVIEW_HINT_NONE means no size constraint.
	oWebView.setSize(400, 450, WEBVIEW_HINT_NONE)

	# Bind Ring functions to be callable from JavaScript.
	# These functions update the global `nCount` and then synchronize the UI.
	oWebView.bind("incrementFromJS", func (id, req) {
		see "Ring: JavaScript requested increment." + nl
		nCount++
		updateUICounter() # Update the UI after changing count.
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the JS call.
	})
	oWebView.bind("decrementFromJS", func (id, req) {
		see "Ring: JavaScript requested decrement." + nl
		nCount--
		updateUICounter() # Update the UI after changing count.
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the JS call.
	})
	oWebView.bind("getInitialCount", func (id, req) {
		see "Ring: JavaScript requested initial count." + nl
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, string(nCount)) # Return the current count as a string.
	})

	# Load the HTML content for the counter UI.
	loadCounterHTML()

	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Function to load the HTML content.
func loadCounterHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Counter</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<style>
			:root {
				--bg-color: #000000;
				--panel-bg: rgba(30, 30, 32, 0.6);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
				--text-secondary: #a1a1aa;
				--accent-blue: #3b82f6;
				--accent-green: #4ade80;
				--accent-red: #f87171;
			}
			body {
				font-family: 'Inter', sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				margin: 0;
				height: 100vh;
				overflow: hidden;
				position: relative;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
			}
			.background-container {
				position: fixed; top: 0; left: 0; width: 100%; height: 100%;
				z-index: -1; overflow: hidden;
			}
			.aurora {
				position: relative; width: 100%; height: 100%;
				filter: blur(150px); opacity: 0.5;
			}
			.aurora-shape1 {
				position: absolute; width: 50vw; height: 50vh;
				background: radial-gradient(circle, var(--accent-blue), transparent 60%);
				top: 5%; left: 5%;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				background: radial-gradient(circle, var(--accent-green), transparent 60%);
				bottom: 10%; right: 10%;
			}
			.counter-container {
				background-color: var(--panel-bg);
				padding: 40px 32px;
				border-radius: 18px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 400px;
				display: flex;
				flex-direction: column;
				align-items: center;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative;
				z-index: 1;
			}
			h1 {
				text-align: center;
				color: var(--accent-green);
				margin-bottom: 18px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			#counter-display {
				font-size: 4em;
				font-family: 'Fira Code', monospace;
				font-weight: bold;
				color: var(--accent-blue);
				margin-bottom: 28px;
				text-shadow: 1px 1px 6px rgba(0,0,0,0.2);
			}
			.buttons {
				display: flex;
				gap: 18px;
				margin-bottom: 18px;
			}
			button {
				padding: 14px 28px;
				border: none;
				border-radius: 10px;
				font-size: 1.1em;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				font-family: 'Inter', sans-serif;
				font-weight: 500;
			}
			.inc-btn {
				background-color: var(--accent-green);
				color: white;
			}
			.inc-btn:hover {
				background-color: #22c55e;
				transform: translateY(-2px);
			}
			.dec-btn {
				background-color: var(--accent-red);
				color: white;
			}
			.dec-btn:hover {
				background-color: #dc2626;
				transform: translateY(-2px);
			}
			.ring-btn {
				background-color: var(--accent-blue);
				color: white;
				margin-top: 10px;
			}
			.ring-btn:hover {
				background-color: #2563eb;
				transform: translateY(-2px);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="counter-container">
			<h1><i class="fa-solid fa-hashtag"></i> Ring Counter</h1>
			<div id="counter-display">0</div>
			<div class="buttons">
				<button class="dec-btn" onclick="decrement()"><i class="fa-solid fa-minus"></i> Decrement (JS)</button>
				<button class="inc-btn" onclick="increment()"><i class="fa-solid fa-plus"></i> Increment (JS)</button>
			</div>
			<button class="ring-btn" onclick="callRingIncrement()"><i class="fa-solid fa-arrow-up"></i> Increment (Ring)</button>
			<button class="ring-btn" onclick="callRingDecrement()"><i class="fa-solid fa-arrow-down"></i> Decrement (Ring)</button>
		</div>
		<script>
			const counterDisplay = document.getElementById('counter-display');
			function updateCounterUI(value) {
				counterDisplay.textContent = value;
			}
			async function increment() {
				await window.incrementFromJS();
			}
			async function decrement() {
				await window.decrementFromJS();
			}
			function callRingIncrement() {
				console.log("Simulating Ring-side increment...");
				window.incrementFromRingInternal();
			}
			function callRingDecrement() {
				console.log("Simulating Ring-side decrement...");
				window.decrementFromRingInternal();
			}
			window.onload = async () => {
				try {
					const initialCount = await window.getInitialCount();
					updateCounterUI(initialCount);
				} catch (e) {
					console.error("Error getting initial count:", e);
				}
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)


# --- Callbacks from JavaScript (Called from aBindList) ---
func incrementFromRingInternal(id, req)
	see "Ring: Incrementing from internal call." + nl
	nCount++
	updateUICounter() # Update the UI after changing count.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the JS call.

func decrementFromRingInternal(id, req)
	see "Ring: Decrementing from internal call." + nl
	nCount--
	updateUICounter() # Update the UI after changing count.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the JS call.

# --- Helper Function ---

# Updates the counter display in the WebView UI.
# This function is called by Ring to push updates to the JavaScript frontend.
func updateUICounter()
	see "Ring: Pushing UI update for counter: " + nCount + nl
	# Construct JavaScript code to call `updateCounterUI` with the current count.
	cJsCode = "updateCounterUI(" + nCount + ");"
	oWebView.evalJS(cJsCode) # Execute the JavaScript in the webview.