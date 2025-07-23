# Basic WebView Example in Ring

load "webview.ring"

# Create a new WebView instance.
oWebView = new WebView()

oWebView {
	# Set the title of the webview window.
	setTitle("Basic Webview Example")
	# Set the size of the webview window (width, height, hint).
	# WEBVIEW_HINT_NONE means no size constraint.
	setSize(500, 300, WEBVIEW_HINT_NONE)
	# Set the HTML content for the webview.
	setHtml(`
		<!DOCTYPE html>
		<html lang="en">
		<head>
		    <meta charset="UTF-8">
		    <meta name="viewport" content="width=device-width, initial-scale=1.0">
		    <title>Ring WebView</title>
		    <style>
		        body {
		            font-family: Arial, sans-serif;
		            text-align: center;
		            padding: 50px;
		            margin: 0;
		            background-color: #f4f4f9;
		            color: #333;
		        }
		        h1 {
		            font-size: 2em;
		            margin-bottom: 20px;
		        }
		        p {
		            font-size: 1.2em;
		            margin-bottom: 30px;
		        }
		        button {
		            font-size: 16px;
		            padding: 10px 20px;
		            cursor: pointer;
		            border: none;
		            border-radius: 5px;
		            background-color: #007BFF;
		            color: white;
		            transition: background-color 0.3s ease;
		        }
		        button:hover {
		            background-color: #0056b3;
		        }
		    </style>
		</head>
		<body>
		    <header>
		        <h1>Hello from Ring!</h1>
		    </header>
		    <main>
		        <p>This is a basic webview example.</p>
		        <button onclick="alert('Button clicked!')">Click Me</button>
		    </main>
		</body>
		</html>
	`)

	# Run the webview event loop.
	# This is a blocking call that keeps the window open until it's closed by the user.
	run()
}

see "Webview closed." + nl
