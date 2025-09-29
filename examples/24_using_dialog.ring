# Using Dialog Example
# This example demonstrates how to use various native dialogs (message, prompt, file, color picker)
# Using the Ring Dialog library (https://github.com/ysdragon/dialog)
# in a Ring WebView application.

load "webview.ring"
load "dialog.ring"
load "simplejson.ring"

# Global variable to hold the webview instance.
oWebView = NULL

# Bind Ring functions to be callable from JavaScript.
aBindList = [
	["messageDialog", :handleMessageDialog],
	["promptDialog", :handlePromptDialog],
	["fileDialog", :handleFileDialog],
	["colorPicker", :handleColorPicker]
]

func main()
	oWebView = new WebView()
	oWebView {
		# Set the window title.
		setTitle("WebView Dialogs Demo")

		# Set the window size (no size constraint).
		setSize(800, 600, WEBVIEW_HINT_NONE)
		
		# Load the HTML content for the UI.
		loadHtmlContent()

		# Run the webview's main event loop. This is a blocking call.
		run()
	}

# --- Callback Functions ---

func handleMessageDialog(id, req)
	cMessage = json_decode(req)[1]
	nResult = dialog_message(DIALOG_INFO, DIALOG_OK_CANCEL, cMessage)
	if nResult = 1
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"User clicked OK!"')
	else
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"User clicked Cancel!"')
	ok

func handlePromptDialog(id, req)
	aReq = json_decode(req)[1]
	cPrompt = aReq
	cDefault = ""
	cName = dialog_prompt(DIALOG_INFO, cPrompt, cDefault)
	if cName != ""
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + cName + '"')
	else
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')
	ok

func handleFileDialog(id, req)
	aReq = json_decode(req)
	nMode = aReq[1]
	cTitle = aReq[2]
	cDefaultPath = aReq[3]
	cFilters = aReq[4]

	cPath = dialog_file(nMode, cTitle, cDefaultPath, cFilters)
	cPath = substr(cPath, "\", "\\")

	if cPath != ""
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([cPath]))
	else
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')
	ok

func handleColorPicker(id, req)
	aReq = json_decode(req)
	aInitialColor = aReq[1]
	nEnableOpacity = aReq[2]

	aColor = [aInitialColor[1], aInitialColor[2], aInitialColor[3], aInitialColor[4]]
	nResult = dialog_color_picker(aColor, nEnableOpacity)
	
	aColor2 = []
	for color in aColor
		add(aColor2, string(color))
	next

	if nResult
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode(aColor2))
	else
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')
	ok

# --- HTML Content ---

