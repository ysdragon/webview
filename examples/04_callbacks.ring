# This example demonstrates how to use Ring's WebView to create a simple web application
# that can communicate with JavaScript using callbacks.

load "webview.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

# List of bindings for the webview instance (optional global list loaded by default).
aBindList = [
	["myRingFunc3", :myRingCallback2],
]

func main
	oWebView = new WebView()

	# Create an instance myClass for binding.
	# This instance will be used to demonstrate object method binding.
	oMyObject = new myClass

	oWebView {
		setTitle("Ring Webview - Callback Example")
		setSize(800, 650, WEBVIEW_HINT_NONE)

		# Bind a Ring function to handle JavaScript calls.
		# `bind` registers a Ring function (`myRingFunc` in JS) that can be invoked from JavaScript.
		# The Ring function receives `id` (callback ID for `wreturn`) and `req` (request data from JS).
		# This example uses an anonymous function for the callback.
		bind("myRingFunc", func (id, req) {
				see "Called from JavaScript! Callback ID: " + id + ", Request Data: " + req + nl
				# Send a response back to JavaScript using `wreturn`.
				oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back from Ring anonymous function!"')
			}
		)

		bind("myRingFunc2", :myRingCallback)

		# Bind methods from the myClass instance.
		# The first parameter is the object instance, the second is a list of [jsName, ringMethodName] pairs.
		bind(oMyObject, [
			["myRingObjectMethod", :myMethod]
		])

		html = `
				<!DOCTYPE html>
				<html>
				<head>
					<title>Ring WebView Callback Demo</title>
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
						<h1><i class="fa-solid fa-code"></i> Ring WebView Callback Demo</h1>
						<p>
							Interact with the Ring backend using JavaScript callbacks.<br>
							Choose a function to call:
						</p>
						<div class="button-row">
							<button onclick="callRingAnon()">Call Anonymous Function</button>
							<button onclick="callRingNormal()">Call Normal Function</button>
							<button onclick="callRingFunc3()">Call Function from aBindList</button>
							<button onclick="callRingObjectMethod()">Call Object Method</button>
						</div>
						<div id="response"></div>
					</div>
					<script>
						function callRingAnon() {
							myRingFunc('Sent from JS (anonymous)').then(res => {
								showResponse(res);
							});
						}
						function callRingNormal() {
							myRingFunc2('Sent from JS (normal)').then(res => {
								showResponse(res);
							});
						}
						function callRingFunc3() {
							myRingFunc3('Sent from JS (Using the global aBindList)').then(res => {
								showResponse(res);
							});
						}
						function callRingObjectMethod() {
							myRingObjectMethod('Sent from JS (object method)').then(res => {
								showResponse(res);
							});
						}
						function showResponse(msg) {
							document.getElementById('response').innerText = 'Ring says: ' + msg;
						}
					</script>
				</body>
				</html>
			`
		setHtml(html)

		run()
	}

# A regular Ring function to be bound and called from JavaScript.
func myRingCallback(id, req)
	see "Called from JavaScript! Callback ID: " + id + ", Request Data: " + req + nl
	# Send a response back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back from Ring normal function!"')

# A regular Ring function to be bound and called from JavaScript.
func myRingCallback2(id, req)
	see "Called from JavaScript! Callback ID: " + id + ", Request Data: " + req + nl
	# Send a response back to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back Ring aBindList"')

# A class to demonstrate object method binding.
Class myClass
	func myMethod(id, req)
		see "Called from JavaScript on an object! Callback ID: " + id + ", Request Data: " + req + nl
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back from Ring object method!"')