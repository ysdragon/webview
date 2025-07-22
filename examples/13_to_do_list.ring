# To-Do List Application
# This script implements a feature-rich to-do list application with task management,
# categorization, and persistence of data using a JSON file.

load "webview.ring"
load "jsonlib.ring"

# --- Global Variables ---
oWebView = NULL
aTodos = []
cTodosFile = "todos.json"

# ==================================================
# Main Application Flow
# ==================================================

func main()
	see "Setting up To-Do List Application..." + nl
	# Create a new WebView instance (debug mode enabled).
	oWebView = new WebView(1, NULL)

	# Set the window title.
	oWebView.setTitle("Ring To-Do List")
	# Set the window size (no size constraint).
	oWebView.setSize(700, 700, WEBVIEW_HINT_NONE)

	# Bind Ring functions to be callable from JavaScript.
	# These functions handle various to-do list operations.
	oWebView.bind("getInitialTodos", :handleGetInitialTodos) # Get initial state (todos and categories).
	oWebView.bind("addTodo", :handleAddTodo)                 # Add a new to-do item.
	oWebView.bind("toggleTodo", :handleToggleTodo)           # Toggle a to-do item's completion status.
	oWebView.bind("deleteTodo", :handleDeleteTodo)           # Delete a to-do item.
	oWebView.bind("getCategories", :handleGetCategories)     # Get unique categories for filtering.

	# Load the HTML content for the to-do list UI.
	loadTodoHTML()
	
	# Load existing to-do items from the persistence file.
	loadTodos()

	see "Running the WebView main loop. Interact with the to-do list." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	see "Cleaning up WebView resources and exiting." + nl
	# Destroy the webview instance.
	oWebView.destroy()

