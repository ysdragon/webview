# Example 42: WebView Features
# Demonstrates: back, forward, reload, getUrl, getPageTitle, setDevTools, 
#               setContextMenu, setForceDark, getScreens, setClickThrough

load "webview.ring"

aBindList = [
    ["doNavigate", :doNavigate],
    ["doBack", :doBack],
    ["doForward", :doForward],
    ["doReload", :doReload],
    ["getPageInfo", :getPageInfo],
    ["toggleDevTools", :toggleDevTools],
    ["toggleContextMenu", :toggleContextMenu],
    ["toggleDarkMode", :toggleDarkMode],
    ["showScreens", :showScreens]
]

oWebView = new WebView()

bDevTools = false
bContextMenu = true
bDarkMode = false

oWebView {
    setTitle("WebView Features Demo")
    setSize(650, 550, WEBVIEW_HINT_NONE)

    setHtml(`
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 20px;
                    margin: 0;
                    background: linear-gradient(135deg, #fc466b 0%, #3f5efb 100%);
                    color: white;
                    min-height: 100vh;
                }
                h2 { text-align: center; margin-bottom: 20px; }
                .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
                .section {
                    background: rgba(255,255,255,0.15);
                    padding: 15px;
                    border-radius: 10px;
                }
                .section h3 {
                    margin: 0 0 10px 0;
                    font-size: 0.95rem;
                    opacity: 0.9;
                }
                button {
                    padding: 8px 15px;
                    border: none;
                    border-radius: 5px;
                    cursor: pointer;
                    font-size: 0.85rem;
                    background: white;
                    color: #3f5efb;
                    margin: 3px;
                }
                button:hover { opacity: 0.9; }
                .btn-row { display: flex; flex-wrap: wrap; gap: 5px; }
                #info {
                    background: rgba(0,0,0,0.2);
                    padding: 10px;
                    border-radius: 5px;
                    font-family: monospace;
                    font-size: 0.8rem;
                    margin-top: 10px;
                    max-height: 120px;
                    overflow-y: auto;
                    white-space: pre-wrap;
                    word-break: break-all;
                }
                .note { font-size: 0.75rem; opacity: 0.7; margin-top: 8px; }
                .full-width { grid-column: 1 / -1; }
                .nav-btns button { min-width: 70px; }
            </style>
        </head>
        <body>
            <h2>WebView Features</h2>
            <div class="grid">
                <div class="section">
                    <h3>Navigation</h3>
                    <div class="btn-row nav-btns">
                        <button onclick="doBack()">← Back</button>
                        <button onclick="doForward()">Forward →</button>
                        <button onclick="doReload()">↻ Reload</button>
                    </div>
                    <div class="btn-row" style="margin-top:10px">
                        <button onclick="doNavigate('https://ring-lang.github.io')">Ring Lang</button>
                        <button onclick="doNavigate('https://github.com')">GitHub</button>
                    </div>
                </div>
                
                <div class="section">
                    <h3>Developer</h3>
                    <div class="btn-row">
                        <button onclick="toggleDevTools()">Toggle DevTools</button>
                        <button onclick="toggleContextMenu()">Toggle Right-Click</button>
                    </div>
                    <div id="devStatus" class="note">DevTools: Off | Context Menu: On</div>
                </div>
                
                <div class="section">
                    <h3>Appearance</h3>
                    <div class="btn-row">
                        <button onclick="toggleDarkMode()">Toggle Dark Mode</button>
                    </div>
                    <div class="note">Linux only (libadwaita)</div>
                </div>
                
                <div class="section">
                    <h3>System</h3>
                    <div class="btn-row">
                        <button onclick="showScreens()">Show Screens</button>
                        <button onclick="getPageInfo()">Page Info</button>
                    </div>
                </div>
                
                <div class="section full-width">
                    <h3>Info</h3>
                    <div id="info">Click buttons above to see information here</div>
                </div>
            </div>
        </body>
        </html>
    `)
    
    run()
}

func doNavigate(id, req)
    cUrl = substr(req, 3, len(req) - 4)
    oWebView.navigate(cUrl)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doBack(id, req)
    oWebView.back()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doForward(id, req)
    oWebView.forward()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doReload(id, req)
    oWebView.reload()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func getPageInfo(id, req)
    cInfo = "URL: " + oWebView.getUrl() + "\nTitle: " + oWebView.getPageTitle()
    oWebView.evalJS('document.getElementById("info").textContent = `' + cInfo + '`')
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func toggleDevTools(id, req)
    bDevTools = !bDevTools
    oWebView.setDevTools(bDevTools)
    updateDevStatus()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func toggleContextMenu(id, req)
    bContextMenu = !bContextMenu
    oWebView.setContextMenu(bContextMenu)
    updateDevStatus()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func updateDevStatus()
    cDev = "Off"  if !bDevTools cDev = "Off" else cDev = "On" ok
    cCtx = "Off"  if !bContextMenu cCtx = "Off" else cCtx = "On" ok
    oWebView.evalJS('document.getElementById("devStatus").textContent = "DevTools: ' + cDev + ' | Context Menu: ' + cCtx + '"')

func toggleDarkMode(id, req)
    bDarkMode = !bDarkMode
    oWebView.setForceDark(bDarkMode)
    cStatus = "Dark Mode: "
    if bDarkMode cStatus += "On" else cStatus += "Off" ok
    oWebView.evalJS('document.getElementById("info").textContent = "' + cStatus + '"')
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func showScreens(id, req)
    aScreens = oWebView.getScreens()
    cInfo = "Screens: " + len(aScreens) + "\n"
    for i = 1 to len(aScreens)
        s = aScreens[i]
        # Format: [name, x, y, width, height]
        cInfo += "\n[" + i + "] " + s[1] + "\n"
        cInfo += "    Size: " + s[4] + "x" + s[5] + "\n"
        cInfo += "    Pos: " + s[2] + "," + s[3]
    next
    oWebView.evalJS('document.getElementById("info").textContent = `' + cInfo + '`')
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")
