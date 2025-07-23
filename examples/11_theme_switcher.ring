# Theme Switcher Example
# This example demonstrates how to create a simple theme switcher application using Ring and WebView.

load "webview.ring"
load "jsonlib.ring"

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
	oWebView.setSize(500, 350, WEBVIEW_HINT_NONE)

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
		<style>
			body {
				font-family: sans-serif;
				margin: 0;
				height: 100vh;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				transition: background-color 0.5s ease;
			}
			.theme-card {
				padding: 30px;
				border-radius: 12px;
				box-shadow: 0 4px 15px rgba(0,0,0,0.1);
				text-align: center;
				width: 80%;
				max-width: 400px;
				transition: background-color 0.5s ease, color 0.5s ease;
			}
			h1 {
				margin-bottom: 25px;
			}
			button {
				padding: 12px 25px;
				font-size: 1.1em;
				border: none;
				border-radius: 8px;
				cursor: pointer;
				transition: background-color 0.2s, color 0.2s;
			}

			/* Light Theme */
			body[data-theme="light"] {
				background-color: #f8f8f8;
				color: #333;
			}
			.theme-card[data-theme="light"] {
				background-color: #ffffff;
			}
			button[data-theme="light"] {
				background-color: #007bff;
				color: white;
			}
			button[data-theme="light"]:hover {
				background-color: #0056b3;
			}

			/* Dark Theme */
			body[data-theme="dark"] {
				background-color: #2c3e50;
				color: #ecf0f1;
			}
			.theme-card[data-theme="dark"] {
				background-color: #34495e;
			}
			button[data-theme="dark"] {
				background-color: #e67e22;
				color: white;
			}
			button[data-theme="dark"]:hover {
				background-color: #d35400;
			}
		</style>
	</head>
	<body data-theme="light">
		<div class="theme-card" data-theme="light">
			<h1>Theme Switcher</h1>
			<p>Toggle between light and dark themes.</p>
			<button id="theme-toggle-btn" data-theme="light" onclick="toggleTheme()">Switch Theme</button>
		</div>

		<script>
			const body = document.body;
			const themeCard = document.querySelector('.theme-card');
			const themeToggleBtn = document.getElementById('theme-toggle-btn');
			
			let currentTheme = 'light'; // Default client-side

			function applyTheme(theme) {
				currentTheme = theme;
				body.setAttribute('data-theme', theme);
				themeCard.setAttribute('data-theme', theme);
				themeToggleBtn.setAttribute('data-theme', theme);
				themeToggleBtn.textContent = (theme === 'light' ? 'Switch to Dark' : 'Switch to Light');
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
	req = json2list(req)[1] # Parse the request data.
	cNewTheme = req[1] # Extract the new theme name.
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