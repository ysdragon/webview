/*
 * RingFetch - A system information dashboard using WebView and SysInfo (https://github.com/ysdragon/SysInfo).
 * This example demonstrates how to create a web-based dashboard
 * that fetches and displays system information.
*/
load "webview.ring"
load "SysInfo.ring"
load "jsonlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL
# Global variable to hold the SysInfo instance.
sys = new SysInfo

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set the title of the webview window.
		setTitle("RingFetch - System Information Dashboard")
		# Set the size of the webview window (no size constraint).
		setSize(800, 700, WEBVIEW_HINT_FIXED)

		# Bind Ring functions to be callable from JavaScript.
		# `getSystemData` will fetch and return system information.
		bind("getSystemData", :handleGetSystemData)

		# Load the HTML content for the dashboard UI.
		loadFetchHTML()

		# Run the webview's main event loop. This is a blocking call.
		run()

		# No need to manually destroy the webview instance,
		# as it will be automatically cleaned up when the run() method exits.
	}

# Defines the HTML structure and inline JavaScript for the RingFetch dashboard.
func loadFetchHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>RingFetch</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"%3E%3Ctext x="-5" y="90" font-size="90"%3E🚀%3C/text%3E%3C/svg%3E" type="image/svg+xml">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap");
			:root {
				--bg-color: #000000;
				--sidebar-bg: transparent;
				--tab-bg: rgba(30, 30, 32, 0.6);
				--tab-active-bg: rgba(59, 130, 246, 0.2);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
				--text-secondary: #a1a1aa;
				--accent-cyan: #22d3ee;
				--accent-purple: #c084fc;
				--accent-green: #4ade80;
				--accent-yellow: #facc15;
				--accent-red: #f87171;
				--sidebar-width: 20%; /* Changed to percentage for flexibility */
			}
			:root.light-mode {
				--bg-color: #f0f2f5;
				--sidebar-bg: #ffffff;
				--tab-bg: rgba(220, 222, 224, 0.6);
				--tab-active-bg: rgba(147, 197, 253, 0.2);
				--border-color: rgba(0, 0, 0, 0.1);
				--text-primary: #1a202c;
				--text-secondary: #4a5568;
				--accent-cyan: #06b6d4;
				--accent-purple: #9333ea;
				--accent-green: #10b981;
				--accent-yellow: #f59e0b;
				--accent-red: #ef4444;
				--light-gradient-start: rgba(240, 242, 245, 0.8);
				--light-gradient-end: rgba(255, 255, 255, 0.8);
			}
			:root.dark-mode {
				--dark-gradient-start: rgba(0, 0, 0, 0.8);
				--dark-gradient-end: rgba(20, 20, 25, 0.8);
			}
			body {
				font-family: "Inter", sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				margin: 0;
				min-height: 100vh;
				overflow-x: hidden;
				position: relative;
				transition: background-color 0.3s ease, color 0.3s ease;
			}
			.background-container {
				position: fixed; top: 0; left: 0; width: 100%; height: 100%;
				z-index: -1; overflow: hidden;
			}
			.aurora {
				position: relative; width: 100%; height: 100%;
				filter: blur(150px); opacity: 0.5;
				animation: aurora-move 20s infinite alternate;
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
			@keyframes aurora-move {
				0% { transform: translate(0, 0); }
				50% { transform: translate(5%, 5%); }
				100% { transform: translate(0, 0); }
			}
			
			.app-layout { display: flex; min-height: 100vh; }
			.sidebar {
				/* width: var(--sidebar-width); Removed fixed width for flexibility */
				background: linear-gradient(to bottom, var(--sidebar-bg), var(--sidebar-bg)),
							linear-gradient(to bottom, var(--dark-gradient-start, rgba(0,0,0,0.8)), var(--dark-gradient-end, rgba(20,20,25,0.8)));
				background-blend-mode: overlay;
				padding: 1.5em;
				flex-shrink: 0;
				display: flex;
				flex-direction: column;
				box-sizing: border-box;
				border-right: 1px solid var(--border-color);
			}
			.light-mode .sidebar {
				background: linear-gradient(to bottom, var(--light-gradient-start), var(--light-gradient-end));
			}
			.sidebar-header {
				padding: 0 0.5em; margin-bottom: 2em;
				display: flex; align-items: center; gap: 0.75em;
			}
			.sidebar-header i { font-size: 1.8em; color: var(--accent-cyan); }
			.sidebar-header h1 { font-size: 1.5em; margin: 0; }
			
			.nav-tabs {
				display: flex; flex-direction: column; gap: 0.75em;
				position: relative;
			}
			.tab-btn {
				display: flex; align-items: center; gap: 1em;
				padding: 0.9em 1.2em;
				background-color: var(--tab-bg);
				border: 1px solid var(--border-color);
				border-radius: 10px;
				color: var(--text-secondary);
				font-size: 1em; font-weight: 500;
				cursor: pointer; text-align: left;
				transition: all 0.2s ease-in-out, background-color 0.3s ease;
				backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
				position: relative;
				z-index: 2;
			}
			.tab-btn:hover {
				transform: translateY(-3px);
				color: var(--text-primary);
				box-shadow: 0 6px 20px rgba(0,0,0,0.3);
			}
			.tab-btn.active {
				color: var(--text-primary);
				box-shadow: 0 4px 15px rgba(0,0,0,0.2);
			}
			.tab-btn i { width: 24px; text-align: center; font-size: 1.1em; }

			.active-pill {
				position: absolute;
				left: 0;
				width: 100%;
				background-color: var(--tab-active-bg);
				border: 1px solid var(--accent-cyan);
				border-radius: 10px;
				z-index: 1;
				transition: top 0.3s cubic-bezier(0.25, 0.8, 0.25, 1), height 0.3s cubic-bezier(0.25, 0.8, 0.25, 1), opacity 0.3s ease;
				box-shadow: 0 4px 15px rgba(34, 211, 238, 0.2); /* Cyan glow */
			}

			.content-area {
				flex-grow: 1; padding: 2em;
				overflow-y: auto; min-height: 100vh; box-sizing: border-box;
			}
			.content-page { display: none; animation: fadeIn 0.6s ease-out forwards; }
			.content-page.active { display: block; }
			@keyframes fadeIn {
				from { opacity: 0; transform: translateY(20px); }
				to { opacity: 1; transform: translateY(0); }
			}
 
			 .section-container {
				background-color: rgba(0,0,0,0.2);
				padding: 1.5em;
				border-radius: 12px;
				margin-bottom: 2em;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(8px);
				-webkit-backdrop-filter: blur(8px);
				box-shadow: 0 4px 20px rgba(0,0,0,0.2);
				transition: transform 0.2s ease, box-shadow 0.2s ease;
			}
			.section-container:hover {
				transform: translateY(-5px);
				box-shadow: 0 8px 25px rgba(0,0,0,0.3);
			}
			.light-mode .section-container {
				background-color: rgba(255,255,255,0.7);
				box-shadow: 0 4px 20px rgba(0,0,0,0.1);
			}
			.light-mode .section-container:hover {
				box-shadow: 0 8px 25px rgba(0,0,0,0.15);
			}
			.section-title {
				font-size: 1.3em;
				color: var(--text-primary);
				margin-bottom: 1em;
				border-bottom: 1px solid var(--border-color);
				padding-bottom: 0.5em;
			}
			.info-grid { display: grid; grid-template-columns: 120px 1fr; gap: 0.8em 1.5em; align-items: center; }
			.info-grid.half-width { grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); }
			.label { font-weight: 500; color: var(--text-secondary); text-align: left; }
			.value { font-family: "Fira Code", monospace; color: var(--text-primary); overflow-wrap: break-word; }
			.progress-bar {
				background-color: rgba(0,0,0,0.3); border-radius: 8px;
				height: 1.75em; width: 100%; overflow: hidden;
				border: 1px solid var(--border-color);
				position: relative; display: flex; align-items: center; justify-content: center;
			}
			.progress-fill {
				background-color: var(--accent-green);
				height: 100%; position: absolute; top: 0; left: 0;
				transition: width 0.5s ease-out, background-color 0.5s ease-out;
			}
			.progress-text {
				position: relative; z-index: 1; font-size: 0.85em; font-weight: 700;
				color: #fff; text-shadow: 1px 1px 2px rgba(0,0,0,0.6);
			}
			.list-item { margin-bottom: 1em; }
			.list-header {
				display: flex; justify-content: space-between;
				font-family: "Fira Code", monospace; margin-bottom: 0.4em;
				font-size: 0.9em; color: var(--text-secondary);
			}
			.disk-item {
				font-family: "Fira Code", monospace;
				background-color: rgba(0,0,0,0.2);
				padding: 0.6em 1em; border-radius: 6px;
				margin-bottom: 0.5em; border: 1px solid var(--border-color);
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
				background: rgba(255, 255, 255, 0.2);
				border-radius: 10px;
			}
			::-webkit-scrollbar-thumb:hover {
				background: rgba(255, 255, 255, 0.3);
			}
			html {
				scrollbar-width: thin;
				scrollbar-color: rgba(255, 255, 255, 0.2) rgba(255, 255, 255, 0.05);
			}
 
			#loading-overlay {
				position: fixed;
				top: 0;
				left: 0;
				width: 100%;
				height: 100%;
				background-color: var(--bg-color);
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				z-index: 1000;
				transition: opacity 0.5s ease-out;
			}
			#loading-overlay.hidden {
				opacity: 0;
				pointer-events: none;
			}
			.spinner {
				border: 4px solid rgba(255, 255, 255, 0.3);
				border-top: 4px solid var(--accent-cyan);
				border-radius: 50%;
				width: 40px;
				height: 40px;
				animation: spin 1s linear infinite;
				margin-bottom: 1em;
			}
			@keyframes spin {
				0% { transform: rotate(0deg); }
				100% { transform: rotate(360deg); }
			}
			#loading-overlay p {
				color: var(--text-secondary);
				font-size: 1.1em;
			}
 		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div id="loading-overlay">
			<div class="spinner"></div>
			<p>Loading system data...</p>
		</div>
		
		<div class="app-layout">
			<nav class="sidebar">
				<div class="sidebar-header">
					<i class="fa-solid fa-rocket"></i>
					<h1>RingFetch</h1>
				</div>
				<div class="nav-tabs">
					<button class="tab-btn active" data-tab="system">
						<i class="fa-solid fa-desktop"></i>
						<span>System</span>
					</button>
					<button class="tab-btn" data-tab="hardware">
						<i class="fa-solid fa-microchip"></i>
						<span>Hardware</span>
					</button>
					<button class="tab-btn" data-tab="usage">
						<i class="fa-solid fa-heart-pulse"></i>
						<span>Live Usage</span>
					</button>
					<button class="tab-btn" data-tab="storage">
						<i class="fa-solid fa-database"></i>
						<span>Storage</span>
					</button>
					<button class="tab-btn" data-tab="network">
						<i class="fa-solid fa-network-wired"></i>
						<span>Network</span>
					</button>
				</div>
				<div class="sidebar-footer" style="margin-top: auto; padding-top: 1em; border-top: 1px solid var(--border-color);">
					<button id="theme-toggle" class="tab-btn">
						<i class="fa-solid fa-circle-half-stroke"></i>
						<span>Toggle Theme</span>
					</button>
				</div>
			</nav>

			<main class="content-area">
				<div id="page-system" class="content-page active">
					<div class="section-container">
						<h2 class="section-title">System Information</h2>
						<div class="info-grid">
							<span class="label">Hostname</span> <span id="hostname" class="value"></span>
							<span class="label">User</span> <span id="user-model" class="value"></span>
							<span class="label">OS</span> <span id="os" class="value"></span>
							<span class="label">Kernel</span> <span id="kernel" class="value"></span>
							<span class="label">Uptime</span> <span id="uptime" class="value"></span>
							<span class="label">Shell</span> <span id="shell" class="value"></span>
							<span class="label">Packages</span> <span id="packages" class="value"></span>
						</div>
					</div>
				</div>
				<div id="page-hardware" class="content-page">
					<div class="section-container">
						<h2 class="section-title">Hardware Overview</h2>
						<div class="info-grid">
							<span class="label">CPU</span> <span id="cpu" class="value"></span>
							<span class="label">GPU</span> <span id="gpu" class="value"></span>
							<span class="label">Arch</span> <span id="arch" class="value"></span>
						</div>
					</div>
					<div class="section-container">
						<h2 class="section-title">Physical Disks</h2>
						<div id="disks-list"></div>
					</div>
				</div>
				<div id="page-usage" class="content-page">
					<div class="section-container">
						<h2 class="section-title">Live Resource Usage</h2>
						<div class="info-grid" style="grid-template-columns: 60px 1fr;">
							<span class="label">CPU</span>
							<div class="progress-bar">
								<div id="cpu-usage-fill" class="progress-fill"></div>
								<span id="cpu-text" class="progress-text"></span>
							</div>
							<span class="label">RAM</span>
							<div class="progress-bar">
								<div id="ram-usage-fill" class="progress-fill"></div>
								<span id="ram-text" class="progress-text"></span>
							</div>
						</div>
					</div>
				</div>
				<div id="page-storage" class="content-page">
					<div class="section-container">
						<h2 class="section-title">Storage Partitions</h2>
						<div id="partitions-list"></div>
					</div>
				</div>
				<div id="page-network" class="content-page">
					<div class="section-container">
						<h2 class="section-title">Network Interfaces</h2>
						<div id="network-interfaces-list"></div>
					</div>
				</div>
			</main>
		</div>

		<script>
			function setupTabs() {
				const navTabs = document.querySelector(".nav-tabs");
				const tabButtons = document.querySelectorAll(".tab-btn");
				const contentPages = document.querySelectorAll(".content-page");
				const activePill = document.createElement("div");
				activePill.className = "active-pill";
				navTabs.prepend(activePill);
				function moveToTab(tabButton) {
					activePill.style.top = tabButton.offsetTop + "px";
					activePill.style.height = tabButton.offsetHeight + "px";
				}
				tabButtons.forEach(button => {
					if (button.dataset.tab) { // Only apply to tab buttons with data-tab attribute
						button.addEventListener("click", () => {
							tabButtons.forEach(btn => btn.classList.remove("active"));
							contentPages.forEach(page => page.classList.remove("active"));
							button.classList.add("active");
							const pageId = "page-" + button.dataset.tab;
							document.getElementById(pageId).classList.add("active");
							moveToTab(button);
						});
					}
				});
				const initialActiveTab = document.querySelector(".tab-btn.active[data-tab]");
				if (initialActiveTab) moveToTab(initialActiveTab);
			}
 
			function setupThemeSwitcher() {
				const themeToggleBtn = document.getElementById("theme-toggle");
				const themeToggleIcon = themeToggleBtn.querySelector("i");
				const themeToggleText = themeToggleBtn.querySelector("span");
				const htmlElement = document.documentElement;

				const applyTheme = (theme) => {
					htmlElement.classList.remove("light-mode", "dark-mode"); // Ensure only one is active
					htmlElement.classList.add(theme);
					if (theme === "light-mode") {
						themeToggleIcon.classList.remove("fa-moon");
						themeToggleIcon.classList.add("fa-sun");
						themeToggleText.textContent = "Light Mode";
					} else {
						themeToggleIcon.classList.remove("fa-sun");
						themeToggleIcon.classList.add("fa-moon");
						themeToggleText.textContent = "Dark Mode";
					}
				};

				// Check if localStorage is available and secure (not about:blank)
				const isLocalStorageAvailable = () => {
					try {
						const test = "test";
						localStorage.setItem(test, test);
						localStorage.removeItem(test);
						return true;
					} catch (e) {
						return false;
					}
				};

				const useLocalStorage = isLocalStorageAvailable();
				let initialTheme = "dark-mode"; // Default to dark mode

				if (useLocalStorage) {
					const savedTheme = localStorage.getItem("theme");
					if (savedTheme) {
						initialTheme = savedTheme;
					} else if (window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches) {
						initialTheme = "dark-mode";
					}
				} else {
					// Fallback for insecure contexts (e.g., about:blank)
					if (window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches) {
						initialTheme = "dark-mode";
					}
				}
				applyTheme(initialTheme); // Apply initial theme

				themeToggleBtn.addEventListener("click", () => {
					const currentTheme = htmlElement.classList.contains("light-mode") ? "light-mode" : "dark-mode";
					const newTheme = currentTheme === "light-mode" ? "dark-mode" : "light-mode";
					applyTheme(newTheme);
					if (useLocalStorage) localStorage.setItem("theme", newTheme);
				});
			}

			function updateDashboard(data) {
				// System Page
				document.getElementById("hostname").textContent = data.hostname;
				document.getElementById("user-model").textContent = data.user_model;
				document.getElementById("os").textContent = data.os;
				document.getElementById("kernel").textContent = data.kernel;
				document.getElementById("uptime").textContent = data.uptime;
				document.getElementById("shell").textContent = data.shell;
				document.getElementById("packages").textContent = data.packages;

				// Hardware Page
				document.getElementById("cpu").textContent = data.cpu;
				document.getElementById("gpu").textContent = data.gpu;
				document.getElementById("arch").textContent = data.arch;
				const disksList = document.getElementById("disks-list");
				disksList.innerHTML = "";
				data.disks.forEach(disk => {
					const div = document.createElement("div");
					div.className = "disk-item";
					div.textContent = disk;
					disksList.appendChild(div);
				});

				// Live Usage Page
				const cpuFill = document.getElementById("cpu-usage-fill");
				cpuFill.style.width = data.cpu_usage + "%";
				cpuFill.style.backgroundColor = getUsageColor(data.cpu_usage);
				document.getElementById("cpu-text").textContent = data.cpu_usage + "%";

				const ramFill = document.getElementById("ram-usage-fill");
				ramFill.style.width = data.ram_usage_percent + "%";
				ramFill.style.backgroundColor = getUsageColor(data.ram_usage_percent);
				document.getElementById("ram-text").textContent = formatBytes(data.ram_used_kb * 1024) + " / " + formatBytes(data.ram_total_kb * 1024);

				// Storage Page
				const partitionsList = document.getElementById("partitions-list");
				partitionsList.innerHTML = "";
				data.partitions.forEach(part => {
					const item = document.createElement("div");
					item.className = "list-item";
					const usedPercent = (part.used_kb / part.size_kb) * 100 || 0;
					item.innerHTML = `
						<div class="list-header">
							<span>${part.name}</span>
							<span>${formatBytes(part.used_kb * 1024)} / ${formatBytes(part.size_kb * 1024)}</span>
						</div>
						<div class="progress-bar">
							<div class="progress-fill" style="width:${usedPercent.toFixed(1)}%; background-color:${getUsageColor(usedPercent)};"></div>
							<span class="progress-text">${usedPercent.toFixed(1)}%</span>
						</div>
					`;    
					partitionsList.appendChild(item);
				});

				// Network Page
				const networkInterfacesList = document.getElementById("network-interfaces-list");
				networkInterfacesList.innerHTML = "";
				data.network_interfaces.forEach(net => {
					const div = document.createElement("div");
					div.className = "disk-item"; // Re-using disk-item style for now, can be refined
					div.innerHTML = `<strong>${net.name}</strong><br>IP: ${net.ip || "N/A"}<br>Status: ${net.status}`;
					networkInterfacesList.appendChild(div);
				});
			}

			function getUsageColor(percentage) {
				if (percentage > 85) return "var(--accent-red)";
				if (percentage > 60) return "var(--accent-yellow)";
				return "var(--accent-green)";
			}

			// *** FIX 5: Add formatBytes function back to JavaScript ***
			function formatBytes(bytes, decimals = 2) {
				if (!bytes || bytes === 0) return "0 Bytes";
				const k = 1024;
				const dm = decimals < 0 ? 0 : decimals;
				const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
				const i = Math.floor(Math.log(bytes) / Math.log(k));
				return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + " " + sizes[i];
			}

			async function fetchData() {
				try {
					const systemData = await window.getSystemData();
					updateDashboard(systemData);
				} catch (e) {
					console.error("Error fetching system data:", e);
					if (window.dataInterval) clearInterval(window.dataInterval);
				}
			}

			window.onload = () => {
				setupTabs();
				setupThemeSwitcher();
				fetchData();
				document.getElementById("loading-overlay").classList.add("hidden"); // Hide loading overlay
			};
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# Handles requests from JavaScript to get all system data.
func handleGetSystemData(id, req)
	aData = buildSystemDataList()
	cJson = substr(list2json(aData), char(13), "")
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson)

