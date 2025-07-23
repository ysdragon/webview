# Live Markdown Editor
# This example implements a real-time Markdown editor using Ring WebView 
# and Ring Markdown (https://github.com/ysdragon/markdown).
# It converts Markdown input into HTML dynamically and displays it in a side-by-side preview.

load "webview.ring"
load "markdown.ring"
load "jsonlib.ring"

# --- Global variables ---
oWebView = NULL
oMarkdown = new Markdown()
oMarkdown.setFlags(MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | MD_FLAG_TASKLISTS | MD_FLAG_PERMISSIVEAUTOLINKS)
aBindList = [
	["updateMarkdown", :handleMarkdownUpdate]  # Bind the updateMarkdown function to handle Markdown updates
]

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set the title of the webview window.
		setTitle("Live Markdown Editor")
		# Set the size of the webview window (width, height, hint).
		setSize(1024, 768, WEBVIEW_HINT_NONE)
		# Load the HTML content for the editor UI.
		loadEditorHTML()

		# Run the webview's main event loop. This is a blocking call.
		run()

		# No need to destroy the webview instance here, as it will be automatically cleaned up when the run() method exits.
	}

# Defines the HTML structure and inline JavaScript for the Markdown editor.
func loadEditorHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Live Markdown Editor</title>
		<meta charset="UTF-8">
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;600&display=swap');

			:root {
				--gh-bg-color: #0d1117;
				--gh-text-color: #c9d1d9;
				--gh-border-color: #30363d;
				--gh-code-bg: rgba(110, 118, 129, 0.1);
				--gh-link-color: #58a6ff;
				--gh-heading-border: #21262d;
				--gh-quote-border: #8b949e;

				--glass-bg-base: rgba(13, 17, 23, 0.6);
				--glass-border: rgba(255, 255, 255, 0.1);
			}

			html, body {
				margin: 0;
				padding: 0;
				height: 100%;
				font-family: 'Inter', sans-serif;
				background-color: var(--gh-bg-color);
				color: var(--gh-text-color);
				overflow: hidden;
			}

			.background-texture {
				position: fixed;
				top: 0;
				left: 0;
				width: 100%;
				height: 100%;
				z-index: -1;
				background: linear-gradient(45deg, #0d1117 0%, #161b22 100%);
				opacity: 0.8;
			}

			.container {
				display: flex;
				height: 100vh;
				position: relative;
				z-index: 1;
			}

			.pane {
				width: 50%;
				height: 100%;
				box-sizing: border-box;
				overflow-y: auto;
				background-color: var(--glass-bg-base);
				border: 1px solid var(--glass-border);
				backdrop-filter: blur(10px);
				-webkit-backdrop-filter: blur(10px);
				border-radius: 8px;
				margin: 10px;
			}
			#editor {
				padding: 20px;
			}
			#preview {
				padding: 10px 20px;
				line-height: 1.6;
			}

			#editor {
				border: none;
				color: var(--gh-text-color);
				font-family: 'Fira Code', monospace;
				font-size: 16px;
				resize: none;
				outline: none;
			}

			#preview {
				line-height: 1.6;
			}

			#preview h1, #preview h2, #preview h3, #preview h4, #preview h5, #preview h6 {
				border-bottom: 1px solid var(--gh-heading-border);
				padding-bottom: 0.3em;
				margin-top: 1em;
				margin-bottom: 0.5em;
				color: var(--gh-text-color);
			}
			#preview h1 { font-size: 2em; }
			#preview h2 { font-size: 1.75em; }
			#preview h3 { font-size: 1.5em; }
			#preview h4 { font-size: 1.25em; }
			#preview h5 { font-size: 1em; }
			#preview h6 { font-size: 0.875em; color: var(--gh-text-color); }

			#preview > *:first-child {
				margin-top: 0;
			}

			#preview p { margin: 1em 0; }

			#preview code {
				background-color: var(--gh-code-bg);
				padding: 0.2em 0.4em;
				border-radius: 6px;
				font-family: 'Fira Code', monospace;
				font-size: 0.85em;
				color: var(--gh-text-color);
			}

			#preview pre {
				background-color: var(--gh-code-bg);
				padding: 1em;
				border-radius: 8px;
				overflow-x: auto;
				margin: 1em 0;
				border: 1px solid var(--gh-border-color);
			}
			#preview pre code {
				background-color: transparent;
				padding: 0;
				border-radius: 0;
				font-size: 1em;
			}

			#preview ul, #preview ol {
				padding-left: 2em;
				margin: 1em 0;
			}
			#preview li { margin-bottom: 0.5em; }
			#preview ul ul, #preview ol ol, #preview ul ol, #preview ol ul {
				margin-top: 0;
				margin-bottom: 0;
			}

			#preview hr {
				border: 0;
				border-top: 1px solid var(--gh-border-color);
				margin: 2em 0;
			}

			#preview blockquote {
				border-left: 0.25em solid var(--gh-quote-border);
				padding: 0 1em;
				margin: 1em 0;
				color: var(--gh-text-color);
			}

			#preview a {
				color: var(--gh-link-color);
				text-decoration: none;
			}
			#preview a:hover { text-decoration: underline; }

			#preview img {
				max-width: 100%;
				height: auto;
				display: block;
				margin: 1em 0;
				border-radius: 4px;
				border: 1px solid var(--gh-border-color);
			}

			#preview table {
				width: 100%;
				border-collapse: collapse;
				margin: 1em 0;
				border: 1px solid var(--gh-border-color);
			}
			#preview th, #preview td {
				border: 1px solid var(--gh-border-color);
				padding: 0.8em;
				text-align: left;
			}
			#preview th {
				background-color: var(--gh-code-bg);
				font-weight: 600;
			}

			#preview strong, #preview b { font-weight: 700; }
			#preview em, #preview i { font-style: italic; }

			#preview input[type="checkbox"] {
				margin-right: 0.5em;
			}
		</style>
	</head>
	<body>
		<div class="background-texture"></div> <!-- New background texture div -->
		<div class="container">
			<textarea id="editor" class="pane" placeholder="Type your Markdown here..."></textarea>
			<div id="preview" class="pane"></div>
		</div>
		<script>
			const editor = document.getElementById('editor');
			const preview = document.getElementById('preview');

			editor.addEventListener('keydown', (e) => {
				if (e.key === 'Tab') {
					e.preventDefault(); // Prevent default tab behavior (focusing next element)
					const start = editor.selectionStart;
					const end = editor.selectionEnd;

					// Insert two spaces for a tab
					editor.value = editor.value.substring(0, start) + '  ' + editor.value.substring(end);

					// Move cursor to the new position
					editor.selectionStart = editor.selectionEnd = start + 2;

					// Manually trigger input event to update preview
					editor.dispatchEvent(new Event('input'));
				}
			});

			editor.addEventListener('input', async () => {
				try {
					const htmlContent = await window.updateMarkdown(editor.value);
					preview.innerHTML = htmlContent;
				} catch (e) {
					console.error("Error updating preview:", e);
					preview.innerHTML = "<p style='color: #ef4444;'>Error processing Markdown.</p>";
				}
			});

			editor.value = "# Welcome to Ring Markdown!";
			
			editor.dispatchEvent(new Event('input'));
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

func handleMarkdownUpdate(id, req)
	req = json2list(req)[1]
	
	// Correctly parse the JSON request string into a Ring list
	cMarkdownText = req[1]

	// Convert Markdown to HTML using our library
	cRenderedHTML = oMarkdown.toHTML(cMarkdownText)
	crenderedHTML = escape_json_string(cRenderedHTML)

	// Return the generated HTML back to the JavaScript promise.
	cJsonResult = '"' + crenderedHTML + '"'
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResult)

# Helper to escape strings for JSON transport
func escape_json_string(cText)
	cText = substr(cText, "\\", "") 
	cText = substr(cText, '"', "")
	cText = substr(cText, nl, "\n")
	cText = substr(cText, char(13), "\r")
	cText = substr(cText, char(9), "\t")
	cText = substr(cText, char(8), "\b")
	cText = substr(cText, char(12), "\f")
	return cText