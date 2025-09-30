# Simple Notes Application

load "webview.ring"
load "simplejson.ring"

# Global Variables
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

# Defines the HTML structure and inline JavaScript for the notes application.
func loadNotesHTML()
	cHTML = '
	<!DOCTYPE html>
	<html lang="en" dir="ltr">
	<head>
		<title>Ring Notes App</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fira+Code:wght@400;500;600&family=Tajawal:wght@400;500;600;700&display=swap");
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
			html[lang="ar"] body { font-family: "Tajawal", sans-serif; }
			html[dir="rtl"] body { direction: rtl; }
			html {
				background: var(--bg-primary);
			}

			body {
				font-family: "Inter", sans-serif;
				background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
				color: var(--text-primary);
				margin: 0;
				height: 100vh;
				overflow: hidden;
				position: relative;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
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

			.notes-container {
				background: var(--card-bg);
				padding: clamp(1.5rem, 4vw, 2.5rem);
				border-radius: 20px;
				box-shadow: var(--shadow-lg), 0 0 0 1px var(--card-border);
				width: min(90vw, 32rem);
				display: flex;
				flex-direction: column;
				position: relative;
				z-index: 10;
				border: 1px solid var(--card-border);
				backdrop-filter: blur(var(--blur-lg));
				-webkit-backdrop-filter: blur(var(--blur-lg));
				height: min(85vh, 42rem);
				transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
			}
			.notes-container:hover {
				transform: translateY(-4px);
				box-shadow: var(--shadow-lg), 0 25px 50px -12px rgba(0, 0, 0, 0.25);
				border-color: rgba(59, 130, 246, 0.3);
			}
			.notes-header {
				display: flex;
				justify-content: space-between;
				align-items: center;
				margin-bottom: clamp(1.5rem, 4vw, 2rem);
				padding-bottom: clamp(0.75rem, 2vw, 1rem);
				border-bottom: 1px solid var(--card-border);
			}
			html[dir="rtl"] .notes-header {
				flex-direction: row-reverse;
			}
			.notes-header h1 {
				order: 1;
			}
			.notes-header .control-btn {
				order: 2;
			}
			html[dir="rtl"] .notes-header h1 {
				order: 2;
			}
			html[dir="rtl"] .notes-header .control-btn {
				order: 1;
			}
			h1 {
				color: var(--text-primary);
				margin: 0;
				font-size: clamp(1.5rem, 5vw, 2rem);
				font-weight: 700;
				letter-spacing: -0.025em;
				text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
				display: flex;
				align-items: center;
				gap: 0.75rem;
				text-align: left;
				flex-direction: row;
			}
			h1 i {
				color: var(--accent-warning);
				font-size: clamp(1.2rem, 4vw, 1.6rem);
				order: 1;
			}
			.title-text {
				order: 2;
			}
			html[dir="rtl"] h1 {
				text-align: right;
				flex-direction: row-reverse;
			}
			html[dir="rtl"] h1 i {
				order: 2;
			}
			html[dir="rtl"] .title-text {
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
			html[lang="en"] .control-btn {
				font-family: "Inter", sans-serif;
			}
			html[lang="ar"] .control-btn {
				font-family: "Tajawal", sans-serif;
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
				flex-direction: row;
			}
			html[dir="rtl"] .input-group {
				flex-direction: row-reverse;
			}
			.input-group button {
				order: 2;
			}
			.input-group textarea {
				order: 1;
			}
			html[dir="rtl"] .input-group button {
				order: 1;
			}
			html[dir="rtl"] .input-group textarea {
				order: 2;
			}
			textarea {
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
			}
			textarea:focus {
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
			html[lang="en"] button {
				font-family: "Inter", sans-serif;
			}
			html[lang="ar"] button {
				font-family: "Tajawal", sans-serif;
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
			.notes-list {
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
			.note-item {
				background: rgba(148, 163, 184, 0.05);
				padding: clamp(0.75rem, 2vw, 1rem);
				border-radius: 12px;
				margin-bottom: clamp(0.75rem, 2vw, 1rem);
				border: 1px solid var(--card-border);
				display: flex;
				flex-direction: column;
				gap: clamp(0.5rem, 1.5vw, 0.75rem);
				backdrop-filter: blur(var(--blur-sm));
				-webkit-backdrop-filter: blur(var(--blur-sm));
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				position: relative;
				overflow: hidden;
			}
			.note-item:hover {
				transform: translateY(-2px);
				background: rgba(59, 130, 246, 0.08);
				border-color: rgba(59, 130, 246, 0.3);
				box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
			}
			.note-item:last-child {
				margin-bottom: 0;
			}
			html[dir="rtl"] .note-item { flex-direction: column; }

			.note-content {
				flex-grow: 1;
				font-size: clamp(1rem, 2.5vw, 1.1rem);
				white-space: pre-wrap;
				color: var(--text-primary);
				line-height: 1.6;
				font-weight: 400;
				word-wrap: break-word;
				margin: 0;
			}
			html[dir="rtl"] .note-content { text-align: right; }

			.note-timestamp {
				font-size: clamp(0.8rem, 2vw, 0.85rem);
				color: var(--text-muted);
				text-align: right;
				font-weight: 500;
				font-family: "Fira Code", monospace;
				opacity: 0.8;
				letter-spacing: 0.025em;
			}
			html[lang="en"] .note-timestamp {
				font-family: "Fira Code", "Inter", monospace, sans-serif;
			}
			html[lang="ar"] .note-timestamp {
				font-family: "Fira Code", "Tajawal", monospace, sans-serif;
				direction: ltr;
			}
			html[dir="rtl"] .note-timestamp { text-align: left; }

			.note-actions {
				display: flex;
				justify-content: flex-end;
				gap: clamp(0.5rem, 1.5vw, 0.75rem);
				margin-top: clamp(0.5rem, 1.5vw, 0.75rem);
				padding-top: clamp(0.5rem, 1.5vw, 0.75rem);
				border-top: 1px solid var(--card-border);
				flex-direction: row;
			}
			html[dir="rtl"] .note-actions {
				justify-content: flex-start;
				flex-direction: row-reverse;
			}
			.note-actions .edit-btn {
				order: 1;
			}
			.note-actions .delete-btn {
				order: 2;
			}
			html[dir="rtl"] .note-actions .edit-btn {
				order: 2;
			}
			html[dir="rtl"] .note-actions .delete-btn {
				order: 1;
			}
			.note-actions button {
				padding: clamp(0.4rem, 1.5vw, 0.5rem) clamp(0.75rem, 2vw, 1rem);
				font-size: clamp(0.8rem, 2vw, 0.9rem);
				margin: 0;
				min-height: auto;
				font-weight: 600;
				border-radius: 8px;
				transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
				backdrop-filter: blur(var(--blur-sm));
				-webkit-backdrop-filter: blur(var(--blur-sm));
				border: 1px solid rgba(255, 255, 255, 0.1);
				text-transform: none;
				letter-spacing: normal;
				white-space: nowrap;
				font-family: inherit;
			}
			html[lang="en"] .note-actions button {
				font-family: "Inter", sans-serif;
			}
			html[lang="ar"] .note-actions button {
				font-family: "Tajawal", sans-serif;
			}
			.note-actions .edit-btn {
				background: linear-gradient(135deg, var(--accent-success), #22c55e);
				box-shadow: 0 3px 8px rgba(16, 185, 129, 0.25);
			}
			.note-actions .edit-btn:hover {
				background: linear-gradient(135deg, #22c55e, #16a34a);
				box-shadow: 0 6px 16px rgba(16, 185, 129, 0.4);
				transform: translateY(-1px);
			}
			.note-actions .delete-btn {
				background: linear-gradient(135deg, var(--accent-danger), #dc2626);
				box-shadow: 0 3px 8px rgba(239, 68, 68, 0.25);
			}
			.note-actions .delete-btn:hover {
				background: linear-gradient(135deg, #dc2626, #b91c1c);
				box-shadow: 0 6px 16px rgba(239, 68, 68, 0.4);
				transform: translateY(-1px);
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
		

		<div class="notes-container">
			<div class="notes-header">
				<h1 id="ui-title"><i class="fa-solid fa-note-sticky"></i><span class="title-text">My Notes</span></h1>
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
			let editingIndex = -1;
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

				document.getElementById("ui-title").innerHTML = `<i class="fa-solid fa-note-sticky"></i><span class="title-text">${strings.title}</span>`;
				noteInput.placeholder = strings.placeholder;
				addNoteBtn.innerHTML = strings.addNote;
				document.getElementById("lang-toggle").textContent = lang === "en" ? "AR" : "EN";
			}

			async function setLanguageAndLoadNotes(lang) {
				setLanguage(lang);
				const notes = await window.getInitialNotes();
				renderNotes(notes);
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
				notesList.scrollTop = notesList.scrollHeight;
			}

			function escapeHTML(str) {
				const div = document.createElement("div");
				div.appendChild(document.createTextNode(str));
				return div.innerHTML;
			}

			async function addNoteItem() {
				const text = noteInput.value.trim();
				if (text) {
					try {
						let updatedNotes;
						if (editingIndex === -1) {
							updatedNotes = await window.addNote(text);
						} else {
							updatedNotes = await window.editNote(editingIndex, text);
							editingIndex = -1;
							addNoteBtn.innerHTML = uiStrings[currentLang].addNote;
							addNoteBtn.classList.remove("edit-mode");
						}
						noteInput.value = "";
						renderNotes(updatedNotes);
					} catch (error) {
						console.error("Error saving note:", error);
					}
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
					try {
						const updatedNotes = await window.deleteNote(index);
						renderNotes(updatedNotes);
						if (editingIndex === index) {
							editingIndex = -1;
							noteInput.value = "";
							addNoteBtn.innerHTML = uiStrings[currentLang].addNote;
							addNoteBtn.classList.remove("edit-mode");
						} else if (editingIndex > index) {
							editingIndex--;
						}
					} catch (error) {
						console.error("Error deleting note:", error);
					}
				}
			}

			window.onload = async () => {
				try {
					const initialSettings = await window.getInitialSettings();
					await setLanguageAndLoadNotes(initialSettings.language);
					document.getElementById("lang-toggle").addEventListener("click", async () => {
						const newLang = currentLang === "en" ? "ar" : "en";
						await setLanguageAndLoadNotes(newLang);
						window.saveSettings(newLang);
					});
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

# Handles requests from JavaScript to get the initial list of notes.
func handleGetInitialNotes(id, req)
	see "Ring: JavaScript requested initial notes." + nl
	cJsonArray = build_notes_json()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonArray) # Return the notes as a JSON array.

# Handles requests from JavaScript to get the initial application settings.
func handleGetInitialSettings(id, req)
	see "Ring: JavaScript requested initial settings." + nl
	# Create a Ring list structure
	aSettingsObj = []
	for aSetting in aSettings
		# Add each setting as a key-value pair in the object
		add(aSettingsObj, [aSetting[1], aSetting[2]])
	next
	# Convert the Ring list to JSON using json_encode
	cJson = json_encode(aSettingsObj)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson) # Return settings as a JSON object.

# Handles requests from JavaScript to save updated settings.
func handleSaveSettings(id, req)
	req = json_decode(req) # Parse the request data.
	cLang = req[1] # Extract the language setting.
	see "Ring: JavaScript requested to save settings. New language: '" + cLang + "'" + nl

	# Update the global settings list with the new language.
	aSettings[1][2] = cLang

	saveSettings() # Persist the updated settings to a file.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# Handles requests from JavaScript to add a new note.
func handleAddNote(id, req)
	cNoteText = json_decode(req)[1] # Extract the note text.
	cTimestamp = currentdatetime() # Get the current timestamp for the note.
	see "Ring: Adding new note: '" + cNoteText + "' at " + cTimestamp + nl
	add(aNotes, [cNoteText, cTimestamp]) # Add the new note to the in-memory list.
	saveNotes() # Persist the updated notes list.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, build_notes_json())

# Handles requests from JavaScript to edit an existing note.
func handleEditNote(id, req)
	aReq = json_decode(req) # Parse the request data.
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
	nIndex = json_decode(req)[1] # Extract the index of the note to delete.
	see "Ring: Deleting note at index: " + nIndex + nl
	if nIndex >= 0 and nIndex < len(aNotes)
		del(aNotes, nIndex + 1) # Delete the note from the in-memory list.
		saveNotes() # Persist the updated notes list.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, build_notes_json())

# Helper Functions

func build_notes_json()
	# Create a Ring list structure
	aNotesList = []
	for i = 1 to len(aNotes)
		aNote = aNotes[i]
		# Add each note as an object with text and timestamp properties
		add(aNotesList, [
			:text = aNote[1],
			:timestamp = aNote[2]
		])
	next
	# Convert the Ring list to JSON using json_encode
	return json_encode(aNotesList)

# Loads application settings from `notes_settings.json`.
func loadSettings()
	see "Loading application settings from file: " + cNotesSettingsFile + nl
	if fexists(cNotesSettingsFile)
		try
			cJson = read(cNotesSettingsFile) # Read the JSON string from the file.
			tempSettings = json_decode(cJson) # Parse the JSON into a Ring list.
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
	# Default language is English.
	return [
		:language = "en"
	]

# Saves the current application settings to `notes_settings.json`.
func saveSettings()
	cJson = json_encode(aSettings) # Convert settings list to JSON string.
	write(cNotesSettingsFile, cJson) # Write JSON string to file.
	see "Settings saved to file: " + cNotesSettingsFile + nl

# Loads notes from the `notes.json` file.
func loadNotes()
	see "Loading notes from file: " + cNotesFile + nl
	if fexists(cNotesFile)
		try
			cJson = read(cNotesFile) # Read the JSON string from the file.
			aLoadedNotes = json_decode(cJson) # Parse the JSON into a Ring list.
			if islist(aLoadedNotes)
				aNotes = [] # Clear existing in-memory notes before loading.
				for aItem in aLoadedNotes
					if islist(aItem) and len(aItem) > 0
						add(aNotes, [aItem[:text], aItem[:timestamp]]) # Add loaded notes to in-memory list.
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