# --- Helper Functions ---

# Gathers various system information and organizes it into a list (array).
func buildSystemDataList()
	# --- Basic System Information ---
	cHostname = sys.hostname()
	cUserModel = sys.username() + "@" + sys.model()

	# --- Operating System Details ---
	cOS = sys.os()[:name]
	cKernel = sys.version()
	cArch = sys.arch()
	cUptime = sys.sysUptime([])
	cShell = sys.shell()[:name] + " " + sys.shell()[:version]
	cPackages = sys.packageManager()
	cPackages = string(cPackages[:count]) + " ("+cPackages[:name]+")"

	# --- Hardware Information ---
	oCPU = sys.cpu([:usage = 1])
	nCpuUsage = oCPU[:usage]
	if (oCPU[:count] > 1)
		cCPU = string(oCPU[:count]) + "x " + oCPU[:model]
	else
		cCPU = oCPU[:model]
	ok
	cGPU = sys.gpu()

	# --- Memory Usage ---
	# Retrieve raw RAM values in kilobytes.
	nTotalRamKB = sys.ram()[:size]
	nUsedRamKB = sys.ram()[:used]
	nRamUsagePercent = 0
	if nTotalRamKB > 0
		nRamUsagePercent = floor((nUsedRamKB / nTotalRamKB) * 100)
	ok

	# --- Disk Information ---
	aDisks = []
	aPhysicalDisks = sys.storageDisks()
	for disk in aPhysicalDisks
		add(aDisks, disk[:name] + " (" + formatSize(disk[:size]) + ")")
	next

	# --- Storage Partitions ---
	aPartitions = []
	aStorageParts = sys.storageParts()
	if (isList(aStorageParts) and len(aStorageParts) > 0)
		for part in aStorageParts
			aPartitionObject = [
				["name", part[:name]],
				["size_kb", part[:size]], 
				["used_kb", part[:used]]
			]
			add(aPartitions, aPartitionObject)
		next
	ok

	aNetworkInfo = sys.network()
	aNetworkInterfaces = []
	# --- Network Interfaces ---
	if (isList(aNetworkInfo) and len(aNetworkInfo) > 0)
		for interface in aNetworkInfo
			aInterfaceObject = [
				["name", interface[:name]],
				["ip", interface[:ip]],
				["status", interface[:status]]
			]
			add(aNetworkInterfaces, aInterfaceObject)
		next
	ok

	# Build the final list for JSON conversion.
	aSystemData = [
		["hostname", cHostname],
		["user_model", cUserModel],
		["os", cOS],
		["kernel", cKernel],
		["arch", cArch],
		["uptime", cUptime],
		["shell", cShell],
		["packages", cPackages],
		["cpu", cCPU],
		["cpu_usage", nCpuUsage],
		["gpu", cGPU],
		["ram_usage_percent", nRamUsagePercent],
		["ram_total_kb", nTotalRamKB],
		["ram_used_kb", nUsedRamKB],
		["disks", aDisks],
		["partitions", aPartitions],
		["network_interfaces", aNetworkInterfaces]
	]
	return aSystemData

# Helper function to format size values (KB, MB, GB, TB).
func formatSize(size)
	if not isNumber(size)
		size = number(size)
	ok
	if size < 1024
		return string(size) + " KB"
	ok
	if size < 1024 * 1024
		return string(floor(size / 1024)) + " MB"
	ok
	if size < 1024 * 1024 * 1024
		nGB = floor( (size / (1024*1024) * 100) + 0.5) / 100
		return string(nGB) + " GB"
	ok
	nTB = floor( (size / (1024*1024*1024) * 100) + 0.5) / 100
	return string(nTB) + " TB"
