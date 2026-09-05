# Weather App
# This example demonstrates a weather application that fetches weather data
# from the Open-Meteo API (free, no API key required) and displays current
# weather conditions and forecast information.

load "webview.ring"
load "simplejson.ring"
load "libcurl.ring"

# Global Variables
oWebView = NULL
# Open-Meteo APIs (free, no API key required)
cGeocodingAPI = "https://geocoding-api.open-meteo.com/v1/search?name={city}&count=1&language=en"
cForecastAPI = "https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,surface_pressure,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5&wind_speed_unit=ms"
aBindList = [
	["getWeather", :handleGetWeather],
	["getForecast", :handleGetForecast],
	["getLocation", :handleGetLocation]
]

# ==================================================
# Main Application Flow
# ==================================================

func main()
	see "Setting up Weather Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	oWebView {
		# Set title of the window.
		setTitle("Ring Weather App")

		# Set the window size (no size constraint).
		setSize(600, 750, WEBVIEW_HINT_NONE)

		# Load the HTML content for the weather app UI.
		loadWeatherHTML()

		# Run the webview's main event loop. This is a blocking call.
		run()
	}

# Defines the HTML structure and inline JavaScript for the weather app.
func loadWeatherHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Ring Weather App</title>
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
				font-family: "Inter", sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				margin: 0;
				height: 100vh;
				overflow: hidden;
				position: relative;
				display: flex;
				flex-direction: column;
				justify-content: center;
				align-items: center;
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

			.weather-container {
				background-color: var(--panel-bg);
				padding: 30px;
				border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3);
				width: 90%;
				max-width: 650px;
				display: flex;
				flex-direction: column;
				position: relative; z-index: 1;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				text-align: center;
				color: var(--accent-cyan);
				margin-bottom: 25px;
				font-size: 2em;
				text-shadow: 1px 1px 3px rgba(0,0,0,0.2);
			}
			.input-group {
				display: flex;
				margin-bottom: 20px;
			}
			input[type="text"] {
				flex-grow: 1;
				padding: 12px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				font-size: 1em;
				outline: none;
				background-color: rgba(255, 255, 255, 0.05);
				color: var(--text-primary);
			}
			input[type="text"]:focus {
				border-color: var(--accent-cyan);
			}
			button {
				padding: 12px 20px;
				border: none;
				border-radius: 8px;
				background-color: var(--accent-blue);
				color: white;
				font-size: 1em;
				cursor: pointer;
				margin-left: 10px;
				transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
			}
			button:hover {
				transform: translateY(-2px);
				box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
			}
			.weather-display {
				display: none;
				margin-top: 20px;
			}
			.current-weather {
				display: flex;
				align-items: center;
				justify-content: space-between;
				margin-bottom: 20px;
				padding: 15px;
				background-color: rgba(255, 255, 255, 0.05);
				border-radius: 10px;
			}
			.weather-main {
				display: flex;
				align-items: center;
			}
			.weather-icon {
				font-size: 3em;
				margin-right: 15px;
				color: var(--accent-yellow);
			}
			.weather-info h2 {
				margin: 0;
				font-size: 1.5em;
			}
			.weather-info p {
				margin: 5px 0;
				color: var(--text-secondary);
			}
			.temperature {
				font-size: 2.5em;
				font-weight: bold;
			}
			.weather-details {
				display: grid;
				grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
				gap: 15px;
				margin-bottom: 20px;
			}
			.detail-card {
				background-color: rgba(255, 255, 255, 0.05);
				padding: 15px;
				border-radius: 10px;
				text-align: center;
			}
			.detail-card i {
				font-size: 1.5em;
				margin-bottom: 10px;
				color: var(--accent-blue);
			}
			.detail-card h3 {
				margin: 0;
				font-size: 1.2em;
			}
			.detail-card p {
				margin: 5px 0 0;
				color: var(--text-secondary);
			}
			.forecast-container {
				margin-top: 20px;
			}
			.forecast-container h3 {
				margin-bottom: 15px;
				color: var(--accent-green);
			}
			.forecast-items {
				display: flex;
				overflow-x: auto;
				gap: 15px;
				padding-bottom: 10px;
			}
			.forecast-item {
				min-width: 120px;
				background-color: rgba(255, 255, 255, 0.05);
				padding: 15px;
				border-radius: 10px;
				text-align: center;
			}
			.forecast-item p {
				margin: 5px 0;
			}
			.forecast-item .forecast-time {
				font-weight: bold;
				color: var(--accent-green);
			}
			.forecast-item .forecast-temp {
				font-size: 1.2em;
			}
			.error-message {
				color: var(--accent-red);
				text-align: center;
				margin-top: 20px;
			}
			.loading {
				text-align: center;
				margin-top: 20px;
				color: var(--text-secondary);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		
		<div class="weather-container">
			<h1><i class="fa-solid fa-cloud-sun"></i> Weather App</h1>
			<div class="input-group">
				<input type="text" id="cityInput" placeholder="Enter city name (e.g., London, New York, Tokyo)" value="London">
				<button onclick="fetchWeatherData()"><i class="fa-solid fa-search"></i> Get Weather</button>
				<button onclick="fetchLocationAndWeather()"><i class="fa-solid fa-location-dot"></i> Use My Location</button>
			</div>
			
			<div id="loadingMessage" class="loading" style="display: none;">
				<i class="fa-solid fa-spinner fa-spin"></i> Loading weather data...
			</div>
			
			<div id="errorMessage" class="error-message"></div>
			
			<div id="weatherDisplay" class="weather-display">
				<div class="current-weather">
					<div class="weather-main">
						<div id="weatherIcon" class="weather-icon"><i class="fa-solid fa-sun"></i></div>
						<div class="weather-info">
							<h2 id="cityName">City</h2>
							<p id="weatherDescription">Description</p>
						</div>
					</div>
					<div id="temperature" class="temperature">--°C</div>
				</div>
				
				<div class="weather-details">
					<div class="detail-card">
						<i class="fa-solid fa-temperature-high"></i>
						<h3>Feels Like</h3>
						<p id="feelsLike">--°C</p>
					</div>
					<div class="detail-card">
						<i class="fa-solid fa-droplet"></i>
						<h3>Humidity</h3>
						<p id="humidity">--%</p>
					</div>
					<div class="detail-card">
						<i class="fa-solid fa-wind"></i>
						<h3>Wind Speed</h3>
						<p id="windSpeed">-- m/s</p>
					</div>
					<div class="detail-card">
						<i class="fa-solid fa-gauge"></i>
						<h3>Pressure</h3>
						<p id="pressure">-- hPa</p>
					</div>
				</div>
				
				<div class="forecast-container">
					<h3><i class="fa-solid fa-calendar-days"></i> 5-Day Forecast</h3>
					<div id="forecastItems" class="forecast-items">
						<!-- Forecast items will be added here -->
					</div>
				</div>
			</div>
		</div>

		<script>
			const cityInput = document.getElementById("cityInput");
			const loadingMessage = document.getElementById("loadingMessage");
			const errorMessage = document.getElementById("errorMessage");
			const weatherDisplay = document.getElementById("weatherDisplay");
			
			// Weather icon mapping
			const weatherIcons = {
				"01d": "fa-sun",
				"01n": "fa-moon",
				"02d": "fa-cloud-sun",
				"02n": "fa-cloud-moon",
				"03d": "fa-cloud",
				"03n": "fa-cloud",
				"04d": "fa-cloud",
				"04n": "fa-cloud",
				"09d": "fa-cloud-showers-heavy",
				"09n": "fa-cloud-showers-heavy",
				"10d": "fa-cloud-sun-rain",
				"10n": "fa-cloud-moon-rain",
				"11d": "fa-bolt",
				"11n": "fa-bolt",
				"13d": "fa-snowflake",
				"13n": "fa-snowflake",
				"50d": "fa-smog",
				"50n": "fa-smog"
			};
			
			function getWeatherIcon(iconCode) {
				return weatherIcons[iconCode] || "fa-question";
			}
			
			function formatTime(timestamp) {
				const date = new Date(timestamp * 1000);
				return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
			}
			
			function formatDate(dtTxt) {
				const date = new Date(dtTxt.replace(" ", "T"));
				return date.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" });
			}
			
			async function fetchWeatherData() {
				const city = cityInput.value.trim();
				if (!city) {
					showError("Please enter a city name.");
					return;
				}
				
				hideError();
				showLoading();
				hideWeatherDisplay();
				
				try {
					// Fetch current weather
					const weatherData = await window.getWeather(city);
					
					if (weatherData.error) {
						showError(weatherData.error);
						return;
					}
					
					// Fetch forecast
					const forecastData = await window.getForecast(city);
					
					if (forecastData.error) {
						showError(forecastData.error);
						return;
					}
					
					// Display weather data
					displayWeatherData(weatherData, forecastData);
				} catch (e) {
					console.error("Error fetching weather data:", e);
					showError("Failed to fetch weather data. Please try again.");
				} finally {
					hideLoading();
				}
			}
			
			function displayWeatherData(weatherData, forecastData) {
				// Display current weather
				document.getElementById("cityName").textContent = weatherData.name + ", " + weatherData.sys.country;
				document.getElementById("weatherDescription").textContent = weatherData.weather[0].description;
				document.getElementById("temperature").textContent = Math.round(weatherData.main.temp) + "°C";
				document.getElementById("feelsLike").textContent = Math.round(weatherData.main.feels_like) + "°C";
				document.getElementById("humidity").textContent = weatherData.main.humidity + "%";
				document.getElementById("windSpeed").textContent = weatherData.wind.speed + " m/s";
				document.getElementById("pressure").textContent = weatherData.main.pressure + " hPa";
				
				// Set weather icon
				const iconCode = weatherData.weather[0].icon;
				const iconClass = getWeatherIcon(iconCode);
				document.getElementById("weatherIcon").innerHTML = `<i class="fa-solid ${iconClass}"></i>`;
				
				// Display forecast
				const forecastItems = document.getElementById("forecastItems");
				forecastItems.innerHTML = "";
				
				// Get one forecast per day (at noon)
				const dailyForecasts = {};
				for (const item of forecastData.list) {
					const date = formatDate(item.dt_txt);
					if (!dailyForecasts[date] || item.dt_txt.includes("12:00:00")) {
						dailyForecasts[date] = item;
					}
				}
				
				// Display up to 5 days
				let count = 0;
				for (const date in dailyForecasts) {
					if (count >= 5) break;
					
					const forecast = dailyForecasts[date];
				 const iconCode = forecast.weather[0].icon;
					const iconClass = getWeatherIcon(iconCode);
					
					const forecastItem = document.createElement("div");
					forecastItem.className = "forecast-item";
					forecastItem.innerHTML = `
						<p class="forecast-time">${date}</p>
						<p><i class="fa-solid ${iconClass}"></i></p>
						<p class="forecast-temp">${Math.round(forecast.main.temp)}°C</p>
						<p>${forecast.weather[0].description}</p>
					`;
					
					forecastItems.appendChild(forecastItem);
					count++;
				}
				
				showWeatherDisplay();
			}
			
			function showLoading() {
				loadingMessage.style.display = "block";
			}
			
			function hideLoading() {
				loadingMessage.style.display = "none";
			}
			
			function showError(message) {
				errorMessage.textContent = message;
				errorMessage.style.display = "block";
			}
			
			function hideError() {
				errorMessage.style.display = "none";
			}
			
			function showWeatherDisplay() {
				weatherDisplay.style.display = "block";
			}
			
			function hideWeatherDisplay() {
				weatherDisplay.style.display = "none";
			}
			
			// Allow Enter key to trigger search
			cityInput.addEventListener("keypress", function(event) {
				if (event.key === "Enter") {
					fetchWeatherData();
				}
			});
			
			// Fetch weather for default city on page load
			window.onload = fetchLocationAndWeather;
			
			async function fetchLocationAndWeather() {
				showLoading();
				hideError();
				hideWeatherDisplay();
				
				try {
					// Get location from IP
					const loc = await window.getLocation();
					if (loc && loc.city) {
						cityInput.value = loc.city;
						fetchWeatherData();
					} else {
						// Fallback to default city
						fetchWeatherData();
					}
				} catch (e) {
					console.error("Error getting location:", e);
					// Fallback to default city
					fetchWeatherData();
				} finally {
					hideLoading();
				}
			}
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)

