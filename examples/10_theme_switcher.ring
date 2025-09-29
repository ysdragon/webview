# Theme Switcher Example
# This example demonstrates how to create a simple theme switcher application using Ring and WebView.

load "webview.ring"
load "simplejson.ring"

oWebView = NULL
cCurrentTheme = "light"

func main()
	# Load the initial theme preference from a file (if it exists).
	cCurrentTheme = loadThemePreference()

	see "Setting up the Theme Switcher application..." + nl

	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring Theme Switcher")
	# Set the window size (no size constraint).
	oWebView.setSize(400, 250, WEBVIEW_HINT_NONE)

	# Bind Ring functions that will be called from JavaScript.
	oWebView.bind("getInitialTheme", :handleGetInitialTheme) # To fetch the current theme.
	oWebView.bind("setTheme", :handleSetTheme)             # To update and persist the theme.

	# Load the HTML content for the theme switcher UI.
	loadThemeHTML()

	see "Running the WebView main loop. Interact with the UI to switch themes." + nl
	oWebView.run()

# Function to load the HTML content.
func loadThemeHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Theme Switcher</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- Font Awesome for icons -->
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			:root {
				--bg-color-light: #f1f5f9;
				--panel-bg-light: rgba(255, 255, 255, 0.8);
				--border-color-light: rgba(0, 0, 0, 0.1);
				--text-primary-light: #1e293b;
				--text-secondary-light: #64748b;
				--accent-light: #3b82f6;
				--accent-hover-light: #2563eb;
				--aurora1-light: rgba(59, 130, 246, 0.3);
				--aurora2-light: rgba(168, 85, 247, 0.2);
				
				--bg-color-dark: #000000;
				--panel-bg-dark: rgba(30, 30, 32, 0.6);
				--border-color-dark: rgba(255, 255, 255, 0.1);
				--text-primary-dark: #f8fafc;
				--text-secondary-dark: #a1a1aa;
				--accent-dark: #22d3ee;
				--accent-hover-dark: #06b6d4;
				--aurora1-dark: rgba(34, 211, 238, 0.4);
				--aurora2-dark: rgba(192, 132, 252, 0.3);
			}
			body {
				font-family: 'Inter', sans-serif;
				margin: 0;
				height: 100vh;
				overflow: hidden;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				position: relative;
				transition: background-color 0.5s ease;
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
				top: 5%; left: 5%;
				transition: background 0.5s ease;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				bottom: 10%; right: 10%;
				transition: background 0.5s ease;
			}
			
			.theme-card {
				border: 1px solid var(--border-color);
				border-radius: 15px;
				padding: 30px;
				text-align: center;
				max-width: 500px;
				width: 90%;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative; z-index: 1;
				transition: background-color 0.5s ease, color 0.5s ease, border-color 0.5s ease;
			}
			h1 {
				margin-bottom: 15px;
				font-size: 2.2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
				transition: color 0.5s ease;
			}
			p {
				margin-bottom: 25px;
				font-size: 1.1em;
				transition: color 0.5s ease;
			}
			button {
				border: none;
				border-radius: 8px;
				padding: 12px 20px;
				font-size: 1em;
				font-weight: 500;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				margin: 0 8px 10px 8px;
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}

			body[data-theme="light"] {
				background-color: var(--bg-color-light);
				color: var(--text-primary-light);
				--border-color: var(--border-color-light);
			}
			body[data-theme="light"] .aurora-shape1 {
				background: radial-gradient(circle, var(--aurora1-light), transparent 60%);
			}
			body[data-theme="light"] .aurora-shape2 {
				background: radial-gradient(circle, var(--aurora2-light), transparent 60%);
			}
			.theme-card[data-theme="light"] {
				background-color: var(--panel-bg-light);
			}
			.theme-card[data-theme="light"] h1 {
				color: var(--text-primary-light);
			}
			.theme-card[data-theme="light"] p {
				color: var(--text-secondary-light);
			}
			button[data-theme="light"] {
				background-color: var(--accent-light);
				color: white;
			}
			button[data-theme="light"]:hover {
				background-color: var(--accent-hover-light);
			}

			body[data-theme="dark"] {
				background-color: var(--bg-color-dark);
				color: var(--text-primary-dark);
				--border-color: var(--border-color-dark);
			}
			body[data-theme="dark"] .aurora-shape1 {
				background: radial-gradient(circle, var(--aurora1-dark), transparent 60%);
			}
			body[data-theme="dark"] .aurora-shape2 {
				background: radial-gradient(circle, var(--aurora2-dark), transparent 60%);
			}
			.theme-card[data-theme="dark"] {
				background-color: var(--panel-bg-dark);
			}
			.theme-card[data-theme="dark"] h1 {
				color: var(--text-primary-dark);
			}
			.theme-card[data-theme="dark"] p {
				color: var(--text-secondary-dark);
			}
			button[data-theme="dark"] {
				background-color: var(--accent-dark);
				color: white;
			}
			button[data-theme="dark"]:hover {
				background-color: var(--accent-hover-dark);
			}
		</style>
	</head>
	<body data-theme="light">
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="theme-card" data-theme="light">
			<h1><i class="fa-solid fa-palette"></i> Theme Switcher</h1>
			<p>Toggle between beautiful light and dark themes.</p>
			<button id="theme-toggle-btn" data-theme="light" onclick="toggleTheme()"><i class="fa-solid fa-moon"></i> Switch to Dark</button>
		</div>

		<script>
			const body = document.body;
			const themeCard = document.querySelector('.theme-card');
			const themeToggleBtn = document.getElementById('theme-toggle-btn');
			
			let currentTheme = 'light';

			function applyTheme(theme) {
				currentTheme = theme;
				body.setAttribute('data-theme', theme);
				themeCard.setAttribute('data-theme', theme);
				themeToggleBtn.setAttribute('data-theme', theme);
				if (theme === 'light') {
					themeToggleBtn.innerHTML = '<i class="fa-solid fa-moon"></i> Switch to Dark';
				} else {
					themeToggleBtn.innerHTML = '<i class="fa-solid fa-sun"></i> Switch to Light';
				}
			}

			async function toggleTheme() {
				const newTheme = (currentTheme === 'light' ? 'dark' : 'light');
				applyTheme(newTheme);
				await window.setTheme(newTheme);
			}

			window.onload = async () => {
				try {
					const initialTheme = await window.getInitialTheme();
					applyTheme(initialTheme);
				} catch (e) {
					console.error("Error loading initial theme:", e);
					applyTheme('light'); 
				}
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles requests from JavaScript to get the currently active theme.
func handleGetInitialTheme(id, req)
	see "Ring: JavaScript requested the initial theme." + nl
	# Return the current theme (`cCurrentTheme`) as a JSON string.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + cCurrentTheme + '"')

# Handles requests from JavaScript to set a new theme.
func handleSetTheme(id, req)
	cNewTheme = json_decode(req)[1] # Extract the new theme name.
	see "Ring: JavaScript requested to set theme to: '" + cNewTheme + "'" + nl
	
	cCurrentTheme = cNewTheme # Update the global current theme.
	saveThemePreference(cNewTheme) # Persist the new theme to a file.
	
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call to JavaScript.

# Loads the theme preference from `theme_preference.txt`.
func loadThemePreference()
	cThemeFile = "theme_preference.txt"
	if fexists(cThemeFile)
		cTheme = read(cThemeFile)
		see "Loaded theme preference from file: '" + cTheme + "'" + nl
		return cTheme
	else
		see "No theme preference file found. Using default 'light' theme." + nl
		return "light"
	ok

# Saves the current theme preference to `theme_preference.txt`.
func saveThemePreference(cTheme)
	cThemeFile = "theme_preference.txt"
	write(cThemeFile, cTheme)
	see "Theme preference saved to file: '" + cTheme + "'" + nl