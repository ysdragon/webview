load "webview.ring"
load "stdlibcore.ring"
load "threads.ring"

# Global variable to hold the WebView instance.
oWebView = NULL
# Global bind list for JavaScript function bindings.
aBindList = [
	["toggleCounter", :toggleCounter] # Bind the toggleCounter function to JavaScript.
]
# Global flag to control the counter thread.
bRunCounter = false
# Global variable for the counter value.
nCounter = 0

func main()
	oWebView = new WebView()

	oWebView {
		# Set the window title.
		setTitle("Ring Threaded Counter Example")
		# Set the window size (WEBVIEW_HINT_NONE means no size constraint).
		setSize(400, 300, WEBVIEW_HINT_NONE)

		# Load the HTML content.
		loadCounterHTML()

		# Run the WebView main loop.
		run()
	}

	? "Threaded Counter example has been closed."

func loadCounterHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- Font Awesome for icons -->
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
				display: flex;
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
			
			.counter-container {
				background-color: var(--panel-bg);
				padding: 2.5em;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 320px;
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				text-align: center;
			}
			h1 {
				text-align: center;
				color: var(--text-primary);
				margin-bottom: 1.5em;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			#counter {
				font-size: 4em;
				margin-bottom: 20px;
				color: var(--text-primary);
			}
			button {
				padding: 0.9em 1.5em;
				background-color: var(--accent-blue);
				color: white;
				border: none;
				border-radius: 8px;
				font-size: 1em;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 0.5em;
				font-weight: 600;
				flex: 1;
			}
			button:disabled {
				background-color: #64748b;
				cursor: not-allowed;
				opacity: 0.6;
				box-shadow: none;
			}
			.button-group {
				display: flex;
				gap: 10px;
				width: 100%;
				max-width: 320px;
				margin-top: 20px;
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
		<div class="counter-container">
			<h1>Threaded Counter</h1>
			<div id="counter">0</div>
			<div class="button-group">
				<button id="startButton" onclick="startCounter()"><i class="fa-solid fa-play"></i> <span id="startBtnText">Start</span></button>
				<button id="stopButton" onclick="stopCounter()"><i class="fa-solid fa-stop"></i> Stop</button>
			</div>
		</div>

		<script>
			function setStartButtonState(isRunning, firstLoad = false) {
				const startBtn = document.getElementById('startButton');
				const startBtnText = document.getElementById('startBtnText');
				if (isRunning) {
					startBtn.disabled = true;
					startBtnText.textContent = 'Start';
				} else {
					startBtn.disabled = false;
					startBtnText.textContent = firstLoad ? 'Start' : 'Resume';
				}
			}

			async function startCounter() {
				await window.toggleCounter(1);
				setStartButtonState(true);
			}

			async function stopCounter() {
				await window.toggleCounter(0);
				setStartButtonState(false);
			}

			window.onload = function() {
				setStartButtonState(false, true); // Show 'Start' and enabled on first load
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)


func toggleCounter(id, req)
	bStart = number(substr(req, 2, len(req)-2))
	if bStart
		if not bRunCounter
			bRunCounter = true
			oCounterThread = new_thrd_t()
			thrd_create(oCounterThread, "runCounterThread()")
			thrd_detach(oCounterThread)
			see "Ring: Counter thread started." + nl
		ok
	else
		if bRunCounter
			bRunCounter = false
			see "Ring: Counter thread stopped." + nl
		ok
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, "")

func runCounterThread()
	while bRunCounter
		nCounter++
		oWebView.dispatch(`oWebView.evalJS("document.getElementById('counter').innerText = " + nCounter)`)
		sleep(0.1) # Sleep for 100ms
	end
	see "Ring: Counter thread finished execution." + nl