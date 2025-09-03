# This file is part of the Ring WebView library.

load "webview.ring"

# Variable to hold the webview instance.
oWebView = NULL

# Optional Configuration for the WebView instance.
# This can be customized as needed.
aWebViewConfig = [
	:debug = false,  # Disable debug mode
	:window = NULL  # No parent window, create a new one
]

# Define a global list of bindings for the first webview instance.
# The WebView class will automatically detect and use this global list.
aBindList = [
	["sayHello", :handleSayHello],
	["showInfo", :handleShowInfo],
	[new Greeter, [
		["js_greet", :greet],
		["js_sayBye", :sayBye]
	]],
	[new Counter, [
		["js_increment", :increment],
		["js_decrement", :decrement],
		["js_getValue", :getValue]
	]],
]

# --- Main Application Logic ---

func main
	# Create a webview instance, which will use the global `aBindList`.
	oWebView = new WebView()
	
	oWebView {
		# Set the title and size of the webview window.
		setTitle("bindMany() - Global List")
		setSize(780, 650, 0) # 0 = WEBVIEW_HINT_NONE
		
		# You can also use bindMany(BindList) to explicitly bind the list.
		# Like this: 
		# BindList = [
		# 	["sayHello", :handleSayHello],
		# 	["showInfo", :handleShowInfo],
		# 	[new Greeter, [
		# 		["js_greet", :greet],
		# 		["js_sayBye", :sayBye]
		# 	]],
		# 	[new Counter, [
		# 		["js_increment", :increment],
		# 		["js_decrement", :decrement],
		# 		["js_getValue", :getValue]
		# 	]],
		# ]
		# bindMany(BindList)

		# Set the HTML content for the webview.
		setHtml(getHtmlContent())

		# Run the webview event loop.
		run()
	}

# --- HTML Content ---

