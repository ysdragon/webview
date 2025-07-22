# QR Code Generator
# This example demonstrates generating QR codes within the WebView using a JavaScript library.
# The Ring backend captures user input and passes the text to the WebView for QR code generation.

load "webview.ring"
load "jsonlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL

func main()
	see "Setting up QR Code Generator Application..." + nl
	# Create a new WebView instance (debug mode enabled).
	oWebView = new WebView(1, NULL)

	# Set the window title.
	oWebView.setTitle("QR Code Generator")
	# Set the window size (no size constraint).
	oWebView.setSize(450, 550, WEBVIEW_HINT_NONE)

	# Bind the `generateQrCode` function to be callable from JavaScript.
	# This function receives the text from the JS frontend and instructs the webview to generate the QR.
	oWebView.bind("generateQrCode", func(id, req) {
			cText = json2list(req)[1][1] # Extract the text to encode from the request.
			see "Ring: JavaScript requested QR code for text: '" + cText + "'" + nl
	
			# Execute JavaScript in the webview to call its `updateQrCode` function
			# with the text provided by the user.
			cJsCode = `updateQrCode("` + cText + `");`
			oWebView.evalJS(cJsCode)
				
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.
		})

	# Load the HTML content for the QR code generator UI.
	loadQRCodeHTML()

	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	# Destroy the webview instance.
	oWebView.destroy()

# Defines the HTML structure and inline JavaScript for the QR code generator.
func loadQRCodeHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>QR Code Generator</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- QR Code Library from CDN -->
		<script src="https://cdn.jsdelivr.net/npm/davidshimjs-qrcodejs@0.0.2/qrcode.min.js"></script>
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

			.qr-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				text-align: center;
				width: 90%;
				max-width: 400px;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				color: var(--accent-green);
				margin-bottom: 25px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			input[type="text"] {
				width: calc(100% - 24px);
				padding: 12px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				margin-bottom: 20px;
				outline: none;
				background-color: rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
			}
			input[type="text"]:focus {
				border-color: var(--accent-cyan);
			}
			button {
				padding: 12px 25px;
				font-size: 1.1em;
				border: none;
				border-radius: 8px;
				cursor: pointer;
				background-color: var(--accent-blue);
				color: white;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			#qrcode {
				margin-top: 30px;
				display: flex;
				justify-content: center;
				align-items: center;
				min-height: 200px;
				background-color: rgba(255, 255, 255, 0.1);
				border-radius: 8px;
				padding: 10px;
			}
			#qrcode img {
				background-color: white;
				padding: 10px;
				border-radius: 5px;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="qr-container">
			<h1>QR Code Generator</h1>
			<input type="text" id="qrTextInput" placeholder="Enter text or URL" value="https://ring-lang.github.io">
			<button onclick="requestQrCode()">Generate QR Code</button>
			<div id="qrcode"></div>
		</div>

		<script>
			const qrTextInput = document.getElementById('qrTextInput');
			const qrcodeDiv = document.getElementById('qrcode');
			let qrcode = new QRCode(qrcodeDiv, {
				width: 200,
				height: 200,
				colorDark : "#000000",
				colorLight : "#ffffff",
				correctLevel : QRCode.CorrectLevel.H
			});

			async function requestQrCode() {
				const text = qrTextInput.value.trim();
				if (text) {
					try {
						// Clear existing QR code
						qrcode.clear();
						// Call Ring to get the text, though in this simple case,
						// we could just generate it directly from JS.
						// This demonstrates the binding mechanism.
						await window.generateQrCode(text);
					} catch (e) {
						console.error("Error requesting QR code generation:", e);
					}
				} else {
					qrcode.clear();
				}
			}

			function updateQrCode(text) {
				qrcode.makeCode(text);
			}

			window.onload = () => {
				requestQrCode();
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)