# Using WebLib to create a dynamic HTML page
# This example demonstrates how to use WebLib to create a dynamic HTML page

load "webview.ring"
load "weblib.ring"
import System.Web

# Define a global binding list for the webview instance.
aBindList = [
	["showAlert", :showAlert]
]

// Create a new webview instance
w = new WebView()

// Set the title and size
w.setTitle("Using WebLib")
w.setSize(800, 650, WEBVIEW_HINT_NONE)

// Create the page using HtmlPage for in-memory generation
myPage = new HtmlPage {

	// Apply global styles by calling the Style() method
	Style(`
		@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap");
		:root {
			--bg-color: #000000;
			--sidebar-bg: transparent;
			--tab-bg: rgba(30, 30, 32, 0.6);
			--tab-active-bg: rgba(59, 130, 246, 0.2);
			--border-color: rgba(255, 255, 255, 0.1);
			--text-primary: #f8fafc;
			--text-secondary: #a1a1aa;
			--accent-cyan: #22d3ee;
			--accent-purple: #c084fc;
			--accent-green: #4ade80;
			--accent-yellow: #facc15;
			--accent-red: #f87171;
		}
		:root.light-mode {
			--bg-color: #f0f2f5;
			--text-primary: #1a202c;
			--text-secondary: #4a5568;
			--accent-cyan: #06b6d4;
			--accent-purple: #9333ea;
			--accent-green: #10b981;
			--accent-yellow: #f59e0b;
			--accent-red: #ef4444;
			--light-gradient-start: rgba(240, 242, 245, 0.8);
			--light-gradient-end: rgba(255, 255, 255, 0.8);
		}
		:root.dark-mode {
			--dark-gradient-start: rgba(0, 0, 0, 0.8);
			--dark-gradient-end: rgba(20, 20, 25, 0.8);
		}
		body {
			font-family: "Inter", sans-serif;
			background-color: var(--bg-color);
			color: var(--text-primary);
			margin: 0;
			min-height: 100vh;
			overflow-x: hidden;
			position: relative;
			transition: background-color 0.3s ease, color 0.3s ease;
		}
		.background-container {
			position: fixed; top: 0; left: 0; width: 100%; height: 100%;
			z-index: -1; overflow: hidden;
		}
		.aurora {
			position: relative; width: 100%; height: 100%;
			filter: blur(150px); opacity: 0.5;
			animation: aurora-move 20s infinite alternate;
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
		@keyframes aurora-move {
			0% { transform: translate(0, 0); }
			50% { transform: translate(5%, 5%); }
			100% { transform: translate(0, 0); }
		}
		/* Scrollbar Styling */
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
		}
		/* Loading Overlay */
		#loading-overlay {
			position: fixed;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			background-color: var(--bg-color);
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			z-index: 1000;
			transition: opacity 0.5s ease-out;
		}
		#loading-overlay.hidden {
			opacity: 0;
			pointer-events: none;
		}
		.spinner {
			border: 4px solid rgba(255, 255, 255, 0.3);
			border-top: 4px solid var(--accent-cyan);
			border-radius: 50%;
			width: 40px;
			height: 40px;
			animation: spin 1s linear infinite;
			margin-bottom: 1em;
		}
		@keyframes spin {
			0% { transform: rotate(0deg); }
			100% { transform: rotate(360deg); }
		}
		#loading-overlay p {
			color: var(--text-secondary);
			font-size: 1.1em;
		}
	`)

	div {
		style = "background: rgba(30,30,32,0.35); border-radius: 18px; box-shadow: 0 8px 32px 0 rgba(31,38,135,0.37); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border-color); padding: 2.5em 2em; margin: 2em auto; max-width: 650px;"
		
		h1 {
			style = "font-size: 2.2em; color: var(--accent-cyan); margin-bottom: 0.5em; text-align: center; text-shadow: 0 2px 12px rgba(34,211,238,0.15);"
			text("About the Ring Programming Language")
		}

		p {
			style = "font-size: 1.1em; color: var(--text-secondary); margin-bottom: 1.5em; text-align: center;"
			text("Ring is an innovative, dynamic, and practical programming "+nl+" language designed for productivity, simplicity, and natural coding style.")
		}

		h2 {
			style = "font-size: 1.3em; color: var(--accent-purple); margin-bottom: 0.7em; text-align: left;"
			text("Key Features of Ring:")
		}

		UL {
			style = "margin-left: 1.2em; margin-bottom: 1.5em;"
			LI { style = "color: var(--accent-green); margin-bottom: 0.4em;" text("Simple syntax inspired by natural language.") }
			LI { style = "color: var(--accent-yellow); margin-bottom: 0.4em;" text("Supports procedural, object-oriented, functional, and declarative programming.") }
			LI { style = "color: var(--accent-cyan); margin-bottom: 0.4em;" text("Easy integration with C/C++ and other languages.") }
			LI { style = "color: var(--accent-red);" text("Ideal for desktop, web, mobile, and embedded development.") }
		}

		p {
			style = "margin-top: 2em; text-align: center; color: var(--text-secondary);"
			text("Learn more at the ")
			Link {
				Title = "Ring Language Homepage"
				Link = "http://ring-lang.net/"
				style = "color: var(--accent-purple); text-decoration: underline; font-weight: 500;"
				target = "_blank"
			}
		}
	
		div {
			style = "display: flex; flex-direction: column; align-items: center; margin-top: 2.5em; gap: 1.2em;"
			button {
				style = "
					background: linear-gradient(90deg, var(--accent-cyan) 0%, var(--accent-purple) 100%);
					color: #fff;
					border: none;
					border-radius: 12px;
					padding: 14px 32px;
					font-size: 1.08em;
					font-weight: 600;
					cursor: pointer;
					transition: transform 0.15s cubic-bezier(.4,2,.6,1), box-shadow 0.18s;
					box-shadow: 0 6px 24px 0 rgba(34,211,238,0.15), 0 1.5px 6px 0 rgba(192,132,252,0.10);
					letter-spacing: 0.03em;
					outline: none;
				"
				onmouseover = "this.style.transform='translateY(-2px) scale(1.04)'; this.style.boxShadow='0 10px 32px 0 rgba(34,211,238,0.22), 0 2px 8px 0 rgba(192,132,252,0.16)';"
				onmouseout = "this.style.transform='none'; this.style.boxShadow='0 6px 24px 0 rgba(34,211,238,0.15), 0 1.5px 6px 0 rgba(192,132,252,0.10)';"
				text("🚀 Show Alert")
				onclick = "window.showAlert()"
			}
		}
	}

	p {
	   style = "text-align: center; color: var(--text-secondary); margin-top: 2.5em; font-size: 1em;"
	   text("Page generated using WebLib.")
	}
}

# Set the dynamically generated HTML content in the webview.
w.setHtml(mypage.output())

# Run the webview's main event loop. This is a blocking call.
w.run()

see "Webview closed." + nl

func showAlert(id, req)
	w.evalJS("alert('Hello from Ring! This alert was triggered by a callback.')")
	w.wreturn(id, WEBVIEW_ERROR_OK, '""')