func getHtmlContent()
	return `<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
	<style>
		@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap');
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
			min-height: 100vh;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			position: relative;
			padding: 10px;
			box-sizing: border-box;
		}
		.background-container {
			position: fixed;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			z-index: -1;
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
		.main-card {
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			border-radius: 15px;
			padding: 10px;
			text-align: center;
			width: 90%;
			max-width: 900px;
			max-height: 90vh;
			overflow-y: auto;
			box-shadow: 0 8px 30px rgba(0,0,0,0.3);
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			position: relative;
			z-index: 1;
			box-sizing: border-box;
		}
		h1 {
			color: var(--text-primary);
			margin-bottom: 10px;
			font-size: 2em;
		}
		p {
			color: var(--text-secondary);
			margin-bottom: 15px;
			font-size: 1.1em;
		}
		button {
			background-color: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 8px;
			padding: 0.5rem 1rem;
			font-size: 1em;
			font-weight: 500;
			cursor: pointer;
			transition: all 0.2s ease-in-out;
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			margin: 0 8px 10px 8px;
		}
		button:hover {
			transform: translateY(-2px);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
		}
		#response {
			margin-top: 10px;
			font-style: italic;
			color: var(--text-secondary);
			font-size: 0.95em;
			min-height: 20px;
		}
		.card {
			margin-bottom: 1rem;
			padding: 1rem;
			border: 1px solid var(--border-color);
			border-radius: 8px;
			background-color: rgba(255, 255, 255, 0.05);
			flex: 1;
			min-width: 250px;
			max-width: 45%;
		}
		h2 {
			color: var(--text-primary);
			margin-top: 0;
			margin-bottom: 0.5rem;
			border-bottom: 2px solid var(--border-color);
			padding-bottom: 0.5rem;
		}
		.button-group {
			display: flex;
			justify-content: center;
			gap: 0.5rem;
			margin-bottom: 1rem;
			flex-wrap: wrap;
		}
		.result {
			font-size: 1.2rem;
			font-weight: 500;
			margin-top: 1rem;
			padding: 0.5rem;
			background-color: rgba(255, 255, 255, 0.1);
			border-radius: 8px;
			min-height: 2rem;
			display: flex;
			justify-content: center;
			align-items: center;
			color: var(--text-primary);
		}
		.counter-value {
			color: var(--accent-cyan);
			font-weight: 700;
		}
		.modules-container {
			display: flex;
			flex-wrap: wrap;
			justify-content: center;
			gap: 1rem;
			width: 100%;
			margin-top: 1rem;
		}
		@media (max-width: 600px) {
			.main-card {
				padding: 10px;
			}
			h1 {
				font-size: 1.5em;
			}
			button {
				width: 100%;
			}
			.card {
				max-width: 90%;
			}
		}
	</style>
</head>
<body>
	<div class="background-container">
		<div class="aurora">
			<div class="aurora-shape1"></div>
			<div class="aurora-shape2"></div>
		</div>
	</div>
	<div class="main-card">
		<h1>bindMany()</h1>
		<p>Binding multiple functions from Ring to JavaScript.</p>
		<div class="button-group">
			<button onclick="window.sayHello()">Say Hello</button>
			<button onclick="window.showInfo()">Show Info</button>
		</div>
		<div class="modules-container">
			<div class="card">
				<h2>Greeter Module</h2>
				<div class="button-group">
					<button onclick="callGreet()"><i class="fa-solid fa-hand-sparkles"></i> Greet</button>
					<button onclick="callSayBye()"><i class="fa-solid fa-hand-wave"></i> Say Bye</button>
				</div>
				<div id="greeting-result" class="result">...</div>
			</div>
			<div class="card">
				<h2>Counter Module</h2>
				<div class="button-group">
					<button onclick="callIncrement()"><i class="fa-solid fa-plus"></i> Increment</button>
					<button onclick="callDecrement()"><i class="fa-solid fa-minus"></i> Decrement</button>
				</div>
				<div class="result">
					Current Value: <span id="counter-value" class="counter-value">...</span>
				</div>
			</div>
		</div>
	</div>
	<script>
		async function callBackend(fn, resultElementId, ...args) {
			const element = document.getElementById(resultElementId);
			element.innerText = 'Loading...';
			try {
				const result = await fn(...args);
				element.innerText = result;
			} catch (e) {
				element.innerText = 'Error!';
				console.error(e);
			}
		}
		const callGreet = () => callBackend(js_greet, 'greeting-result', '');
		const callSayBye = () => callBackend(js_sayBye, 'greeting-result', '');
		const updateCounter = async () => {
			await callBackend(js_getValue, 'counter-value', '');
		};
		const callIncrement = async () => {
			await callBackend(js_increment, 'counter-value', '');
		};
		const callDecrement = async () => {
			await callBackend(js_decrement, 'counter-value', '');
		};
		window.onload = () => {
			updateCounter();
			document.getElementById('greeting-result').innerText = 'Ready';
		};
	</script>
</body>
</html>`

# --- Callback Functions ---

func handleSayHello(id, req)
	see "handleSayHello called" + nl
	oWebView.evalJS("alert('Hello from Ring!');")

func handleShowInfo(id, req)
	see "handleShowInfo called" + nl
	oWebView.evalJS("alert('This is the first webview, using a global binding list.');")

class Greeter
	_name = "World"

	func greet(id, req)
		see "Greeter.greet() called" + nl
		# In a real app, you might parse `req` to get arguments
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello from ' + self._name + '!"')

	func sayBye(id, req)
		see "Greeter.sayBye() called" + nl
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Goodbye from ' + self._name + '!"')

class Counter
	_value = 0

	func increment(id, req)
		see "Counter.increment() called" + nl
		_value++
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, "" + _value)

	func decrement(id, req)
		see "Counter.decrement() called" + nl
		_value--
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, "" + _value)

	func getValue(id, req)
		see "Counter.getValue() called" + nl
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, "" + _value)