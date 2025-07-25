# All Functions Demo
# Demonstrates most functions of the WebView class with an interactive UI.

load "webview.ring"
load "jsonlib.ring"

# Global variable for the WebView instance.
oWebView = NULL
# Global list of bound functions to be callable from JavaScript.
aBindList = [
	["ring_getVersion", :handle_getVersion],
	["ring_echo", :handle_echo],
	["ring_setTitle", :handle_setTitle],
	["ring_setSize", :handle_setSize],
	["ring_navigate", :handle_navigate],
	["ring_setHtml", :handle_setHtml],
	["ring_evalJs", :handle_evalJs],
	["ring_dispatch", :handle_dispatch],
	["ring_initJs", :handle_initJs],
	["ring_unbindFunc", :handle_unbindFunc],
	["ring_terminate", :handle_terminate]
]

# --- Main Application Logic ---

func main()
	see "--- WebView All Functions Demo ---" + nl

	# Get and print WebView version info.
	aVersionInfo = webview_version()
	see "   WebView Version String: " + aVersionInfo + nl
	see "   Major: " + WEBVIEW_VERSION_MAJOR + ", Minor: " + WEBVIEW_VERSION_MINOR + ", Patch: " + WEBVIEW_VERSION_PATCH + nl

	# Create a new WebView window.
	oWebView = new WebView()
	see "   Webview instance created." + nl

	# Set window title.
	oWebView.setTitle("WebView All Functions Demo")
	see "   Title set to 'WebView All Functions Demo'." + nl

	# Set window size.
	see "   Setting window size..." + nl
	oWebView.setSize(500, 700, WEBVIEW_HINT_NONE)

	# Define the HTML and JavaScript content for the webview.
	cHTML = '
<!DOCTYPE html>
<html>
<head>
	<title>WebView Interactive Demo</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap" rel="stylesheet">
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
			min-height: 100vh;
			position: relative;
			display: flex;
			flex-direction: column;
			justify-content: flex-start;
			align-items: center;
			overflow-y: auto;
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
			max-width: 960px;
			width: 100%;
			margin: 0 auto;
			background-color: var(--panel-bg);
			padding: 2.5vw 2vw;
			border-radius: 2vw;
			box-shadow: 0 8px 30px rgba(0,0,0,0.3);
			position: relative; z-index: 1;
			border: 1px solid var(--border-color);
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			box-sizing: border-box;
		}
		h1 {
			color: var(--accent-green);
			text-align: center;
			margin-bottom: 30px;
			font-size: 2em;
			text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
		}
		.section {
			background-color: rgba(255,255,255,0.03);
			padding: 18px;
			border-radius: 10px;
			margin-bottom: 22px;
			border: 1px solid var(--border-color);
			box-shadow: 0 2px 8px rgba(0,0,0,0.08);
		}
		.section h2 {
			margin-top: 0;
			color: var(--accent-blue);
			font-size: 1.15em;
			border-bottom: 1px solid var(--border-color);
			padding-bottom: 8px;
			margin-bottom: 15px;
		}
		.input-group {
			display: flex;
			flex-wrap: wrap;
			gap: 10px;
			margin-bottom: 10px;
			align-items: center;
		}
		.input-group label {
			flex-shrink: 0;
			font-weight: 500;
			color: var(--text-secondary);
		}
		.input-group input[type="text"], .input-group input[type="number"], .input-group textarea, .input-group select {
			flex-grow: 1;
			padding: 0.7em 1em;
			border: 1px solid var(--border-color);
			border-radius: 0.6em;
			font-size: 1em;
			min-width: 0;
			width: 100%;
			background-color: rgba(255,255,255,0.05);
			color: var(--text-primary);
			font-family: "Inter", sans-serif;
			transition: border-color 0.2s;
			box-sizing: border-box;
		}
		.input-group select {
			background-color: rgba(30,30,32,0.8);
			color: var(--text-primary);
			border: 1px solid var(--border-color);
			border-radius: 8px;
			font-size: 1em;
			font-family: "Inter", sans-serif;
			padding: 10px;
			appearance: none;
			-webkit-appearance: none;
			-moz-appearance: none;
		}
		.input-group input[type="text"]:focus, .input-group input[type="number"]:focus, .input-group textarea:focus, .input-group select:focus {
			border-color: var(--accent-cyan);
			outline: none;
		}
		.input-group textarea {
			min-height: 60px;
			resize: vertical;
			width: 100%;
			box-sizing: border-box;
		}
		.input-group button {
			padding: 10px 18px;
			background-color: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 8px;
			cursor: pointer;
			font-size: 1em;
			font-family: "Inter", sans-serif;
			transition: all 0.2s;
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
		}
		.input-group button:hover {
			background-color: var(--accent-cyan);
			transform: translateY(-2px);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
		}
		.output {
			background-color: rgba(0,0,0,0.1);
			border: 1px solid var(--border-color);
			padding: 12px;
			border-radius: 8px;
			min-height: 30px;
			white-space: pre-wrap;
			word-break: break-all;
			font-family: "Fira Code", monospace;
			font-size: 0.95em;
			color: var(--text-primary);
		}
		.output.error {
			color: var(--accent-red);
		}
		.note {
			font-size: 0.85em;
			color: var(--text-secondary);
			margin-top: 5px;
		}
	</style>
