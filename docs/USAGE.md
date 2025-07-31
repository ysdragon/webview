# Usage Guide

This guide provides practical examples of how to use the Ring WebView library to build your applications.

## Basic Setup

Every WebView application starts with creating a `WebView` instance, setting its properties, and running the event loop.

```ring
# Load the webview library
load "webview.ring"

# To customize, modify the global config before creating the instance
aWebViewConfig[:debug] = false

# Create a new WebView instance using the global configuration
oWebView = new WebView()

# Set the window title
oWebView.setTitle("My App")

# Set the window size
oWebView.setSize(800, 600, WEBVIEW_HINT_NONE)

# Load your HTML content
oWebView.setHtml("<h1>Hello, World!</h1>")

# Run the main event loop
oWebView.run()
```

## Loading External HTML

Instead of embedding HTML directly, you can load it from a local file or a remote URL.

### Loading a Local File

```ring
# Load HTML from a local file
my_html = read("path/to/your/index.html")
oWebView.setHtml(my_html)
```

### Navigating to a URL

```ring
# Navigate to a remote URL
oWebView.navigate("https://www.google.com")
```

## Two-Way Binding: Ring and JavaScript

One of the most powerful features of WebView is the ability to communicate between your Ring backend and JavaScript frontend.

### Calling Ring from JavaScript

You can expose Ring functions to your JavaScript code using the `bind()` method.

**Ring Code:**
```ring
load "jsonlib.ring" # Required for JSON parsing

# Define a global list of functions to bind
aBindList = [
    ["sayHello", :greet]
]

# The new WebView() constructor automatically binds the global `aBindList`.
oWebView = new WebView()

# You can also bind more functions later
oWebView.bind("anotherFunc", :anotherHandler)

func greet(id, req)
    # `id` is the callback ID for wreturn()
    # `req` is a JSON string containing arguments from JavaScript
    aArgs = json2list(req) # Parse the JSON string into a Ring list
    cName = aArgs[1][1] # Assuming a single string argument

    see "Hello, " + cName + " from Ring!" + nl

    # Return a response to JavaScript
    oWebView.wreturn(id, WEBVIEW_ERROR_OK, '"Greeting received by Ring!"')

```

**JavaScript Code:**
```html
<script>
async function callGreet() {
    const response = await window.sayHello('World'); // Calls Ring function
    alert(response); // Displays "Greeting received by Ring!"
}
</script>
<button onclick="callGreet()">Say Hello</button>
```
When the button is clicked, the `greet` function in your Ring code will be called with the argument `'World'`, and the alert will show the response from Ring.

### Binding Object Methods

You can bind specific methods of a Ring object to JavaScript functions.

**Ring Code:**
```ring
load "webview.ring"

oCounter = new Counter
oWebView = new WebView()

oWebView.bind(oCounter, [
			["getValue", :getValue],
			["increment", :increment]
		])

oWebView.setHtml(`
	<h1>Counter: <span id="counter">0</span></h1>
	<button onclick="window.increment()">Increment</button>
	<script>
		async function updateValue() {
			const value = await window.getValue();
			document.getElementById('counter').innerText = value;
		}
		updateValue();
	</script>
`)
oWebView.run()

class Counter
	value = 0

	func getValue(id, req)
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, "" + self.value)

	func increment(id, req)
		self._value++
		oWebView.evalJS("document.getElementById('counter').innerText = " + self.value)
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')
```

### Using `bindMany`

You can use `bindMany` to bind multiple functions and object methods at once.

```ring
aBindList = [
    # Simple function binding
    ["showAlert", :showAlert],
    # Object method binding
    [oCounter, [
        ["increment", :increment],
        ["getValue", :getValue]
    ]]
]

# This will be called automatically if `aBindList` is global,
# or you can call it manually:
oWebView.bindMany(aBindList)
```

### Calling JavaScript from Ring

You can execute JavaScript from your Ring code using the `evalJS()` method. This is useful for dynamic UI updates or triggering client-side logic.

```ring
# This will execute the alert in the webview
oWebView.evalJS("alert('This is called from Ring!');")
```

### Injecting JavaScript (`injectJS`)

Use `injectJS()` to run JavaScript code *before* the main document content loads. This is ideal for setting up global variables, listeners, or utility functions that should be available as soon as the page is ready.

```ring
oWebView.injectJS("window.myGlobalVar = 'Hello from injected JS!'; console.log(window.myGlobalVar);")
```

### Dispatching Ring Code to Main Thread (`dispatch`)

The `dispatch()` method allows you to execute a Ring function on the main UI thread of the webview. This is crucial when you need to update the UI or perform operations that require the main thread context, especially if your Ring logic is running asynchronously or in a separate thread.

**Ring Code:**
```ring
# To call it:
oWebView.dispatch("updateUiFromThread()")

func updateUiFromThread()
    oWebView.evalJS("document.getElementById('status').innerText = 'UI Updated from Dispatched Call!';")
```

### Unbinding Functions (`unbind`)

If you no longer need a JavaScript-to-Ring binding, you can remove it using `unbind()`. This frees up resources and prevents further calls to the Ring function from JavaScript.

```ring
# Assuming 'sayHello' was previously bound
oWebView.unbind("sayHello")
```

## Advanced Example: Counter

Here is an example of a simple counter application that demonstrates two-way binding.

**Ring Code (`counter.ring`):**
```ring
load "webview.ring"

# Create a new WebView instance
oWebView = new WebView()

oWebView {
    setTitle("Counter Example")
    setSize(300, 200, WEBVIEW_HINT_FIXED)
    bind("increment", :increment)
    setHtml(`
        <!DOCTYPE html>
        <html>
            <head><title>Counter</title></head>
            <body>
                <h1>Counter</h1>
                <p id="counter">0</p>
                <button onclick="window.increment(document.getElementById('counter').innerText)">
                    Increment
                </button>
            </body>
        </html>
    `)
    run()
}

func increment(id, req)
	# req is a string representing the current value, e.g., ["0"]
	current_value = number(substr(req, 3, len(req)-4))
	new_value = current_value + 1
	oWebView.evalJS("document.getElementById('counter').innerText = " + new_value)
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""')
```

This example shows how JavaScript can call a Ring function (`increment`) to perform a calculation, and how Ring can then call JavaScript (`evalJS`) to update the UI. It also demonstrates how to pass data from JavaScript to Ring and receive an acknowledgment using `wreturn()`.