# Ring Callback Handlers (Bound to JavaScript)

# Handles requests from JavaScript to get current weather data.
func handleGetWeather(id, req)
	cCity = req[1]
	see "Ring: JavaScript requested weather for city: " + cCity + nl
	
	cResponse = NULL
	bError = false
	cErrorMessage = NULL
	
	try
		# Geocode the city name to coordinates, then fetch the current weather.
		aGeo = geocodeCity(cCity)
		if isNull(aGeo)
			bError = true
			cErrorMessage = "City not found: " + cCity
		else
			cURL = substr(cForecastAPI, "{lat}", string(aGeo[:latitude]))
			cURL = substr(cURL, "{lon}", string(aGeo[:longitude]))
			aData = json_decode(request(cURL))
			if isList(aData) and aData[:current]
				aCurrent = aData[:current]
				# Shape the Open-Meteo response like the frontend expects.
				aResult = [
					:name = aGeo[:name],
					:sys = [:country = aGeo[:country]],
					:weather = [wmoToWeather(aCurrent[:weather_code], aCurrent[:is_day])],
					:main = [
						:temp = aCurrent[:temperature_2m],
						:feels_like = aCurrent[:apparent_temperature],
						:humidity = aCurrent[:relative_humidity_2m],
						:pressure = aCurrent[:surface_pressure]
					],
					:wind = [:speed = aCurrent[:wind_speed_10m]]
				]
				oWebView.wreturn(id, WEBVIEW_ERROR_OK, aResult)
			else
				bError = true
				cErrorMessage = "Invalid API response format."
			ok
		ok
	catch
		bError = true
		cErrorMessage = "Network Error: " + cCatchError
		see "Error fetching weather data: " + cErrorMessage + nl
	end
		
	if bError
		# If an error occurred, return an error message
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, [:error = cErrorMessage])
	ok

