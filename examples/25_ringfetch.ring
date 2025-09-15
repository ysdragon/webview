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
		setSize(800, 700, WEBVIEW_HINT_NONE)

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
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css" referrerpolicy="no-referrer" />
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fira+Code:wght@400;500;600&display=swap");
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
				--sidebar-width: 280px;
			}
			:root.light-mode {
				--bg-primary: #f8fafc;
				--bg-secondary: #ffffff;
				--card-bg: rgba(255, 255, 255, 0.8);
				--card-border: rgba(148, 163, 184, 0.2);
				--text-primary: #1e293b;
				--text-secondary: #475569;
				--text-muted: #64748b;
				--accent-primary: #3b82f6;
				--accent-secondary: #8b5cf6;
				--accent-success: #10b981;
				--accent-warning: #f59e0b;
				--accent-danger: #ef4444;
				--accent-cyan: #06b6d4;
			}
			:root.dark-mode {
				--dark-gradient-start: rgba(0, 0, 0, 0.8);
				--dark-gradient-end: rgba(20, 20, 25, 0.8);
			}
			body {
				font-family: "Inter", sans-serif;
				background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
				color: var(--text-primary);
				margin: 0;
				padding: 0;
				min-height: 100vh;
				overflow-x: hidden;
				position: relative;
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
			}
			.background-container {
				position: fixed; top: 0; left: 0; width: 100%; height: 100%;
				z-index: -1; overflow: hidden;
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
				0%, 100% { transform: translate(0, 0) rotate(0deg) scale(1); }
				25% { transform: translate(10px, -15px) rotate(1deg) scale(1.05); }
				50% { transform: translate(-5px, 10px) rotate(-0.5deg) scale(0.95); }
				75% { transform: translate(-15px, -5px) rotate(0.5deg) scale(1.02); }
			}
			
			.app-layout { 
				display: flex; 
				min-height: 100vh;
				gap: 0;
			}
			.sidebar {
				width: var(--sidebar-width);
				min-width: var(--sidebar-width);
				background: var(--card-bg);
				padding: clamp(1rem, 3vw, 2rem);
				flex-shrink: 0;
				display: flex;
				flex-direction: column;
				box-sizing: border-box;
				border-right: 1px solid var(--card-border);
				backdrop-filter: blur(var(--blur-lg));
				-webkit-backdrop-filter: blur(var(--blur-lg));
				box-shadow: var(--shadow-lg);
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
			}
			.sidebar-header {
				padding: 0 0.5rem;
				margin-bottom: 2rem;
				display: flex;
				align-items: center;
				gap: 0.75rem;
			}
			.sidebar-header i {
				font-size: clamp(1.5rem, 4vw, 1.8rem);
				color: var(--accent-cyan);
			}
			.sidebar-header h1 {
				font-size: clamp(1.25rem, 4vw, 1.5rem);
				margin: 0;
				font-weight: 700;
				letter-spacing: -0.025em;
			}
			
			.nav-tabs {
				display: flex; flex-direction: column; gap: 0.75em;
				position: relative;
			}
			.tab-btn {
				display: flex;
				align-items: center;
				gap: 1rem;
				padding: clamp(0.75rem, 2vw, 1rem) clamp(1rem, 3vw, 1.25rem);
				background: rgba(148, 163, 184, 0.05);
				border: 1px solid var(--card-border);
				border-radius: 12px;
				color: var(--text-secondary);
				font-size: clamp(0.9rem, 2.5vw, 1rem);
				font-weight: 500;
				cursor: pointer;
				text-align: left;
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-md));
				-webkit-backdrop-filter: blur(var(--blur-md));
				position: relative;
				z-index: 2;
			}
			.tab-btn:hover {
				transform: translateY(-2px);
				color: var(--text-primary);
				background: rgba(59, 130, 246, 0.1);
				border-color: var(--accent-primary);
				box-shadow: 0 8px 25px rgba(59, 130, 246, 0.15);
			}
			.tab-btn.active {
				color: var(--text-primary);
				background: rgba(59, 130, 246, 0.15);
				border-color: var(--accent-primary);
				box-shadow: 0 4px 15px rgba(59, 130, 246, 0.2);
			}
			.tab-btn i {
				width: 24px;
				text-align: center;
				font-size: clamp(1rem, 2.5vw, 1.1rem);
			}

			.active-pill {
				position: absolute;
				left: 0;
				width: 100%;
				background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(139, 92, 246, 0.1));
				border: 1px solid var(--accent-primary);
				border-radius: 12px;
				z-index: 1;
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
				box-shadow: 0 4px 15px rgba(59, 130, 246, 0.25);
				backdrop-filter: blur(var(--blur-sm));
			}

			.content-area {
				flex: 1;
				padding: clamp(1rem, 3vw, 2rem);
				overflow-y: auto;
				min-height: 100vh;
				box-sizing: border-box;
				max-width: calc(100vw - var(--sidebar-width));
			}
			.content-page { display: none; animation: fadeIn 0.6s ease-out forwards; }
			.content-page.active { display: block; }
			@keyframes fadeIn {
				from { opacity: 0; transform: translateY(20px); }
				to { opacity: 1; transform: translateY(0); }
			}
 
			.section-container {
				background: var(--card-bg);
				padding: clamp(1.25rem, 3vw, 2rem);
				border-radius: 16px;
				margin-bottom: clamp(1.5rem, 4vw, 2rem);
				border: 1px solid var(--card-border);
				backdrop-filter: blur(var(--blur-lg));
				-webkit-backdrop-filter: blur(var(--blur-lg));
				box-shadow: var(--shadow-lg);
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				position: relative;
				overflow: hidden;
			}
			.section-container:hover {
				transform: translateY(-4px);
				box-shadow: var(--shadow-lg), 0 25px 50px -12px rgba(0, 0, 0, 0.25);
				border-color: rgba(59, 130, 246, 0.3);
			}
			.section-title {
				font-size: clamp(1.1rem, 3vw, 1.4rem);
				color: var(--text-primary);
				margin-bottom: 1.5rem;
				border-bottom: 1px solid var(--card-border);
				padding-bottom: 0.75rem;
				font-weight: 600;
				letter-spacing: -0.025em;
				display: flex;
				align-items: center;
				gap: 0.5rem;
			}
			.info-grid {
				display: grid;
				grid-template-columns: minmax(120px, auto) 1fr;
				gap: clamp(0.75rem, 2vw, 1rem) clamp(1rem, 3vw, 1.5rem);
				align-items: center;
			}
			.info-grid.half-width {
				grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
			}
			.label {
				font-weight: 500;
				color: var(--text-secondary);
				text-align: left;
				font-size: clamp(0.9rem, 2.5vw, 1rem);
			}
			.value {
				font-family: "Fira Code", monospace;
				color: var(--text-primary);
				overflow-wrap: break-word;
				font-size: clamp(0.85rem, 2vw, 0.95rem);
				padding: 0.5rem 0.75rem;
				background: rgba(148, 163, 184, 0.05);
				border-radius: 8px;
				border: 1px solid var(--card-border);
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				cursor: pointer;
				position: relative;
				user-select: none;
			}
			.value:hover {
				background: rgba(59, 130, 246, 0.1);
				border-color: var(--accent-primary);
				transform: translateY(-1px);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
			}
			.value::after {
				content: "Click to copy";
				position: absolute;
				top: -2.5rem;
				left: 50%;
				transform: translateX(-50%);
				background: rgba(0, 0, 0, 0.9);
				color: white;
				padding: 0.4rem 0.8rem;
				border-radius: 6px;
				font-size: 0.75rem;
				white-space: nowrap;
				opacity: 0;
				visibility: hidden;
				transition: all 0.2s ease;
				pointer-events: none;
				z-index: 100;
				font-family: "Inter", sans-serif;
			}
			.value:hover::after {
				opacity: 1;
				visibility: visible;
				transform: translateX(-50%) translateY(-5px);
			}
			.progress-bar {
				background: rgba(148, 163, 184, 0.1);
				border-radius: 12px;
				height: 2rem;
				width: 100%;
				overflow: hidden;
				border: 1px solid var(--card-border);
				position: relative;
				display: flex;
				align-items: center;
				justify-content: center;
				backdrop-filter: blur(var(--blur-sm));
			}
			.progress-fill {
				background: linear-gradient(90deg, var(--accent-success), var(--accent-cyan));
				height: 100%;
				position: absolute;
				top: 0;
				left: 0;
				transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
				border-radius: 12px;
				box-shadow: 0 2px 10px rgba(16, 185, 129, 0.3);
			}
			.progress-text {
				position: relative;
				z-index: 1;
				font-size: clamp(0.8rem, 2vw, 0.9rem);
				font-weight: 600;
				color: var(--text-primary);
				text-shadow: 0 1px 3px rgba(0, 0, 0, 0.3);
				font-family: "Fira Code", monospace;
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
				background: var(--bg-primary);
			}
			@media (max-width: 768px) {
				.app-layout {
					flex-direction: column;
				}
				.sidebar {
					width: 100%;
					min-width: 100%;
					border-right: none;
					border-bottom: 1px solid var(--card-border);
					padding: 1rem;
				}
				.nav-tabs {
					flex-direction: row;
					gap: 0.5rem;
					overflow-x: auto;
					padding: 0.5rem 0;
				}
				.tab-btn {
					flex-shrink: 0;
					min-width: fit-content;
					padding: 0.75rem 1rem;
				}
				.tab-btn span {
					display: none;
				}
				.content-area {
					max-width: 100vw;
					padding: 1rem;
				}
				.info-grid {
					grid-template-columns: 1fr;
					gap: 0.5rem;
				}
				.label {
					font-weight: 600;
					margin-bottom: 0.25rem;
				}
				.value::after {
					content: "Tap to copy";
				}
			}
				@media (max-width: 480px) {
					.sidebar {
						padding: 0.75rem;
					}
					.sidebar-header {
						margin-bottom: 1rem;
					}
					.tab-btn {
						padding: 0.5rem;
					}
					.section-container {
						padding: 1rem;
						margin-bottom: 1rem;
					}
					.progress-bar {
						height: 1.5rem;
					}
				}
 
			#loading-overlay {
				position: fixed;
				top: 0;
				left: 0;
				width: 100%;
				height: 100%;
				background: var(--bg-primary);
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				z-index: 1000;
				transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
			}
			#loading-overlay.hidden {
				opacity: 0;
				visibility: hidden;
				pointer-events: none;
			}
			.spinner {
				border: 4px solid rgba(59, 130, 246, 0.2);
				border-top: 4px solid var(--accent-primary);
				border-radius: 50%;
				width: 48px;
				height: 48px;
				animation: spin 1s linear infinite;
				margin-bottom: 1.5rem;
			}
			@keyframes spin {
				0% { transform: rotate(0deg); }
				100% { transform: rotate(360deg); }
			}
			#loading-overlay p {
				color: var(--text-secondary);
				font-size: 1.1rem;
				font-weight: 500;
			}
			.copy-feedback {
				position: fixed;
				bottom: 2rem;
				left: 50%;
				transform: translateX(-50%);
				background: var(--accent-success);
				color: white;
				padding: 1rem 1.5rem;
				border-radius: 12px;
				box-shadow: 0 10px 25px rgba(16, 185, 129, 0.3);
				opacity: 0;
				visibility: hidden;
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-md));
				border: 1px solid rgba(255, 255, 255, 0.1);
				font-weight: 500;
				font-size: 0.9rem;
				z-index: 1000;
			}
			.copy-feedback.show {
				opacity: 1;
				visibility: visible;
				transform: translateX(-50%) translateY(-10px);
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
						<span>Usage</span>
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
		<div id="copy-feedback" class="copy-feedback">Copied to clipboard!</div>

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
					if (button.dataset.tab) {
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

			function setupCopyToClipboard() {
				document.querySelectorAll(".value").forEach(element => {
					element.addEventListener("click", async () => {
						const text = element.textContent.trim();
						if (text) {
							try {
								if (navigator.clipboard && window.isSecureContext) {
									await navigator.clipboard.writeText(text);
								} else {
									fallbackCopyToClipboard(text);
								}
								showCopyFeedback();
							} catch (err) {
								console.error("Failed to copy:", err);
								fallbackCopyToClipboard(text);
							}
						}
					});
				});
			}

			function fallbackCopyToClipboard(text) {
				const textArea = document.createElement("textarea");
				textArea.value = text;
				textArea.style.position = "fixed";
				textArea.style.left = "-999999px";
				document.body.appendChild(textArea);
				textArea.focus();
				textArea.select();
				try {
					document.execCommand("copy");
					showCopyFeedback();
				} catch (err) {
					console.error("Fallback copy failed:", err);
				}
				document.body.removeChild(textArea);
			}

			function showCopyFeedback() {
				const feedback = document.getElementById("copy-feedback");
				feedback.classList.add("show");
				setTimeout(() => {
					feedback.classList.remove("show");
				}, 2000);
			}
 
			function setupThemeSwitcher() {
				const themeToggleBtn = document.getElementById("theme-toggle");
				const themeToggleIcon = themeToggleBtn.querySelector("i");
				const themeToggleText = themeToggleBtn.querySelector("span");
				const htmlElement = document.documentElement;

				const applyTheme = (theme) => {
					htmlElement.classList.add(theme);
					htmlElement.classList.remove(theme === "light-mode" ? "dark-mode" : "light-mode");
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
				let initialTheme = "dark-mode";

				if (useLocalStorage) {
					const savedTheme = localStorage.getItem("theme");
					if (savedTheme) {
						initialTheme = savedTheme;
					} else if (window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches) {
						initialTheme = "light-mode";
					}
				} else {
					if (window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches) {
						initialTheme = "light-mode";
					}
				}
				applyTheme(initialTheme);

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

				// Usage Page
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
					div.className = "disk-item";
					div.innerHTML = `<strong>${net.name}</strong><br>IP: ${net.ip || "N/A"}<br>Status: ${net.status}`;
					networkInterfacesList.appendChild(div);
				});
			}

			function getUsageColor(percentage) {
				if (percentage > 85) return "var(--accent-red)";
				if (percentage > 60) return "var(--accent-yellow)";
				return "var(--accent-green)";
			}

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
				setupCopyToClipboard();
				fetchData();
				document.getElementById("loading-overlay").classList.add("hidden");
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
