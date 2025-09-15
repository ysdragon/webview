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
w.setSize(900, 800, WEBVIEW_HINT_NONE)

// Create the page using HtmlPage for in-memory generation
myPage = new HtmlPage {
	// Apply global styles by calling the Style() method
	Style(`
		@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Fira+Code:wght@400;500;600&display=swap');
		@import url('https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css');
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
		html {
			background: var(--bg-primary);
		}
		body {
			font-family: 'Inter', sans-serif;
			background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
			color: var(--text-primary);
			margin: 0;
			padding: 0;
			height: 100vh;
			overflow: hidden;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			position: relative;
			box-sizing: border-box;
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
		.main-card {
			background: var(--card-bg);
			border: 1px solid var(--card-border);
			border-radius: 20px;
			padding: clamp(1.5rem, 4vw, 2.5rem);
			text-align: center;
			width: min(90vw, 50rem);
			max-height: min(85vh, 42rem);
			overflow-y: auto;
			box-shadow: var(--shadow-lg), 0 0 0 1px var(--card-border);
			backdrop-filter: blur(var(--blur-lg));
			-webkit-backdrop-filter: blur(var(--blur-lg));
			position: relative;
			z-index: 10;
			box-sizing: border-box;
			transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
		}
		.main-card:hover {
			transform: translateY(-4px);
			box-shadow: var(--shadow-lg), 0 25px 50px -12px rgba(0, 0, 0, 0.25);
			border-color: rgba(59, 130, 246, 0.3);
		}
		h1 {
			color: var(--text-primary);
			margin-bottom: clamp(1rem, 3vw, 1.5rem);
			font-size: clamp(1.5rem, 5vw, 2.2rem);
			font-weight: 700;
			letter-spacing: -0.025em;
			text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.75rem;
		}
		h1 i {
			color: var(--accent-cyan);
			font-size: clamp(1.2rem, 4vw, 1.8rem);
		}
		p {
			color: var(--text-secondary);
			margin-bottom: clamp(1rem, 3vw, 1.5rem);
			font-size: clamp(1rem, 2.5vw, 1.1rem);
			line-height: 1.6;
			font-weight: 400;
		}
		button {
			background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
			color: white;
			border: none;
			border-radius: 12px;
			padding: clamp(0.6rem, 2vw, 0.75rem) clamp(1rem, 3vw, 1.5rem);
			font-size: clamp(0.9rem, 2.5vw, 1rem);
			font-weight: 600;
			cursor: pointer;
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
			box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
			margin: clamp(0.25rem, 1vw, 0.5rem);
			backdrop-filter: blur(var(--blur-sm));
			border: 1px solid rgba(255, 255, 255, 0.1);
			text-transform: uppercase;
			letter-spacing: 0.5px;
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
		#response {
			margin-top: clamp(1rem, 3vw, 1.5rem);
			font-style: italic;
			color: var(--text-secondary);
			font-size: clamp(0.9rem, 2.5vw, 1rem);
			min-height: clamp(1.5rem, 4vw, 2rem);
			padding: clamp(0.5rem, 2vw, 0.75rem);
			background: rgba(148, 163, 184, 0.05);
			border-radius: 8px;
			border: 1px solid var(--card-border);
		}
		.card {
			margin-bottom: clamp(1rem, 3vw, 1.5rem);
			padding: clamp(1rem, 3vw, 1.5rem);
			border: 1px solid var(--card-border);
			border-radius: 12px;
			background: rgba(148, 163, 184, 0.05);
			flex: 1;
			min-width: clamp(200px, 45%, 300px);
			max-width: 45%;
			backdrop-filter: blur(var(--blur-sm));
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
		}
		.card:hover {
			background: rgba(59, 130, 246, 0.08);
			transform: translateY(-2px);
			box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
		}
		h2 {
			color: var(--text-primary);
			margin-top: 0;
			margin-bottom: clamp(0.75rem, 2vw, 1rem);
			border-bottom: 2px solid var(--card-border);
			padding-bottom: clamp(0.5rem, 1.5vw, 0.75rem);
			font-size: clamp(1.1rem, 3vw, 1.3rem);
			font-weight: 600;
			letter-spacing: -0.025em;
		}
		.button-group {
			display: flex;
			justify-content: center;
			gap: clamp(0.5rem, 2vw, 0.75rem);
			margin-bottom: clamp(1rem, 3vw, 1.5rem);
			flex-wrap: wrap;
			align-items: center;
		}
		.result {
			font-size: clamp(1.1rem, 3vw, 1.3rem);
			font-weight: 600;
			margin-top: clamp(1rem, 3vw, 1.5rem);
			padding: clamp(0.75rem, 2vw, 1rem);
			background: rgba(148, 163, 184, 0.05);
			border-radius: 12px;
			min-height: clamp(2rem, 5vw, 3rem);
			display: flex;
			justify-content: center;
			align-items: center;
			color: var(--text-primary);
			border: 1px solid var(--card-border);
			backdrop-filter: blur(var(--blur-sm));
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
		}
		.counter-value {
			color: var(--accent-cyan);
			font-weight: 700;
			font-family: 'Fira Code', monospace;
			font-size: clamp(1.2rem, 3.5vw, 1.5rem);
			text-shadow: 0 2px 8px rgba(6, 182, 212, 0.3);
		}
		.modules-container {
			display: flex;
			flex-wrap: wrap;
			justify-content: center;
			gap: clamp(1rem, 3vw, 1.5rem);
			width: 100%;
			margin-top: clamp(1.5rem, 4vw, 2rem);
			align-items: stretch;
		}
		@media (max-width: 768px) {
			.main-card {
				padding: clamp(1rem, 4vw, 1.5rem);
				width: min(95vw, 28rem);
			}
			h1 {
				flex-direction: column;
				gap: 0.5rem;
			}
			ul {
				gap: 0.5rem;
			}
			h4 {
				padding-left: 2.5rem;
			}
			h4::before {
				left: 0.75rem;
			}
		}
		@media (max-width: 480px) {
			.main-card {
				padding: 1rem;
				width: 95vw;
				border-radius: 16px;
			}
			button {
				width: 100%;
				margin: 0.5rem 0;
			}
			h4 {
				padding: 0.75rem;
				padding-left: 2.25rem;
				font-size: 0.9rem;
			}
			h4::before {
				left: 0.75rem;
				font-size: 1rem;
			}
		}
	`)

	div {
		style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; overflow: hidden;"
		div {
			style = "position: relative; width: 100%; height: 100%; filter: blur(120px); opacity: 0.4;"
			div {
				style = "position: absolute; width: 60vw; height: 60vh; background: radial-gradient(ellipse at center, rgba(59, 130, 246, 0.3) 0%, rgba(139, 92, 246, 0.2) 40%, transparent 70%); top: -10%; left: -15%; animation: aurora-drift 20s ease-in-out infinite;"
			}
			div {
				style = "position: absolute; width: 50vw; height: 50vh; background: radial-gradient(ellipse at center, rgba(6, 182, 212, 0.25) 0%, rgba(16, 185, 129, 0.15) 50%, transparent 70%); bottom: -10%; right: -15%; animation: aurora-drift 25s ease-in-out infinite reverse;"
			}
		}
	}
	div {
		style = "background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 20px; padding: clamp(1.5rem, 4vw, 2.5rem); text-align: center; width: min(90vw, 50rem); max-height: min(85vh, 42rem); overflow-y: auto; box-shadow: var(--shadow-lg), 0 0 0 1px var(--card-border); backdrop-filter: blur(var(--blur-lg)); -webkit-backdrop-filter: blur(var(--blur-lg)); position: relative; z-index: 10; box-sizing: border-box; transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);"
		h1 {
			text("Ring Programming Language") 
		}
		p { 
			text("Ring is an innovative, dynamic, and practical programming "+nl+" language designed for productivity, simplicity, and natural coding style.") 
		}
		UL {
			H4 { text("Simple syntax inspired by natural language.") }
			H4 { text("Supports procedural, object-oriented, functional, and declarative programming.") }
			H4 { text("Easy integration with C/C++ and other languages.") }
			H4 { text("Ideal for desktop, web, mobile, and embedded development.") }
		}
		p {
			text("Learn more at the ")
			Link {
				Title = "Ring Language Homepage"
				Link = "http://ring-lang.net/"
				style = "color: var(--accent-secondary); text-decoration: none; font-weight: 600; position: relative; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);"
				target = "_blank"
			}
		}
		div {
			style = "display: flex; flex-direction: column; align-items: center; margin-top: 2.5em; gap: 1.2em;"
			button {
				style = "
					background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
					color: white;
					border: none;
					border-radius: 12px;
					padding: clamp(0.6rem, 2vw, 0.75rem) clamp(1rem, 3vw, 1.5rem);
					font-size: clamp(0.9rem, 2.5vw, 1rem);
					font-weight: 600;
					cursor: pointer;
					transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
					box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
					margin: clamp(0.25rem, 1vw, 0.5rem);
					backdrop-filter: blur(var(--blur-sm));
					border: 1px solid rgba(255, 255, 255, 0.1);
					text-transform: uppercase;
					letter-spacing: 0.5px;
				"
				text("Show Alert")
				onclick = "window.showAlert()"
			}
		}
		p {
		   style = "text-align: center; color: var(--text-secondary); margin-top: clamp(2rem, 5vw, 3rem); font-size: clamp(0.9rem, 2.5vw, 1rem); font-style: italic; opacity: 0.8;"
		   text("Page generated using WebLib.")
		}
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
