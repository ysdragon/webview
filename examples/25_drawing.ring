# Drawing example with Undo/Redo

load "webview.ring"
load "jsonlib.ring"

# --- Global State ---
oWebView = NULL

# Bind Ring functions to be callable from JavaScript.
aBindList = [
	["addStroke", :handleAddStroke],
	["undoStroke", :handleUndoStroke],
	["redoStroke", :handleRedoStroke],
	["clearCanvas", :handleClearCanvas],
	["getDrawingHistory", :handleGetDrawingHistory]
]

aDrawingHistory = []
nCurrentHistoryIndex = -1

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring Drawing App with Undo/Redo")
	# Set the window size (no size constraint).
	oWebView.setSize(800, 650, WEBVIEW_HINT_NONE)

	# Load the HTML content for the drawing application UI.
	loadDrawingHTML()

	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	# Destroy the webview instance.
	oWebView.destroy()

	see "Drawing application closed." + nl

# Defines the HTML structure and inline JavaScript for the drawing application.
func loadDrawingHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Drawing App with Undo/Redo</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap");
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
				height: 100vh;
				overflow: hidden;
				position: relative;
				display: flex;
				flex-direction: column;
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

			.drawing-container {
				display: flex;
				flex-direction: column;
				align-items: center;
				background-color: var(--panel-bg);
				padding: 20px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			canvas {
				border: 1px solid var(--border-color);
				background-color: rgba(255, 255, 255, 0.05); /* Slightly transparent background for canvas */
				cursor: crosshair;
				border-radius: 10px;
				margin-bottom: 20px;
			}
			.controls {
				display: flex;
				flex-wrap: wrap;
				justify-content: center;
				gap: 10px;
			}
			.controls input[type="color"] {
				width: 40px;
				height: 40px;
				border: 2px solid var(--border-color);
				padding: 0;
				cursor: pointer;
				border-radius: 8px;
				overflow: hidden;
			}
			.controls input[type="range"] {
				width: 120px;
				cursor: pointer;
				accent-color: var(--accent-blue);
			}
			.controls button {
				padding: 10px 15px;
				border: none;
				border-radius: 8px;
				background-color: var(--accent-blue);
				color: white;
				cursor: pointer;
				font-size: 1em;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			.controls button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			.controls button:disabled {
				opacity: 0.4;
				cursor: not-allowed;
				transform: none;
				box-shadow: none;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="drawing-container">
			<canvas id="drawingCanvas" width="700" height="500"></canvas>
			<div class="controls">
				Line Color: <input type="color" id="colorPicker" value="#FFFFFF">
				Line Width: <input type="range" id="lineWidth" min="1" max="10" value="2">
				<button id="undoBtn" onclick="undo()"><i class="fa-solid fa-rotate-left"></i> Undo</button>
				<button id="redoBtn" onclick="redo()"><i class="fa-solid fa-rotate-right"></i> Redo</button>
				<button id="clearBtn" onclick="clearAll()"><i class="fa-solid fa-eraser"></i> Clear</button>
			</div>
		</div>

		<script>
			const canvas = document.getElementById("drawingCanvas");
			const ctx = canvas.getContext("2d");
			const colorPicker = document.getElementById("colorPicker");
			const lineWidthControl = document.getElementById("lineWidth");
			const undoBtn = document.getElementById("undoBtn");
			const redoBtn = document.getElementById("redoBtn");
			const clearBtn = document.getElementById("clearBtn");

			let isDrawing = false;
			let lastX = 0;
			let lastY = 0;

			// Function to redraw the entire canvas from history
			function redrawCanvas(history) {
				ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear everything
				history.forEach(stroke => {
					ctx.strokeStyle = stroke.color;
					ctx.lineWidth = stroke.width;
					ctx.lineCap = "round";
					ctx.beginPath();
					ctx.moveTo(stroke.points[0].x, stroke.points[0].y);
					for (let i = 1; i < stroke.points.length; i++) {
						ctx.lineTo(stroke.points[i].x, stroke.points[i].y);
					}
					ctx.stroke();
				});
			}

			// Function to update UI buttons based on history state
			function updateButtonStates(canUndo, canRedo) {
				undoBtn.disabled = !canUndo;
				redoBtn.disabled = !canRedo;
				clearBtn.disabled = !canUndo; // Can only clear if there"s something to undo
			}

			canvas.addEventListener("mousedown", (e) => {
				isDrawing = true;
				[lastX, lastY] = [e.offsetX, e.offsetY];
				ctx.strokeStyle = colorPicker.value;
				ctx.lineWidth = lineWidthControl.value;
				ctx.lineCap = "round";
				ctx.beginPath();
				ctx.moveTo(lastX, lastY);
				currentStroke = { color: colorPicker.value, width: lineWidthControl.value, points: [{ x: lastX, y: lastY }] };
			});

			canvas.addEventListener("mousemove", (e) => {
				if (!isDrawing) return;
				ctx.lineTo(e.offsetX, e.offsetY);
				ctx.stroke();
				currentStroke.points.push({ x: e.offsetX, y: e.offsetY });
			});

			canvas.addEventListener("mouseup", async () => {
				isDrawing = false;
				if (currentStroke && currentStroke.points.length > 1) { // Only add if it"s an actual stroke
					await window.addStroke(JSON.stringify(currentStroke));
					currentStroke = null;
				}
			});

			canvas.addEventListener("mouseout", () => {
				if (isDrawing && currentStroke && currentStroke.points.length > 1) {
					window.addStroke(JSON.stringify(currentStroke));
				}
				isDrawing = false;
				currentStroke = null;
			});

			async function undo() {
				await window.undoStroke();
			}

			async function redo() {
				await window.redoStroke();
			}

			async function clearAll() {
				await window.clearCanvas();
			}

			// Function called by Ring to update the canvas and buttons
			function updateDrawingUI(history, canUndo, canRedo) {
				redrawCanvas(history);
				updateButtonStates(canUndo, canRedo);
			}

			window.onload = async () => {
				const initialData = await window.getDrawingHistory();
				updateDrawingUI(initialData.history, initialData.canUndo, initialData.canRedo);
			};
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers (Bound to JavaScript) ---

func handleAddStroke(id, req)
	cStrokeJson = json2list(req)[1][1]
	aStroke = json2list(cStrokeJson)
	if nCurrentHistoryIndex < len(aDrawingHistory) - 1
		aNewHistory = []
		for i = 1 to nCurrentHistoryIndex + 1
			add(aNewHistory, aDrawingHistory[i])
		next
		aDrawingHistory = aNewHistory
	ok
	add(aDrawingHistory, aStroke)
	nCurrentHistoryIndex = len(aDrawingHistory) - 1
	see "Ring: Added stroke. Total history size: " + len(aDrawingHistory) + nl
	updateDrawingUI()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleUndoStroke(id, req)
	see "Ring: Undo stroke requested." + nl
	if nCurrentHistoryIndex >= 0
		nCurrentHistoryIndex--
	ok
	updateDrawingUI()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleRedoStroke(id, req)
	see "Ring: Redo stroke requested." + nl
	if nCurrentHistoryIndex < len(aDrawingHistory) - 1
		nCurrentHistoryIndex++
	ok
	updateDrawingUI()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleClearCanvas(id, req)
	see "Ring: Clear canvas requested." + nl
	aDrawingHistory = []
	nCurrentHistoryIndex = -1
	updateDrawingUI()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleGetDrawingHistory(id, req)
	see "Ring: JavaScript requested drawing history." + nl
	aCurrentHistory = []
	if len(aDrawingHistory) > 0 and nCurrentHistoryIndex >= 0
		for i = 1 to nCurrentHistoryIndex + 1
			add(aCurrentHistory, aDrawingHistory[i])
		next
	ok
	bCanUndo = nCurrentHistoryIndex >= 0
	bCanRedo = nCurrentHistoryIndex < len(aDrawingHistory) - 1
	aResult = [
		:history = aCurrentHistory,
		:canUndo = bCanUndo,
		:canRedo = bCanRedo
	]
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aResult))

func updateDrawingUI()
	see "Ring: Pushing drawing update to UI." + nl
	aCurrentHistory = []
	if len(aDrawingHistory) > 0 and nCurrentHistoryIndex >= 0
		for i = 1 to nCurrentHistoryIndex + 1
			add(aCurrentHistory, aDrawingHistory[i])
		next
	ok
	bCanUndo = nCurrentHistoryIndex >= 0
	bCanRedo = nCurrentHistoryIndex < len(aDrawingHistory) - 1
	aHistoryList = []
	for aStroke in aCurrentHistory
		add(aHistoryList, [
			:color = aStroke[:color],
			:width = aStroke[:width],
			:points = aStroke[:points]
		])
	next
	cHistoryJson = list2json(aHistoryList)
	if left(cHistoryJson, 1) = "{"
		cHistoryJson = "[" + substr(cHistoryJson, 2, len(cHistoryJson)-2) + "]"
	ok
	cJsCode = "updateDrawingUI(" + cHistoryJson + ", " + string(bCanUndo) + ", " + string(bCanRedo) + ");"
	oWebView.evalJS(cJsCode)
