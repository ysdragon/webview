# File Explorer Example
# This example demonstrates how to build a simple file explorer using Ring WebView.
# It allows browsing the file system, navigating into directories, and going back up.

load "webview.ring"
load "jsonlib.ring"

# Global Variables
oWebView = NULL

# Bind Ring functions to be callable from JavaScript.
aBindList = [
	["getInitialPath", :handleGetInitialPath],
	["getDirectoryContents", :handleGetDirectoryContents],
	["openFile", :handleOpenFile]
]

# Main Function
func main()
	see "Setting up File Explorer Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set the window title.
		setTitle("Ring File Explorer")
		# Set the window size (no size constraint).
		setSize(800, 600, WEBVIEW_HINT_NONE)

		# Load the HTML content for the file explorer UI.
		loadExplorerHTML()
		
		# Run the webview's main event loop. This is a blocking call.
		run()
	}

# Defines the HTML structure and inline JavaScript for the file explorer.
func loadExplorerHTML()
	cHTML = '<!DOCTYPE html>
<html>

<head>
	<title>File Explorer</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
	<link rel="stylesheet"
		href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fira+Code:wght@400;500;600&display=swap">
	<style>
		:root {
			--bg-primary: #0f172a;
			--bg-secondary: #1e293b;
			--card-bg: rgba(15, 23, 42, 0.8);
			--card-border: rgba(148, 163, 184, 0.1);
			--text-primary: #f1f5f9;
			--text-secondary: #94a3b8;
			--text-muted: #64748b;
			--accent-primary: #3b82f6;
			--accent-secondary: #8b5cf6;
			--accent-success: #10b981;
			--accent-warning: #f59e0b;
			--accent-danger: #ef4444;
			--accent-cyan: #06b6d4;
			--shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
			--blur-sm: 4px;
			--blur-md: 12px;
			--blur-lg: 16px;
		}

		body {
			font-family: "Inter", sans-serif;
			background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
			color: var(--text-primary);
			margin: 0;
			height: 100vh;
			overflow: hidden;
			display: flex;
			flex-direction: column;
			position: relative;
		}

		.container {
			display: flex;
			flex-direction: column;
			height: 100%;
			padding: 15px;
			box-sizing: border-box;
		}

		.header {
			display: flex;
			align-items: center;
			background: var(--card-bg);
			border: 1px solid var(--card-border);
			border-radius: 16px;
			padding: 1rem;
			margin-bottom: 1rem;
			flex-shrink: 0;

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
				filter: blur(120px);
				opacity: 0.4;
			}

			.aurora-shape1 {
				position: absolute;
				width: 60vw;
				height: 60vh;
				background: radial-gradient(ellipse at center, rgba(59, 130, 246, 0.3) 0%, rgba(139, 92, 246, 0.2) 40%, transparent 70%);
				top: -10%;
				left: -15%;
				animation: aurora-drift 20s ease-in-out infinite;
			}

			.aurora-shape2 {
				position: absolute;
				width: 50vw;
				height: 50vh;
				background: radial-gradient(ellipse at center, rgba(6, 182, 212, 0.25) 0%, rgba(16, 185, 129, 0.15) 50%, transparent 70%);
				bottom: -10%;
				right: -15%;
				animation: aurora-drift 25s ease-in-out infinite reverse;
			}

			@keyframes aurora-drift {

				0%,
				100% {
					transform: translate(0, 0) rotate(0deg) scale(1);
				}

				25% {
					transform: translate(10px, -15px) rotate(1deg) scale(1.05);
				}

				50% {
					transform: translate(-5px, 10px) rotate(-0.5deg) scale(0.95);
				}

				75% {
					transform: translate(-15px, -5px) rotate(0.5deg) scale(1.02);
				}
			}
		}

		#back-btn {
			background: none;
			border: 1px solid var(--card-border);
			color: var(--text-primary);
			font-size: 1.2em;
			cursor: pointer;
			padding: 0.5rem 0.75rem;
			border-radius: 10px;
			margin-right: 1rem;
			transition: all 0.2s;
		}

		#back-btn:hover:not(:disabled) {
			background: rgba(59, 130, 246, 0.1);
			border-color: var(--accent-primary);
			transform: translateY(-2px);
		}

		#back-btn:disabled {
			color: var(--text-muted);
			cursor: not-allowed;
			opacity: 0.6;
		}

		#current-path {
			background-color: rgba(148, 163, 184, 0.05);
			border: 1px solid var(--card-border);
			border-radius: 10px;
			padding: 0.75rem 1rem;
			flex-grow: 1;
			font-family: "Fira Code", monospace;
			font-size: 0.9em;
			white-space: nowrap;
			overflow-x: auto;
			color: var(--text-primary);
			outline: none;
			transition: all 0.2s;
		}

		#current-path:focus {
			border-color: var(--accent-primary);
			box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
			background: rgba(59, 130, 246, 0.05);
		}

		.file-list-container {
			flex-grow: 1;
			background: var(--card-bg);
			border: 1px solid var(--card-border);
			border-radius: 16px;
			overflow-y: auto;
			padding: 0.5rem;
		}

		#file-list {
			list-style: none;
			padding: 0;
			margin: 0;
		}

		.file-item {
			display: flex;
			align-items: center;
			padding: 0.75rem 1rem;
			border-bottom: 1px solid var(--card-border);
			cursor: pointer;
			transition: all 0.2s;
			border-radius: 10px;
			margin: 0.25rem;
		}

		.file-item:last-child {
			border-bottom: none;
		}

		.file-item:hover {
			background: rgba(59, 130, 246, 0.1);
			border-color: rgba(59, 130, 246, 0.3);
			transform: translateY(-2px);
			box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
		}

		.file-item i {
			margin-right: 15px;
			width: 20px;
			text-align: center;
			color: var(--text-secondary);
		}

		.file-item .fa-folder {
			color: var(--accent-primary);
		}

		.file-item .fa-file-image {
			color: #d8a8ff;
		}

		.file-item .fa-file-zipper {
			color: #facc15;
		}

		.file-item .fa-file-pdf {
			color: var(--accent-danger);
		}

		.file-item .fa-file-word {
			color: var(--accent-primary);
		}

		.file-item .fa-file-excel {
			color: var(--accent-success);
		}

		.file-item .fa-file-powerpoint {
			color: #fb923c;
		}

		.file-item .fa-file-code {
			color: var(--accent-cyan);
		}

		.file-item .fa-ring {
			color: #58a6ff;
		}

		.file-item .fa-file-markdown {
			color: #f1f5f9;
		}

		.file-item .fa-file-audio {
			color: #a78bfa;
		}

		.file-item .fa-file-video {
			color: #f472b6;
		}

		.file-item .fa-file,
		.file-item .fa-file-lines {
			color: var(--text-secondary);
		}

		.file-name {
			flex-grow: 1;
		}

		.file-size {
			font-family: "Fira Code", monospace;
			color: var(--text-muted);
			font-size: 0.85em;
		}

		::-webkit-scrollbar {
			width: 12px;
			height: 12px;
		}

		::-webkit-scrollbar-track {
			background: var(--card-bg);
			border-radius: 10px;
		}

		::-webkit-scrollbar-thumb {
			background: var(--card-border);
			border-radius: 10px;
			border: 2px solid var(--card-bg);
		}

		::-webkit-scrollbar-thumb:hover {
			background: var(--accent-primary);
		}

		* {
			scrollbar-width: thin;
			scrollbar-color: var(--card-border) var(--card-bg);
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
	<div class="container">
		<div class="header">
			<button id="back-btn" disabled><i class="fa-solid fa-arrow-left"></i></button>
			<input type="text" id="current-path" value="Loading...">
		</div>
		<div class="file-list-container">
			<ul id="file-list">
				<!-- File items will be rendered here -->
			</ul>
		</div>
	</div>

	<script>
		const currentPathDiv = document.getElementById("current-path");
		const fileListUl = document.getElementById("file-list");
		const backBtn = document.getElementById("back-btn");
		let pathHistory = [];

		async function navigateTo(path) {
			try {
				const contents = await window.getDirectoryContents(path);
				if (contents) {
					if (pathHistory[pathHistory.length - 1] !== contents.path) {
						pathHistory.push(contents.path);
					}
					render(contents);
				}
			} catch (e) {
				alert("Error navigating to path: " + path);
				console.error(e);
			}
		}

		function goBack() {
			if (pathHistory.length > 1) {
				pathHistory.pop();
				navigateTo(pathHistory[pathHistory.length - 1]);
			}
		}

		function render(data) {
			currentPathDiv.value = data.path;
			fileListUl.innerHTML = "";

			data.items.sort((a, b) => {
				if (a.is_dir && !b.is_dir) return -1;
				if (!a.is_dir && b.is_dir) return 1;
				return a.name.localeCompare(b.name);
			}).forEach(item => {
				const li = document.createElement("li");
				li.className = "file-item";
				li.onclick = () => {
					if (item.is_dir) {
						let newPath;
						if (item.name === "..") {
							let parentPath = data.path.substring(0, data.path.lastIndexOf("/"));
							if (parentPath.endsWith(":") && parentPath.length === 2) {
								parentPath += "/";
							}
							newPath = parentPath || "/";
						} else {
							newPath = data.path + (data.path.endsWith("/") ? "" : "/") + item.name;
						}
						navigateTo(newPath);
					} else {
						window.openFile(data.path + (data.path.endsWith("/") ? "" : "/") + item.name);
					}
				};

				const iconClass = item.is_dir ? "fa-folder" : getFileIconClass(item.name);
				li.innerHTML = `
						<i class="fa-solid ${iconClass}"></i>
						<span class="file-name">${item.name}</span>
						<span class="file-size">${item.is_dir ? "" : formatBytes(item.size)}</span>
					`;
				fileListUl.appendChild(li);
			});

			backBtn.disabled = pathHistory.length <= 1;
		}

		function getFileIconClass(filename) {
			const extension = filename.split(".").pop().toLowerCase();
			if (filename.endsWith(".")) return "fa-file";

			const iconMap = {
				"jpg": "fa-file-image", "jpeg": "fa-file-image", "png": "fa-file-image", "gif": "fa-file-image", "bmp": "fa-file-image", "svg": "fa-file-image",
				"zip": "fa-file-zipper", "rar": "fa-file-zipper", "7z": "fa-file-zipper", "tar": "fa-file-zipper", "gz": "fa-file-zipper",
				"pdf": "fa-file-pdf", "doc": "fa-file-word", "docx": "fa-file-word", "xls": "fa-file-excel", "xlsx": "fa-file-excel", "ppt": "fa-file-powerpoint", "pptx": "fa-file-powerpoint", "txt": "fa-file-lines",
				"ring": "fa-ring", "html": "fa-file-code", "css": "fa-file-code", "js": "fa-file-code", "json": "fa-file-code", "xml": "fa-file-code",
				"c": "fa-file-code", "cpp": "fa-file-code", "h": "fa-file-code", "py": "fa-file-code", "java": "fa-file-code", "sh": "fa-file-code", "md": "fa-brands fa-markdown",
				"mp3": "fa-file-audio", "wav": "fa-file-audio", "mp4": "fa-file-video", "mov": "fa-file-video", "avi": "fa-file-video"
			};

			return iconMap[extension] || "fa-file";
		}

		function formatBytes(bytes, decimals = 2) {
			if (bytes === 0) return "0 Bytes";
			const k = 1024;
			const dm = decimals < 0 ? 0 : decimals;
			const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
			const i = Math.floor(Math.log(bytes) / Math.log(k));
			return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
		}

		backBtn.addEventListener("click", goBack);

		window.onload = async () => {
			try {
				const initialPath = await window.getInitialPath();
				navigateTo(initialPath);
			} catch (e) {
				console.error("Error getting initial path:", e);
				currentPathDiv.value = "Error loading initial path.";
			}

			currentPathDiv.addEventListener("keydown", (e) => {
				if (e.key === "Enter") {
					navigateTo(e.target.value);
				}
			});
		};
	</script>
</body>

</html>'

	oWebView.setHtml(cHTML)

# Ring Callback Handlers (Bound to JavaScript)

# Returns the initial path to display (the current working directory)
func handleGetInitialPath(id, req)
	see "Ring: JavaScript requested initial path." + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + normalizePath(currentdir()) + '"')

