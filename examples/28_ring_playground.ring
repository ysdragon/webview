# Ring Playground App

load "webview.ring"
load "jsonlib.ring"

# Global variable to hold the webview instance.
oWebView = NULL

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
	<!-- CodeMirror CSS -->
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.15/codemirror.min.css">
	<link rel="stylesheet"
		href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.15/theme/material-darker.min.css">
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

		.CodeMirror {
			flex-grow: 1;
			font-size: 15px;
			height: auto;
			background-color: transparent !important;
			font-family: 'Fira Code', monospace;
		}

		.CodeMirror-gutters {
			background-color: rgba(0, 0, 0, 0.1) !important;
			border-right: 1px solid var(--border-color) !important;
		}

		.cm-s-material-darker.CodeMirror {
			background-color: transparent;
		}

		.CodeMirror-lines {
			padding: 10px 0;
		}

		.CodeMirror-scroll {}

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
				<textarea id="editor"></textarea>
			</div>
			<div class="panel">
				<div class="panel-header">Output</div>
				<pre id="output">Welcome to the Ring Playground! Press the "Run" button to execute your code.</pre>
			</div>
		</div>
	</div>

	<!-- CodeMirror JS -->
	<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.15/codemirror.min.js"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.15/addon/mode/simple.min.js"></script>
	<script>
		// Custom Ring syntax mode for CodeMirror
		(function (mod) {
			if (typeof exports == "object" && typeof module == "object")
				mod(require("../../lib/codemirror"));
			else if (typeof define == "function" && define.amd)
				define(["../../lib/codemirror"], mod);
			else
				mod(CodeMirror);
		})(function (CodeMirror) {
			"use strict";

			CodeMirror.defineMode("ring", function () {
				var keywords = (function () {
					function kw(type) {
						return { type: type, style: "keyword" };
					}
					var A = kw("keyword a"), B = kw("keyword b"), C = kw("keyword c");
					var operator = kw("operator"), atom = { type: "atom", style: "atom" };

					return {
						"if": A, "to": operator, "or": operator, "and": operator, "not": operator, "for": A,
						"new": A, "func": A, "from": A, "next": A, "load": A, "else": B, "see": A,
						"while": A, "ok": B, "class": A, "return": C, "but": B, "end": B, "give": A,
						"bye": A, "exit": C, "try": A, "catch": B, "done": B, "switch": A, "on": B,
						"other": B, "off": B, "in": operator, "loop": C, "package": A, "import": A,
						"private": kw("modifier"), "step": operator, "do": A, "again": B, "call": A,
						"elseif": B, "put": A, "get": A, "case": B, "def": A, "endfunc": B,
						"endclass": B, "endpackage": B, "endif": B, "endfor": B, "endwhile": B,
						"endswitch": B, "endtry": B, "function": A, "endfunction": B, "break": C,
						"continue": C, "true": atom, "false": atom, "nl": atom, "null": atom,
						"self": kw("self"), "this": kw("self"), "super": kw("self")
					};
				}());

				var isOperatorChar = /[+\-*\/%&|^~=<>!?:.]/;

				function tokenBase(stream, state) {
					var ch = stream.next();
					if (ch == "#" || (ch == "/" && stream.eat("/"))) {
						stream.skipToEnd();
						return "comment";
					}
					if (ch == "/" && stream.eat("*")) {
						state.tokenize = tokenComment;
						return tokenComment(stream, state);
					}
					if (ch == '"' || ch == "'") {
						state.tokenize = tokenString(ch);
						return state.tokenize(stream, state);
					}
					if (ch == ":" && /[A-Za-z_]/.test(stream.peek())) {
						stream.eatWhile(/[A-Za-z_0-9]/);
						return "string-2";
					}
					if (/[\[\]{}\(\),;\.]/.test(ch)) {
						return "bracket";
					}
					if (/\d/.test(ch)) {
						stream.eatWhile(/[\w\.]/);
						return "number";
					}
					if (isOperatorChar.test(ch)) {
						stream.eatWhile(isOperatorChar);
						return "operator";
					}
					stream.eatWhile(/[\w\$_]/);
					var word = stream.current().toLowerCase();
					if (keywords.propertyIsEnumerable(word)) {
						var keyword = keywords[word];
						return keyword.style;
					}
					return "variable";
				}

				function tokenString(quote) {
					return function (stream, state) {
						var escaped = false, next, end = false;
						while ((next = stream.next()) != null) {
							if (next == quote && !escaped) {
								end = true;
								break;
							}
							escaped = !escaped && next == "\\";
						}
						if (end) state.tokenize = tokenBase;
						return "string";
					};
				}

				function tokenComment(stream, state) {
					var maybeEnd = false, ch;
					while (ch = stream.next()) {
						if (ch == "/" && maybeEnd) {
							state.tokenize = tokenBase;
							break;
						}
						maybeEnd = (ch == "*");
					}
					return "comment";
				}

				return {
					startState: function () {
						return { tokenize: tokenBase };
					},
					token: function (stream, state) {
						if (stream.eatSpace()) return null;
						return state.tokenize(stream, state);
					},
					blockCommentStart: "/*",
					blockCommentEnd: "*/",
					lineComment: ["#", "//"],
				};
			});
		});

		const editor = CodeMirror.fromTextArea(document.getElementById('editor'), {
			lineNumbers: true,
			theme: 'material-darker',
			mode: 'ring',
			autofocus: true
		});
		editor.setValue('see "Hello from the Playground!" + nl\n\nfor x = 1 to 5\n    see "This is line " + x + nl\nnext');

		const runBtn = document.getElementById('run-btn');
		const clearBtn = document.getElementById('clear-btn');
		const outputEl = document.getElementById('output');

		async function runCode() {
			const code = editor.getValue();
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
		editor.setOption("extraKeys", {
			"Ctrl-Enter": runCode,
			"Cmd-Enter": runCode
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