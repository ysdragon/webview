# Example 44: Custom Titlebar
# Demonstrates: setDecorated, window control (minimize, maximize, close), startDrag

load "webview.ring"

oWebView = NULL

aBindList = [
	["windowMinimize", :handleMinimize],
	["windowMaximize", :handleMaximize],
	["windowClose", :handleClose],
	["windowStartDrag", :handleStartDrag],
	["windowIsMaximized", :handleIsMaximized]
]

func main()
	see "=== Custom Titlebar Demo ===" + nl

	oWebView = new WebView()

	oWebView {
		setTitle("Custom Titlebar")
		setSize(900, 600, WEBVIEW_HINT_NONE)

		setDecorated(false)

		setHtml(`
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<style>
		* {
			margin: 0;
			padding: 0;
			box-sizing: border-box;
		}
		
		:root {
			--titlebar-height: 38px;
			--bg-color: #1a1a2e;
			--titlebar-bg: #16213e;
			--content-bg: #0f0f1a;
			--text-primary: #eee;
			--text-secondary: #888;
			--accent: #4a9eff;
			--btn-hover: rgba(255, 255, 255, 0.1);
			--btn-close-hover: #e81123;
		}
		
		html, body {
			height: 100%;
			overflow: hidden;
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
			background: var(--bg-color);
			color: var(--text-primary);
		}
		
		.window-container {
			display: flex;
			flex-direction: column;
			height: 100%;
			border: 1px solid rgba(255, 255, 255, 0.1);
			border-radius: 8px;
			overflow: hidden;
		}
		
		.titlebar {
			height: var(--titlebar-height);
			background: var(--titlebar-bg);
			display: flex;
			align-items: center;
			justify-content: space-between;
			user-select: none;
			-webkit-app-region: drag;
		}
		
		.titlebar-left {
			display: flex;
			align-items: center;
			padding-left: 12px;
			gap: 10px;
		}
		
		.app-icon {
			width: 18px;
			height: 18px;
			background: linear-gradient(135deg, var(--accent), #7c3aed);
			border-radius: 4px;
		}
		
		.app-title {
			font-size: 13px;
			font-weight: 500;
			color: var(--text-primary);
		}
		
		.titlebar-center {
			flex: 1;
			display: flex;
			justify-content: center;
		}
		
		.window-controls {
			display: flex;
			height: 100%;
			-webkit-app-region: no-drag;
		}
		
		.window-btn {
			width: 46px;
			height: 100%;
			border: none;
			background: transparent;
			color: var(--text-primary);
			font-size: 10px;
			cursor: pointer;
			display: flex;
			align-items: center;
			justify-content: center;
			transition: background 0.15s;
		}
		
		.window-btn:hover {
			background: var(--btn-hover);
		}
		
		.window-btn.close:hover {
			background: var(--btn-close-hover);
		}
		
		.window-btn svg {
			width: 10px;
			height: 10px;
			fill: none;
			stroke: currentColor;
			stroke-width: 1.5;
		}
		
		.content {
			flex: 1;
			background: var(--content-bg);
			overflow-y: auto;
			padding: 30px;
		}
		
		.hero {
			text-align: center;
			padding: 40px 20px;
			background: linear-gradient(135deg, rgba(74, 158, 255, 0.1), rgba(124, 58, 237, 0.1));
			border-radius: 16px;
			margin-bottom: 30px;
		}
		
		.hero h1 {
			font-size: 2.2em;
			margin-bottom: 10px;
			background: linear-gradient(90deg, var(--accent), #a855f7);
			-webkit-background-clip: text;
			-webkit-text-fill-color: transparent;
		}
		
		.hero p {
			color: var(--text-secondary);
			font-size: 1.1em;
		}
		
		.features {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
			gap: 20px;
			margin-bottom: 30px;
		}
		
		.feature-card {
			background: rgba(255, 255, 255, 0.03);
			border: 1px solid rgba(255, 255, 255, 0.08);
			border-radius: 12px;
			padding: 24px;
			transition: transform 0.2s, border-color 0.2s;
		}
		
		.feature-card:hover {
			transform: translateY(-2px);
			border-color: rgba(74, 158, 255, 0.3);
		}
		
		.feature-card h3 {
			color: var(--accent);
			margin-bottom: 8px;
			font-size: 1.1em;
		}
		
		.feature-card p {
			color: var(--text-secondary);
			font-size: 0.9em;
			line-height: 1.5;
		}
		
		.demo-section {
			background: rgba(255, 255, 255, 0.02);
			border-radius: 12px;
			padding: 24px;
			border: 1px solid rgba(255, 255, 255, 0.05);
		}
		
		.demo-section h2 {
			margin-bottom: 20px;
			font-size: 1.3em;
		}
		
		.btn-group {
			display: flex;
			flex-wrap: wrap;
			gap: 12px;
		}
		
		.btn {
			padding: 12px 24px;
			border: none;
			border-radius: 8px;
			font-size: 0.95em;
			cursor: pointer;
			transition: all 0.2s;
			font-weight: 500;
		}
		
		.btn-primary {
			background: var(--accent);
			color: white;
		}
		
		.btn-primary:hover {
			background: #3d8be8;
			transform: translateY(-1px);
		}
		
		.btn-secondary {
			background: rgba(255, 255, 255, 0.1);
			color: var(--text-primary);
		}
		
		.btn-secondary:hover {
			background: rgba(255, 255, 255, 0.15);
		}
		
		.btn-danger {
			background: #dc3545;
			color: white;
		}
		
		.btn-danger:hover {
			background: #c82333;
		}
		
		.status {
			margin-top: 20px;
			padding: 12px;
			background: rgba(0, 0, 0, 0.2);
			border-radius: 8px;
			font-family: monospace;
			font-size: 0.9em;
			color: var(--text-secondary);
		}
	</style>
</head>
<body>
	<div class="window-container">
		<div class="titlebar" onmousedown="startDrag(event)">
			<div class="titlebar-left">
				<div class="app-icon"></div>
				<span class="app-title">Ring WebView - Custom Titlebar</span>
			</div>
			<div class="titlebar-center"></div>
			<div class="window-controls">
				<button class="window-btn minimize" onclick="minimizeWindow()">
					<svg viewBox="0 0 10 10"><line x1="0" y1="5" x2="10" y2="5"/></svg>
				</button>
				<button class="window-btn maximize" onclick="maximizeWindow()">
					<svg viewBox="0 0 10 10" id="maxIcon"><rect x="0.5" y="0.5" width="9" height="9" rx="1"/></svg>
				</button>
				<button class="window-btn close" onclick="closeWindow()">
					<svg viewBox="0 0 10 10"><line x1="0" y1="0" x2="10" y2="10"/><line x1="10" y1="0" x2="0" y2="10"/></svg>
				</button>
			</div>
		</div>
		
		<div class="content">
			<div class="hero">
				<h1>Custom Titlebar Demo</h1>
				<p>A frameless window with a custom HTML/CSS titlebar</p>
			</div>
			
			<div class="features">
				<div class="feature-card">
					<h3>Frameless Window</h3>
					<p>Native window decorations are hidden, giving you full control over the window appearance.</p>
				</div>
				<div class="feature-card">
					<h3>Custom Controls</h3>
					<p>Minimize, maximize, and close buttons are implemented in HTML/CSS with Ring callbacks.</p>
				</div>
				<div class="feature-card">
					<h3>Draggable Titlebar</h3>
					<p>The titlebar supports window dragging via CSS app-region or native API calls.</p>
				</div>
				<div class="feature-card">
					<h3>Cross-Platform</h3>
					<p>Works on Windows, Linux, and macOS with platform-specific native APIs.</p>
				</div>
			</div>
			
			<div class="demo-section">
				<h2>Window Controls Demo</h2>
				<div class="btn-group">
					<button class="btn btn-primary" onclick="minimizeWindow()">Minimize</button>
					<button class="btn btn-primary" onclick="maximizeWindow()">Toggle Maximize</button>
					<button class="btn btn-secondary" onclick="checkMaximized()">Check State</button>
					<button class="btn btn-danger" onclick="closeWindow()">Close Window</button>
				</div>
				<div class="status" id="status">Window state: Normal</div>
			</div>
		</div>
	</div>

	<script>
		async function startDrag(e) {
			if (e.target.closest('.window-controls')) return;
			if (e.target.closest('button')) return;
			await window.windowStartDrag();
		}
		
		async function minimizeWindow() {
			await window.windowMinimize();
			document.getElementById('status').textContent = 'Window state: Minimized';
		}
		
		async function maximizeWindow() {
			const result = await window.windowMaximize();
			updateMaxIcon();
		}
		
		async function closeWindow() {
			await window.windowClose();
		}
		
		async function checkMaximized() {
			const isMax = await window.windowIsMaximized();
			document.getElementById('status').textContent = 
				'Window state: ' + (isMax ? 'Maximized' : 'Normal');
			updateMaxIconState(isMax);
		}
		
		function updateMaxIconState(isMaximized) {
			const icon = document.getElementById('maxIcon');
			if (isMaximized) {
				icon.innerHTML = '<rect x="2" y="0.5" width="7" height="7" rx="1"/><rect x="0.5" y="2.5" width="7" height="7" rx="1"/>';
			} else {
				icon.innerHTML = '<rect x="0.5" y="0.5" width="9" height="9" rx="1"/>';
			}
		}
		
		async function updateMaxIcon() {
			const isMax = await window.windowIsMaximized();
			document.getElementById('status').textContent = 
				'Window state: ' + (isMax ? 'Maximized' : 'Normal');
			updateMaxIconState(isMax);
		}
	</script>
</body>
</html>
		`)

		run()
	}

	see "Demo finished." + nl

func handleMinimize(id, req)
	oWebView.minimize()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleMaximize(id, req)
	if oWebView.isMaximized()
		oWebView.restore()
	else
		oWebView.maximize()
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleClose(id, req)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')
	oWebView.terminate()

func handleStartDrag(id, req)
	oWebView.startDrag()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleIsMaximized(id, req)
	nResult = oWebView.isMaximized()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, "" + nResult)
