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

		html = `
				<!DOCTYPE html>
				<html>
				<head>
					<title>Ring WebView Callback Demo</title>
					<meta name="viewport" content="width=500, initial-scale=1">
					<style>
						body {
							font-family: 'Segoe UI', Arial, sans-serif;
							background: linear-gradient(120deg, #f0f4f8 0%, #dbeafe 100%);
							margin: 0;
							padding: 0;
							display: flex;
							flex-direction: column;
							align-items: center;
							min-height: 100vh;
						}
						.container {
							background: #fff;
							margin-top: 60px;
							padding: 36px 44px 44px 44px;
							border-radius: 20px;
							box-shadow: 0 6px 32px rgba(0,0,0,0.10);
							max-width: 440px;
							width: 100%;
							transition: box-shadow 0.2s;
						}
						.container:hover {
							box-shadow: 0 10px 40px rgba(37,99,235,0.13);
						}
						h1 {
							color: #1e293b;
							margin-bottom: 12px;
							font-size: 2.1em;
							letter-spacing: 0.5px;
						}
						p {
							color: #475569;
							margin-bottom: 30px;
							font-size: 1.08em;
						}
						.button-row {
							display: flex;
							justify-content: center;
							gap: 18px;
							margin-bottom: 26px;
						}
						button {
							background: linear-gradient(90deg, #2563eb 60%, #38bdf8 100%);
							color: #fff;
							border: none;
							border-radius: 8px;
							font-size: 17px;
							padding: 13px 26px;
							cursor: pointer;
							transition: background 0.18s, transform 0.13s;
							box-shadow: 0 2px 10px rgba(37,99,235,0.10);
							font-weight: 500;
							outline: none;
						}
						button:hover, button:focus {
							background: linear-gradient(90deg, #1d4ed8 60%, #0ea5e9 100%);
							transform: translateY(-2px) scale(1.04);
						}
						#response {
							margin-top: 20px;
							font-size: 19px;
							color: #059669;
							min-height: 26px;
							font-weight: 600;
							transition: color 0.2s;
							word-break: break-word;
						}
						@media (max-width: 600px) {
							.container {
								padding: 20px 8px 26px 8px;
							}
							.button-row {
								flex-direction: column;
								gap: 12px;
							}
							h1 {
								font-size: 1.3em;
							}
						}
					</style>
				</head>
				<body>
					<div class="container">
						<h1>Ring WebView Callback Demo</h1>
						<p>
							Interact with the Ring backend using JavaScript callbacks.<br>
							Choose a function to call:
						</p>
						<div class="button-row">
							<button onclick="callRingAnon()">Call Anonymous Function</button>
							<button onclick="callRingNormal()">Call Normal Function</button>
							<button onclick="callRingFunc3()">Call Function with Default Bindings (aBindList)</button>
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
							myRingFunc3('Sent from JS (Using the default aBindList)').then(res => {
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