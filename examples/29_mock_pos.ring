# Simple Point of Sale (POS) Example
# This script implements a basic Point of Sale (POS) system using WebView.
# It demonstrates product listing, adding items to a cart, calculating totals, and checkout.

load "webview.ring"
load "simplejson.ring"

# Global variables
oWebView = NULL

# Global list of bindings to be callable from JavaScript.
aBindList = [
	["getInitialData", :handleGetInitialData],  # Get initial product and cart data.
	["addToCart", :handleAddToCart],             # Add an item to the shopping cart.
	["checkout", :handleCheckout],               # Process the checkout.
	["removeFromCart", :handleRemoveFromCart]    # Remove an item from the cart.
]

# Sample product data for the POS system.
aProducts = [
	["Coffee", 4.50],
	["Salad", 9.00],
	["Juice", 3.00],
	["Soda", 2.00],
	["Water", 1.50]
]

# Global cart to hold items added by the user.
aCart = []

func main()
	see "Setting up the POS System WebView..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Mock POS Example")
	# Set the window size (no size constraint).
	oWebView.setSize(900, 700, WEBVIEW_HINT_NONE)

	# Load the HTML content for the POS UI.
	loadPOS_HTML()

	see "Running the WebView main loop. Interact with the POS system." + nl
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Defines the HTML structure and inline JavaScript for the POS system.
func loadPOS_HTML()
	cHTML = `
	<!DOCTYPE html>
	<html lang="en">
	<head>
		<title>Ring POS</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
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
			
			.pos-container {
				display: flex;
				gap: 2em;
				width: 90%;
				max-width: 1200px;
				height: 90vh;
				background-color: var(--panel-bg);
				border: 1px solid var(--border-color);
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
				position: relative; z-index: 1;
				overflow: hidden;
			}
			.products-section {
				flex: 2;
				border-right: 1px solid var(--border-color);
				overflow-y: auto;
				padding: 1.5em;
			}
			.cart-section {
				flex: 1;
				overflow-y: auto;
				padding: 1.5em;
				display: flex;
				flex-direction: column;
			}
			h2 {
				color: var(--text-primary);
				border-bottom: 2px solid rgba(255, 255, 255, 0.1);
				padding-bottom: 0.5em;
				margin-top: 0;
				margin-bottom: 1.5em;
				font-size: 1.5em;
			}
			.product-grid {
				display: grid;
				grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
				gap: 1.5em;
			}
			.product-card {
				background-color: rgba(255, 255, 255, 0.05);
				border: 1px solid rgba(255, 255, 255, 0.1);
				border-radius: 10px;
				padding: 1em;
				display: flex;
				flex-direction: column;
				align-items: center;
				text-align: center;
				transition: all 0.2s ease-in-out;
				cursor: pointer;
			}
			.product-card:hover {
				transform: translateY(-5px);
				box-shadow: 0 8px 20px rgba(0,0,0,0.3);
				background-color: rgba(255, 255, 255, 0.1);
			}
			.product-card .icon {
				font-size: 2.5em;
				margin-bottom: 0.5em;
				color: var(--accent-cyan);
			}
			.product-card .name {
				font-weight: 600;
				font-size: 1.1em;
				color: var(--text-primary);
				margin-bottom: 0.2em;
			}
			.product-card .price {
				font-family: 'Fira Code', monospace;
				color: var(--accent-green);
				font-size: 1em;
			}
			.cart-items-list {
				list-style-type: none;
				padding: 0;
				flex-grow: 1;
				margin-bottom: 1em;
				overflow-y: auto;
			}
			.cart-item {
				display: flex;
				justify-content: space-between;
				align-items: center;
				padding: 0.8em 0;
				border-bottom: 1px dashed rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
			}
			.cart-item-info {
				display: flex;
				flex-direction: column;
				align-items: flex-start;
			}
			.cart-item-name {
				font-weight: 500;
			}
			.cart-item-price {
				font-family: 'Fira Code', monospace;
				font-size: 0.9em;
				color: var(--text-secondary);
			}
			.remove-btn {
				background: none;
				border: none;
				color: var(--accent-red);
				cursor: pointer;
				font-size: 1.1em;
				transition: transform 0.2s ease-in-out;
			}
			.remove-btn:hover {
				transform: scale(1.2);
			}
			.cart-total {
				text-align: right;
				font-size: 1.6em;
				font-weight: bold;
				margin-top: 1em;
				padding-top: 0.8em;
				border-top: 2px solid rgba(255, 255, 255, 0.2);
				color: var(--accent-green);
				font-family: 'Fira Code', monospace;
			}
			.checkout-btn {
				width: 100%;
				padding: 1em;
				font-size: 1.2em;
				background-color: var(--accent-green);
				color: white;
				border: none;
				border-radius: 10px;
				cursor: pointer;
				margin-top: 1.5em;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 0.8em;
				font-weight: 600;
			}
			.checkout-btn:hover {
				transform: translateY(-3px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			@media (max-width: 768px) {
				.pos-container {
					flex-direction: column;
					height: auto;
					max-height: 95vh;
					overflow-y: auto;
				}
				.products-section {
					border-right: none;
					border-bottom: 1px solid var(--border-color);
					flex: none;
					width: 100%;
					max-height: 60vh;
				}
				.cart-section {
					flex: none;
					width: 100%;
					max-height: 40vh;
				}
				.product-grid {
					grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
					gap: 1em;
				}
				.product-card .icon {
					font-size: 2em;
				}
				.product-card .name {
					font-size: 0.9em;
				}
				.product-card .price {
					font-size: 0.8em;
				}
				h2 {
					font-size: 1.3em;
				}
				.cart-total {
					font-size: 1.3em;
				}
				.checkout-btn {
					font-size: 1em;
					padding: 0.8em;
				}
			}
			html[dir="rtl"] body {
				direction: rtl;
				text-align: right;
			}
			html[dir="rtl"] .products-section {
				border-right: none;
				border-left: 1px solid var(--border-color);
			}
			html[dir="rtl"] .product-card {
				text-align: center;
			}
			html[dir="rtl"] .add-btn {
				flex-direction: row-reverse;
			}
			html[dir="rtl"] .cart-item {
				flex-direction: row-reverse;
			}
			html[dir="rtl"] .cart-item-info {
				align-items: flex-end;
			}
			html[dir="rtl"] .cart-total {
				text-align: left;
			}
			html[dir="rtl"] .checkout-btn {
				flex-direction: row-reverse;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="pos-container">
			<div class="products-section">
				<h2><i class="fa-solid fa-boxes-stacked"></i> Products</h2>
				<div id="product-list" class="product-grid"></div>
			</div>
			<div class="cart-section">
				<h2><i class="fa-solid fa-cart-shopping"></i> Shopping Cart</h2>
				<ul id="cart-items" class="cart-items-list"></ul>
				<div class="cart-total">Total: $<span id="total-price">0.00</span></div>
				<button class="checkout-btn" onclick="handleCheckout()"><i class="fa-solid fa-cash-register"></i> Checkout</button>
			</div>
		</div>
		<script>
			const productIcons = {
				"Coffee": "fa-mug-hot",
				"Tea": "fa-tea",
				"Salad": "fa-leaf",
				"Muffin": "fa-muffin",
				"Sandwich": "fa-sandwich",
				"Juice": "fa-bottle-droplet",
				"Soda": "fa-wine-bottle",
				"Water": "fa-bottle-water",
				"default": "fa-box"
			};
			function getProductIcon(productName) {
				switch (productName) {
					case "Coffee": return productIcons["Coffee"];
					case "Tea": return productIcons["Tea"];
					case "Salad": return productIcons["Salad"];
					case "Muffin": return productIcons["Muffin"];
					case "Sandwich": return productIcons["Sandwich"];
					case "Juice": return productIcons["Juice"];
					case "Soda": return productIcons["Soda"];
					case "Water": return productIcons["Water"];
					default: return productIcons["default"];
				}
			}
			function renderProducts(products) {
				const productListDiv = document.getElementById('product-list');
				productListDiv.innerHTML = '';
				products.forEach((product, index) => {
					const itemDiv = document.createElement('div');
					itemDiv.className = 'product-card';
					itemDiv.onclick = () => handleAddToCart(index);
					itemDiv.innerHTML =
						'<i class="fa-solid ' + getProductIcon(product.name) + ' icon"></i>' +
						'<span class="name">' + product.name + '</span>' +
						'<span class="price">$ ' + product.price.toFixed(2) + '</span>';
					productListDiv.appendChild(itemDiv);
				});
			}
			function renderCart(cart, total) {
				const cartItemsUl = document.getElementById('cart-items');
				cartItemsUl.innerHTML = '';
				cart.forEach((item, index) => {
					const li = document.createElement('li');
					li.className = 'cart-item';
					li.innerHTML =
						'<div class="cart-item-info">' +
						'    <span class="cart-item-name">' + item.name + '</span>' +
						'    <span class="cart-item-price">$ ' + item.price.toFixed(2) + '</span>' +
						'</div>' +
						'<button class="remove-btn" onclick="handleRemoveFromCart(' + index + ')"><i class="fa-solid fa-trash-can"></i></button>';
					cartItemsUl.appendChild(li);
				});
				document.getElementById('total-price').textContent = total.toFixed(2);
				// Auto-scroll to the bottom of the cart when items are added
				cartItemsUl.scrollTop = cartItemsUl.scrollHeight;
			}
			async function handleAddToCart(productIndex) {
				try { await window.addToCart(productIndex); }
				catch (e) { console.error('Error adding to cart:', e); }
			}
			async function handleRemoveFromCart(cartIndex) {
				try { await window.removeFromCart(cartIndex); }
				catch (e) { console.error('Error removing from cart:', e); }
			}
			async function handleCheckout() {
				try {
					await window.checkout();
					alert('Checkout successful! Thank you for your purchase.');
				} catch (e) { console.error('Error during checkout:', e); }
			}
			window.onload = async () => {
				try {
					const initialData = await window.getInitialData();
					renderProducts(initialData.products);
					renderCart(initialData.cart, initialData.total);
				} catch (e) { console.error('Error getting initial data:', e); }
			};
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)


# --- Ring Callback Handlers (Bound to JavaScript) ---

# Handles requests from JavaScript to get the initial product list and current cart state.
func handleGetInitialData(id, req)
	see "Ring: JavaScript requested initial data." + nl
	cJson = buildStateJSON() # Build the JSON string representing the current state.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson) # Return the JSON data.

# Handles requests from JavaScript to add a product to the cart.
func handleAddToCart(id, req)
	req = json_decode(req) # Parse the request data.
	nProductIndex = req[1] + 1 # Get the product index (adjust for 1-based indexing in Ring).
	if nProductIndex >= 1 and nProductIndex <= len(aProducts)
		add(aCart, aProducts[nProductIndex]) # Add the selected product to the cart.
		updateUI() # Update the UI to reflect changes in the cart.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""') # Acknowledge the call.

# Handles requests from JavaScript to remove a product from the cart.
func handleRemoveFromCart(id, req)
	req = json_decode(req)[1] # Parse the request data.
	nCartIndex = req[1] + 1 # Get the cart item index (adjust for 1-based indexing in Ring).
	if nCartIndex >= 1 and nCartIndex <= len(aCart)
		del(aCart, nCartIndex) # Delete the item from the cart.
		updateUI() # Update the UI to reflect changes in the cart.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""') # Acknowledge the call.

# Handles checkout requests from JavaScript.
func handleCheckout(id, req)
	if len(aCart) > 0
		aCart = [] # Clear the cart after checkout.
		updateUI() # Update the UI to show an empty cart.
	ok
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '""') # Acknowledge the call.

# --- Helper Functions ---

# Updates the UI in the webview by pushing the current cart and total.
func updateUI()
	see "Ring: Pushing cart update to UI." + nl
	cJson = buildStateJSON() # Rebuild the entire state JSON.
	# Construct JavaScript code to call `renderCart` with updated cart data and total.
	cJsCode = "renderCart(" + cJson + ".cart, " + cJson + ".total);"
	oWebView.evalJS(cJsCode) # Execute the JavaScript in the webview.

# Builds a JSON string representing the current state of products, cart, and total.
func buildStateJSON()
	# Prepare products list.
	aProductsList = []
	for aItem in aProducts
		aProductsList + [ :name = aItem[1], :price = aItem[2] ]
	next

	# Prepare cart list and calculate total.
	aCartList = []
	nTotal = 0.0
	for aItem in aCart
		cName = aItem[1]
		nPrice = aItem[2]
		nTotal += nPrice
		aCartList + [ :name = cName, :price = nPrice ]
	next

	# Build state as a Ring list.
	aState = [
		:products = aProductsList,
		:cart = aCartList,
		:total = nTotal
	]

	# Convert to JSON string.
	return json_encode(aState)
