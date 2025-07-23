# Mock Chat Bot Application using Ring and WebView

load "webview.ring"
load "jsonlib.ring"

# -- Global Variables --
# Variable to hold the WebView instance.
oWebView = NULL
# Variable to hold the settings file path.
cSettingsFile = "chat_settings.json"
# Global variable to hold the application settings.
aSettings = []

func main()
	# Load initial settings from file or create defaults.
	aSettings = loadSettings()
	
	see "Setting up Advanced Chat Bot Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Chat Bot")
	# Set the window size (no size constraint).
	oWebView.setSize(450, 750, WEBVIEW_HINT_NONE)

	# Bind all necessary Ring functions to be callable from JavaScript.
	oWebView.bind("getInitialSettings", :handleGetInitialSettings)
	oWebView.bind("handleSendMessage", :handleSendMessage)
	oWebView.bind("saveSettings", :handleSaveSettings)

	# Load the HTML content for the chat UI.
	oWebView.setHtml(getChatHTML())

	see "Running the WebView main loop. Start chatting!" + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

	see "Cleaning up WebView resources and exiting." + nl

# Handles requests from JavaScript to get the initial application settings.
func handleGetInitialSettings(id, req)
	see "Ring: JavaScript requested initial settings." + nl
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aSettings)) # Return settings as a JSON object.

# Handles incoming messages from the JavaScript frontend.
func handleSendMessage(id, req)
	req = json2list(req)[1] # Parse the request data.
	cUserMessage = req[1] # Extract the user's message.
	cLang = req[2] # Extract the current language from JS.
	see "User (" + cLang + ")> " + cUserMessage + nl

	syssleep(1) # Simulate a delay to represent "thinking" time for the bot.

	cBotReply = getBotReply(cUserMessage, cLang) # Get the bot's reply based on message and language.
	see "Bot (" + cLang + ")> " + cBotReply + nl

	# Return the bot's reply as a valid JSON string to JavaScript.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"' + substr(cBotReply, '"', '\"') + '"')

# Handles requests from JavaScript to save updated application settings.
func handleSaveSettings(id, req)
	req = json2list(req)[1] # Parse the request data.
	cTheme = req[1] # Extract the new theme.
	cLang = req[2] # Extract the new language.
	
	# Update the global settings list with the new values.
	aSettings[1][2] = cTheme
	aSettings[2][2] = cLang
	
	saveSettings() # Persist the updated settings to a file.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}') # Acknowledge the call.

# --- State Management and Bot Logic ---

# Loads application settings from `chat_settings.json`.
func loadSettings()
	see "Loading application settings..." + nl
	if fexists(cSettingsFile)
		try
			cJson = read(cSettingsFile) # Read the JSON string from the file.
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
		["theme", "dark"],   # Default theme is dark.
		["language", "en"] # Default language is English.
	]

# Saves the current application settings to `chat_settings.json`.
func saveSettings()
	cJson = list2json(aSettings) # Convert settings list to JSON string.
	write(cSettingsFile, cJson) # Write JSON string to file.
	see "Settings saved to file: " + cSettingsFile + nl

# Generates a bot reply based on the user's message and current language.
func getBotReply(cMessage, cLang)
	cMessage = lower(cMessage) # Convert message to lowercase for easier matching.
	
	if cLang = "ar"
		# Arabic Replies
		if substr(cMessage, "مرحبا") or substr(cMessage, "السلام عليكم") return "أهلاً بك! أنا بوت مبرمج بلغة رينج." ok
		if substr(cMessage, "كيف حالك") return "أنا مجرد سكربت، لكني أعمل بشكل ممتاز، شكراً لسؤالك!" ok
		if substr(cMessage, "رينج") return "رينج لغة رائعة لبناء تطبيقات مثلي." ok
		if substr(cMessage, "الوقت") return "الوقت الحالي هو " + time() ok
		return "لست متأكداً من كيفية الرد على ذلك. حاول أن تسأل عن 'رينج' أو 'الوقت'."
	else
		# English Replies (Default)
		if substr(cMessage, "hello") or substr(cMessage, "hi") return "Hello there! I am a Ring language bot." ok
		if substr(cMessage, "how are you") return "I am just a script, but I'm running perfectly, thanks!" ok
		if substr(cMessage, "ring") return "Ring is a great language for building apps like me." ok
		if substr(cMessage, "time") return "The current time is " + time() ok
		return "I'm not sure how to respond to that. Try asking about 'Ring' or the 'time'."
	ok
	