</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="container">
			<h1>WebView Interactive Demo</h1>

			<div class="section">
				<h2><i class="fa-solid fa-code-branch"></i> webview_version()</h2>
				<div class="input-group">
					<button onclick="displayVersion()">Get Version</button>
				</div>
				<div id="versionOutput" class="output"></div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-heading"></i> setTitle()</h2>
				<div class="input-group">
					<label for="titleInput">New Title:</label>
					<input type="text" id="titleInput" value="New Ring Title">
					<button onclick="setTitle()">Set Title</button>
				</div>
				<div id="titleOutput" class="output"></div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-expand-alt"></i> setSize()</h2>
				<div class="input-group">
					<label for="widthInput">Width:</label>
					<input type="number" id="widthInput" value="800">
					<label for="heightInput">Height:</label>
					<input type="number" id="heightInput" value="600">
					<label for="hintSelect">Hint:</label>
					<select id="hintSelect">
						<option value="0">WEBVIEW_HINT_NONE</option>
						<option value="1">WEBVIEW_HINT_MIN</option>
						<option value="2">WEBVIEW_HINT_MAX</option>
						<option value="3">WEBVIEW_HINT_FIXED</option>
					</select>
					<button onclick="setSize()">Set Size</button>
				</div>
				<div id="sizeOutput" class="output"></div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-globe"></i> navigate()</h2>
				<div class="input-group">
					<label for="urlInput">URL:</label>
					<input type="text" id="urlInput" value="https://ring-lang.github.io">
					<button onclick="navigateUrl()">Navigate</button>
				</div>
				<div id="navigateOutput" class="output"></div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-code"></i> setHtml()</h2>
				<div class="input-group">
					<label for="htmlInput">HTML Content:</label>
					<textarea id="htmlInput"><h2>Hello from custom HTML!</h2><p>This content was set via setHtml().</p></textarea>
					<button onclick="setHtml()">Set HTML</button>
				</div>
				<div id="setHtmlOutput" class="output"></div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-handshake"></i> bind() & wreturn()</h2>
				<div class="input-group">
					<label for="boundFuncInput">Message:</label>
					<input type="text" id="boundFuncInput" value="Hello from JS!">
					<button onclick="callBoundFunc()">Call Bound Function (ring_echo)</button>
				</div>
				<div id="boundFuncOutput" class="output"></div>
				<div class="note">This calls Ring function "ring_echo" with the message.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-terminal"></i> eval()</h2>
				<div class="input-group">
					<label for="evalInput">JS Code:</label>
					<input type="text" id="evalInput" value="alert(`Evaluated from Ring!`);">
					<button onclick="evalJs()">Evaluate JS</button>
				</div>
				<div id="evalOutput" class="output"></div>
				<div class="note">This demonstrates Ring calling JS code.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-paper-plane"></i> dispatch()</h2>
				<div class="input-group">
					<button onclick="dispatchRing()">Dispatch Ring Function</button>
				</div>
				<div id="dispatchOutput" class="output"></div>
				<div class="note">This schedules a Ring function to run on the main UI thread. Check console for output.</div>
			</div>


			<div class="section">
				<h2><i class="fa-solid fa-code-compare"></i> inject()</h2>
				<div class="input-group">
					<label for="initInput">JS Init Code:</label>
					<input type="text" id="initInput" value="window.myGlobalVar = `Initialized!`; console.log(`Init JS executed!`);">
					<button onclick="initJs()">Initialize JS</button>
				</div>
				<div id="initOutput" class="output"></div>
				<div class="note">Executes JS code before page load. Works best on initial load or after set_html.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-unlink"></i> unbind()</h2>
				<div class="input-group">
					<button onclick="unbindFunc(`ring_echo`)">Unbind "ring_echo"</button>
					<button onclick="testUnboundFunc()">Test "ring_echo"</button>
				</div>
				<div id="unbindOutput" class="output"></div>
				<div class="note">Tests if "ring_echo" (from bind section) is still callable.</div>
			</div>

			<div class="section">
				<h2><i class="fa-solid fa-power-off"></i> terminate()</h2>
				<div class="input-group">
					<button onclick="terminateWebview()">Terminate Webview</button>
				</div>
				<div id="terminateOutput" class="output"></div>
				<div class="note">This will close the webview window.</div>
			</div>

		</div>

		<script>
			
			function updateOutput(elementId, message, isError = false) {
				const outputDiv = document.getElementById(elementId);
				outputDiv.textContent = message;
				if (isError) {
					outputDiv.classList.add("error");
				} else {
					outputDiv.classList.remove("error");
				}
			}

			
			async function displayVersion() {
				try {
					const versionInfo = await window.ring_getVersion();
					updateOutput("versionOutput", "Version: " + versionInfo.version +
												"\nMajor: " + versionInfo.major +
												", Minor: " + versionInfo.minor +
												", Patch: " + versionInfo.patch);
				} catch (e) {
					updateOutput("versionOutput", "Error getting version: " + e, true);
				}
			}

			
			async function setTitle() {
				const newTitle = document.getElementById("titleInput").value;
				try {
					await window.ring_setTitle(newTitle);
					updateOutput("titleOutput", `Title set to: "` + newTitle + `"`);
				} catch (e) {
					updateOutput("titleOutput", "Error setting title: " + e, true);
				}
			}

			
			async function setSize() {
				const width = parseInt(document.getElementById("widthInput").value);
				const height = parseInt(document.getElementById("heightInput").value);
				const hint = parseInt(document.getElementById("hintSelect").value);
				try {
					await window.ring_setSize(width, height, hint);
					updateOutput("sizeOutput", `Size set to ${width}x${height} with hint ${hint}.`);
				} catch (e) {
					updateOutput("sizeOutput", "Error setting size: " + e, true);
				}
			}

			
			async function navigateUrl() {
				const url = document.getElementById("urlInput").value;
				try {
					await window.ring_navigate(url);
					updateOutput("navigateOutput", "Navigated to: " + url);
				} catch (e) {
					updateOutput("navigateOutput", "Error navigating: " + e, true);
				}
			}

			
			async function setHtml() {
				const htmlContent = document.getElementById("htmlInput").value;
				try {
					await window.ring_setHtml(htmlContent);
					updateOutput("setHtmlOutput", "HTML content set successfully.");
				} catch (e) {
					updateOutput("setHtmlOutput", "Error setting HTML: " + e, true);
				}
			}

			
			async function callBoundFunc() {
				const message = document.getElementById("boundFuncInput").value;
				try {
					const response = await window.ring_echo(message);
					updateOutput("boundFuncOutput", "Ring Response: " + response);
				} catch (e) {
					updateOutput("boundFuncOutput", "Error calling bound function (ring_echo): " + e, true);
				}
			}

			
			async function evalJs() {
				const jsCode = document.getElementById("evalInput").value;
				try {
					await window.ring_evalJs(jsCode);
					updateOutput("evalOutput", "JavaScript evaluated. Check browser console or alert for effects.");
				} catch (e) {
					updateOutput("evalOutput", "Error evaluating JS: " + e, true);
				}
			}

			
			async function dispatchRing() {
				try {
					await window.ring_dispatch();
					updateOutput("dispatchOutput", "Ring function dispatched. Check Ring console for output.");
				} catch (e) {
					updateOutput("dispatchOutput", "Error dispatching Ring function: " + e, true);
				}
			}


			
			async function initJs() {
				const jsInitCode = document.getElementById("initInput").value;
				try {
					await window.ring_initJs(jsInitCode);
					updateOutput("initOutput", "JS init code sent. It will execute when the next page loads or when set_html is called.");
				} catch (e) {
					updateOutput("initOutput", "Error initializing JS: " + e, true);
				}
			}

			
			async function unbindFunc(funcName) {
				try {
					await window.ring_unbindFunc(funcName);
					updateOutput("unbindOutput", `"${funcName}" unbound successfully.`);
				} catch (e) {
					updateOutput("unbindOutput", `Error unbinding "${funcName}": ` + e, true);
				}
			}

			
			async function testUnboundFunc() {
				try {
					const response = await window.ring_echo("This should fail if unbound.");
					updateOutput("unbindOutput", `Test "ring_echo": Still bound. Response: ` + response);
				} catch (e) {
					updateOutput("unbindOutput", `Test "ring_echo": Successfully unbound (Error: ` + e + `).`, true);
				}
			}

			
			async function terminateWebview() {
				try {
					await window.ring_terminate();
					updateOutput("terminateOutput", "Webview termination requested. Window should close shortly.");
				} catch (e) {
					updateOutput("terminateOutput", "Error terminating webview: " + e, true);
				}
			}
		</script>
	</body>
	</html>
	'
	# Load the HTML content into the webview.
	oWebView.setHtml(cHTML)
	see "   Interactive demo HTML loaded." + nl

	# Run the webview main loop.
	oWebView.run()

	# Destroy the webview instance after closing.
	oWebView.destroy()
	see "   Webview instance destroyed." + nl

	see "All functions demonstration finished. Program exiting." + nl

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Echo handler for JS ring_echo.
func handle_echo(id, req)
	cMessage = json2list(req)[1][1]
	see "   Ring: handle_echo received: '" + cMessage + "'" + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Echo: ' + cMessage + '"')

