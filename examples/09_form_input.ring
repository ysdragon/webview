# Simple Form Input Example

load "webview.ring"
load "jsonlib.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main()
	see "Setting up Form Input App..." + nl
	oWebView = new WebView()

	oWebView.setTitle("Ring Form Input")
	oWebView.setSize(500, 400, WEBVIEW_HINT_NONE)

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
		<meta charset="UTF-8">
		<style>
			body {
				font-family: sans-serif;
				margin: 0;
				height: 100vh;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				background-color: #e6e6fa; /* Light Purple */
				color: #333;
			}
			.form-container {
				background-color: #ffffff;
				padding: 30px;
				border-radius: 12px;
				box-shadow: 0 4px 15px rgba(0,0,0,0.1);
				text-align: center;
				width: 80%;
				max-width: 400px;
			}
			h1 {
				color: #6a5acd; /* Slate Blue */
				margin-bottom: 25px;
			}
			.input-group {
				margin-bottom: 20px;
			}
			label {
				display: block;
				margin-bottom: 8px;
				font-weight: bold;
				color: #483d8b; /* Dark Slate Blue */
			}
			input[type="text"] {
				width: calc(100% - 20px);
				padding: 10px;
				border: 1px solid #ccc;
				border-radius: 5px;
				font-size: 1em;
			}
			button {
				padding: 12px 25px;
				font-size: 1.1em;
				border: none;
				border-radius: 8px;
				cursor: pointer;
				background-color: #8a2be2; /* Blue Violet */
				color: white;
				transition: background-color 0.2s;
			}
			button:hover {
				background-color: #6a0dad; /* Darker Blue Violet */
			}
			#response {
				margin-top: 20px;
				color: #32cd32; /* Lime Green */
				font-weight: bold;
			}
		</style>
	</head>
	<body>
		<div class="form-container">
			<h1>Enter Your Name</h1>
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
					responseEl.style.color = "red";
					return;
				}
				
				try {
					responseEl.textContent = "Sending to Ring...";
					responseEl.style.color = "#333";
					// Call the Ring function 'processInput' with the name
					const ringResponse = await window.processInput(name);
					responseEl.textContent = ringResponse;
					responseEl.style.color = "#32cd32";
				} catch (e) {
					console.error("Error calling Ring function:", e);
					responseEl.textContent = "Error communicating with Ring backend.";
					responseEl.style.color = "red";
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
	cName = json2list(req)[1][1] # Extract the name from the request.
	see "Ring: Received name from JavaScript: '" + cName + "'" + nl
	
	cResponse = "Hello, " + cName + "! Your name was processed by Ring."
	# Return the response as a JSON string back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + cResponse + '"')