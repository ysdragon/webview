# Showcase Example
# This example demonstrates the usage of the WebView functions for creating interactive UI
# with JavaScript communication, DOM manipulation, and main thread dispatching

load "webview.ring"
load "jsonlib.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main()
	# Create a new webview instance using the procedural API.
	# The '1' enables debug mode, NULL means create a new window.
	oWebView = new Webview(1, NULL)

	# Set the title of the webview window.
	oWebView.setTitle("Ring WebView Example")
	# Set the size of the webview window. WEBVIEW_HINT_NONE means no size constraint.
	oWebView.setSize(500, 400, WEBVIEW_HINT_NONE)

	# Bind Ring functions to be callable from JavaScript.
	# `greet` will be called when JS invokes `window.greet()`.
	# `changeColor` will be called when JS invokes `window.changeColor()`.
	# `scheduleDispatch` will be called when JS invokes `window.scheduleDispatch()`.
	oWebView.bind("greet", :greet)
	oWebView.bind("changeColor", :changeColor)
	oWebView.bind("scheduleDispatch", :schedule_dispatch_task)

	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring WebView</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- Font Awesome for icons -->
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap');
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
				position: fixed; top: 0; left: 0; width: 100%; height: 100%;
				z-index: -1; overflow: hidden;
			}
			.aurora {
				position: relative; width: 100%; height: 100%;
				filter: blur(150px); opacity: 0.5;
			}
			.aurora-shape1 {
				position: absolute; width: 50vw; height: 50vh;
				background: radial-gradient(circle, var(--accent-cyan), transparent 60%);
				top: 5%; left: 5%;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				background: radial-gradient(circle, var(--accent-purple), transparent 60%);
				bottom: 10%; right: 10%;
			}
			
			.main-card {
				background-color: var(--panel-bg);
				border: 1px solid var(--border-color);
				border-radius: 15px;
				padding: 30px;
				text-align: center;
				max-width: 500px;
				width: 90%;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative; z-index: 1;
			}
			h1 {
				color: var(--text-primary);
				margin-bottom: 15px;
				font-size: 2.2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			p {
				color: var(--text-secondary);
				margin-bottom: 25px;
				font-size: 1.1em;
			}
			input {
				padding: 12px 15px;
				border-radius: 8px;
				border: 1px solid var(--border-color);
				background-color: rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
				font-size: 1em;
				width: calc(100% - 30px);
				margin-bottom: 20px;
				box-sizing: border-box;
				transition: border-color 0.2s ease;
			}
			input:focus {
				outline: none;
				border-color: var(--accent-cyan);
			}
			button {
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
				margin: 0 8px 10px 8px;
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			#response {
				margin-top: 20px;
				font-style: italic;
				color: var(--text-secondary);
				font-size: 0.95em;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="main-card">
			<h1 id="greeting"><i class="fa-solid fa-hand-sparkles"></i> Hello from Ring!</h1>
			<p>This content is running inside a native webview window.</p>

			<input type="text" id="nameInput" placeholder="Enter your name">
			<button onclick="callGreet()"><i class="fa-solid fa-face-smile"></i> Greet Me</button>
			<button onclick="callChangeColor()"><i class="fa-solid fa-palette"></i> Change Title Color</button>
			<button onclick="callDispatch()"><i class="fa-solid fa-paper-plane"></i> Schedule Dispatch</button>

			<p id="response"></p>
		</div>

		<script>
			async function callGreet() {
				const name = document.getElementById('nameInput').value || 'World';
				try {
					const res = await window.greet(name);
					document.getElementById('response').innerText = res;
				} catch (e) {
					console.error(e);
					document.getElementById('response').innerText = 'Error: ' + e;
				}
			}

			async function callChangeColor() {
				const res = await window.changeColor();
				console.log(res);
			}

			async function callDispatch() {
				await window.scheduleDispatch();
				console.log("Dispatch call has been scheduled from JS.");
			}
		</script>
	</body>
	</html>
	`

	# Load the HTML content into the webview.
	oWebView.setHtml(cHTML)

	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	# Destroy the webview instance.
	oWebView.destroy()

	see "WebView closed. Program finished." + nl

# This function is called by JavaScript via `window.greet()`.
# It receives an ID for returning a value and a request object (JSON string).
func greet(id, req)
	see "Ring function 'greet' called from JavaScript!" + nl
	see "  Binding ID: " + id + nl
	cName = json2list(req)[1][1] # Extract the name from the request.

	cResponse = "Hello, " + cName + "! Greetings from the Ring language."
	cResultJson = list2json([cResponse]) # Prepare the response as a JSON string.

	# Return the result to JavaScript. Status 0 indicates success.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cResultJson)

# This function is called by JavaScript via `window.changeColor()`.
# It uses `webview_eval()` to execute JavaScript that manipulates the DOM.
func changeColor(id, req)
	see "Ring function 'changeColor' called." + nl
	# Generate a random color and construct JavaScript code to change the H1 element's color.
	cJsCode = "document.getElementById('greeting').style.color = '" + generatePalette() + "';"
	oWebView.evalJS(cJsCode) # Execute the JavaScript code in the webview.

	# Acknowledge the call by returning a success message to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Color changed successfully!"')

# This function is a task that will be dispatched to run on the main UI thread.
func dispatched_task()
	see "This message is from a dispatched task running on the main UI thread." + nl
	# Execute an alert in the webview.
	oWebView.evalJS("alert('This is a dispatched message!');")

# This function is called by JavaScript via `window.scheduleDispatch()`.
# It schedules `dispatched_task()` to run on the main UI thread.
func schedule_dispatch_task(id, req)
	see "Scheduling a dispatched call..." + nl
	# `webview_dispatch` is crucial for safely running code on the main UI thread,
	# especially in multi-threaded applications.
	oWebView.dispatch("dispatched_task()")
	# Return an empty string (undefined in JS) to acknowledge the call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')

# --- Helper Function ---

# Generates a random RGB hex color code.
func generatePalette()
	cHex = "#"
	for x = 1 to 3
		nVal = random(255)
		cHex += right("0" + hex(nVal), 2)
	next
	return cHex