# Function to load the HTML content.
func loadTodoHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring To-Do List</title>
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

			.todo-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 700px;
				display: flex;
				flex-direction: column;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				height: 80vh;
			}
			h1 {
				text-align: center;
				color: var(--accent-green);
				margin-bottom: 30px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			.input-group {
				display: flex;
				margin-bottom: 20px;
				gap: 10px;
			}
			input[type="text"], select {
				flex-grow: 1;
				padding: 12px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				outline: none;
				background-color: var(--panel-bg); /* Explicitly set dark background */
				color: var(--text-primary);
				box-sizing: border-box;
				-webkit-appearance: none; /* Remove default styling for better consistency */
				-moz-appearance: none;
				appearance: none;
				background-image: url("data:image/svg+xml,%3Csvg xmlns=`http://www.w3.org/2000/svg` viewBox=`0 0 24 24` fill=`%23f8fafc`%3E%3Cpath d=`M7 10l5 5 5-5z`/%3E%3C/svg%3E");
				background-repeat: no-repeat;
				background-position: right 10px center;
				padding-right: 30px; /* Make space for the arrow */
			}
			input[type="text"]:focus, select:focus {
				border-color: var(--accent-cyan);
			}
			button {
				padding: 12px 20px;
				border: none;
				border-radius: 8px;
				background-color: var(--accent-blue);
				color: white;
				font-size: 1em;
				cursor: pointer;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				box-sizing: border-box;
			}
			button:hover {
				transform: translateY(-3px); /* Increased lift */
				box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4); /* Stronger shadow */
			}
			.category-filter {
				margin-bottom: 20px;
				display: flex;
				align-items: center;
				gap: 10px;
			}
			.category-filter label {
				color: var(--text-secondary);
			}
			.todo-list {
				list-style: none;
				padding: 0;
				margin: 0;
				flex-grow: 1;
				overflow-y: auto;
				color: var(--text-primary);
			}
			.todo-item {
				display: flex;
				align-items: center;
				padding: 12px 0;
				border-bottom: 1px solid var(--border-color);
				font-size: 1.1em;
				transition: background-color 0.3s ease; /* Smooth transition for hover */
			}
			.todo-item:hover {
				background-color: rgba(255, 255, 255, 0.03); /* Subtle hover background */
			}
			.todo-item:last-child {
				border-bottom: none;
			}
			.todo-item.completed span.todo-text {
				text-decoration: line-through;
				color: var(--text-secondary);
			}
			.todo-item input[type="checkbox"] {
				margin-right: 15px;
				width: 20px;
				height: 20px;
				cursor: pointer;
				accent-color: var(--accent-green);
			}
			.todo-text {
				flex-grow: 1;
			}
			.todo-category {
				font-size: 0.85em; /* Slightly larger font */
				background-color: var(--accent-purple);
				color: white;
				padding: 5px 10px; /* Increased padding */
				border-radius: 15px; /* More rounded corners */
				margin-left: 15px; /* Increased margin */
				flex-shrink: 0;
				border: 1px solid rgba(255, 255, 255, 0.2); /* Subtle border */
			}
			.delete-btn {
				background: none;
				border: none;
				color: var(--accent-red);
				font-size: 1.2em;
				cursor: pointer;
				transition: transform 0.2s ease;
			}
			.delete-btn:hover {
				transform: scale(1.2);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="todo-container">
			<h1><i class="fa-solid fa-clipboard-list"></i> To-Do List</h1>
			<div class="input-group">
				<input type="text" id="new-todo-input" placeholder="Add a new task...">
				<select id="todo-category-select">
					<option value="General">General</option>
				</select>
				<button onclick="addTodoItem()"><i class="fa-solid fa-plus"></i> Add</button>
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

			let allTodos = [];
			let allCategories = ["General"];

			function renderTodos() {
				const filter = filterCategorySelect.value;
				todoList.innerHTML = "";
				const filteredTodos = filter === "All" ? allTodos : allTodos.filter(todo => todo.category === filter);

				filteredTodos.forEach((todo, index) => {
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
				const initialData = await window.getInitialTodos();
				allTodos = initialData.todos || [];
				allCategories = initialData.categories || ["General"];
				updateCategorySelects();
				renderTodos();
			};
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles requests from JavaScript to get the initial list of to-do items and categories.
func handleGetInitialTodos(id, req)
	see "Ring: JavaScript requested initial todos and categories." + nl
	aJsonTodos = []
	for aTodo in aTodos
		add(aJsonTodos, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	
	aResult = [
		:todos = aJsonTodos,
		:categories = getUniqueCategories()
	]
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aResult)) # Return the data as a JSON string.

# Handles requests from JavaScript to add a new to-do item.
func handleAddTodo(id, req)
	aReq = json2list(req)[1] # Parse the request data.
	cTaskText = aReq[1] # Extract the task text.
	cCategory = aReq[2] # Extract the category.
	see "Ring: Adding new todo: '" + cTaskText + "' in category '" + cCategory + "'" + nl
	add(aTodos, [cTaskText, false, cCategory]) # Add the new to-do item (initially not completed).
	saveTodos() # Persist the updated list.
	updateUI() # Update the UI in the webview.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles requests from JavaScript to toggle the completion status of a to-do item.
func handleToggleTodo(id, req)
	nIndex = json2list(req)[1][1] # Extract the index of the to-do item.
	see "Ring: Toggling todo at index: " + nIndex + nl
	if nIndex >= 0 and nIndex < len(aTodos)
		aTodos[nIndex + 1][2] = not aTodos[nIndex + 1][2] # Toggle the boolean completed status.
		saveTodos() # Persist the updated list.
		updateUI() # Update the UI in the webview.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles requests from JavaScript to delete a to-do item.
func handleDeleteTodo(id, req)
	nIndex = json2list(req)[1][1] # Extract the index of the to-do item.
	see "Ring: Deleting todo at index: " + nIndex + nl
	if nIndex >= 0 and nIndex < len(aTodos)
		del(aTodos, nIndex + 1) # Delete the item from the list.
		saveTodos() # Persist the updated list.
		updateUI() # Update the UI in the webview.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles requests from JavaScript to get the list of unique categories.
func handleGetCategories(id, req)
	see "Ring: JavaScript requested categories." + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(getUniqueCategories())) # Return unique categories as JSON.

# --- Helper Functions ---

# Updates the UI in the webview by pushing the current state of todos and categories.
func updateUI()
	see "Ring: Pushing updated to-do list and categories to UI." + nl
	aJsonTodos = []
	for aTodo in aTodos
		add(aJsonTodos, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	
	aResult = [
		:todos = aJsonTodos,
		:categories = getUniqueCategories()
	]
	cJsonResult = list2json(aResult)
	# Construct JavaScript code to update the frontend's data and re-render.
	cJsCode = "allTodos = " + cJsonResult + ".todos; allCategories = " + cJsonResult + ".categories; updateCategorySelects(); renderTodos();"
	oWebView.evalJS(cJsCode) # Execute the JavaScript in the webview.

# Loads to-do items from the `todos.json` file.
func loadTodos()
	see "Loading todos from file: " + cTodosFile + nl
	if fexists(cTodosFile)
		try
			cJson = read(cTodosFile) # Read the JSON string from the file.
			aLoadedTodos = json2list(cJson)[1] # Parse the JSON into a Ring list.
			aTodos = [] # Clear existing in-memory todos before loading.
			for aItem in aLoadedTodos
				cTaskText = aItem["text"]
				bCompleted = aItem["completed"]
				cCategory = aItem["category"]
				if isNull(cCategory) cCategory = "General" ok # Assign "General" if category is missing.

				add(aTodos, [cTaskText, bCompleted, cCategory]) # Add the loaded item to the in-memory list.
			next
			see "Todos loaded successfully." + nl
		catch
			see "Error loading todos file. Starting with an empty list." + nl
			aTodos = [] # Revert to empty list on error.
		end
	else
		see "No todos file found. Starting with an empty list." + nl
		aTodos = [] # Start with an empty list if no file exists.
	ok

# Saves the current list of to-do items to the `todos.json` file.
func saveTodos()
	see "Saving todos to file: " + cTodosFile + nl
	aJsonList = []
	for aTodo in aTodos
		add(aJsonList, [:text = aTodo[1], :completed = aTodo[2], :category = aTodo[3]])
	next
	cJson = list2json(aJsonList) # Convert the list of todos to a JSON string.
	# Ensure the JSON is an array, not a single object if only one item exists.
	if left(cJson, 1) = "{"
		cJson = "[" + substr(cJson, 2, len(cJson)-2) + "]"
	ok
	write(cTodosFile, cJson) # Write the JSON string to the file.
	see "Todos saved successfully." + nl

# Returns a list of unique categories from the current to-do items.
func getUniqueCategories()
	aCategories = ["General"] # Always include "General" as a default category.
	for aTodo in aTodos
		if not find(aCategories, aTodo[3]) # If category is not already in the list, add it.
			add(aCategories, aTodo[3])
		ok
	next
	return aCategories