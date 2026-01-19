# Example 43: Event Callbacks
# Demonstrates: onClose, onFocus, onDomReady, onLoad, onNavigate, onTitle

load "webview.ring"

aBindList = [
    ["goTo", :goTo],
    ["changeTitle", :changeTitle]
]

oWebView = new WebView()

oWebView {
    setTitle("Event Callbacks Demo")
    setSize(600, 500, WEBVIEW_HINT_NONE)
    
    # Register event callbacks
    onDomReady(:handleDomReady)
    onLoad(:handleLoad)
    onTitle(:handleTitle)
    onNavigate(:handleNavigate)
    onFocus(:handleFocus)
        
    setHtml(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Event Callbacks Demo</title>
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 20px;
                    margin: 0;
                    background: linear-gradient(135deg, #5f2c82 0%, #49a09d 100%);
                    color: white;
                    min-height: 100vh;
                }
                h2 { text-align: center; margin-bottom: 20px; }
                .section {
                    background: rgba(255,255,255,0.15);
                    padding: 15px;
                    border-radius: 10px;
                    margin-bottom: 15px;
                }
                .section h3 {
                    margin: 0 0 10px 0;
                    font-size: 0.95rem;
                }
                button {
                    padding: 10px 18px;
                    border: none;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 0.9rem;
                    background: white;
                    color: #5f2c82;
                    margin: 3px;
                }
                button:hover { opacity: 0.9; }
                input {
                    padding: 10px;
                    border: none;
                    border-radius: 6px;
                    font-size: 0.9rem;
                    width: 250px;
                    margin-right: 10px;
                }
                #log {
                    background: rgba(0,0,0,0.3);
                    padding: 12px;
                    border-radius: 8px;
                    font-family: monospace;
                    font-size: 0.85rem;
                    max-height: 180px;
                    overflow-y: auto;
                }
                .log-entry {
                    padding: 4px 0;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .log-entry:last-child { border: none; }
                .time { opacity: 0.6; }
                .event-type { 
                    background: rgba(255,255,255,0.2);
                    padding: 2px 6px;
                    border-radius: 3px;
                    margin-right: 8px;
                }
            </style>
        </head>
        <body>
            <h2>Event Callbacks</h2>
            
            <div class="section">
                <h3>Test Navigation Events</h3>
                <button onclick="goTo('https://ring-lang.github.io')">Ring Lang</button>
                <button onclick="goTo('https://github.com')">GitHub</button>
            </div>
            
            <div class="section">
                <h3>Test Title Events</h3>
                <input type="text" id="titleInput" placeholder="New title...">
                <button onclick="changeTitle()">Change Title</button>
            </div>
            
            <div class="section">
                <h3>Event Log</h3>
                <div id="log">
                    <div class="log-entry"><span class="time">[--:--:--]</span> Waiting for events...</div>
                </div>
            </div>
            
            <script>
                function addLog(type, msg) {
                    const log = document.getElementById('log');
                    const time = new Date().toLocaleTimeString();
                    const entry = document.createElement('div');
                    entry.className = 'log-entry';
                    entry.innerHTML = '<span class="time">[' + time + ']</span> <span class="event-type">' + type + '</span>' + msg;
                    log.insertBefore(entry, log.firstChild);
                    if (log.children.length > 20) log.removeChild(log.lastChild);
                }
            </script>
        </body>
        </html>
    `)
    
    run()
}

func goTo(id, req)
    cUrl = substr(req, 3, len(req) - 4)
    oWebView.navigate(cUrl)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func changeTitle(id, req)
    oWebView.evalJS(`
        var t = document.getElementById('titleInput').value;
        if (t) document.title = t;
    `)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func handleDomReady
    see "Event: DOM Ready" + nl
    oWebView.evalJS('addLog("DOM", "Document ready")')

func handleLoad(cState)
    see "Event: Load - " + cState + nl
    oWebView.evalJS('addLog("LOAD", "' + cState + '")')

func handleTitle(cTitle)
    see "Event: Title - " + cTitle + nl
    cSafe = substr(cTitle, "'", "\'")
    oWebView.setTitle(cTitle)
    oWebView.evalJS("addLog('TITLE', '" + cSafe + "')")

func handleNavigate(cUrl)
    see "Event: Navigate - " + cUrl + nl
    oWebView.evalJS('addLog("NAV", "' + cUrl + '")')

func handleFocus(cFocused)
    see "Event: Focus - " + cFocused + nl
    oWebView.evalJS('addLog("FOCUS", "' + cFocused + '")')