# Returns the HTML content for the chat bot UI.
func getChatHTML()
	return `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Chat Bot</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Tajawal:wght@400;500;700&display=swap');
			:root {
				/* Light Theme (Default) */
				--bg-color: #e5ddd5;
				--bg-image: url('https://i.pinimg.com/originals/97/c0/0e/97c00e6242483875335e21b8141663f5.jpg');
				--card-bg-color: rgba(240, 242, 245, 0.9);
				--header-bg-color: #f0f2f5;
				--footer-bg-color: #f0f2f5;
				--border-color: rgba(0, 0, 0, 0.1);
				--user-bubble-bg: linear-gradient(135deg, #dcf8c6, #c5eab3);
				--bot-bubble-bg: #ffffff;
				--text-primary: #111b21;
				--text-secondary: #667781;
				--accent-green: #008069;
				--icon-color: #54656f;
			}
			html[data-theme="dark"] {
				/* Dark Theme Overrides */
				--bg-color: #0c141a;
				--bg-image: none; /* No background image for dark theme */
				--card-bg-color: rgba(17, 27, 33, 0.8);
				--header-bg-color: #202c33;
				--footer-bg-color: #111b21;
				--border-color: rgba(255, 255, 255, 0.15);
				--user-bubble-bg: linear-gradient(135deg, #005c4b, #008069);
				--bot-bubble-bg: #202c33;
				--text-primary: #e9edef;
				--text-secondary: #8696a0;
				--accent-green: #00a884;
				--icon-color: #aebac1;
			}
			body {
				font-family: 'Inter', sans-serif;
				margin: 0; height: 100vh; overflow: hidden;
				background-color: var(--bg-color);
				background-image: var(--bg-image);
				background-size: cover; background-position: center;
				display: flex; align-items: center; justify-content: center;
				padding: 1em; box-sizing: border-box;
				transition: background-color 0.5s ease;
			}
			html[lang="ar"] body { font-family: 'Tajawal', sans-serif; }
			.chat-window {
				width: 100%; height: 100%; max-width: 450px; max-height: 95vh;
				display: flex; flex-direction: column;
				background-color: var(--card-bg-color);
				border-radius: 16px; border: 1px solid var(--border-color);
				backdrop-filter: blur(25px); -webkit-backdrop-filter: blur(25px);
				box-shadow: 0 15px 35px rgba(0,0,0,0.3);
				animation: fadeIn 0.5s ease-out; overflow: hidden;
			}
			@keyframes fadeIn { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }
			
			.chat-header {
				display: flex; justify-content: space-between; align-items: center;
				padding: 10px 15px; background-color: var(--header-bg-color); flex-shrink: 0;
			}
			.header-title { display: flex; align-items: center; gap: 1em; }
			.header-title i { font-size: 1.5em; color: var(--accent-green); }
			.header-title h2 { margin: 0; font-size: 1.1em; font-weight: 500; color: var(--text-primary); }
			.header-controls { display: flex; gap: 1em; }
			.control-btn { background: none; border: none; font-size: 1.2em; cursor: pointer; color: var(--icon-color); }
			
			#chat-log { flex-grow: 1; padding: 10px 15px; overflow-y: auto; display: flex; flex-direction: column; gap: 10px; }
			.message { max-width: 75%; padding: 10px 15px; border-radius: 12px; line-height: 1.5; color: var(--text-primary); animation: popIn 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275); word-wrap: break-word; }
			@keyframes popIn { from { opacity: 0; transform: translateY(10px) scale(0.9); } to { opacity: 1; transform: translateY(0) scale(1); } }
			.user { background: var(--user-bubble-bg); align-self: flex-end; border-bottom-right-radius: 3px; }
			html[dir="rtl"] .user { align-self: flex-start; border-bottom-right-radius: 12px; border-bottom-left-radius: 3px; }
			.bot { background: var(--bot-bubble-bg); align-self: flex-start; border-bottom-left-radius: 3px; }
			html[dir="rtl"] .bot { align-self: flex-end; border-bottom-left-radius: 12px; border-bottom-right-radius: 3px; }
			.typing-indicator { align-self: flex-start; color: var(--text-secondary); font-style: italic; }
			html[dir="rtl"] .typing-indicator { align-self: flex-end; }
			
			#input-bar { display: flex; padding: 12px; background: var(--footer-bg-color); flex-shrink: 0; align-items: center; }
			#msg-input { flex-grow: 1; background: var(--bot-bubble-bg); border: 1px solid var(--border-color); border-radius: 22px; padding: 12px 18px; font-size: 15px; color: var(--text-primary); outline: none; transition: border-color 0.2s; }
			#msg-input:focus { border-color: var(--accent-green); }
			#send-btn { background: var(--accent-green); color: white; border: none; border-radius: 50%; width: 45px; height: 45px; margin: 0 12px; cursor: pointer; font-size: 18px; display: flex; align-items: center; justify-content: center; transition: transform 0.2s, background-color 0.2s; }
			html[dir="ltr"] #send-btn { order: 2; }
			#send-btn:hover { transform: scale(1.1); background-color: #008a6e; }
		</style>
	</head>
	<body>
		<div class="chat-window">
			<div class="chat-header">
				<div class="header-title">
					<i class="fa-solid fa-robot"></i>
					<h2 id="ui-title"></h2>
				</div>
				<div class="header-controls">
					<button id="theme-toggle" class="control-btn"></button>
					<button id="lang-toggle" class="control-btn"></button>
				</div>
			</div>
			<div id="chat-log"></div>
			<div id="input-bar">
				<input type="text" id="msg-input">
				<button id="send-btn"><i class="fa-solid fa-paper-plane"></i></button>
			</div>
		</div>

		<script>
			// The JavaScript logic is already correct and needs no changes.
			let currentTheme, currentLang;
			const uiStrings = {
				en: { title: "Ring Bot", placeholder: "Type a message...", greeting: "Hello! I'm a bot powered by Ring. How can I help?", typing: "Bot is typing..." },
				ar: { title: "بوت رينج", placeholder: "اكتب رسالة...", greeting: "أهلاً بك! أنا بوت مبرمج بلغة رينج. كيف أساعدك؟", typing: "البوت يكتب الآن..." }
			};

			function setTheme(theme) {
				currentTheme = theme;
				document.documentElement.setAttribute('data-theme', theme);
				document.getElementById('theme-toggle').innerHTML = theme === 'dark' ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
			}

			function setLanguage(lang) {
				currentLang = lang;
				const strings = uiStrings[lang];
				document.documentElement.lang = lang;
				document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
				document.getElementById('ui-title').textContent = strings.title;
				document.getElementById('msg-input').placeholder = strings.placeholder;
				document.getElementById('lang-toggle').textContent = lang === 'en' ? 'AR' : 'EN';
				document.getElementById('chat-log').innerHTML = '<div class="message bot">' + strings.greeting + '</div>';
			}

			function addMessage(text, sender) {
				const log = document.getElementById('chat-log');
				const msgDiv = document.createElement('div');
				const safeText = text.replace(/</g, "<").replace(/>/g, ">");
				msgDiv.className = 'message ' + sender;
				msgDiv.innerHTML = safeText;
				log.appendChild(msgDiv);
				log.scrollTop = log.scrollHeight;
			}

			function setTyping(isTyping) {
				let indicator = document.getElementById('typing-indicator');
				if (isTyping) {
					if (!indicator) {
						indicator = document.createElement('div');
						indicator.id = 'typing-indicator';
						indicator.className = 'message bot typing-indicator';
						indicator.innerHTML = '<i>' + uiStrings[currentLang].typing + '</i>';
						document.getElementById('chat-log').appendChild(indicator);
						document.getElementById('chat-log').scrollTop = document.getElementById('chat-log').scrollHeight;
					}
				} else {
					if (indicator) indicator.remove();
				}
			}

			async function sendMessage() {
				const input = document.getElementById('msg-input');
				const text = input.value.trim();
				if (text) {
					addMessage(text, 'user');
					input.value = '';
					setTyping(true);
					const botReply = await window.handleSendMessage(text, currentLang);
					setTyping(false);
					addMessage(botReply, 'bot');
				}
			}

			window.onload = async () => {
				const settings = await window.getInitialSettings();
				setTheme(settings.theme);
				setLanguage(settings.language);

				document.getElementById('theme-toggle').addEventListener('click', () => {
					const newTheme = currentTheme === 'light' ? 'dark' : 'light';
					setTheme(newTheme);
					window.saveSettings(newTheme, currentLang);
				});
				document.getElementById('lang-toggle').addEventListener('click', () => {
					const newLang = currentLang === 'en' ? 'ar' : 'en';
					setLanguage(newLang);
					window.saveSettings(currentTheme, newLang);
				});
				document.getElementById('send-btn').addEventListener('click', sendMessage);
				document.getElementById('msg-input').addEventListener('keypress', (e) => {
					if (e.key === 'Enter') sendMessage();
				});
			};
		</script>
	</body>
	</html>
	`