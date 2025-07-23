# Random Quote Generator
# This example fetches and displays a random quote from an external API.

load "webview.ring"
load "jsonlib.ring"
load "internetlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL
# API endpoint for fetching random quotes.
cQuoteAPI = "https://thequoteshub.com/api/random-quote?format=json"

# ==================================================
# Main Application Flow
# ==================================================

func main()
	see "Setting up Quote Generator Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring Random Quote Generator")
	# Set the window size (no size constraint).
	oWebView.setSize(600, 600, WEBVIEW_HINT_NONE)

	# Bind the `fetchQuote` function to be callable from JavaScript.
	# This function will fetch a new quote from the external API.
	oWebView.bind("fetchQuote", :handleFetchQuote)

	# Load the HTML content for the quote generator UI.
	loadQuoteHTML()

	see "Running the WebView main loop. Click 'New Quote' to fetch quotes." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Defines the HTML structure and inline JavaScript for the random quote generator.
func loadQuoteHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Random Quote</title>
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

			.quote-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 500px;
				min-height: 250px;
				display: flex;
				flex-direction: column;
				justify-content: space-between;
				align-items: center;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				text-align: center;
				color: var(--accent-yellow);
				margin-bottom: 25px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			#quote-text {
				font-family: 'Inter', sans-serif;
				font-size: 1.4em;
				font-style: italic;
				text-align: center;
				margin-bottom: 20px;
				color: var(--text-primary);
			}
			#quote-author {
				font-family: 'Fira Code', monospace;
				font-size: 1em;
				text-align: center;
				color: var(--text-secondary);
				margin-bottom: 30px;
			}
			button {
				padding: 12px 25px;
				border: none;
				border-radius: 8px;
				background-color: var(--accent-blue);
				color: white;
				font-size: 1em;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="quote-container">
			<h1><i class="fa-solid fa-quote-right"></i> Random Quote</h1>
			<div id="quote-text">Loading quote...</div>
			<div id="quote-author">- Unknown</div>
			<button onclick="getNewQuote()"><i class="fa-solid fa-arrows-rotate"></i> New Quote</button>
		</div>

		<script>
			const quoteText = document.getElementById('quote-text');
			const quoteAuthor = document.getElementById('quote-author');

			async function getNewQuote() {
				quoteText.textContent = 'Loading quote...';
				quoteAuthor.textContent = '- Unknown';
				try {
					const data = await window.fetchQuote();
					if (data.quote && data.author) {
						quoteText.textContent = data.quote;
						quoteAuthor.textContent = '- ' + data.author;
					} else {
						quoteText.textContent = 'Failed to load quote.';
						quoteAuthor.textContent = '';
					}
				} catch (e) {
					console.error("Error fetching quote:", e);
					quoteText.textContent = 'Error fetching quote.';
					quoteAuthor.textContent = '';
				}
			}

			window.onload = getNewQuote;
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handler (Bound to JavaScript) ---

# Handles requests from JavaScript to fetch a new random quote.
func handleFetchQuote(id, req)
	see "Ring: JavaScript requested a new quote." + nl
	
	cResponse = ""
	bError = false
	cErrorMessage = ""

	try
		cResponse = download(cQuoteAPI) # Fetch data from the external quote API.
		aJson = json2list(cResponse) # Parse the JSON response.
		# Check if the expected 'text' and 'author' fields exist in the response.
		if isList(aJson) and aJson["text"] and aJson["author"]
			# Structure the result as a list (array) for JSON conversion.
			aResult = [
				:quote = aJson["text"],
				:author = aJson["author"]
			]
			cJsonResult = list2json(aResult) # Convert to JSON string.
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResult) # Return success with the quote data.
		else
			bError = true
			cErrorMessage = "Invalid API response format. Expected 'text' and 'author' fields."
		ok
	catch
		bError = true
		cErrorMessage = "Network Error: " + ccatcherror # Capture network errors.
		see "Error fetching quote: " + cErrorMessage + nl
	end
		
	if bError
		# If an error occurred (either network or invalid format), return an error message.
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json([:error = cErrorMessage]))
	ok