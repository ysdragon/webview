# Simple Notes Application

load "webview.ring"
load "jsonlib.ring"

# --- Global Variables ---
oWebView = NULL # Instance of the WebView class

# Bind Ring functions to be callable from JavaScript.
# These functions handle various notes and settings operations.
aBindList = [
	["getInitialNotes", :handleGetInitialNotes],     # Get initial notes data
	["addNote", :handleAddNote],                     # Add a new note
	["editNote", :handleEditNote],                   # Edit an existing note
	["deleteNote", :handleDeleteNote],               # Delete a note
	["getInitialSettings", :handleGetInitialSettings], # Get initial settings (e.g., language)
	["saveSettings", :handleSaveSettings]            # Save updated settings
]

aNotes = [] # Each item will be [cNoteText, cTimestamp]
cNotesFile = "notes.json" # File to store notes
cNotesSettingsFile = "notes_settings.json" # File to store settings
aSettings = [] # Will hold language setting

func main()
	# Load user preferences (e.g., language setting) from a file.
	aSettings = loadSettings()
	# Load existing notes from a file at application startup.
	loadNotes()
	see "Setting up Notes Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Notes")
	# Set the window size (no size constraint).
	oWebView.setSize(600, 700, WEBVIEW_HINT_NONE)

	# Load the HTML content for the notes application UI.
	loadNotesHTML()

	see "Running the WebView main loop. Interact with the notes app." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	see "Cleaning up WebView resources and exiting." + nl
	# Destroy the webview instance.
	oWebView.destroy()

