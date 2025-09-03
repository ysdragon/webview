# Ring Playground App

load "webview.ring"
load "jsonlib.ring"

# Global variable to hold the webview instance.
oWebView = NULL

# Ring definition for syntax highlighting
cRingDefinition = NULL
try
	cRingDefinition = read("assets/ring.js")
catch
	cRingDefinition = "function ring(hljs) { return { name: 'Ring', keywords: { keyword: ['if', 'for', 'while', 'func', 'class', 'return'] } }; }"
done

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set the title of the webview window.
		setTitle("Ring Playground")
		# Set the size of the webview window (no size constraint).
		setSize(1100, 800, WEBVIEW_HINT_NONE)

		# Bind the `executeCode` function to be callable from JavaScript.
		# This function will receive the user's Ring code for execution.
		bind("executeCode", :handleExecuteCode)

		# Load the HTML content for the playground UI.
		load_html()

		# Run the webview's main event loop. This is a blocking call.
		run()
	}

# Defines the HTML structure.
func load_html()
	cHTML = `
<!DOCTYPE html>
<html lang="en">

<head>
	<meta charset="UTF-8">
	<title>Ring Playground</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<!-- Highlight.js CSS -->
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
	<!-- Font Awesome for icons -->
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
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
			font-family: 'Inter', sans-serif;
			background-color: var(--bg-color);
			color: var(--text-primary);
			margin: 0;
			height: 100vh;
			overflow: hidden;
			position: relative;
		}

		.background-container {
			position: fixed;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			z-index: -1;
			overflow: hidden;
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

		.layout {
			display: flex;
			flex-direction: column;
			height: 100vh;
			padding: 20px;
			box-sizing: border-box;
			position: relative;
			z-index: 1;
		}

		.toolbar {
			display: flex;
			align-items: center;
			justify-content: space-between;
			padding: 15px 25px;
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			border-radius: 15px;
			margin-bottom: 25px;
			flex-shrink: 0;
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			box-shadow: 0 8px 30px rgba(0, 0, 0, 0.3);
		}

		.toolbar h1 {
			font-size: 1.5em;
			margin: 0;
			color: var(--text-primary);
		}

		.toolbar h1 i {
			color: var(--accent-cyan);
			margin-right: 0.5em;
		}

		.toolbar .buttons {
			display: flex;
			gap: 15px;
		}

		.btn {
			display: flex;
			align-items: center;
			gap: 8px;
			padding: 0.9em 1.2em;
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			border-radius: 10px;
			color: var(--text-primary);
			font-size: 1em;
			font-weight: 500;
			cursor: pointer;
			transition: all 0.2s ease-in-out;
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
		}

		.btn:hover {
			transform: scale(1.03);
			color: var(--accent-cyan);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
		}

		.btn.clear {
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			color: var(--text-secondary);
		}

		.btn.clear:hover {
			background-color: var(--panel-bg);
			color: var(--text-primary);
			transform: scale(1.03);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
		}

		.btn.loading {
			background-color: #6b7280;
			cursor: not-allowed;
			transform: none;
			box-shadow: none;
			opacity: 0.8;
		}

		.panels {
			display: flex;
			flex-grow: 1;
			gap: 25px;
			height: calc(100% - 119px);
		}

		.panel {
			width: 50%;
			display: flex;
			flex-direction: column;
			background-color: var(--panel-bg);
			border: 1px solid var(--border-color);
			border-radius: 15px;
			overflow: hidden;
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
		}

		.panel-header {
			background-color: rgba(255, 255, 255, 0.1);
			padding: 12px 20px;
			font-weight: 600;
			color: var(--text-primary);
			border-bottom: 1px solid var(--border-color);
			font-size: 1em;
		}

		.editor-container {
			position: relative;
			flex-grow: 1;
			overflow: hidden;
			border-radius: 0 0 15px 15px;
			display: flex;
		}

		.line-numbers {
			padding: 15px 6px 15px 10px;
			font-family: 'Fira Code', monospace;
			font-size: 15px;
			line-height: 1.5;
			color: var(--text-secondary);
			background-color: rgba(255, 255, 255, 0.03);
			border-right: 1px solid var(--border-color);
			user-select: none;
			pointer-events: none;
			white-space: pre;
			text-align: right;
			min-width: 20px;
			max-height: 100%;
			overflow: hidden;
			letter-spacing: 0;
			word-spacing: 0;
			margin: 0;
		}

		.editor-content {
			position: relative;
			flex: 1;
			overflow: hidden;
		}

		#code-editor {
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			padding: 15px;
			font-family: 'Fira Code', monospace;
			font-size: 15px;
			line-height: 1.5;
			tab-size: 4;
			border: none;
			outline: none;
			resize: none;
			background: transparent;
			color: transparent;
			z-index: 2;
			white-space: pre-wrap;
			word-wrap: break-word;
			overflow-y: auto;
			caret-color: var(--accent-cyan);
			letter-spacing: 0;
			word-spacing: 0;
			margin: 0;
		}

		#highlighted-code {
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			padding: 15px;
			pointer-events: none;
			font-family: 'Fira Code', monospace;
			font-size: 15px;
			line-height: 1.5;
			tab-size: 4;
			white-space: pre-wrap;
			word-wrap: break-word;
			overflow: hidden;
			z-index: 1;
			margin: 0;
			letter-spacing: 0;
			word-spacing: 0;
		}

		.hljs {
			background: transparent !important;
			padding: 0 !important;
		}

		#output {
			flex-grow: 1;
			padding: 1.2em;
			margin: 0;
			overflow-y: auto;
			white-space: pre-wrap;
			font-family: 'Fira Code', monospace;
			color: var(--text-primary);
			font-size: 0.95em;
			line-height: 1.5;
			text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
		}

		#output.error {
			color: var(--accent-red);
		}

		::-webkit-scrollbar {
			width: 8px;
			height: 8px;
		}

		::-webkit-scrollbar-track {
			background: rgba(255, 255, 255, 0.05);
			border-radius: 10px;
		}

		::-webkit-scrollbar-thumb {
			background: linear-gradient(45deg, var(--accent-cyan), var(--accent-purple));
			border-radius: 10px;
			border: 1px solid rgba(255, 255, 255, 0.1);
			transition: all 0.3s ease;
		}

		::-webkit-scrollbar-thumb:hover {
			background: linear-gradient(45deg, var(--accent-blue), var(--accent-cyan));
			box-shadow: 0 0 10px rgba(59, 130, 246, 0.3);
		}

		::-webkit-scrollbar-corner {
			background: rgba(255, 255, 255, 0.05);
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

	<div class="layout">
		<div class="toolbar">
			<h1><i class="fa-solid fa-code"></i> Ring Playground</h1>
			<div class="buttons">
				<button id="clear-btn" class="btn clear"><i class="fa-solid fa-eraser"></i> Clear</button>
				<button id="run-btn" class="btn"><i class="fa-solid fa-play"></i> Run</button>
			</div>
		</div>
		<div class="panels">
			<div class="panel editor-panel">
				<div class="panel-header">Code Editor</div>
				<div class="editor-container">
					<div id="line-numbers" class="line-numbers"></div>
					<div class="editor-content">
						<pre id="highlighted-code"><code class="language-ring"></code></pre>
						<textarea id="code-editor" spellcheck="false"></textarea>
					</div>
				</div>
			</div>
			<div class="panel">
				<div class="panel-header">Output</div>
				<pre id="output">Welcome to the Ring Playground! Press the "Run" button to execute your code.</pre>
			</div>
		</div>
	</div>

	<!-- Highlight.js JS -->
	<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
	<script>` + cRingDefinition + `</script>
	<script>
		// Register Ring language with Highlight.js
		hljs.registerLanguage('ring', ring);

		const codeEditor = document.getElementById('code-editor');
		const highlightedCode = document.getElementById('highlighted-code').querySelector('code');
		const lineNumbers = document.getElementById('line-numbers');
		const runBtn = document.getElementById('run-btn');
		const clearBtn = document.getElementById('clear-btn');
		const outputEl = document.getElementById('output');

		// Initial code
		const initialCode = 'see "Hello from the Playground!" + nl\n\nfor x = 1 to 5\n    see "This is line " + x + nl\nnext';
		codeEditor.value = initialCode;

		// Update line numbers based on content
		function updateLineNumbers() {
			const lines = codeEditor.value.split('\n');
			const lineCount = lines.length;
			const numbers = [];
			
			for (let i = 1; i <= lineCount; i++) {
				numbers.push(i);
			}
			
			lineNumbers.textContent = numbers.join('\n');
		}

		function updateHighlighting() {
			highlightedCode.textContent = codeEditor.value;
			highlightedCode.removeAttribute('data-highlighted');
			hljs.highlightElement(highlightedCode);
			updateLineNumbers();
		}

		function syncScroll() {
			const container = highlightedCode.parentElement;
			container.scrollTop = codeEditor.scrollTop;
			container.scrollLeft = codeEditor.scrollLeft;
			
			lineNumbers.scrollTop = codeEditor.scrollTop;
		}

		codeEditor.addEventListener('input', updateHighlighting);
		codeEditor.addEventListener('scroll', syncScroll);

		updateHighlighting();

		async function runCode() {
			const code = codeEditor.value;
			if (!code.trim()) {
				outputEl.textContent = 'Code is empty.';
				return;
			}

			runBtn.disabled = true;
			runBtn.classList.add('loading');
			runBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Running...';
			outputEl.classList.remove('error');
			outputEl.textContent = 'Executing...';

			try {
				const result = await window.executeCode(code);
				outputEl.textContent = result.output;
				if (result.error) {
					outputEl.classList.add('error');
				}
			} catch (e) {
				outputEl.textContent = "Fatal Backend Error: " + e;
				outputEl.classList.add('error');
			} finally {
				runBtn.disabled = false;
				runBtn.classList.remove('loading');
				runBtn.innerHTML = '<i class="fa-solid fa-play"></i> Run';
			}
		}

		clearBtn.addEventListener('click', () => {
			outputEl.textContent = '';
			outputEl.classList.remove('error');
		});
		runBtn.addEventListener('click', runCode);

		codeEditor.addEventListener('keydown', (e) => {
			if (e.key === 'Tab') {
				e.preventDefault();
				
				const start = codeEditor.selectionStart;
				const end = codeEditor.selectionEnd;
				const value = codeEditor.value;
				
				if (start !== end) {
					const beforeSelection = value.substring(0, start);
					const selectedText = value.substring(start, end);
					const afterSelection = value.substring(end);
					
					const lastNewLineBeforeStart = beforeSelection.lastIndexOf('\n');
					const actualStart = lastNewLineBeforeStart === -1 ? 0 : lastNewLineBeforeStart + 1;
					
					const fullSelectedText = value.substring(actualStart, end);
					
					if (e.shiftKey) {
						const unindentedText = fullSelectedText.replace(/^(\t|    )/gm, '');
						const newValue = value.substring(0, actualStart) + unindentedText + afterSelection;
						codeEditor.value = newValue;
						codeEditor.setSelectionRange(actualStart, actualStart + unindentedText.length);
					} else {
						const indentedText = fullSelectedText.replace(/^/gm, '\t');
						const newValue = value.substring(0, actualStart) + indentedText + afterSelection;
						codeEditor.value = newValue;
						codeEditor.setSelectionRange(actualStart, actualStart + indentedText.length);
					}
				} else {
					const newValue = value.substring(0, start) + '\t' + value.substring(end);
					codeEditor.value = newValue;
					codeEditor.setSelectionRange(start + 1, start + 1);
				}
				
				updateHighlighting();
			}
			
			if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
				e.preventDefault();
				runCode();
			}
		});

	</script>
</body>

</html>
	`
	oWebView.setHtml(cHTML)

# Handles requests from JavaScript to execute Ring code.
func handleExecuteCode(id, req)
	cCode = json2list(req)[1][1]
	cTempFile = substr(tempname(), ".", "") + ".ring"
	cOutputFile = tempname()
	bHasError = false
	cOutput = ""

	write(cTempFile, cCode)
	cOutput = systemCmd("ring " + cTempFile)
	write(cOutputFile, cOutput)
	
	cOutput = substr(cOutput, nl, "\n")

	if fexists(cTempFile)
		remove(cTempFile)
	ok

	if fexists(cOutputFile)
		remove(cOutputFile)
	ok
	
	if substr(cOutput, "Error")
		bHasError = true
	ok
	
	aResult = [ :output = cOutput, :error = bHasError ]
	cJsonResult = list2json(aResult)
	cJsonResult = substr(cJsonResult, char(13), "")
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResult)