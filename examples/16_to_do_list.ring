# To-Do List Application
# This script implements a feature-rich to-do list application with task management,
# categorization, and persistence of data using a JSON file.

load "webview.ring"
load "simplejson.ring"

# Global Variables
oWebView = NULL
aTodos = []
aSettings = []
cTodosFile = "todos.json"
cTodoSettingsFile = "todo_settings.json"
aBindList = [
	["getInitialSettings", :handleGetInitialSettings],
	["saveSettings", :handleSaveSettings],
	["getInitialTodos", :handleGetInitialTodos],
	["addTodo", :handleAddTodo],
	["toggleTodo", :handleToggleTodo],
	["deleteTodo", :handleDeleteTodo],
	["getCategories", :handleGetCategories],
]
	
# ==================================================
# Main Application Flow
# ==================================================

func main()
	# Load user preferences (e.g., theme setting) from a file.
	aSettings = loadSettings()
	# Load existing todos from a file at application startup.
	loadTodos()
	? "Setting up To-Do List Application..."
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring To-Do List")
	# Set the window size (no size constraint).
	oWebView.setSize(700, 700, WEBVIEW_HINT_NONE)

	# Load the HTML content for the to-do list UI.
	loadTodoHTML()

	? "Running the WebView main loop. Interact with the to-do list."
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	? "Cleaning up WebView resources and exiting."

# Function to load the HTML content.
func loadTodoHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring To-Do List</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fira+Code:wght@400;500&display=swap");
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
			:root.light {
				--bg-primary: #f8fafc;
				--bg-secondary: #ffffff;
				--card-bg: rgba(255, 255, 255, 0.8);
				--card-border: rgba(148, 163, 184, 0.2);
				--text-primary: #1e293b;
				--text-secondary: #475569;
				--text-muted: #64748b;
			}

			body {
				font-family: "Inter", sans-serif;
				background: var(--bg-primary);
				color: var(--text-primary);
				margin: 0;
				height: 100vh;
				overflow: hidden;
				position: relative;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				transition: background 0.3s cubic-bezier(0.4, 0, 0.2, 1);
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

			.todo-container {
				background: var(--card-bg);
				padding: clamp(1.5rem, 4vw, 2.5rem);
				border-radius: 20px;
				box-shadow: var(--shadow-lg), 0 0 0 1px var(--card-border);
				width: min(90vw, 40rem);
				display: flex;
				flex-direction: column;
				position: relative;
				z-index: 10;
				border: 1px solid var(--card-border);
				backdrop-filter: blur(var(--blur-lg));
				-webkit-backdrop-filter: blur(var(--blur-lg));
				height: min(85vh, 48rem);
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
			}
			.todo-container:hover {
				transform: translateY(-4px);
				box-shadow: var(--shadow-lg), 0 25px 50px -12px rgba(0, 0, 0, 0.25);
				border-color: rgba(59, 130, 246, 0.3);
			}
			.todo-header {
				display: flex;
				justify-content: space-between;
				align-items: center;
				margin-bottom: clamp(1.5rem, 4vw, 2rem);
				padding-bottom: clamp(0.75rem, 2vw, 1rem);
				border-bottom: 1px solid var(--card-border);
			}
			h1 {
				margin: 0;
				font-size: clamp(1.5rem, 5vw, 2rem);
				font-weight: 700;
				letter-spacing: -0.025em;
				text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
				display: flex;
				align-items: center;
				gap: 0.75rem;
				text-align: left;
				color: var(--text-primary);
			}
			h1 i {
				color: var(--accent-warning);
				font-size: clamp(1.2rem, 4vw, 1.6rem);
			}
			.title-text {
				order: 1;
			}
			.control-btn {
				background: rgba(148, 163, 184, 0.05);
				border: 1px solid var(--card-border);
				border-radius: 10px;
				padding: clamp(0.5rem, 2vw, 0.75rem);
				font-size: clamp(0.9rem, 2.5vw, 1.1rem);
				cursor: pointer;
				color: var(--text-primary);
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-sm));
				font-weight: 600;
				min-width: 44px;
				min-height: 44px;
				display: flex;
				align-items: center;
				justify-content: center;
				font-family: inherit;
			}
			.control-btn:hover {
				transform: translateY(-2px);
				background: rgba(59, 130, 246, 0.1);
				border-color: var(--accent-primary);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
			}
			.input-group {
				display: flex;
				margin-bottom: clamp(1.25rem, 3vw, 1.75rem);
				gap: clamp(0.75rem, 2vw, 1rem);
				align-items: stretch;
			}
			textarea, select {
				flex-grow: 1;
				padding: clamp(0.75rem, 2vw, 1rem);
				border: 1px solid var(--card-border);
				border-radius: 12px;
				font-size: clamp(0.9rem, 2.5vw, 1rem);
				outline: none;
				background: rgba(148, 163, 184, 0.05);
				color: var(--text-primary);
				resize: vertical;
				min-height: clamp(3.5rem, 8vw, 4rem);
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-sm));
				font-family: inherit;
				line-height: 1.5;
				-webkit-appearance: none;
				appearance: none;
				background-image: url("data:image/svg+xml,%3Csvg xmlns=`http://www.w3.org/2000/svg` viewBox=`0 0 24 24` fill=`%23f1f5f9`%3E%3Cpath d=`M7 10l5 5 5-5z`/%3E%3C/svg%3E");
				background-repeat: no-repeat;
				background-position: right 10px center;
				padding-right: 30px;
			}
			select.minimal {
				flex-grow: 0;
				flex-basis: 150px;
			}
			textarea:focus, select:focus {
				border-color: var(--accent-primary);
				box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
				background: rgba(59, 130, 246, 0.05);
				transform: translateY(-1px);
			}
			button {
				padding: clamp(0.75rem, 2vw, 1rem) clamp(1rem, 3vw, 1.5rem);
				border: none;
				border-radius: 12px;
				background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
				color: white;
				font-size: clamp(0.9rem, 2.5vw, 1rem);
				font-weight: 600;
				cursor: pointer;
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
				backdrop-filter: blur(var(--blur-sm));
				border: 1px solid rgba(255, 255, 255, 0.1);
				white-space: nowrap;
				min-height: 44px;
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 0.5rem;
				font-family: inherit;
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 8px 20px rgba(59, 130, 246, 0.4);
				background: linear-gradient(135deg, #60a5fa, #a78bfa);
			}
			button:active {
				transform: translateY(0);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
			}
			.category-filter {
				margin-bottom: clamp(1.25rem, 3vw, 1.75rem);
				display: flex;
				align-items: center;
				gap: 1rem;
			}
			.category-filter label {
				color: var(--text-secondary);
				font-weight: 500;
				font-size: clamp(0.9rem, 2.5vw, 1rem);
			}
			.todo-list {
				list-style: none;
				padding: 0;
				margin: 0;
				flex-grow: 1;
				overflow-y: auto;
				color: var(--text-primary);
				border-radius: 12px;
				background: rgba(148, 163, 184, 0.02);
				border: 1px solid var(--card-border);
				padding: clamp(0.75rem, 2vw, 1rem);
				min-height: clamp(12rem, 30vh, 20rem);
				backdrop-filter: blur(var(--blur-sm));
				-webkit-backdrop-filter: blur(var(--blur-sm));
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
			}
			.todo-item {
				display: flex;
				align-items: center;
				padding: clamp(0.75rem, 2vw, 1rem);
				border-radius: 12px;
				margin-bottom: clamp(0.75rem, 2vw, 1rem);
				border: 1px solid var(--card-border);
				background: rgba(148, 163, 184, 0.05);
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-sm));
				-webkit-backdrop-filter: blur(var(--blur-sm));
				position: relative;
				overflow: hidden;
			}
			.todo-item:hover {
				transform: translateY(-2px);
				background: rgba(59, 130, 246, 0.08);
				border-color: rgba(59, 130, 246, 0.3);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
			}
			.todo-item:last-child {
				margin-bottom: 0;
			}
			.todo-item.completed .todo-text {
				text-decoration: line-through;
				color: var(--text-muted);
			}
			.todo-item input[type="checkbox"] {
				margin-right: clamp(0.75rem, 2vw, 1rem);
				width: 20px;
				height: 20px;
				cursor: pointer;
				accent-color: var(--accent-success);
			}
			.todo-text {
				flex-grow: 1;
				font-size: clamp(1rem, 2.5vw, 1.1rem);
				line-height: 1.6;
				font-weight: 400;
				word-wrap: break-word;
			}
			.todo-category {
				font-size: clamp(0.8rem, 2vw, 0.85rem);
				font-weight: 500;
				background: linear-gradient(135deg, var(--accent-secondary), var(--accent-cyan));
				color: white;
				padding: clamp(0.3rem, 1vw, 0.5rem) clamp(0.75rem, 2vw, 1rem);
				border-radius: 20px;
				margin-left: clamp(0.75rem, 2vw, 1rem);
				flex-shrink: 0;
				border: 1px solid rgba(255, 255, 255, 0.2);
				backdrop-filter: blur(var(--blur-sm));
			}
			.delete-btn {
				background: none;
				border: none;
				color: var(--accent-danger);
				font-size: 1.2em;
				cursor: pointer;
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				margin-left: clamp(0.5rem, 1.5vw, 0.75rem);
				padding: clamp(0.4rem, 1.5vw, 0.5rem);
				border-radius: 8px;
				min-width: 44px;
				min-height: 44px;
				display: flex;
				align-items: center;
				justify-content: center;
			}
			.delete-btn:hover {
				transform: scale(1.1);
				background: rgba(239, 68, 68, 0.1);
			}

			::-webkit-scrollbar {
				width: 8px;
				height: 8px;
			}
			::-webkit-scrollbar-track {
				background: rgba(148, 163, 184, 0.05);
				border-radius: 8px;
				margin: 4px;
			}
			::-webkit-scrollbar-thumb {
				background: linear-gradient(45deg, var(--accent-primary), var(--accent-secondary));
				border-radius: 8px;
				border: 1px solid rgba(255, 255, 255, 0.1);
				transition: all 0.3s ease;
			}
			::-webkit-scrollbar-thumb:hover {
				background: linear-gradient(45deg, var(--accent-secondary), var(--accent-cyan));
				box-shadow: 0 0 8px rgba(59, 130, 246, 0.3);
			}
			::-webkit-scrollbar-corner {
				background: rgba(148, 163, 184, 0.05);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>

		<div class="todo-container">
			<div class="todo-header">
				<h1><i class="fa-solid fa-clipboard-list"></i><span class="title-text">To-Do List</span></h1>
				<button id="theme-toggle" class="control-btn">
					<i class="fa-solid fa-circle-half-stroke"></i>
				</button>
			</div>
			<div class="input-group">
				<textarea id="new-todo-input" placeholder="Write a new task..."></textarea>
				<select id="todo-category-select" class="minimal">
					<option value="General">General</option>
				</select>
				<button onclick="addTodoItem()"><i class="fa-solid fa-plus"></i> Add Task</button>
			</div>
			<div class="category-filter">
				<label for="filter-category">Filter by Category:</label>
				<select id="filter-category" onchange="renderTodos()">
					<option value="All">All</option>
				</select>
			</div>
			<ul id="todo-list" class="todo-list">
				<!-- To-do items will be rendered here -->
			</ul>
		</div>

		<script>
			const todoInput = document.getElementById("new-todo-input");
			const todoCategorySelect = document.getElementById("todo-category-select");
			const filterCategorySelect = document.getElementById("filter-category");
			const todoList = document.getElementById("todo-list");
			const themeToggleBtn = document.getElementById("theme-toggle");
			const htmlElement = document.documentElement;

			let allTodos = [];
			let allCategories = ["General"];
			let currentTheme;

			function setTheme(theme) {
				currentTheme = theme;
				htmlElement.classList.add(theme);
				htmlElement.classList.remove(theme === "light" ? "dark" : "light");
				const icon = themeToggleBtn.querySelector("i");
				if (theme === "light") {
					icon.classList.remove("fa-moon");
					icon.classList.add("fa-sun");
				} else {
					icon.classList.remove("fa-sun");
					icon.classList.add("fa-moon");
				}
			}

			async function setThemeAndSave(theme) {
				setTheme(theme);
				await window.saveSettings(theme);
			}

			themeToggleBtn.addEventListener("click", () => {
				const newTheme = currentTheme === "light" ? "dark" : "light";
				setThemeAndSave(newTheme);
			});

			function renderTodos() {
				const filter = filterCategorySelect.value;
				todoList.innerHTML = "";
				const filteredTodos = filter === "All" ? allTodos : allTodos.filter(todo => todo.category === filter);

				filteredTodos.forEach((todo) => {
					const li = document.createElement("li");
					li.className = `todo-item ${todo.completed ? "completed" : ""}`;
					li.innerHTML = `
						<input type="checkbox" ${todo.completed ? "checked" : ""} onchange="toggleTodoItem(${allTodos.indexOf(todo)})">
						<span class="todo-text">${escapeHTML(todo.text)}</span>
						<span class="todo-category">${escapeHTML(todo.category)}</span>
						<button class="delete-btn" onclick="deleteTodoItem(${allTodos.indexOf(todo)})"><i class="fa-solid fa-trash-can"></i></button>
					`;
					todoList.appendChild(li);
				});
				todoList.scrollTop = todoList.scrollHeight;
			}

			function updateCategorySelects() {
				todoCategorySelect.innerHTML = "";
				filterCategorySelect.innerHTML = `<option value="All">All</option>`;
				allCategories.forEach(cat => {
					const option1 = document.createElement("option");
					option1.value = cat;
					option1.textContent = cat;
					todoCategorySelect.appendChild(option1);

					const option2 = document.createElement("option");
					option2.value = cat;
					option2.textContent = cat;
					filterCategorySelect.appendChild(option2);
				});
			}

			function escapeHTML(str) {
				const div = document.createElement("div");
				div.appendChild(document.createTextNode(str));
				return div.innerHTML;
			}

			async function addTodoItem() {
				const text = todoInput.value.trim();
				const category = todoCategorySelect.value;
				if (text) {
					await window.addTodo(text, category);
					todoInput.value = "";
				}
			}

			async function toggleTodoItem(index) {
				await window.toggleTodo(index);
			}

			async function deleteTodoItem(index) {
				await window.deleteTodo(index);
			}

			window.onload = async () => {
				try {
					const initialSettings = await window.getInitialSettings();
					const initialTheme = initialSettings.theme || "dark";
					setTheme(initialTheme);

					const initialData = await window.getInitialTodos();
					allTodos = initialData.todos || [];
					allCategories = initialData.categories || ["General"];
					updateCategorySelects();
					renderTodos();
				} catch (error) {
					console.error("Error initializing app:", error);
				}
			};
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# Ring Callback Handlers (Bound to JavaScript)

# Handles requests from JavaScript to get the initial list of to-do items and categories.
func handleGetInitialTodos(id, req)
	? "Ring: JavaScript requested initial todos and categories."
	aJsonTodos = []
	for aTodo in aTodos
		add(aJsonTodos, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	
	aResult = [
		:todos = aJsonTodos,
		:categories = getUniqueCategories()
	]
	
	# Return the data as a JSON string
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode(aResult))

# Handles requests from JavaScript to add a new to-do item.
func handleAddTodo(id, req)
	# Parse the request data.
	aReq = json_decode(req)
	# Extract the task text.
	cTaskText = aReq[1]
	# Extract the category.
	cCategory = aReq[2]
	? "Ring: Adding new todo: '" + cTaskText + "' in category '" + cCategory + "'"
	# Add the new to-do item (initially not completed).
	add(aTodos, [cTaskText, false, cCategory])
	# Persist the updated list.
	saveTodos()
	# Update the UI in the webview.
	updateUI()

	# Acknowledge the call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Handles requests from JavaScript to toggle the completion status of a to-do item.
func handleToggleTodo(id, req)
	# Extract the index of the to-do item.
	nIndex = json_decode(req)[1]
	? "Ring: Toggling todo at index: " + nIndex
	if nIndex >= 0 and nIndex < len(aTodos)
		# Toggle the boolean completed status.
		aTodos[nIndex + 1][2] = not aTodos[nIndex + 1][2]
		# Persist the updated list.
		saveTodos()
		# Update the UI in the webview.
		updateUI()
	ok

	# Acknowledge the call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Handles requests from JavaScript to delete a to-do item.
func handleDeleteTodo(id, req)
	# Extract the index of the to-do item.
	nIndex = json_decode(req)[1]
	? "Ring: Deleting todo at index: " + nIndex
	if nIndex >= 0 and nIndex < len(aTodos)
		# Delete the item from the list.
		del(aTodos, nIndex + 1)
		# Persist the updated list.
		saveTodos()
		# Update the UI in the webview.
		updateUI()
	ok

	# Acknowledge the call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Handles requests from JavaScript to get the list of unique categories.
func handleGetCategories(id, req)
	? "Ring: JavaScript requested categories."
	
	# Return unique categories as JSON.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode(getUniqueCategories()))

# Handles requests from JavaScript to get the initial application settings.
func handleGetInitialSettings(id, req)
	? "Ring: JavaScript requested initial settings."
	# Create a Ring list structure
	aSettingsObj = []
	for aSetting in aSettings
		# Add each setting as a key-value pair
		add(aSettingsObj, [aSetting[1], aSetting[2]])
	next
	# Convert the Ring list to JSON using json_encode
	cJson = json_encode(aSettingsObj)

	# Return settings as a JSON object.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson)

# Handles requests from JavaScript to save updated settings.
func handleSaveSettings(id, req)
	# Parse the request data.
	req = json_decode(req)
	
	# Extract the theme setting.
	cTheme = req[1]
	? "Ring: JavaScript requested to save settings. New theme: '" + cTheme + "'"

	# Update the global settings list with the new theme.
	aSettings[1][2] = cTheme

	# Persist the updated settings to a file.
	saveSettings()
	
	# Acknowledge the call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

# Helper Functions

# Updates the UI in the webview by pushing the current state of todos and categories.
func updateUI()
	? "Ring: Pushing updated to-do list and categories to UI."
	aJsonTodos = []
	for aTodo in aTodos
		add(aJsonTodos, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	
	aResult = [
		:todos = aJsonTodos,
		:categories = getUniqueCategories()
	]
	
	# Convert Ring list to JSON.
	cJsonResult = json_encode(aResult)
	
	# Construct JavaScript code to update the frontend's data and re-render.
	cJsCode = "allTodos = " + cJsonResult + ".todos; allCategories = " + cJsonResult + ".categories; updateCategorySelects(); renderTodos();"
	
	# Execute the JavaScript in the webview.
	oWebView.evalJS(cJsCode)

# Loads to-do items from the `todos.json` file.
func loadTodos()
	? "Loading todos from file: " + cTodosFile
	if fexists(cTodosFile)
		try
			# Read the JSON string from the file.
			cJson = read(cTodosFile)
			# Parse the JSON into a Ring list.
			aLoadedTodos = json_decode(cJson)
			# Clear existing in-memory todos before loading.
			aTodos = []
			for aItem in aLoadedTodos
				cTaskText = aItem[:text]
				bCompleted = aItem[:completed]
				cCategory = aItem[:category]
				# Assign "General" if category is missing.
				if isNull(cCategory)
					cCategory = "General"
				ok

				# Add the loaded item to the in-memory list.
				add(aTodos, [cTaskText, bCompleted, cCategory])
			next
			? "Todos loaded successfully."
		catch
			? "Error loading todos file. Starting with an empty list."
			# Revert to empty list on error.
			aTodos = []
		end
	else
		? "No todos file found. Starting with an empty list."
		# Start with an empty list if no file exists.
		aTodos = []
	ok

# Saves the current list of to-do items to the `todos.json` file.
func saveTodos()
	? "Saving todos to file: " + cTodosFile
	aJsonList = []
	for aTodo in aTodos
		add(aJsonList, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	
	# Convert the list of todos to a JSON string.
	cJson = json_encode(aJsonList)

	# Write the JSON string to the file.
	write(cTodosFile, cJson)
	? "Todos saved successfully."

# Returns a list of unique categories from the current to-do items.
func getUniqueCategories()
	# Always include "General" as a default category.
	aCategories = ["General"]
	for aTodo in aTodos
		# If category is not already in the list, add it.
		if not find(aCategories, aTodo[3])
			add(aCategories, aTodo[3])
		ok
	next
	return aCategories

# Loads application settings from `todo_settings.json`.
func loadSettings()
	? "Loading application settings from file: " + cTodoSettingsFile
	if fexists(cTodoSettingsFile)
		try
			# Read the JSON string from the file.
			cJson = read(cTodoSettingsFile)
			# Parse the JSON into a Ring list.
			tempSettings = json_decode(cJson)
			? "Settings loaded successfully."
			return tempSettings
		catch
			? "Error loading settings file. Creating default settings."
			# Create defaults on error.
			return createDefaultSettings()
		end
	else
		? "No settings file found. Creating default settings."
		# Create defaults if no file exists.
		return createDefaultSettings()
	ok

# Creates and returns a default set of application settings.
func createDefaultSettings()
	# Default theme is dark.
	return [
		:theme = "dark"
	]

# Saves the current application settings to `todo_settings.json`.
func saveSettings()
	# Convert settings list to JSON string.
	cJson = json_encode(aSettings)
	# Write JSON string to file.
	write(cTodoSettingsFile, cJson)
	? "Settings saved to file: " + cTodoSettingsFile
