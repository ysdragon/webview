# Color Palette Generator
# This example implements a simple color palette generator using WebView.
# It generates random hex color codes and displays them.

load "webview.ring"
load "jsonlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL

func main()
	see "Setting up Color Palette Generator Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		setTitle("Color Palette Generator")
		setSize(800, 600, WEBVIEW_HINT_NONE)
		# Bind Ring functions to be callable from JavaScript.
		# `getInitialPalette` generates and returns the first palette on load.
		bind("getInitialPalette", func (id, req) {
			see "Ring: JavaScript requested initial color palette." + nl
			Palette = generatePalette() # Generate the initial palette.
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(Palette)) # Return the palette as JSON.
		})

		# `generateNewPalette` generates and returns a new palette on demand.
		bind("generateNewPalette", func (id, req) {
			see "Ring: JavaScript requested a new color palette." + nl
			Palette = generatePalette() # Generate a new palette.
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(Palette)) # Return the new palette as JSON.
		})

		# `copyToClipboard` simulates copying text to the clipboard.
		bind("copyToClipboard", func (id, req) {
			cTextToCopy = json2list(req)[1][1] # Extract text to copy from the request.
			see "--- Clipboard Simulation ---" + nl
			see "Text copied to clipboard (simulated): " + cTextToCopy + nl
			see "---" + nl
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.
		})

		# Load the HTML content for the color palette UI.
		loadPaletteHTML() # Load the HTML content for the color palette UI.

		# Run the webview's main event loop. This is a blocking call.
		run() 
	}

# Defines the HTML structure and inline JavaScript for the color palette generator.
func loadPaletteHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Color Palette Generator</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@500&display=swap');
			body {
				font-family: 'Inter', sans-serif;
				margin: 0;
				height: 100vh;
				overflow: hidden;
				display: flex;
				flex-direction: column;
			}
			.palette-container {
				flex-grow: 1;
				display: flex;
				transition: background-color 0.5s;
			}
			.color-column {
				flex: 1;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				color: white;
				font-family: 'Fira Code', monospace;
				font-size: 1.5em;
				font-weight: 500;
				transition: background-color 0.4s ease-in-out;
			}
			.hex-code {
				background-color: rgba(0,0,0,0.2);
				padding: 0.5em 1em;
				border-radius: 8px;
				cursor: pointer;
				transition: transform 0.2s;
			}
			.hex-code:hover {
				transform: scale(1.1);
			}
			.copy-feedback {
				position: fixed;
				bottom: 2em;
				left: 50%;
				transform: translateX(-50%);
				background-color: #22c55e;
				color: white;
				padding: 1em 1.5em;
				border-radius: 8px;
				box-shadow: 0 5px 15px rgba(0,0,0,0.2);
				opacity: 0;
				visibility: hidden;
				transition: opacity 0.3s, transform 0.3s;
			}
			.copy-feedback.show {
				opacity: 1;
				visibility: visible;
				transform: translateX(-50%) translateY(-20px);
			}
			.controls {
				flex-shrink: 0;
				padding: 1em;
				text-align: center;
				background-color: #111827;
			}
			.generate-btn {
				background-color: #3b82f6;
				color: white;
				border: none;
				border-radius: 8px;
				padding: 0.8em 2em;
				font-size: 1.2em;
				font-weight: 700;
				cursor: pointer;
				transition: background-color 0.2s;
			}
			.generate-btn:hover {
				background-color: #60a5fa;
			}
		</style>
	</head>
	<body>
		<div id="palette-container" class="palette-container">
			<!-- Color columns will be generated here -->
		</div>
		<div class="controls">
			<button class="generate-btn">Generate Palette</button>
		</div>
		<div id="copy-feedback" class="copy-feedback">Copied to clipboard!</div>

		<script>
			function renderPalette(colors) {
				const container = document.getElementById('palette-container');
				container.innerHTML = '';
				if (!colors) return;

				colors.forEach(color => {
					const column = document.createElement('div');
					column.className = 'color-column';
					column.style.backgroundColor = color;

					const hexCode = document.createElement('div');
					hexCode.className = 'hex-code';
					hexCode.textContent = color.toUpperCase();
					hexCode.onclick = () => copyToClipboard(color);

					column.appendChild(hexCode);
					container.appendChild(column);
				});
			}

			async function generateNew() {
				const newPalette = await window.generateNewPalette();
				renderPalette(newPalette);
			}

			async function copyToClipboard(text) {
				await window.copyToClipboard(text);
				showCopyFeedback();
				
			}

			function showCopyFeedback() {
				const feedback = document.getElementById('copy-feedback');
				feedback.classList.add('show');
				setTimeout(() => {
					feedback.classList.remove('show');
				}, 1500);
			}

			window.onload = async () => {
				try {
					const initialPalette = await window.getInitialPalette();
					renderPalette(initialPalette);
				} catch (e) { console.error('Error:', e); }

				document.querySelector('.generate-btn').addEventListener('click', generateNew);
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# Generates a list of 5 random RGB hex color codes.
func generatePalette()
	aPalette = []
	for i = 1 to 5
		cHex = "#"
		for x = 1 to 3
			nVal = random(255)
			cHex += right("0" + hex(nVal), 2)
		next
		add(aPalette, cHex)
	next
	return aPalette