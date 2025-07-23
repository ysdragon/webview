# This file is part of the Ring WebView library.

load "webview.ring"

# Variable to hold the webview instance.
oWebView = NULL

# Optional Configuration for the WebView instance.
# This can be customized as needed.
aWebViewConfig = [
    :debug = false,  # Disable debug mode
    :window = NULL  # No parent window, create a new one
]

# Define a global list of bindings for the first webview instance.
# The WebView class will automatically detect and use this global list.
aBindList = [
    ["sayHello", :handleSayHello],
    ["showInfo", :handleShowInfo]
]

# --- Main Application Logic ---

func main
    # Create a webview instance, which will use the global `aBindList`.
    oWebView = new WebView()
    
    oWebView {
        # Set the title and size of the webview window.
        setTitle("bindMany() - Global List")
        setSize(500, 230, WEBVIEW_HINT_NONE)
        
        # You can also use bindMany(BindList) to explicitly bind the list.
        # Like this: 
        # BindList = [
        #     ["sayHello", :handleSayHello],
        #     ["showInfo", :handleShowInfo]
        # ]
        # bindMany(BindList)

        # Set the HTML content for the webview.
        setHtml(getHtmlContent())

        # Run the webview event loop.
        run()
    }

# --- Callback Functions ---

func handleSayHello(id, req)
    oWebView.evalJS("alert('Hello from Ring!');")

func handleShowInfo(id, req)
    oWebView.evalJS("alert('This is the first webview, using a global binding list.');")

# --- HTML Content ---

func getHtmlContent()
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap');
        :root {
            --bg-color: #000000; --panel-bg: rgba(30, 30, 32, 0.6);
            --border-color: rgba(255, 255, 255, 0.1); --text-primary: #f8fafc;
            --text-secondary: #a1a1aa; --accent-blue: #3b82f6;
            --accent-cyan: #22d3ee; --accent-purple: #c084fc;
        }
        body {
            font-family: 'Inter', sans-serif; background-color: var(--bg-color);
            color: var(--text-primary); margin: 0; height: 100vh; overflow: hidden;
            display: flex; flex-direction: column; justify-content: center;
            align-items: center; position: relative;
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
        .main-card {
            background-color: var(--panel-bg); border: 1px solid var(--border-color);
            border-radius: 15px; padding: 30px; text-align: center;
            max-width: 500px; width: 90%; box-shadow: 0 8px 30px rgba(0,0,0,0.3);
            backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
            position: relative; z-index: 1;
        }
        h1 {
            color: var(--text-primary); margin-bottom: 15px; font-size: 2.2em;
        }
        p {
            color: var(--text-secondary); margin-bottom: 25px; font-size: 1.1em;
        }
        button {
            background-color: var(--accent-blue); color: white; border: none;
            border-radius: 8px; padding: 12px 20px; font-size: 1em;
            font-weight: 500; cursor: pointer; transition: all 0.2s ease-in-out;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2); margin: 0 8px 10px 8px;
        }
        button:hover {
            transform: translateY(-2px); box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
        }
        #response {
            margin-top: 20px; font-style: italic; color: var(--text-secondary);
            font-size: 0.95em; min-height: 20px;
        }
    </style>
</head>
<body>
    <div class="background-container">
        <div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
    </div>
    <div class="main-card">
        <h1>bindMany()</h1>
        <p>Binding multiple functions from Ring to JavaScript.</p>
        
        <button onclick="window.sayHello()">Say Hello</button>
        <button onclick="window.showInfo()">Show Info</button>        
    </div>
</body>
</html>
`