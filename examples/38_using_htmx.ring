# HTMX Example with Ring WebView
# This example demonstrates how to use HTMX with Ring WebView
# HTMX allows you to access AJAX, CSS Transitions, WebSockets and Server Sent Events
# directly in HTML, using attributes, without writing JavaScript.

load "webview.ring"
load "simplejson.ring"

# Global variable to hold the WebView instance.
oWebView = NULL

# Bindings for Ring functions to be callable from JavaScript/HTMX
aBindList = [
	["getRandomQuote", :handleGetQuote],
	["incrementCounter", :handleIncrementCounter],
	["loadUserData", :handleLoadUserData],
	["submitForm", :handleSubmitForm],
	["deleteItem", :handleDeleteItem]
]

nClickCount = 0

aQuotes = [
	"The only way to do great work is to love what you do. - Steve Jobs",
	"Innovation distinguishes between a leader and a follower. - Steve Jobs",
	"Code is like humor. When you have to explain it, it's bad. - Cory House",
	"First, solve the problem. Then, write the code. - John Johnson",
	"Experience is the name everyone gives to their mistakes. - Oscar Wilde",
	"Simplicity is the soul of efficiency. - Austin Freeman",
	"Make it work, make it right, make it fast. - Kent Beck"
]

func main()	
	# Create a new WebView instance.
	oWebView = new WebView()
	oWebView {
		# Set the window title.
		setTitle("Using HTMX with Ring WebView")

		# Set the window size.
		setSize(900, 700, WEBVIEW_HINT_NONE)

		# Load the HTML content with HTMX.
		loadHTMXHTML()
	    
		# Run the webview's main event loop.
	    run()
	}