func loadHtmlContent()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring WebView Dialogs</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
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
				--accent-green: #4ade80;
				--accent-yellow: #facc15;
				--accent-red: #f87171;
			}
			body {
				font-family: "Inter", sans-serif;
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
			.container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				text-align: center;
				width: 90%;
				max-width: 600px;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				color: var(--text-primary);
				margin-bottom: 20px;
				font-size: 2em;
			}
			.button-grid {
				display: grid;
				grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
				gap: 15px;
				margin-bottom: 20px;
			}
			button {
				background-color: var(--accent-blue);
				color: white;
				border: none;
				border-radius: 8px;
				padding: 12px 20px;
				font-size: 1em;
				font-weight: 500;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			.output-area {
				margin-top: 20px;
				background-color: rgba(0,0,0,0.1);
				border: 1px solid var(--border-color);
				padding: 15px;
				border-radius: 8px;
				min-height: 50px;
				text-align: left;
				font-family: "Fira Code", monospace;
				font-size: 0.9em;
				white-space: pre-wrap;
				overflow-y: auto;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="container">
			<h1><i class="fa-solid fa-comments"></i> Ring WebView Dialogs</h1>
			<div class="button-grid">
				<button onclick="testMessageDialog()"><i class="fa-solid fa-comment-dots"></i> Message Dialog</button>
				<button onclick="testPromptDialog()"><i class="fa-solid fa-keyboard"></i> Prompt Dialog</button>
				<button onclick="testFileOpenDialog()"><i class="fa-solid fa-folder-open"></i> File Open Dialog</button>
				<button onclick="testDirectoryOpenDialog()"><i class="fa-solid fa-folder"></i> Dir Open Dialog</button>
				<button onclick="testFileSaveDialog()"><i class="fa-solid fa-save"></i> File Save Dialog</button>
				<button onclick="testColorPicker()"><i class="fa-solid fa-palette"></i> Color Picker</button>
			</div>
			<div id="output" class="output-area">Dialog results will appear here.</div>
		</div>

		<script>
			const outputDiv = document.getElementById("output");

			function appendOutput(message) {
				outputDiv.textContent += `\n> ${message}`;
				outputDiv.scrollTop = outputDiv.scrollHeight; // Auto-scroll to bottom
			}

			async function testMessageDialog() {
				outputDiv.textContent = "Testing Message Dialog...";
				try {
					const result = await window.messageDialog("This is an info message from WebView.");
					appendOutput(`Message Dialog Result: ${result}`);
				} catch (e) {
					appendOutput(`Message Dialog Error: ${e}`);
				}
			}

			async function testPromptDialog() {
				outputDiv.textContent = "Testing Prompt Dialog...";
				try {
					const result = await window.promptDialog("What is your name?", "Ring User");
					if (result) {
						appendOutput(`Prompt Dialog Result: Hello, ${result}!`);
					} else {
						appendOutput("Prompt Dialog Result: User cancelled the prompt.");
					}
				} catch (e) {
					appendOutput(`Prompt Dialog Error: ${e}`);
				}
			}

			async function testFileOpenDialog() {
				outputDiv.textContent = "Testing File Open Dialog...";
				const filters = "Source:c,cpp,ring;Images:png,jpg,jpeg;All Files:*";
				try {
					// DIALOG_OPEN = 0 (for Open File)
					const result = await window.fileDialog(0, "Open a file", "", filters);
					console.log(result);
					if (result) {
						appendOutput(`File Open Dialog Result: Selected file: ${result}`);
					} else {
						appendOutput("File Open Dialog Result: User cancelled file selection.");
					}
				} catch (e) {
					appendOutput(`File Open Dialog Error: ${e}`);
				}
			}

			async function testDirectoryOpenDialog() {
				outputDiv.textContent = "Testing Directory Open Dialog...";
				try {
					// DIALOG_OPEN_DIR = 1 (for Open Directory)
					const result = await window.fileDialog(1, "Open a directory", "", "");
					if (result) {
						appendOutput(`Directory Open Dialog Result: Selected directory: ${result}`);
					} else {
						appendOutput("Directory Open Dialog Result: User cancelled directory selection.");
					}
				} catch (e) {
					appendOutput(`Directory Open Dialog Error: ${e}`);
				}
			}

			async function testFileSaveDialog() {
				outputDiv.textContent = "Testing File Save Dialog...";
				const filters = "Source:c,h;Image:jpg,png,gif;Text:txt";
				try {
					// DIALOG_SAVE = 2 (for Save File)
					const result = await window.fileDialog(2, "Save a file", "my_document.txt", filters);
					if (result) {
						appendOutput(`File Save Dialog Result: File to save: ${result}`);
					} else {
						appendOutput("File Save Dialog Result: User cancelled file save.");
					}
				} catch (e) {
					appendOutput(`File Save Dialog Error: ${e}`);
				}
			}

			async function testColorPicker() {
				outputDiv.textContent = "Testing Color Picker...";
				const initialColor = [255, 0, 0, 255]; // RGBA: Red
				try {
					// 1 = enable opacity
					const result = await window.colorPicker(initialColor, 1);
					if (result) {
						const color = result;
						appendOutput(`Color Picker Result: R: ${color[0]}, G: ${color[1]}, B: ${color[2]}, A: ${color[3]}`);
					} else {
						appendOutput("Color Picker Result: User cancelled color selection.");
					}
				} catch (e) {
					appendOutput(`Color Picker Error: ${e}`);
				}
			}
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)