# Gets the contents of a specified directory path.
func handleGetDirectoryContents(id, req)
	cPath = json2list(req)[1][1]
	see "Ring: JavaScript requested contents for path: " + cPath + nl

	if not direxists(cPath)
		oWebView.wreturn(id, WEBVIEW_ERROR_INVALID_ARGUMENT, '"Directory not found"')
		return
	ok

	aItems = []
	aFiles = dir(cPath)

	# Add a ".." entry to go up, unless we are at the root
	if cPath != "/" and (len(cPath) > 3 or (len(cPath) = 3 and cPath[2] != ":"))
		add(aItems, [
			:name = "..",
			:is_dir = true,
			:size = 0
		])
	ok

	# Process files and directories
	for cItem in aFiles
		cFullPath = cPath + "/" + cItem[1]
		if cItem[1] != "." and cItem[1] != ".."
			if cItem[2] = 1
				aItems + [
					:name = cItem[1],
					:is_dir = true,
					:size = 0
				]
			else
				aItems + [
					:name = cItem[1],
					:is_dir = false,
					:size = getfilesize(cFullPath)
				]
			ok
		ok
	next

	aResult = [
		:path = normalizePath(cPath),
		:items = aItems
	]

	cJson = list2json(aResult)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson)

# Handles opening a file.
func handleOpenFile(id, req)
	cPath = json2list(req)[1][1]
	see "Ring: JavaScript requested to open file: " + cPath + nl

	if fexists(cPath)
		if isLinux() or isFreeBSD()
			system('xdg-open "' + cPath + '"')
		but isWindows()
			system('start "" "' + cPath + '"')
		but isMacOSX()
			system('open "' + cPath + '"')
		ok
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, NULL)
	else
		oWebView.wreturn(id, WEBVIEW_ERROR_INVALID_ARGUMENT, '"File not found"')
	ok
	
# Utility function to normalize paths (convert backslashes to slashes)
func normalizePath(cPath)
	return substr(cPath, "\", "/")