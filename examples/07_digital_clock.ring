# Digital Clock Example

load "webview.ring"
load "jsonlib.ring"

# --- Global variable to hold the webview instance ---
oWebView = NULL

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set the title of the webview window.
		setTitle("Ring Digital Clock")
		# Set the size of the webview window. WEBVIEW_HINT_NONE means no size constraint.
		setSize(400, 150, WEBVIEW_HINT_NONE)

		# Bind the `requestTime` function to handle time requests from JavaScript.
		# When JS calls `window.requestTime()`, this anonymous Ring function will execute.
		bind("requestTime", func (id, req) {
			cCurrentTime = time() # Get the current system time.
			# Return the current time as a JSON string to JavaScript.
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json([cCurrentTime]))
		})

		# Load the HTML content that defines the clock UI.
		loadClockHTML()

		# Run the webview's main event loop. This is a blocking call that keeps the window open.
		run()
	}

# Function to load the HTML content.
func loadClockHTML()
	# Define the HTML content for the digital clock.
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Digital Clock</title>
		<meta charset="UTF-8">
		<style>
			:root {
				--bg-color: #000000;
				--panel-bg: rgba(30, 30, 32, 0.6);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
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
				position: relative;
				display: flex;
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
			.clock-container {
				font-family: 'Orbitron', sans-serif;
				background: var(--panel-bg);
				padding: 40px 60px;
				border-radius: 20px;
				border: 1px solid var(--border-color);
				box-shadow: 0 0 30px rgba(0,0,0,0.5);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				color: var(--accent-cyan);
				text-shadow: 0 0 10px var(--accent-cyan), 0 0 20px var(--accent-cyan);
			}
			#clock-display {
				font-size: 5em;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="clock-container">
			<div id="clock-display">00:00:00</div>
		</div>

		<script>
			const clockDisplay = document.getElementById('clock-display');

			async function updateClock() {
				try {
					const time = await window.requestTime();
					clockDisplay.textContent = time;
				} catch (e) {
					console.error("Error fetching time from Ring:", e);
					clockDisplay.textContent = "Error";
				}
			}

			window.onload = () => {
				updateClock();
				setInterval(updateClock, 1000);
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML) # Set the HTML content in the webview.
