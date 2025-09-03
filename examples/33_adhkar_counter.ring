# Adhkar Counter App

load "webview.ring"
load "jsonlib.ring"

oWebView = NULL
nCount = 0
nCurrentZikrIndex = 1

aAzkar = [
	["سُبْحَانَ اللَّهِ", 33],
	["الْحَمْدُ للّهِ", 33],
	["الْلَّهُ أَكْبَرُ", 34],
	["لَا إلَه إلّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلُّ شَيْءِ قَدِيرِ", 1],
]

# Bind Ring functions to be callable from JavaScript.
aBindList = [
	["getInitialCount", :handleGetInitialCount], # Get initial count and Zikr text
	["incrementCounter", :handleIncrementCounter], # Increment the counter
	["resetCounter", :handleResetCounter] # Reset the counter
]

func main()
	see "Starting Adhkar Counter App..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()
	
	oWebView {       
		# Set the title of the webview window. 
		setTitle("السبحة")
		# Set the size of the webview window (width, height, hint).
		setSize(500, 700, WEBVIEW_HINT_NONE)

		loadSebhaHTML()

		run()
	}
	
func loadSebhaHTML()
	cHTML = `
	<!DOCTYPE html>
	<html dir="rtl" lang="ar">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- Font Awesome for icons -->
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;700&display=swap');
			:root {
				--bg-color: #000000;
				--card-bg: rgba(30, 30, 32, 0.6);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
				--text-secondary: #a1a1aa;
				--accent-green: #4ade80;
				--accent-red: #f87171;
			}
			body {
				font-family: 'Tajawal', sans-serif;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				height: 100vh;
				margin: 0;
				background-color: var(--bg-color);
				user-select: none;
				position: relative;
				overflow: hidden;
				color: var(--text-primary);
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
				background: radial-gradient(circle, #22d3ee, transparent 60%);
				top: 5%; left: 5%;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				background: radial-gradient(circle, #c084fc, transparent 60%);
				bottom: 10%; right: 10%;
			}

			.sebha-container {
				text-align: center;
				background-color: var(--card-bg);
				padding: 2em;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				border: 1px solid var(--border-color);
				position: relative; z-index: 1;
				width: 90%;
				max-width: 400px;
			}
			h1 {
				font-size: 1.8em;
				color: var(--text-primary);
				margin-bottom: 1em;
			}
			.counter-display {
				background-color: rgba(255, 255, 255, 0.05);
				width: 100%;
				height: 120px;
				line-height: 120px;
				border-radius: 15px;
				box-shadow: inset 0 2px 5px rgba(0,0,0,0.2);
				font-size: 4em;
				font-weight: 700;
				color: var(--accent-green);
				margin-bottom: 30px;
				border: 1px solid var(--border-color);
			}
			.tasbih-button {
				width: 180px;
				height: 180px;
				border-radius: 50%;
				border: none;
				background-color: var(--accent-green);
				color: white;
				font-size: 2em;
				font-weight: 700;
				cursor: pointer;
				box-shadow: 0 5px 15px rgba(0, 128, 0, 0.4);
				transition: transform 0.1s, box-shadow 0.1s, background-color 0.2s;
				display: flex;
				align-items: center;
				justify-content: center;
				margin: 0 auto 30px auto;
			}
			.tasbih-button:active {
				transform: scale(0.95);
				box-shadow: 0 2px 8px rgba(0, 128, 0, 0.5);
			}
			.tasbih-button:hover {
				background-color: #00a884;
			}
			.reset-button {
				background: none;
				border: 1px solid var(--accent-red);
				color: var(--accent-red);
				padding: 0.8em 2em;
				border-radius: 10px;
				cursor: pointer;
				font-size: 1.1em;
				font-weight: 500;
				transition: all 0.2s ease;
			}
			.reset-button:hover {
				background-color: var(--accent-red);
				color: white;
				box-shadow: 0 4px 10px rgba(0,0,0,0.2);
			}
			@media (max-width: 480px) {
				.sebha-container {
					padding: 1.5em;
				}
				.counter-display {
					font-size: 3em;
					height: 100px;
					line-height: 100px;
				}
				.tasbih-button {
					width: 150px;
					height: 150px;
					font-size: 1.8em;
				}
				.reset-button {
					font-size: 1em;
					padding: 0.7em 1.5em;
				}
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="sebha-container">
			<h1><i class="fa-solid fa-mosque"></i> السبحة</h1>
			<div id="zikr-text" style="font-size: 1.5em; margin-bottom: 15px; color: var(--text-primary);"></div>
			<div id="counter" class="counter-display">0</div>
			<button id="tasbih-btn" class="tasbih-button">سبّح</button>
			<button id="reset-btn" class="reset-button">تصفير</button>
		</div>

		<script>
			function updateCounter(count, zikrText) {
				document.getElementById('counter').textContent = count;
				document.getElementById('zikr-text').textContent = zikrText;
			}

			async function increment() {
				// We don't need to wait for a response if we update the UI from Ring
				window.incrementCounter();
			}

			async function reset() {
				if (confirm('هل أنت متأكد أنك تريد تصفير العداد؟')) {
					window.resetCounter();
				}
			}

			window.onload = async () => {
				try {
					const initialData = await window.getInitialCount();
					updateCounter(initialData.count, initialData.zikr);
				} catch (e) { console.error('Error getting initial count:', e); }

				document.getElementById('tasbih-btn').addEventListener('click', increment);
				document.getElementById('reset-btn').addEventListener('click', reset);
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)
	

# Handles requests from JavaScript to get the initial counter value and current Zikr text.
func handleGetInitialCount(id, req)
	see "Ring: JavaScript requests initial counter value and Zikr text." + nl
	aResponse = [
		:count = nCount,
		:zikr = aAzkar[nCurrentZikrIndex][1]
	]
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aResponse))

# Handles requests from JavaScript to increment the counter.
func handleIncrementCounter(id, req)
	nCount++
	see "Ring: Counter incremented to: " + nCount + nl
	
	if nCount >= aAzkar[nCurrentZikrIndex][2]
		nCurrentZikrIndex++
		nCount = 0
		if nCurrentZikrIndex > len(aAzkar)
			nCurrentZikrIndex = 1
		ok
		see "Ring: Switched to next Zikr: " + aAzkar[nCurrentZikrIndex][1] + nl
	ok
	
	updateUICounter()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Handles requests from JavaScript to reset the counter.
func handleResetCounter(id, req)
	nCount = 0
	see "Ring: Counter has been reset." + nl
	updateUICounter()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Updates the counter and Zikr text displayed in the WebView UI.
func updateUICounter()
	cJsCode = "updateCounter(" + nCount + ", '" + aAzkar[nCurrentZikrIndex][1] + "');"
	oWebView.evalJS(cJsCode)