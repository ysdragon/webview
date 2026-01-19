# Example 40: Window Appearance
# Demonstrates: setDecorated, setOpacity, setBackgroundColor, setIcon, setAlwaysOnTop

load "webview.ring"
load "simplejson.ring"

aBindList = [
    ["toggleDecorated", :toggleDecorated],
    ["setOpacityValue", :setOpacityValue],
    ["setBgColor", :setBgColor],
    ["toggleOnTop", :toggleOnTop]
]

oWebView = new WebView()

bDecorated = true
bOnTop = false

oWebView {
    setTitle("Window Appearance Demo")
    setSize(550, 500, WEBVIEW_HINT_NONE)
    
    bind("toggleDecorated", "toggleDecorated")
    bind("setOpacityValue", "setOpacityValue")
    bind("setBgColor", "setBgColor")
    bind("toggleOnTop", "toggleOnTop")
    
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
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: 100vh;
                }
                h2 { text-align: center; margin-bottom: 25px; }
                .section {
                    background: rgba(255,255,255,0.15);
                    padding: 15px;
                    border-radius: 10px;
                    margin-bottom: 15px;
                }
                .section h3 {
                    margin: 0 0 10px 0;
                    font-size: 1rem;
                    opacity: 0.9;
                }
                button {
                    padding: 10px 20px;
                    border: none;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 0.9rem;
                    background: white;
                    color: #667eea;
                    margin: 3px;
                }
                button:hover { opacity: 0.9; }
                input[type="range"] {
                    width: 100%;
                    margin: 10px 0;
                }
                .color-row { display: flex; gap: 5px; flex-wrap: wrap; }
                .color-btn {
                    width: 40px;
                    height: 40px;
                    border-radius: 8px;
                    border: 2px solid rgba(255,255,255,0.5);
                }
                .status {
                    font-size: 0.85rem;
                    opacity: 0.8;
                    margin-top: 8px;
                }
                .note {
                    font-size: 0.8rem;
                    opacity: 0.7;
                    margin-top: 5px;
                }
            </style>
        </head>
        <body>
            <h2>Window Appearance</h2>
            
            <div class="section">
                <h3>Frameless Window</h3>
                <button onclick="toggleDecorated()">Toggle Decorations</button>
                <div class="status" id="decorStatus">Decorated: Yes</div>
            </div>
            
            <div class="section">
                <h3>Opacity: <span id="opacityVal">100%</span></h3>
                <input type="range" min="20" max="100" value="100" 
                       oninput="document.getElementById('opacityVal').textContent = this.value + '%'; setOpacityValue(this.value)">
            </div>
            
            <div class="section">
                <h3>Background Color</h3>
                <div class="color-row">
                    <button class="color-btn" style="background:#e74c3c" onclick="setBgColor(231,76,60,255)"></button>
                    <button class="color-btn" style="background:#2ecc71" onclick="setBgColor(46,204,113,255)"></button>
                    <button class="color-btn" style="background:#3498db" onclick="setBgColor(52,152,219,255)"></button>
                    <button class="color-btn" style="background:#9b59b6" onclick="setBgColor(155,89,182,255)"></button>
                    <button class="color-btn" style="background:#f39c12" onclick="setBgColor(243,156,18,255)"></button>
                    <button class="color-btn" style="background:#1abc9c" onclick="setBgColor(26,188,156,255)"></button>
                    <button class="color-btn" style="background:rgba(255,255,255,0.5)" onclick="setBgColor(255,255,255,128)"></button>
                </div>
                <div class="note">Background shows behind transparent content</div>
            </div>
            
            <div class="section">
                <h3>Always On Top</h3>
                <button onclick="toggleOnTop()">Toggle Always On Top</button>
                <div class="status" id="onTopStatus">On Top: No</div>
                <div class="note">Windows/macOS only</div>
            </div>
        </body>
        </html>
    `)
    
    run()
}

func toggleDecorated(id, req)
    bDecorated = !bDecorated
    oWebView.setDecorated(bDecorated)
    if bDecorated
        oWebView.evalJS('document.getElementById("decorStatus").textContent = "Decorated: Yes"')
    else
        oWebView.evalJS('document.getElementById("decorStatus").textContent = "Decorated: No"')
    ok
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func setOpacityValue(id, req)
    nVal = json_decode(req)[1]
    oWebView.setOpacity(nVal / 100)
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func setBgColor(id, req)
    aParams = json_decode(req)
    oWebView.setBackgroundColor(number(aParams[1]), number(aParams[2]), number(aParams[3]), number(aParams[4]))
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")

func toggleOnTop(id, req)
    bOnTop = !bOnTop
    oWebView.setAlwaysOnTop(bOnTop)
    if bOnTop
        oWebView.evalJS('document.getElementById("onTopStatus").textContent = "On Top: Yes"')
    else
        oWebView.evalJS('document.getElementById("onTopStatus").textContent = "On Top: No"')
    ok
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, "null")
