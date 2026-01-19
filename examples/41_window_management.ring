# Example 41: Window Management
# Demonstrates: hide, show, focus, minimize, maximize, restore, setPosition, getPosition, 
#               getSize, setMinSize, setMaxSize, setResizable, setFullscreen

load "webview.ring"
load "simplejson.ring"

aBindList = [
    ["doMinimize", :doMinimize],
    ["doMaximize", :doMaximize],
    ["doRestore", :doRestore],
    ["doHide", :doHide],
    ["doFullscreen", :doFullscreen],
    ["setPos", :setPos],
    ["getInfo", :getInfo],
    ["toggleResizable", :toggleResizable],
    ["setConstraints", :setConstraints]
]

oWebView = new WebView()

bResizable = true
bFullscreen = false

oWebView {
    setTitle("Window Management Demo")
    setSize(600, 550, WEBVIEW_HINT_NONE)
    
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
                    background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
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
                    color: #11998e;
                    margin: 3px;
                }
                button:hover { opacity: 0.9; }
                .btn-row { display: flex; flex-wrap: wrap; gap: 5px; }
                #info {
                    background: rgba(0,0,0,0.2);
                    padding: 10px;
                    border-radius: 5px;
                    font-family: monospace;
                    font-size: 0.85rem;
                    margin-top: 10px;
                    white-space: pre-line;
                }
                .note { font-size: 0.75rem; opacity: 0.7; margin-top: 8px; }
                .full-width { grid-column: 1 / -1; }
            </style>
        </head>
        <body>
            <h2>Window Management</h2>
            <div class="grid">
                <div class="section">
                    <h3>Window State</h3>
                    <div class="btn-row">
                        <button onclick="doMinimize()">Minimize</button>
                        <button onclick="doMaximize()">Maximize</button>
                        <button onclick="doRestore()">Restore</button>
                    </div>
                </div>
                
                <div class="section">
                    <h3>Visibility</h3>
                    <div class="btn-row">
                        <button onclick="doHide()">Hide (2s)</button>
                        <button onclick="doFullscreen()">Fullscreen</button>
                    </div>
                </div>
                
                <div class="section">
                    <h3>Position (Win/Mac only)</h3>
                    <div class="btn-row">
                        <button onclick="setPos(100, 100)">Top-Left</button>
                        <button onclick="setPos(500, 100)">Top-Right</button>
                        <button onclick="setPos(300, 300)">Center</button>
                    </div>
                </div>
                
                <div class="section">
                    <h3>Size Constraints</h3>
                    <div class="btn-row">
                        <button onclick="toggleResizable()">Toggle Resizable</button>
                        <button onclick="setConstraints()">Set Min/Max</button>
                    </div>
                    <div class="note">Min: 400x300, Max: 800x600</div>
                </div>
                
                <div class="section full-width">
                    <h3>Window Info</h3>
                    <button onclick="getInfo()">Refresh Info</button>
                    <div id="info">Click "Refresh Info" to see window state</div>
                </div>
            </div>
        </body>
        </html>
    `)
    
    run()
}

func doMinimize(id, req)
    oWebView.minimize()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doMaximize(id, req)
    oWebView.maximize()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doRestore(id, req)
    oWebView.restore()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func doHide(id, req)
    oWebView.hide()
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")
    syssleep(2000)
    oWebView.show()
    oWebView.focus()

func doFullscreen(id, req)
    bFullscreen = !bFullscreen
    oWebView.setFullscreen(bFullscreen)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func setPos(id, req)
    aParams = json_decode(req)
    oWebView.setPosition(number(aParams[1]), number(aParams[2]))
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func getInfo(id, req)
    aPos = oWebView.getPosition()
    aSize = oWebView.getSize()
    cInfo = "Position: " + aPos[1] + ", " + aPos[2] + "\n"
    cInfo += "Size: " + aSize[1] + " x " + aSize[2] + "\n"
    cInfo += "Maximized: " + oWebView.isMaximized() + "\n"
    cInfo += "Fullscreen: " + oWebView.isFullscreen() + "\n"
    cInfo += "Resizable: " + oWebView.isResizable() + "\n"
    cInfo += "Focused: " + oWebView.isFocused() + "\n"
    cInfo += "Visible: " + oWebView.isVisible()
    oWebView.evalJS('document.getElementById("info").textContent = "' + cInfo + '"')
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func toggleResizable(id, req)
    bResizable = !bResizable
    oWebView.setResizable(bResizable)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func setConstraints(id, req)
    oWebView.setMinSize(400, 300)
    oWebView.setMaxSize(800, 600)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")
