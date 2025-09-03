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

		# Load the HTML content for the color palette UI.
		loadPaletteHTML() # Load the HTML content for the color palette UI.

		# Run the webview's main event loop. This is a blocking call.
		run() 
	}

# Defines the HTML structure and inline JavaScript for the color palette generator.
func loadPaletteHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Color Palette Generator</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<style>
			body {
				font-family: "Inter", sans-serif;
				margin: 0;
				height: 100vh;
				overflow: hidden;
				display: flex;
				flex-direction: column;
				background: linear-gradient(45deg, #1e293b, #0f172a);
			}
			.palette-container {
				flex-grow: 1;
				display: flex;
				transition: all 0.3s ease;
				min-height: 0;
				gap: 2px;
				padding: 8px;
			}
			.color-column {
				flex: 1;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				color: white;
				font-family: "Fira Code", monospace;
				font-size: clamp(1rem, 2.5vw, 1.5rem);
				font-weight: 500;
				transition: all 0.3s ease;
				border-radius: 12px;
				min-height: 200px;
				position: relative;
				overflow: hidden;
				cursor: pointer;
			}
			.hex-code {
				background-color: rgba(0,0,0,0.3);
				padding: clamp(0.4em, 2vw, 0.8em) clamp(0.8em, 3vw, 1.2em);
				border-radius: 8px;
				cursor: pointer;
				transition: all 0.2s ease;
				user-select: none;
				position: relative;
				backdrop-filter: blur(10px);
				border: 1px solid rgba(255,255,255,0.1);
				box-shadow: 0 4px 6px rgba(0,0,0,0.1);
				text-shadow: 0 1px 2px rgba(0,0,0,0.5);
				letter-spacing: 0.05em;
			}
			.hex-code:hover {
				transform: scale(1.05) translateY(-2px);
				background-color: rgba(0,0,0,0.5);
				box-shadow: 0 8px 25px rgba(0,0,0,0.3);
				border-color: rgba(255,255,255,0.2);
			}
			.color-column:hover {
				transform: scale(1.02);
				box-shadow: 0 10px 30px rgba(0,0,0,0.2);
			}
			.hex-code:active {
				transform: scale(0.98) translateY(1px);
				transition: transform 0.1s ease;
			}
			.hex-code::after {
				content: "📋 Click to copy";
				position: absolute;
				top: -3em;
				left: 50%;
				transform: translateX(-50%);
				background-color: rgba(0,0,0,0.9);
				color: white;
				padding: 0.4em 0.8em;
				border-radius: 6px;
				font-size: clamp(0.6rem, 1.5vw, 0.8rem);
				white-space: nowrap;
				opacity: 0;
				visibility: hidden;
				transition: all 0.2s ease;
				pointer-events: none;
				z-index: 10;
				backdrop-filter: blur(10px);
				border: 1px solid rgba(255,255,255,0.1);
			}
			.hex-code:hover::after {
				opacity: 1;
				visibility: visible;
				transform: translateX(-50%) translateY(-5px);
			}
			.copy-feedback {
				position: fixed;
				bottom: 2em;
				left: 50%;
				transform: translateX(-50%);
				background-color: #10b981;
				color: white;
				padding: clamp(0.8em, 2vw, 1em) clamp(1.2em, 3vw, 1.5em);
				border-radius: 12px;
				box-shadow: 0 10px 25px rgba(16,185,129,0.3);
				opacity: 0;
				visibility: hidden;
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(10px);
				border: 1px solid rgba(255,255,255,0.1);
				font-weight: 500;
				font-size: clamp(0.9rem, 2vw, 1rem);
				max-width: 90vw;
				text-align: center;
				z-index: 1000;
			}
			.copy-feedback.show {
				opacity: 1;
				visibility: visible;
				transform: translateX(-50%) translateY(-10px) scale(1.02);
			}
			.controls {
				flex-shrink: 0;
				padding: clamp(1em, 3vw, 1.5em);
				text-align: center;
				background: linear-gradient(135deg, #1f2937, #111827);
				border-top: 1px solid rgba(255,255,255,0.1);
			}
			.generate-btn {
				background: linear-gradient(135deg, #3b82f6, #1d4ed8);
				color: white;
				border: none;
				border-radius: 12px;
				padding: clamp(0.7em, 2vw, 1em) clamp(1.5em, 4vw, 2.5em);
				font-size: clamp(1rem, 2.5vw, 1.2rem);
				font-weight: 600;
				cursor: pointer;
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				box-shadow: 0 4px 12px rgba(59,130,246,0.3);
				border: 1px solid rgba(255,255,255,0.1);
				backdrop-filter: blur(10px);
				text-transform: uppercase;
				letter-spacing: 0.5px;
			}
			.generate-btn:hover {
				background: linear-gradient(135deg, #60a5fa, #2563eb);
				transform: translateY(-2px);
				box-shadow: 0 8px 20px rgba(59,130,246,0.4);
			}
			.generate-btn:active {
				transform: translateY(0px);
				box-shadow: 0 4px 12px rgba(59,130,246,0.3);
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
				const container = document.getElementById("palette-container");
				container.innerHTML = "";
				if (!colors) return;

				colors.forEach(color => {
					const column = document.createElement("div");
					column.className = "color-column";
					column.style.backgroundColor = color;

					const hexCode = document.createElement("div");
					hexCode.className = "hex-code";
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
				try {
					if (navigator.clipboard && window.isSecureContext) {
						await navigator.clipboard.writeText(text);
						showCopyFeedback(text);
					} else {
						fallbackCopyTextToClipboard(text);
					}
				} catch (err) {
					console.error("Failed to copy text: ", err);
					fallbackCopyTextToClipboard(text);
				}
			}

			function fallbackCopyTextToClipboard(text) {
				const textArea = document.createElement("textarea");
				textArea.value = text;
				textArea.style.position = "fixed";
				textArea.style.left = "-999999px";
				textArea.style.top = "-999999px";
				document.body.appendChild(textArea);
				textArea.focus();
				textArea.select();
				try {
					document.execCommand("copy");
					showCopyFeedback(text);
				} catch (err) {
					console.error("Fallback: Oops, unable to copy", err);
				}
				document.body.removeChild(textArea);
			}

			function showCopyFeedback(colorCode) {
				const feedback = document.getElementById("copy-feedback");
				feedback.textContent = `Copied ${colorCode} to clipboard!`;
				feedback.classList.add("show");
				setTimeout(() => {
					feedback.classList.remove("show");
				}, 2000);
			}


			window.onload = async () => {
				try {
					const initialPalette = await window.getInitialPalette();
					renderPalette(initialPalette);
				} catch (e) { console.error("Error:", e); }

				document.querySelector(".generate-btn").addEventListener("click", generateNew);
			};
		</script>
	</body>
	</html>
	'
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