# Defines the HTML structure and inline JavaScript for the notes application.
func loadNotesHTML()
	cHTML = '
	<!DOCTYPE html>
	<html lang="en" dir="ltr">
	<head>
		<title>Ring Notes App</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&family=Tajawal:wght@400;500;700&display=swap");
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
			html[lang="ar"] body { font-family: "Tajawal", sans-serif; }
			html[dir="rtl"] body { direction: rtl; }

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

			.notes-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 500px;
				display: flex;
				flex-direction: column;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				height: 80vh;
			}
			.notes-header {
				display: flex;
				justify-content: space-between;
				align-items: center;
				margin-bottom: 25px;
			}
			h1 {
				text-align: center;
				color: var(--accent-yellow);
				margin: 0;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			html[dir="rtl"] h1 { text-align: right; }

			.control-btn {
				background: none;
				border: none;
				font-size: 1.2em;
				cursor: pointer;
				color: var(--text-primary);
				transition: transform 0.2s;
			}
			.control-btn:hover {
				transform: scale(1.1);
			}

			.input-group {
				display: flex;
				margin-bottom: 20px;
				gap: 10px;
			}
			html[dir="rtl"] .input-group { flex-direction: row-reverse; }
			textarea {
				flex-grow: 1;
				padding: 12px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				outline: none;
				background-color: rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
				resize: vertical;
				min-height: 60px;
			}
			textarea:focus {
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
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			.notes-list {
				list-style: none;
				padding: 0;
				margin: 0;
				flex-grow: 1;
				overflow-y: auto;
				color: var(--text-primary);
			}
			.note-item {
				background-color: rgba(255, 255, 255, 0.05);
				padding: 15px;
				border-radius: 10px;
				margin-bottom: 10px;
				border: 1px solid var(--border-color);
				display: flex;
				flex-direction: column;
				gap: 8px;
			}
			html[dir="rtl"] .note-item { flex-direction: column; }

			.note-content {
				flex-grow: 1;
				font-size: 1.1em;
				white-space: pre-wrap;
			}
			html[dir="rtl"] .note-content { text-align: right; }

			.note-timestamp {
				font-size: 0.85em;
				color: var(--text-secondary);
				text-align: right;
			}
			html[dir="rtl"] .note-timestamp { text-align: left; }

			.note-actions {
				display: flex;
				justify-content: flex-end;
				gap: 10px;
			}
			html[dir="rtl"] .note-actions { justify-content: flex-start; }
			.note-actions button {
				padding: 8px 12px;
				font-size: 0.9em;
				margin-left: 0;
			}
			.note-actions .edit-btn {
				background-color: var(--accent-green);
			}
			.note-actions .edit-btn:hover {
				background-color: #22c55e;
			}
			.note-actions .delete-btn {
				background-color: var(--accent-red);
			}
			.note-actions .delete-btn:hover {
				background-color: #dc2626;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="notes-container">
			<div class="notes-header">
				<h1 id="ui-title"><i class="fa-solid fa-note-sticky"></i> My Notes</h1>
				<button id="lang-toggle" class="control-btn"></button>
			</div>
			<div class="input-group">
				<textarea id="new-note-input"></textarea>
				<button id="add-note-btn" onclick="addNoteItem()"></button>
			</div>
			<ul id="notes-list" class="notes-list">
				<!-- Notes will be rendered here -->
			</ul>
		</div>

		<script>
			const noteInput = document.getElementById("new-note-input");
			const addNoteBtn = document.getElementById("add-note-btn");
			const notesList = document.getElementById("notes-list");
			let editingIndex = -1; // -1 means no note is being edited
			let currentLang;

			const uiStrings = {
				en: {
					title: `My Notes`,
					placeholder: `Write a new note...`,
					addNote: `<i class="fa-solid fa-plus"></i> Add Note`,
					saveEdit: `<i class="fa-solid fa-check"></i> Save Edit`,
					edit: `<i class="fa-solid fa-pen-to-square"></i> Edit`,
					delete: `<i class="fa-solid fa-trash-can"></i> Delete`,
					confirmDelete: `Are you sure you want to delete this note?`
				},
				ar: {
					title: `ملاحظاتي`,
					placeholder: `اكتب ملاحظة جديدة...`,
					addNote: `<i class="fa-solid fa-plus"></i> إضافة ملاحظة`,
					saveEdit: `<i class="fa-solid fa-check"></i> حفظ التعديل`,
					edit: `<i class="fa-solid fa-pen-to-square"></i> تعديل`,
					delete: `<i class="fa-solid fa-trash-can"></i> حذف`,
					confirmDelete: `هل أنت متأكد أنك تريد حذف هذه الملاحظة؟`
				}
			};

			function setLanguage(lang) {
				currentLang = lang;
				const strings = uiStrings[lang];
				document.documentElement.lang = lang;
				document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";

				document.getElementById("ui-title").innerHTML = `<i class="fa-solid fa-note-sticky"></i> ${strings.title}`;
				noteInput.placeholder = strings.placeholder;
				addNoteBtn.innerHTML = strings.addNote;
				document.getElementById("lang-toggle").textContent = lang === "en" ? "AR" : "EN";
				
				// Re-render notes to update "Edit" and "Delete" button texts
				// This assumes renderNotes can be called safely without data loss, which it can.
				window.getInitialNotes().then(notes => renderNotes(notes));
			}

			function renderNotes(notes) {
				notesList.innerHTML = "";
				notes.forEach((note, index) => {
					const li = document.createElement("li");
					li.className = "note-item";
					li.innerHTML = `
						<div class="note-content">${escapeHTML(note.text)}</div>
						<div class="note-timestamp">${note.timestamp}</div>
						<div class="note-actions">
							<button class="edit-btn" onclick="startEditNote(${index})">${uiStrings[currentLang].edit}</button>
							<button class="delete-btn" onclick="deleteNoteItem(${index})">${uiStrings[currentLang].delete}</button>
						</div>
					`;
					notesList.appendChild(li);
				});
			}

			function escapeHTML(str) {
				const div = document.createElement("div");
				div.appendChild(document.createTextNode(str));
				return div.innerHTML;
			}

			async function addNoteItem() {
				const text = noteInput.value.trim();
				if (text) {
					let updatedNotes;
					if (editingIndex === -1) {
						updatedNotes = await window.addNote(text);
					} else {
						updatedNotes = await window.editNote(editingIndex, text);
						editingIndex = -1; // Reset editing state
						addNoteBtn.innerHTML = uiStrings[currentLang].addNote;
						addNoteBtn.classList.remove("edit-mode");
					}
					noteInput.value = "";
					renderNotes(updatedNotes);
				}
			}

			function startEditNote(index) {
				editingIndex = index;
				noteInput.value = notesList.children[index].querySelector(".note-content").textContent;
				addNoteBtn.innerHTML = uiStrings[currentLang].saveEdit;
				addNoteBtn.classList.add("edit-mode");
				noteInput.focus();
			}

			async function deleteNoteItem(index) {
				if (confirm(uiStrings[currentLang].confirmDelete)) {
					const updatedNotes = await window.deleteNote(index);
					renderNotes(updatedNotes);
					if (editingIndex === index) { // If the deleted note was being edited
						editingIndex = -1;
						noteInput.value = "";
						addNoteBtn.innerHTML = uiStrings[currentLang].addNote;
						addNoteBtn.classList.remove("edit-mode");
					} else if (editingIndex > index) { // Adjust index if a preceding note was deleted
						editingIndex--;
					}
				}
			}

			window.onload = async () => {
				const initialSettings = await window.getInitialSettings();
				setLanguage(initialSettings.language);
				document.getElementById("lang-toggle").addEventListener("click", () => {
					const newLang = currentLang === "en" ? "ar" : "en";
					setLanguage(newLang);
					window.saveSettings(newLang);
				});
			};
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles requests from JavaScript to get the initial list of notes.
func handleGetInitialNotes(id, req)
	see "Ring: JavaScript requested initial notes." + nl
	cJsonArray = build_notes_json()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonArray) # Return the notes as a JSON array.

# Handles requests from JavaScript to get the initial application settings.
func handleGetInitialSettings(id, req)
	see "Ring: JavaScript requested initial settings." + nl
	# Manually construct the settings JSON to ensure it's a JSON object
	cJson = '{'
	for aSetting in aSettings
		cKey = escape_json_string(aSetting[1])
		cValue = escape_json_string(aSetting[2])
		cJson += '"' + cKey + '":"' + cValue + '",'
	next
	if len(cJson) > 1 cJson = left(cJson, len(cJson) - 1) ok # Remove trailing comma
	cJson += '}'
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson) # Return settings as a JSON object.

# Handles requests from JavaScript to save updated settings.
func handleSaveSettings(id, req)
	req = json2list(req)[1] # Parse the request data.
	cLang = req[1] # Extract the language setting.
	see "Ring: JavaScript requested to save settings. New language: '" + cLang + "'" + nl

	# Update the global settings list with the new language.
	aSettings[1][2] = cLang

	saveSettings() # Persist the updated settings to a file.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles requests from JavaScript to add a new note.
func handleAddNote(id, req)
	cNoteText = json2list(req)[1][1] # Extract the note text.
	cTimestamp = currentdatetime() # Get the current timestamp for the note.
	see "Ring: Adding new note: '" + cNoteText + "' at " + cTimestamp + nl
	add(aNotes, [cNoteText, cTimestamp]) # Add the new note to the in-memory list.
	saveNotes() # Persist the updated notes list.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, build_notes_json())

# Handles requests from JavaScript to edit an existing note.
func handleEditNote(id, req)
	aReq = json2list(req)[1] # Parse the request data.
	nIndex = aReq[1] # Extract the index of the note to edit.
	cNewText = aReq[2] # Extract the new text for the note.
	cTimestamp = currentdatetime() # Update timestamp on edit.
	see "Ring: Editing note at index: " + nIndex + " to '" + cNewText + "' at " + cTimestamp + nl
	if nIndex >= 0 and nIndex < len(aNotes)
		aNotes[nIndex + 1][1] = cNewText # Update note text.
		aNotes[nIndex + 1][2] = cTimestamp # Update timestamp.
		saveNotes() # Persist the updated notes list.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, build_notes_json())

# Handles requests from JavaScript to delete a note.
func handleDeleteNote(id, req)
	nIndex = json2list(req)[1][1] # Extract the index of the note to delete.
	see "Ring: Deleting note at index: " + nIndex + nl
	if nIndex >= 0 and nIndex < len(aNotes)
		del(aNotes, nIndex + 1) # Delete the note from the in-memory list.
		saveNotes() # Persist the updated notes list.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, build_notes_json())

# --- Helper Functions ---

func build_notes_json()
	cJson = "["
	for i = 1 to len(aNotes)
		aNote = aNotes[i]
		cNoteText = escape_json_string(aNote[1])
		cTimestamp = escape_json_string(aNote[2])
		cJson += '{"text":"' + cNoteText + '","timestamp":"' + cTimestamp + '"}'
		if i < len(aNotes)
			cJson += ","
		ok
	next
	cJson += "]"
	return cJson

# Escapes special characters in a string to be safely embedded in a JSON string.
func escape_json_string(cText)
	cText = substr(cText, "\", "\\")
	cText = substr(cText, '"', '\"')
	cText = substr(cText, nl, "\n")
	cText = substr(cText, char(13), "\r")
	cText = substr(cText, char(9), "\t")
	cText = substr(cText, char(8), "\b")
	cText = substr(cText, char(12), "\f")
	return cText

# Loads application settings from `notes_settings.json`.
func loadSettings()
	see "Loading application settings from file: " + cNotesSettingsFile + nl
	if fexists(cNotesSettingsFile)
		try
			cJson = read(cNotesSettingsFile) # Read the JSON string from the file.
			tempSettings = json2list(cJson) # Parse the JSON into a Ring list.
			see "Settings loaded successfully." + nl
			return tempSettings
		catch
			see "Error loading settings file. Creating default settings." + nl
			return createDefaultSettings() # Create defaults on error.
		end
	else
		see "No settings file found. Creating default settings." + nl
		return createDefaultSettings() # Create defaults if no file exists.
	ok

# Creates and returns a default set of application settings.
func createDefaultSettings()
	return [
		["language", "en"] # Default language is English.
	]

# Saves the current application settings to `notes_settings.json`.
func saveSettings()
	cJson = list2json(aSettings) # Convert settings list to JSON string.
	write(cNotesSettingsFile, cJson) # Write JSON string to file.
	see "Settings saved to file: " + cNotesSettingsFile + nl

# Loads notes from the `notes.json` file.
func loadNotes()
	see "Loading notes from file: " + cNotesFile + nl
	if fexists(cNotesFile)
		try
			cJson = read(cNotesFile) # Read the JSON string from the file.
			aLoadedNotes = json2list(cJson)[1] # Parse the JSON into a Ring list.
			if islist(aLoadedNotes)
				aNotes = [] # Clear existing in-memory notes before loading.
				for aItem in aLoadedNotes
					if islist(aItem) and len(aItem) > 0
						add(aNotes, [aItem["text"], aItem["timestamp"]]) # Add loaded notes to in-memory list.
					ok
				next
			else
				aNotes = []
			ok
			see "Notes loaded successfully." + nl
		catch
			see "Error loading notes file. Starting with an empty list." + nl
			aNotes = [] # Revert to empty list on error.
		end
	else
		see "No notes file found. Starting with an empty list." + nl
		aNotes = [] # Start with an empty list if no file exists.
	ok

# Saves the current list of notes to the `notes.json` file.
func saveNotes()
	see "Saving notes to file: " + cNotesFile + nl
	cJsonArray = build_notes_json()
	write(cNotesFile, cJsonArray) # Write the JSON string to the file.
	see "Notes saved successfully." + nl

# Returns the current date and time in a readable string format.
func currentdatetime()
	return date() + " " + time()
