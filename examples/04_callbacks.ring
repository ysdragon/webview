# This example demonstrates how to use Ring's WebView to create a simple web application
# that can communicate with JavaScript using callbacks.

load "webview.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main
	oWebView = new WebView(1, NULL)

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
							background: linear-gradient(120deg, #f8fafc 0%, #e0e7ef 100%);
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
							padding: 32px 40px 40px 40px;
							border-radius: 16px;
							box-shadow: 0 4px 24px rgba(0,0,0,0.08);
							max-width: 420px;
							width: 100%;
						}
						h1 {
							color: #2d3748;
							margin-bottom: 10px;
						}
						p {
							color: #4a5568;
							margin-bottom: 28px;
						}
						.button-row {
							display: flex;
							justify-content: center;
							gap: 16px;
							margin-bottom: 24px;
						}
						button {
							background: #2563eb;
							color: #fff;
							border: none;
							border-radius: 6px;
							font-size: 16px;
							padding: 12px 22px;
							cursor: pointer;
							transition: background 0.2s;
							box-shadow: 0 2px 8px rgba(37,99,235,0.08);
						}
						button:hover {
							background: #1d4ed8;
						}
						#response {
							margin-top: 18px;
							font-size: 18px;
							color: #059669;
							min-height: 24px;
							font-weight: 500;
							transition: color 0.2s;
						}
						@media (max-width: 600px) {
							.container {
								padding: 18px 8px 24px 8px;
							}
							.button-row {
								flex-direction: column;
								gap: 10px;
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