# Basic WebView Example in Ring

load "webview.ring"

# Create a new WebView instance.
oWebView = new WebView()

oWebView {
	# Set the title of the webview window.
	setTitle("Basic Webview Example")
	# Set the size of the webview window (width, height, hint).
	# WEBVIEW_HINT_NONE means no size constraint.
	setSize(550, 300, WEBVIEW_HINT_NONE)
	# Set the HTML content for the webview.
	setHtml(`
		<!DOCTYPE html>
		<html lang="en">
		<head>
		    <title>Ring WebView</title>
		    <meta charset="UTF-8">
		    <meta name="viewport" content="width=500, initial-scale=1">
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
		  <h1><i class="fa-solid fa-desktop"></i> Basic Webview Example</h1>
		  <p>This is a basic webview example.</p>
		  <div class="button-row">
		   <button onclick="alert('Button clicked!')">Click Me</button>
		  </div>
		  <div id="response"></div>
		</body>
		</html>
	`)

	# Run the webview event loop.
	# This is a blocking call that keeps the window open until it's closed by the user.
	run()
}

see "Webview closed." + nl
