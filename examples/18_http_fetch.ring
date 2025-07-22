# Simple HTTP Fetcher
# This script demonstrates how to make an HTTP GET request from the Ring backend
# and display the fetched response (e.g., JSON data) within the WebView UI.

load "webview.ring"
load "jsonlib.ring"
load "internetlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL

func main()
	see "Setting up HTTP Fetcher Application..." + nl
	# Create a new WebView instance (debug mode enabled).
	oWebView = new WebView(1, NULL)

	# Set the window title.
	oWebView.setTitle("HTTP Fetcher")
	# Set the window size (no size constraint).
	oWebView.setSize(800, 600, WEBVIEW_HINT_NONE)

	# Bind the `fetchURL` function to be callable from JavaScript.
	oWebView.bind("fetchURL", :handleFetchURL)

	# Load the HTML content for the HTTP fetcher UI.
	loadFetchHTML()

	see "Running the WebView main loop. Enter a URL and fetch content." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	see "Cleaning up WebView resources and exiting." + nl
	# Destroy the webview instance.
	oWebView.destroy()

# Defines the HTML structure and inline JavaScript for the HTTP fetcher.
func loadFetchHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring HTTP Fetcher</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
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
				background: radial-gradient(circle, var(--accent-cyan), transparent 60%);
				top: 5%; left: 5%;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				background: radial-gradient(circle, var(--accent-purple), transparent 60%);
				bottom: 10%; right: 10%;
			}

			.fetch-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 700px;
				display: flex;
				flex-direction: column;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				text-align: center;
				color: var(--accent-green);
				margin-bottom: 25px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			.input-group {
				display: flex;
				margin-bottom: 20px;
			}
			input[type="text"] {
				flex-grow: 1;
				padding: 12px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				outline: none;
				background-color: rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
			}
			input[type="text"]:focus {
				border-color: var(--accent-cyan);
			}
			button {
				padding: 12px 20px;
				border: none;
				border-radius: 8px;
				background-color: var(--accent-blue);
				color: white;
				font-size: 1em;
				cursor: pointer;
				margin-left: 10px;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			#response-area {
				flex-grow: 1;
				background-color: rgba(0,0,0,0.1);
				border: 1px solid var(--border-color);
				border-radius: 8px;
				padding: 15px;
				font-family: 'Fira Code', monospace;
				font-size: 0.9em;
				white-space: pre-wrap;
				overflow-y: auto;
				min-height: 200px;
				color: var(--text-primary);
			}
			.error-message {
				color: var(--accent-red);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="fetch-container">
			<h1><i class="fa-solid fa-cloud-arrow-down"></i> Ring HTTP Fetcher</h1>
			<div class="input-group">
				<input type="text" id="urlInput" placeholder="Enter URL (e.g., https://jsonplaceholder.typicode.com/todos/1)" value="https://jsonplaceholder.typicode.com/todos/1">
				<button onclick="fetchContent()"><i class="fa-solid fa-download"></i> Fetch</button>
			</div>
			<pre id="response-area">Enter a URL and click Fetch to see the content.</pre>
		</div>

		<script>
			const urlInput = document.getElementById("urlInput");
			const responseArea = document.getElementById("response-area");

			async function fetchContent() {
				const url = urlInput.value.trim();
				if (!url) {
					responseArea.textContent = "Please enter a URL.";
					responseArea.classList.add("error-message");
					return;
				}

				responseArea.textContent = "Fetching data...";
				responseArea.classList.remove("error-message");

				try {
					const result = await window.fetchURL(url);
					if (result.error) {
						responseArea.textContent = "Error: " + result.error;
						responseArea.classList.add("error-message");
					} else {
						responseArea.textContent = JSON.stringify(result.content, null, 2);
						responseArea.classList.remove("error-message");
					}
				} catch (e) {
					console.error("Error calling Ring function:", e);
					responseArea.textContent = "Fatal Error: Could not communicate with Ring backend.";
					responseArea.classList.add("error-message");
				}
			}

			window.onload = () => {
				fetchContent(); // Fetch initial content on load
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handler (Bound to JavaScript) ---

# Handles requests from JavaScript to fetch content from a given URL.
func handleFetchURL(id, req)
	cURL = json2list(req)[1][1]
	see "Ring: Attempting to fetch URL: " + cURL + nl
	
	cResponse = ""
	bError = false
	cErrorMessage = ""

	try
		cResponse = download(cURL)
	catch
		bError = true
		cErrorMessage = "Network Error: " + cCatchError
		see "Error fetching URL: " + cErrorMessage + nl
	end
		
	aResult = []
	if bError
		aResult[:error] = cErrorMessage
	else
		try
			aResult[:content] = json2list(cResponse)
		catch
			bError = true
			cErrorMessage = "JSON Error: " + cCatchError
			see "Error escaping response: " + cErrorMessage + nl
		end
	ok

	 # Convert the result to a JSON string.
	cJsonResult = list2json(aResult)

	# Return the JSON result to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResult)