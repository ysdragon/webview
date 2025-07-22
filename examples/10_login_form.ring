# Login Form Example
# This example demonstrates a simple login form using Ring and WebView.

load "webview.ring"
load "jsonlib.ring"

# Create a new WebView instance.
# The `1` enables debug mode, `NULL` creates a new window.
oWebView = new WebView(1, NULL)

# Set the title of the webview window.
oWebView.setTitle("Ring WebView Login Example")
# Set the size of the webview window. WEBVIEW_HINT_NONE means no size constraint.
oWebView.setSize(550, 500, WEBVIEW_HINT_NONE)

# Define the HTML content for the login form.
cLoginHTML = `
<!DOCTYPE html>
<html>
<head>
	<title>Login</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
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
			display: flex;
			justify-content: center;
			align-items: center;
			position: relative;
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
		
		.login-container {
			background-color: var(--panel-bg);
			padding: 2.5em;
			border-radius: 15px;
			box-shadow: 0 8px 30px rgba(0,0,0,0.3);
			width: 320px;
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			position: relative; z-index: 1;
			border: 1px solid var(--border-color);
		}
		h1 {
			text-align: center;
			color: var(--text-primary);
			margin-bottom: 1.5em;
			font-size: 2em;
			text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
		}
		.form-group {
			margin-bottom: 1.5em;
		}
		label {
			display: block;
			margin-bottom: 0.5em;
			color: var(--text-secondary);
			font-weight: 500;
			font-size: 0.95em;
		}
		input {
			width: 100%;
			padding: 0.8em;
			border: 1px solid var(--border-color);
			border-radius: 8px;
			box-sizing: border-box;
			background-color: rgba(255, 255, 255, 0.05);
			color: var(--text-primary);
			font-size: 1em;
			transition: border-color 0.2s ease;
		}
		input:focus {
			outline: none;
			border-color: var(--accent-cyan);
		}
		button {
			width: 100%;
			padding: 0.9em;
			background-color: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 8px;
			font-size: 1em;
			cursor: pointer;
			transition: all 0.2s ease-in-out;
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.5em;
			font-weight: 600;
		}
		button:hover {
			transform: translateY(-2px);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
		}
		#error-message {
			margin-top: 1em;
			text-align: center;
			color: var(--accent-red);
			font-weight: 500;
			min-height: 1.2em;
			font-size: 0.9em;
		}

		/* Welcome Screen Styles */
		.welcome-card {
			background-color: var(--panel-bg);
			padding: 2.5em;
			border-radius: 15px;
			box-shadow: 0 8px 30px rgba(0,0,0,0.3);
			width: 320px;
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
			position: relative; z-index: 1;
			border: 1px solid var(--border-color);
			text-align: center;
		}
		.welcome-card h1 {
			color: var(--accent-green);
			font-size: 2.5em;
			margin-bottom: 0.5em;
		}
		.welcome-card p {
			color: var(--text-primary);
			font-size: 1.1em;
			margin-bottom: 2em;
		}
		.welcome-card button {
			background-color: var(--accent-red);
			padding: 1em 2em;
			font-size: 1.1em;
		}
		.welcome-card button:hover {
			background-color: #e03f4f; /* Darker red */
		}
	</style>
</head>
<body>
	<div class="background-container">
		<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
	</div>
	<div class="login-container">
		<h1><i class="fa-solid fa-lock"></i> Login</h1>
		<form id="loginForm">
			<div class="form-group">
				<label for="username">Username</label>
				<input type="text" id="username" value="admin" required>
			</div>
			<div class="form-group">
				<label for="password">Password</label>
				<input type="password" id="password" value="1234" required>
			</div>
			<button type="submit"><i class="fa-solid fa-right-to-bracket"></i> Login</button>
		</form>
		<div id="error-message"></div>
	</div>

	<script>
		const form = document.getElementById('loginForm');
		const errorMessageDiv = document.getElementById('error-message');

		form.addEventListener('submit', async (event) => {
			event.preventDefault();
			const username = document.getElementById('username').value;
			const password = document.getElementById('password').value;
			errorMessageDiv.textContent = '';

			try {
				const response = await window.handleLogin(username, password);

				if (response.status === 'success') {
					await window.handleShowWelcome();
				} else {
					errorMessageDiv.textContent = response.message;
				}
			} catch (e) {
				console.error('Error calling Ring backend:', e);
				errorMessageDiv.textContent = 'A communication error occurred.';
			}
		});
	</script>
</body>
</html>
`

# Bind the Ring functions to be callable from JavaScript.
# `handleLogin` processes authentication requests.
# `handleShowWelcome` switches the webview content to the welcome screen.
# `closeApp` terminates the webview application.
oWebView.bind("handleLogin", :handleLogin)
oWebView.bind("handleShowWelcome", :handleShowWelcome)
oWebView.bind("closeApp", :closeApp)

# Set the initial HTML content (the login form).
oWebView.setHtml(cLoginHTML)
# Run the webview's main event loop. This is a blocking call.
oWebView.run()
# Destroy the webview instance.
oWebView.destroy()

see "Application finished." + nl

# --- Ring Functions (Callbacks from JavaScript) ---

# Handles login requests from JavaScript.
# It receives the username and password, simulates authentication, and returns a JSON response.
func handleLogin(id, req)
	see "Ring: `handleLogin` function called from JavaScript." + nl
	req = json2list(req)[1] # Parse the request data.
	cUser = req[1]
	cPass = req[2]

	see "  Attempting login with User: '" + cUser + "', Pass: '" + cPass + "'" + nl

	# Simulate authentication.
	if cUser = "admin" and cPass = "1234"
		see "  Login successful. Returning success status to JavaScript." + nl
		cResult = [
			:status = "success"
		]
		cResultJson = list2json(cResult)
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, cResultJson) # Return success.
	else
		see "  Login failed. Returning error status to JavaScript." + nl
		cResult = [
			:status = "error",
			:message = "Invalid username or password."
		]
		cResultJson = list2json(cResult)
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, cResultJson) # Return error message.
	ok

# Handles the request to display the welcome screen after successful login.
func handleShowWelcome(id, req)
	see "Ring: `handleShowWelcome` function called. Displaying welcome screen." + nl
	# Define the HTML content for the welcome screen.
	cWelcomeHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Welcome</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
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
			html, body {
				height: 100%;
				margin: 0;
				padding: 0;
				box-sizing: border-box;
			}
			body {
				font-family: 'Inter', sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				min-height: 100vh;
				min-width: 100vw;
				width: 100vw;
				height: 100vh;
				overflow: hidden;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				position: relative;
			}
			.background-container {
				position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
				z-index: -1; overflow: hidden;
			}
			.aurora {
				position: relative; width: 100vw; height: 100vh;
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
			.welcome-card {
				background-color: var(--panel-bg);
				padding: 2.5em;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90vw;
				max-width: 400px;
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				text-align: center;
				margin: 2em auto;
			}
			.welcome-card h1 {
				color: var(--accent-green);
				font-size: 2.2em;
				margin-bottom: 0.5em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
				word-break: break-word;
			}
			.welcome-card p {
				color: var(--text-primary);
				font-size: 1.1em;
				margin-bottom: 2em;
				word-break: break-word;
			}
			.welcome-card button {
				background-color: var(--accent-red);
				padding: 1em 2em;
				font-size: 1.1em;
				color: white;
				border: none;
				border-radius: 8px;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 0.5em;
				font-weight: 600;
				width: 100%;
			}
			.welcome-card button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			@media (max-width: 500px) {
				.welcome-card {
					padding: 1em;
					width: 98vw;
					max-width: 98vw;
				}
				.welcome-card h1 {
					font-size: 1.5em;
				}
				.welcome-card p {
					font-size: 1em;
				}
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="welcome-card">
			<h1><i class="fa-solid fa-circle-check"></i> Welcome, Admin!</h1>
			<p>You have successfully logged in using the Ring application backend.</p>
			<button onclick="window.closeApp()"><i class="fa-solid fa-power-off"></i> Close Application</button>
		</div>
	</body>
	</html>
	`
	oWebView.setHtml(cWelcomeHTML)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')


# Handles the request to close the application.
func closeApp(id, req)
	see "Ring: `closeApp` function called. Terminating webview." + nl
	oWebView.terminate() # Terminate the webview, closing the window.