# Return version info for JS ring_getVersion.
func handle_getVersion(id, req)
	aVersionInfo = webview_version()
	aResult = [
		:version = aVersionInfo,
		:major = WEBVIEW_VERSION_MAJOR,
		:minor = WEBVIEW_VERSION_MINOR,
		:patch = WEBVIEW_VERSION_PATCH
	]
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aResult))

# Set window title from JS.
func handle_setTitle(id, req)
	cTitle = json2list(req)[1][1]
	oWebView.setTitle(cTitle)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Set window size from JS.
func handle_setSize(id, req)
	aReq = json2list(req)[1]
	nWidth = aReq[1]
	nHeight = aReq[2]
	nHint = aReq[3]
	oWebView.setSize(nWidth, nHeight, nHint)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Navigate to URL from JS.
func handle_navigate(id, req)
	cUrl = json2list(req)[1][1]
	oWebView.navigate(cUrl)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Set HTML content from JS.
func handle_setHtml(id, req)
	cHtml = json2list(req)[1][1]
	oWebView.setHtml(cHtml)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Evaluate JS code from Ring.
func handle_evalJs(id, req)
	cJsCode = json2list(req)[1][1]
	oWebView.evalJS(cJsCode)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Dispatch Ring function from JS.
func handle_dispatch(id, req)
	oWebView.dispatch("ring_dispatchedFunc()")
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Inject JS code before page load.
func handle_initJs(id, req)
	cJsInitCode = json2list(req)[1][1]
	oWebView.injectJS(cJsInitCode)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Unbind a JS function.
func handle_unbindFunc(id, req)
	cFuncName = json2list(req)[1][1]
	oWebView.unbind(cFuncName)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Terminate the webview.
func handle_terminate(id, req)
	oWebView.terminate()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Handler for dispatch() demo.
func ring_dispatchedFunc()
	see "   Ring: ring_dispatchedFunc executed via dispatch!" + nl
	oWebView.evalJS("alert('Dispatched Ring function executed!');")