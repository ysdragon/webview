# Simple Form Input Example

load "webview.ring"
load "simplejson.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main()
	see "Setting up Form Input App..." + nl
	oWebView = new WebView()

	oWebView.setTitle("Ring Form Input")
	oWebView.setSize(400, 410, WEBVIEW_HINT_NONE)

	# Bind Ring function for JS to call
	oWebView.bind("processInput", :handleProcessInput)

	loadFormHTML()

	see "Running the WebView main loop..." + nl
	oWebView.run()

# Function to load the HTML content.
func loadFormHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Form Input</title>
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
			.input-group {
				margin-bottom: 20px;
			}
			label {
				display: block;
				margin-bottom: 8px;
				font-weight: bold;
				color: var(--text-primary);
			}
			input[type="text"] {
				width: calc(100% - 20px);
				padding: 10px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				background-color: rgba(255, 255, 255, 0.07);
				color: var(--text-primary);
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
			#response {
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
			<h1><i class="fa-solid fa-keyboard"></i> Enter Your Name</h1>
			<p>
				This example demonstrates how to capture user input from a form and send it to the Ring backend.
			</p>
			<div class="input-group">
				<label for="nameInput">Name:</label>
				<input type="text" id="nameInput" placeholder="Type your name here...">
			</div>
			<button onclick="submitName()">Submit</button>
			<p id="response"></p>
		</div>

		<script>
			async function submitName() {
				const name = document.getElementById('nameInput').value;
				const responseEl = document.getElementById('response');
				if (name.trim() === "") {
					responseEl.textContent = "Please enter a name.";
					responseEl.style.color = "var(--accent-red)";
					return;
				}
				
				try {
					responseEl.textContent = "Sending to Ring...";
					responseEl.style.color = "var(--text-secondary)";
					// Call the Ring function 'processInput' with the name
					const ringResponse = await window.processInput(name);
					responseEl.textContent = ringResponse;
					responseEl.style.color = "var(--accent-green)";
				} catch (e) {
					console.error("Error calling Ring function:", e);
					responseEl.textContent = "Error communicating with Ring backend.";
					responseEl.style.color = "var(--accent-red)";
				}
			}
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handler (Bound to JavaScript) ---

# Handles calls from JavaScript's `window.processInput()`.
# It receives an ID for returning a value and a request object (JSON string containing the input).
func handleProcessInput(id, req)
	cName = json_decode(req)[1] # Extract the name from the request.
	see "Ring: Received name from JavaScript: '" + cName + "'" + nl
	
	cResponse = "Hello, " + cName + "! Your name was processed by Ring."
	# Return the response as a JSON string back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + cResponse + '"')