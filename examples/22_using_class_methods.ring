# Using class methods as a WebView callback
# This example demonstrates how to use a wrapper function to call class methods
# Or to call objects directly
# from JavaScript callbacks in WebView.

load "webview.ring"
load "jsonlib.ring"

# Global variables
oWebView = NULL

# Stores object references to be called from wrappers.
aWebObjects = [] 

# Main
func main()
	oWebView = new WebView()
	
	# Create an instance of our class.
	oMyClass = new myClass

	# Use the Method() wrapper to create a callable function for myMethod.
	pMyMethod = Method(oMyClass, :myMethod)

	oWebView {
		setTitle("Using Class Methods")
		setSize(500, 400, WEBVIEW_HINT_NONE)

		# Bind the dynamically created wrapper function to a JavaScript function name.
		bind("callMyMethod", pMyMethod)

		# Direct binding for myOtherMethod using the object instance.
		bind(oMyClass, [
			["callMyOtherMethod", "myOtherMethod"]
		])

		html = `
			<!DOCTYPE html>
			<html>
			<head>
				<title>Method Wrapper</title>
				<meta charset="UTF-8">
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
				<style>
					@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Fira+Code:wght@400;500&display=swap');
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
					body {
						font-family: 'Inter', sans-serif;
						background-color: var(--bg-color);
						color: var(--text-primary);
						margin: 0;
						height: 100vh;
						overflow: hidden;
						display: flex;
						justify-content: center;
						align-items: center;
						position: relative;
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
						background-color: var(--panel-bg);
						border: 1px solid var(--border-color);
						border-radius: 15px;
						padding: 30px;
						text-align: center;
						max-width: 500px;
						width: 90%;
						box-shadow: 0 8px 30px rgba(0,0,0,0.3);
						backdrop-filter: blur(12px);
						-webkit-backdrop-filter: blur(12px);
						position: relative; z-index: 1;
					}
					h1 {
						color: var(--text-primary);
						margin-bottom: 15px;
						font-size: 2.2em;
						text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
					}
					p {
						color: var(--text-secondary);
						margin-bottom: 25px;
						font-size: 1.1em;
					}
					button {
						background-color: var(--accent-blue);
						color: white;
						border: none;
						border-radius: 8px;
						padding: 12px 20px;
						font-size: 1em;
						font-weight: 500;
						cursor: pointer;
						transition: all 0.2s ease-in-out;
						box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
						margin: 0 8px 10px 8px;
					}
					button:hover {
						transform: translateY(-2px);
						box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
					}
					#response {
						margin-top: 20px;
						font-style: italic;
						color: var(--text-secondary);
						font-size: 0.95em;
						min-height: 20px;
					}
				</style>
			</head>
			<body>
				<div class="background-container">
					<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
				</div>
				<div class="main-card">
					<h1><i class="fa-solid fa-code-branch"></i> Calling Ring Class Methods</h1>
					<p>This button will call a method on a Ring object instance via a dynamic wrapper. The new button demonstrates direct binding.</p>
					<button onclick="callRingMethod()"><i class="fa-solid fa-bolt"></i> Call myClass.myMethod() (Wrapper)</button>
					<button onclick="callRingOtherMethod()"><i class="fa-solid fa-magic"></i> Call myClass.myOtherMethod() (Direct)</button>
					<div id="response"></div>
				</div>
				<script>
					async function callRingMethod() {
						const responseDiv = document.getElementById('response');
						responseDiv.innerText = 'Calling Ring method...';
						try {
							const response = await window.callMyMethod('Some data from JavaScript');
							responseDiv.innerText = 'Response from Ring: ' + response;
						} catch (e) {
							responseDiv.innerText = 'Error: ' + e;
						}
					}

					async function callRingOtherMethod() {
						const responseDiv = document.getElementById('response');
						responseDiv.innerText = 'Calling Ring method directly...';
						try {
							const response = await window.callMyOtherMethod('Another data from JavaScript');
							responseDiv.innerText = 'Response from Ring: ' + response;
						} catch (e) {
							responseDiv.innerText = 'Error: ' + e;
						}
					}
				</script>
			</body>
			</html>
		`
		setHtml(html)
		run()
	}

/* 
	Wrapper Function
	This function takes an object and a method name (as a string) and returns
	a new function that can be used as a callback for WebView bindings.
*/
func Method(oObj, cName)
	aWebObjects + ref(oObj)
	cCode = `
		cFunc = func (id, req) {
			aWebObjects[#{id}].#{cName}(id,req)
		}
	`
	cCode = substr(cCode, "#{id}", ""+len(aWebObjects))
	cCode = substr(cCode, "#{cName}", cName)
	eval(cCode)
	return cFunc

# A sample class with a method to be called from JavaScript.
class myClass
	func myMethod(id, req)
		? "Method myClass.myMethod() called from JavaScript."
		
		# Parse the JSON request from JavaScript.
		aReq = json2list(req)
		cDataFromJS = aReq[1]
		
		? "  Callback ID: " + id
		see "  Data from JS: " see cDataFromJS
		
		# Send a response back to the JavaScript promise.
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back from myClass.myMethod!"')

	func myOtherMethod(id, req)
		? "Method myClass.myOtherMethod() called directly from JavaScript."
		aReq = json2list(req)
		cDataFromJS = aReq[1]
		? "  Callback ID: " + id
		see "  Data from JS: " see cDataFromJS
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Hello back from myClass.myOtherMethod! (Direct Bind)"')