# Handles requests from JavaScript to get weather forecast data.
func handleGetForecast(id, req)
	cCity = req[1]
	see "Ring: JavaScript requested forecast for city: " + cCity + nl
	
	cResponse = NULL
	bError = false
	cErrorMessage = NULL
	
	try
		# Geocode the city name to coordinates, then fetch the daily forecast.
		aGeo = geocodeCity(cCity)
		if isNull(aGeo)
			bError = true
			cErrorMessage = "City not found: " + cCity
		else
			cURL = substr(cForecastAPI, "{lat}", string(aGeo[:latitude]))
			cURL = substr(cURL, "{lon}", string(aGeo[:longitude]))
			aData = json_decode(request(cURL))
			if isList(aData) and aData[:daily] and aData[:daily][:time]
				aDaily = aData[:daily]
				aList = []
				for i = 1 to len(aDaily[:time])
					add(aList, [
						:dt_txt = aDaily[:time][i] + " 12:00:00",
						:main = [:temp = aDaily[:temperature_2m_max][i]],
						:weather = [wmoToWeather(aDaily[:weather_code][i], 1)]
					])
				next
				oWebView.wreturn(id, WEBVIEW_ERROR_OK, [
					:city = [:name = aGeo[:name]],
					:list = aList
				])
			else
				bError = true
				cErrorMessage = "Invalid API response format."
			ok
		ok
	catch
		bError = true
		cErrorMessage = "Network Error: " + cCatchError
		see "Error fetching forecast data: " + cErrorMessage + nl
	end
		
	if bError
		# If an error occurred, return an error message
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, [:error = cErrorMessage])
	ok

