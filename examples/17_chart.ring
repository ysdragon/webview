# Data Visualization with Chart.js
# This example demonstrates how to integrate a third-party JavaScript charting library (Chart.js)
# into a WebView application, with data provided dynamically from the Ring backend.

load "webview.ring"
load "jsonlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL

func main()
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Ring + Chart.js Data Visualization")
	# Set the window size (no size constraint).
	oWebView.setSize(900, 650, WEBVIEW_HINT_NONE)

	# Bind the `getSalesData` function to be callable from JavaScript.
	# This function will provide the data needed for the chart.
	oWebView.bind("getSalesData", :handleGetSalesData)

	# Load the HTML content that defines the chart UI.
	loadChartHTML()

	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Defines the HTML structure and inline JavaScript for the Chart.js integration.
func loadChartHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Sales Data</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<!-- Include Chart.js from a CDN -->
		<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap');
			body {
				font-family: 'Inter', sans-serif;
				background-color: #1e293b;
				color: #e2e8f0;
				display: flex;
				justify-content: center;
				align-items: center;
				height: 100vh;
				margin: 0;
				padding: 2em;
				box-sizing: border-box;
			}
			.chart-container {
				position: relative;
				width: 100%;
				max-width: 800px;
				background-color: #0f172a;
				padding: 2em;
				border-radius: 12px;
				box-shadow: 0 10px 25px rgba(0,0,0,0.3);
			}
		</style>
	</head>
	<body>
		<div class="chart-container">
			<canvas id="salesChart"></canvas>
		</div>

		<script>
			async function createChart() {
				try {
					// Request the data from the Ring backend
					const chartData = await window.getSalesData();

					const ctx = document.getElementById('salesChart').getContext('2d');
					
					new Chart(ctx, {
						type: 'bar',
						data: {
							labels: chartData.labels,
							datasets: chartData.datasets
						},
						options: {
							responsive: true,
							maintainAspectRatio: true,
							plugins: {
								legend: {
									position: 'top',
									labels: { color: '#e2e8f0', font: { size: 14 } }
								},
								title: {
									display: true,
									text: 'Quarterly Product Sales (Generated in Ring)',
									color: '#93c5fd',
									font: { size: 20, weight: 'bold' }
								}
							},
							scales: {
								y: {
									beginAtZero: true,
									ticks: { color: '#9ca3af' },
									grid: { color: 'rgba(255, 255, 255, 0.1)' }
								},
								x: {
									ticks: { color: '#9ca3af' },
									grid: { color: 'rgba(255, 255, 255, 0.1)' }
								}
							}
						}
					});

				} catch (e) {
					console.error("Failed to load chart data:", e);
					document.body.innerHTML = '<h1 style="color: #ef4444;">Error: Could not fetch chart data from Ring backend.</h1>';
				}
			}

			// Create the chart once the window loads
			window.onload = createChart;
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# Handles requests from JavaScript to get the sales data for charting.
func handleGetSalesData(id, req)
	see "Ring: JavaScript requested sales data." + nl
	
	# Generate the data structure in a format compatible with Chart.js.
	aChartData = buildChartData()
	
	# Convert the Ring list (array) to a JSON string.
	cJson = list2json(aChartData)
	
	# Return the JSON data to the JavaScript `await` call.
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson)

# --- Helper Functions ---

# Builds a structured list of sales data suitable for Chart.js.
func buildChartData()
	aLabels = ["Q1", "Q2", "Q3", "Q4"]
	
	# Define dataset for Product A.
	aDataset1 = [
		["label", "Product A (Units)"],
		["data", [120, 190, 150, 220]],
		["backgroundColor", "rgba(59, 130, 246, 0.5)"],
		["borderColor", "rgba(59, 130, 246, 1)"],
		["borderWidth", 1]
	]
	
	# Define dataset for Product B.
	aDataset2 = [
		["label", "Product B (Units)"],
		["data", [80, 90, 180, 160]],
		["backgroundColor", "rgba(239, 68, 68, 0.5)"],
		["borderColor", "rgba(239, 68, 68, 1)"],
		["borderWidth", 1]
	]
	
	aDatasets = [aDataset1, aDataset2] # Combine datasets.
	
	# Final data structure including labels and datasets.
	aFinalData = [
		["labels", aLabels],
		["datasets", aDatasets]
	]
	
	return aFinalData