# Defines the HTML structure with HTMX
func loadHTMXHTML()
	cHTML = `
<!DOCTYPE html>
<html>

<head>
	<title>HTMX with Ring WebView</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<script src="https://unpkg.com/htmx.org@2.0.4"></script>
	<script src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.7/dist/htmx.min.js"
		integrity="sha384-ZBXiYtYQ6hJ2Y0ZNoYuI+Nq5MqWBr+chMrS/RkXpNzQCApHEhOt2aY8EJgqwHLkJ"
		crossorigin="anonymous"></script>
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
			--accent-red: #f87171;
		}

		body {
			font-family: 'Inter', 'Segoe UI', sans-serif;
			background-color: var(--bg-color);
			color: var(--text-primary);
			margin: 0;
			padding: 20px;
			min-height: 100vh;
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

		.container {
			max-width: 850px;
			margin: 0 auto;
		}

		h1 {
			text-align: center;
			color: var(--accent-cyan);
			margin-bottom: 10px;
			font-size: 2.5em;
		}

		.subtitle {
			text-align: center;
			color: var(--text-secondary);
			margin-bottom: 40px;
			font-size: 1.1em;
		}

		.demo-section {
			background-color: var(--panel-bg);
			padding: 25px;
			border-radius: 12px;
			margin-bottom: 25px;
			border: 1px solid var(--border-color);
			backdrop-filter: blur(12px);
			-webkit-backdrop-filter: blur(12px);
		}

		.demo-section h2 {
			color: var(--accent-blue);
			margin-top: 0;
			margin-bottom: 15px;
			font-size: 1.5em;
		}

		.demo-section p {
			color: var(--text-secondary);
			margin-bottom: 15px;
		}

		button {
			background-color: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 8px;
			padding: 12px 24px;
			font-size: 1em;
			cursor: pointer;
			transition: all 0.2s ease;
			box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
		}

		button:hover {
			transform: translateY(-2px);
			box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			background-color: #2563eb;
		}

		button.delete-btn {
			background-color: var(--accent-red);
			padding: 8px 16px;
			font-size: 0.9em;
		}

		button.delete-btn:hover {
			background-color: #ef4444;
		}

		#quote-display {
			background-color: rgba(0, 0, 0, 0.2);
			padding: 20px;
			border-radius: 8px;
			margin: 15px 0;
			border-left: 4px solid var(--accent-cyan);
			font-style: italic;
			min-height: 50px;
		}

		#counter-display {
			font-size: 3em;
			text-align: center;
			color: var(--accent-green);
			margin: 20px 0;
			font-weight: bold;
		}

		.user-card {
			background-color: rgba(0, 0, 0, 0.2);
			padding: 20px;
			border-radius: 8px;
			margin-top: 15px;
			border: 1px solid var(--border-color);
		}

		.user-card h3 {
			color: var(--accent-purple);
			margin-top: 0;
		}

		.user-info {
			display: grid;
			grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
			gap: 10px;
			margin-top: 10px;
		}

		.user-info-item {
			display: flex;
			align-items: center;
			gap: 8px;
		}

		.loading {
			text-align: center;
			color: var(--accent-cyan);
			padding: 20px;
		}

		input,
		select {
			width: 100%;
			padding: 12px;
			border: 1px solid var(--border-color);
			border-radius: 8px;
			background-color: rgba(255, 255, 255, 0.05);
			color: var(--text-primary);
			font-size: 1em;
			margin-bottom: 15px;
		}

		input:focus,
		select:focus {
			outline: none;
			border-color: var(--accent-cyan);
		}

		label {
			display: block;
			margin-bottom: 5px;
			color: var(--text-secondary);
		}

		.success-message {
			background-color: rgba(74, 222, 128, 0.2);
			color: var(--accent-green);
			padding: 15px;
			border-radius: 8px;
			margin-top: 15px;
			border: 1px solid var(--accent-green);
		}

		.item-list {
			list-style: none;
			padding: 0;
			margin: 15px 0;
		}

		.item-list li {
			background-color: rgba(0, 0, 0, 0.2);
			padding: 15px;
			border-radius: 8px;
			margin-bottom: 10px;
			display: flex;
			justify-content: space-between;
			align-items: center;
			border: 1px solid var(--border-color);
		}

		.htmx-swapping {
			opacity: 0;
			transition: opacity 0.3s ease;
		}

		.htmx-settling {
			opacity: 1;
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
		<h1><i class="fa-solid fa-bolt"></i> HTMX with Ring WebView</h1>
		<p class="subtitle">Interactive examples demonstrating HTMX integration with Ring backend</p>

		<!-- Example 1: Simple Content Swap -->
		<div class="demo-section">
			<h2><i class="fa-solid fa-quote-left"></i> 1. Content Swapping</h2>
			<p>Click the button to fetch a random quote from the Ring backend using HTMX.</p>
			<button onclick="triggerQuote()">Get Random Quote</button>
			<div id="quote-display">Click the button to load a quote...</div>
		</div>

		<!-- Example 2: Counter -->
		<div class="demo-section">
			<h2><i class="fa-solid fa-calculator"></i> 2. Stateful Counter</h2>
			<p>This counter is maintained on the Ring backend. Each click sends a request to increment it.</p>
			<div id="counter-display">0</div>
			<button onclick="triggerIncrement()">Increment Counter</button>
		</div>

		<!-- Example 3: Load External Data -->
		<div class="demo-section">
			<h2><i class="fa-solid fa-user"></i> 3. Load User Data</h2>
			<p>Simulate loading user data from the backend with a loading indicator.</p>
			<button onclick="triggerLoadUser()">Load User Profile</button>
			<div id="user-container"></div>
		</div>

		<!-- Example 4: Form Submission -->
		<div class="demo-section">
			<h2><i class="fa-solid fa-paper-plane"></i> 4. Form Submission</h2>
			<p>Submit form data to the Ring backend and receive a response.</p>
			<form onsubmit="event.preventDefault(); triggerFormSubmit();">
				<label>Name:</label>
				<input type="text" id="form-name" placeholder="Enter your name" value="John Doe" required>
				<label>Email:</label>
				<input type="email" id="form-email" placeholder="Enter your email" value="john@example.com" required>
				<label>Role:</label>
				<select id="form-role">
					<option value="developer">Developer</option>
					<option value="designer">Designer</option>
					<option value="manager">Manager</option>
				</select>
				<button type="submit">Submit Form</button>
			</form>
			<div id="form-response"></div>
		</div>

		<!-- Example 5: Dynamic List with Delete -->
		<div class="demo-section">
			<h2><i class="fa-solid fa-list"></i> 5. Dynamic List Management</h2>
			<p>Click delete to remove items. HTMX handles the DOM updates automatically.</p>
			<ul class="item-list" id="item-list">
				<li id="item-1">
					<span><i class="fa-solid fa-folder"></i> Project Documentation</span>
					<button class="delete-btn" onclick="triggerDelete('item-1')">
						<i class="fa-solid fa-trash"></i> Delete
					</button>
				</li>
				<li id="item-2">
					<span><i class="fa-solid fa-code"></i> Source Code</span>
					<button class="delete-btn" onclick="triggerDelete('item-2')">
						<i class="fa-solid fa-trash"></i> Delete
					</button>
				</li>
				<li id="item-3">
					<span><i class="fa-solid fa-image"></i> Design Assets</span>
					<button class="delete-btn" onclick="triggerDelete('item-3')">
						<i class="fa-solid fa-trash"></i> Delete
					</button>
				</li>
			</ul>
		</div>
	</div>

	<script>
		// Helper functions to bridge HTMX with Ring WebView bindings

		async function triggerQuote() {
			const result = await window.getRandomQuote();
			document.getElementById('quote-display').innerHTML = result;
		}

		async function triggerIncrement() {
			const result = await window.incrementCounter();
			document.getElementById('counter-display').innerHTML = result;
		}

		async function triggerLoadUser() {
			const container = document.getElementById('user-container');
			container.innerHTML = '<div class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Loading user data...</div>';

			setTimeout(async () => {
				const result = await window.loadUserData();
				container.innerHTML = result;
			}, 500);
		}

		async function triggerFormSubmit() {
			const name = document.getElementById('form-name').value;
			const email = document.getElementById('form-email').value;
			const role = document.getElementById('form-role').value;

			const formData = JSON.stringify({ name: name, email: email, role: role });
			const result = await window.submitForm(formData);
			document.getElementById('form-response').innerHTML = result;
		}

		async function triggerDelete(itemId) {
			const result = await window.deleteItem(itemId);
			console.log('Delete result:', result, 'Type:', typeof result);
			if (result && (result === 'OK' || result === '"OK"' || result.includes('OK'))) {
				const element = document.getElementById(itemId);
				if (element) {
					element.style.transition = 'opacity 0.3s ease';
					element.style.opacity = '0';
					setTimeout(() => element.remove(), 300);
				}
			}
		}
	</script>
</body>

</html>
	`
	oWebView.setHtml(cHTML)

# Ring Callback Handlers

# Handler for getting a random quote
func handleGetQuote(id, req)
	nIndex = random(len(aQuotes) - 1) + 1
	cQuote = aQuotes[nIndex]
	cHTML = '<i class="fa-solid fa-quote-left"></i> ' + cQuote
	see "Ring: Serving random quote #" + nIndex + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([cHTML]))

# Handler for incrementing the counter
func handleIncrementCounter(id, req)
	nClickCount++
	see "Ring: Counter incremented to " + nClickCount + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([nClickCount]))

# Handler for loading user data
func handleLoadUserData(id, req)
	see "Ring: Loading user data..." + nl
	
	cHTML = '
	<div class="user-card">
		<h3><i class="fa-solid fa-id-card"></i> User Profile</h3>
		<div class="user-info">
			<div class="user-info-item">
				<i class="fa-solid fa-user"></i>
				<strong>Name:</strong> Alice Johnson
			</div>
			<div class="user-info-item">
				<i class="fa-solid fa-envelope"></i>
				<strong>Email:</strong> alice@example.com
			</div>
			<div class="user-info-item">
				<i class="fa-solid fa-briefcase"></i>
				<strong>Role:</strong> Senior Developer
			</div>
			<div class="user-info-item">
				<i class="fa-solid fa-calendar"></i>
				<strong>Joined:</strong> January 2023
			</div>
		</div>
	</div>
	'
	
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([cHTML]))

# Handler for form submission
func handleSubmitForm(id, req)
	aFormData = json_decode(json_decode(req)[1])
	
	cName = aFormData[:name]
	cEmail = aFormData[:email]
	cRole = aFormData[:role]
	
	see "Ring: Form submitted - Name: " + cName + ", Email: " + cEmail + ", Role: " + cRole + nl
	
	cHTML = '
	<div class="success-message">
		<i class="fa-solid fa-circle-check"></i> 
		<strong>Success!</strong> Form submitted successfully.<br><br>
		<strong>Name:</strong> ' + cName + '<br>
		<strong>Email:</strong> ' + cEmail + '<br>
		<strong>Role:</strong> ' + cRole + '
	</div>
	'
	
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([cHTML]))

# Handler for deleting items
func handleDeleteItem(id, req)
	cItemId = json_decode(req)[1]
	see "Ring: Deleting item: " + cItemId + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode(["OK"]))