# Handles requests from JavaScript to get location using ip-api.com
func handleGetLocation(id, req)
	cUrl = "http://ip-api.com/json/"
	cResponse = NULL
	cCity = NULL
	cCountry = NULL
	try
		cResponse = request(cUrl)
		aJson = json_decode(cResponse)
		if isList(aJson)
			if isString(aJson[:city])
				cCity = aJson[:city]
			ok
			if isString(aJson[:country])
				cCountry = aJson[:country]
			ok
		ok
	catch
		cCity = NULL
		cCountry = NULL
	done
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, [:city = cCity, :country = cCountry])

# Geocodes a city name via the Open-Meteo geocoding API.
# Returns the first matching location as a list, or NULL if not found.
func geocodeCity(cCity)
	cURL = substr(cGeocodingAPI, "{city}", substr(cCity, " ", "%20"))
	aJson = json_decode(request(cURL))
	if isList(aJson) and aJson[:results] and len(aJson[:results]) > 0
		return aJson[:results][1]
	ok
	return NULL

# Maps a WMO weather code to a description and an OpenWeather-style icon code.
func wmoToWeather(nCode, nIsDay)
	cSuffix = "d"
	if nIsDay = 0
		cSuffix = "n"
	ok
	aMap = [
		[0, "clear sky", "01"],
		[1, "mainly clear", "01"],
		[2, "partly cloudy", "02"],
		[3, "overcast", "04"],
		[45, "fog", "50"],
		[48, "depositing rime fog", "50"],
		[51, "light drizzle", "09"],
		[53, "drizzle", "09"],
		[55, "dense drizzle", "09"],
		[56, "freezing drizzle", "09"],
		[57, "dense freezing drizzle", "09"],
		[61, "light rain", "10"],
		[63, "rain", "10"],
		[65, "heavy rain", "10"],
		[66, "freezing rain", "10"],
		[67, "heavy freezing rain", "10"],
		[71, "light snow", "13"],
		[73, "snow", "13"],
		[75, "heavy snow", "13"],
		[77, "snow grains", "13"],
		[80, "light rain showers", "09"],
		[81, "rain showers", "09"],
		[82, "violent rain showers", "09"],
		[85, "snow showers", "13"],
		[86, "heavy snow showers", "13"],
		[95, "thunderstorm", "11"],
		[96, "thunderstorm with hail", "11"],
		[99, "thunderstorm with heavy hail", "11"]
	]
	for aEntry in aMap
		if aEntry[1] = nCode
			return [:description = aEntry[2], :icon = aEntry[3] + cSuffix]
		ok
	next
	return [:description = "unknown", :icon = "03" + cSuffix]

# Function to make a HTTP request using libcurl
func request(url)
	curl = curl_easy_init()

	curl_easy_setopt(curl, CURLOPT_USERAGENT, "RingLibCurl")
	curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)
	curl_easy_setopt(curl, CURLOPT_URL, url)
	curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, false)
	
	cOutput = curl_easy_perform_silent(curl)

	curl_easy_cleanup(curl)

	return cOutput