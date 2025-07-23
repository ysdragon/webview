# Prayer Times Example

load "webview.ring"
load "jsonlib.ring"
load "internetlib.ring"

# Global variable to hold the WebView instance.
oWebView = NULL
# API endpoint for fetching prayer times by city and country.
cPrayerTimesAPI = "http://api.aladhan.com/v1/timingsByCity"

# ==================================================
# Main Application Flow
# ==================================================

func main()
	see "Setting up Prayer Times Application..." + nl
	# Create a new WebView instance.
	oWebView = new WebView()

	# Set the window title.
	oWebView.setTitle("Prayer Times")
	# Set the window size (no size constraint).
	oWebView.setSize(450, 700, WEBVIEW_HINT_NONE)

	# Bind Ring functions to be callable from JavaScript.
	oWebView.bind("getPrayerTimes", :handleGetPrayerTimes)

	# Load the HTML content for the prayer times UI.
	loadPrayerTimesHTML()
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()
	# Destroy the webview instance.
	oWebView.destroy()

# Defines the HTML structure.
func loadPrayerTimesHTML()
	cHTML = '<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
	<title>Ring Prayer Times</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
	<style>
		@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Tajawal:wght@400;500;700&display=swap");
		:root {
			--bg-gradient: linear-gradient(135deg, #0f2027 0%, #2c5364 100%);
			--card-bg: rgba(40, 44, 52, 0.85);
			--border-color: rgba(255, 255, 255, 0.08);
			--text-primary: #f8fafc;
			--text-secondary: #b3b3b3;
			--accent-green: #4ade80;
			--accent-blue: #3b82f6;
			--accent-purple: #c084fc;
			--accent-red: #f87171;
			--accent-cyan: #22d3ee;
		}
		body {
			font-family: "Tajawal", "Inter", sans-serif;
			background: var(--bg-gradient);
			color: var(--text-primary);
			margin: 0;
			height: 100vh;
			overflow: hidden;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			position: relative;
			padding: 1em;
			box-sizing: border-box;
			direction: rtl;
			text-align: right;
		}
		.background-container {
			position: fixed;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
			z-index: -1;
			overflow: hidden;
		}
		.aurora {
			position: relative;
			width: 100%;
			height: 100%;
			filter: blur(120px);
			opacity: 0.4;
		}
		.aurora-shape1 {
			position: absolute;
			width: 45vw;
			height: 45vh;
			background: radial-gradient(circle, #22d3ee 60%, transparent 100%);
			top: 8%;
			left: 8%;
		}
		.aurora-shape2 {
			position: absolute;
			width: 35vw;
			height: 35vh;
			background: radial-gradient(circle, #c084fc 60%, transparent 100%);
			bottom: 12%;
			right: 12%;
		}
		.prayer-times-container {
			background: var(--card-bg);
			padding: 2.2em 2em 2em 2em;
			border-radius: 18px;
			box-shadow: 0 10px 40px rgba(0,0,0,0.35);
			backdrop-filter: blur(16px);
			-webkit-backdrop-filter: blur(16px);
			border: 1.5px solid var(--border-color);
			position: relative;
			z-index: 1;
			width: calc(100% - 2em);
			max-width: 500px;
			text-align: right;
			display: flex;
			flex-direction: column;
			gap: 1.7em;
			flex-grow: 0;
			flex-shrink: 1;
			overflow-y: auto;
			max-height: calc(100vh - 2em);
			transition: box-shadow 0.2s;
		}
		.prayer-times-container:hover {
			box-shadow: 0 16px 60px rgba(0,0,0,0.45);
		}
		h1 {
			font-size: 2.2em;
			color: var(--text-primary);
			margin-bottom: 0.5em;
			text-shadow: 2px 2px 8px rgba(0,0,0,0.18);
			text-align: right;
			font-weight: 700;
			letter-spacing: 1px;
		}
		.location-display {
			font-size: 1.25em;
			color: var(--text-secondary);
			margin-bottom: 1em;
			text-align: right;
			font-weight: 500;
		}
		.prayer-list {
			list-style: none;
			padding: 0;
			margin: 0;
			flex-grow: 1;
			overflow-y: auto;
			scrollbar-width: thin;
			scrollbar-color: var(--accent-blue) var(--card-bg);
		}
		.prayer-list::-webkit-scrollbar {
			width: 8px;
			border-radius: 8px;
		}
		.prayer-list::-webkit-scrollbar-track {
			background: var(--card-bg);
			border-radius: 8px;
			border: 1.5px solid var(--border-color);
		}
		.prayer-list::-webkit-scrollbar-thumb {
			background: var(--accent-blue);
			border-radius: 8px;
			border: 2px solid var(--card-bg);
		}
		.prayer-item {
			display: flex;
			justify-content: space-between;
			align-items: center;
			padding: 1em 0;
			border-bottom: 1px dashed rgba(255,255,255,0.07);
			
			
			transition: background 0.2s;
		}
		.prayer-item:hover {
			background: rgba(59, 130, 246, 0.08);
		}
		.prayer-item:last-child {
			border-bottom: none;
		}
		.prayer-name {
			font-weight: 600;
			font-size: 1.15em;
			color: var(--text-primary);
			letter-spacing: 0.5px;
			text-align: left;
		}
		.prayer-time {
			font-family: "Fira Code", monospace;
			font-size: 1.15em;
			color: var(--accent-green);
			background: rgba(34, 211, 238, 0.08);
			padding: 0.2em 0.7em;
			text-align: right;
			border-radius: 6px;
			font-weight: 500;
		}
		.current-prayer .prayer-name,
		.current-prayer .prayer-time {
			color: var(--accent-cyan);
			font-weight: 700;
			background: rgba(34, 211, 238, 0.18);
		}
		.next-prayer .prayer-name,
		.next-prayer .prayer-time {
			color: var(--accent-purple);
			font-weight: 700;
			background: rgba(192, 132, 252, 0.18);
		}
		.next-prayer .prayer-time {
			display: flex;
			flex-direction: column;
			align-items: center;
		}
		.countdown {
			font-size: 0.8em;
			color: var(--text-secondary);
			margin-top: 0.2em;
			direction: rtl;
			text-align: center;
			width: 100%;
		}
		
		.input-group {
			display: flex;
			gap: 0.7em;
			margin-top: 1em;
			flex-shrink: 0;
			flex-direction: row-reverse;
		}
		.input-group input {
			flex-grow: 1;
			padding: 0.7em 1.1em;
			border-radius: 10px;
			border: 1.5px solid var(--border-color);
			background-color: rgba(255,255,255,0.07);
			color: var(--text-primary);
			font-size: 1em;
			outline: none;
			text-align: right;
			transition: border 0.2s;
		}
		.input-group input:focus {
			border-color: var(--accent-blue);
		}
		.input-group button {
			background: var(--accent-blue);
			color: white;
			border: none;
			border-radius: 10px;
			padding: 0.7em 1.2em;
			cursor: pointer;
			transition: background 0.2s, box-shadow 0.2s;
			flex-shrink: 0;
			font-weight: 600;
			box-shadow: 0 2px 8px rgba(59,130,246,0.12);
		}
		.input-group button:hover {
			background: #286090;
			box-shadow: 0 4px 16px rgba(59,130,246,0.18);
		}
		@media (max-width: 768px) {
			.prayer-times-container {
				max-width: 400px;
				padding: 1.5em;
				gap: 1em;
			}
			h1 {
				font-size: 1.8em;
			}
			.location-display {
				font-size: 1.1em;
			}
			.prayer-name, .prayer-time {
				font-size: 1em;
			}
		}
		@media (max-width: 480px) {
			.prayer-times-container {
				padding: 1em;
				gap: 0.8em;
				max-width: 100%;
			}
			h1 {
				font-size: 1.6em;
			}
			.location-display {
				font-size: 0.9em;
			}
			.prayer-name, .prayer-time {
				font-size: 0.9em;
			}
			.input-group {
				flex-direction: column-reverse;
				gap: 0.5em;
			}
			.input-group input, .input-group button {
				width: 100%;
				box-sizing: border-box;
				padding: 0.8em 1em;
				font-size: 0.9em;
			}
		}
	</style>
</head>
<body>
	<div class="background-container">
		<div class="aurora">
			<div class="aurora-shape1"></div>
			<div class="aurora-shape2"></div>
		</div>
	</div>
	<div class="prayer-times-container">
		<h1><i class="fa-solid fa-mosque"></i> مواقيت الصلاة</h1>
		<div class="location-display">
			<span id="current-city"></span>, <span id="current-country"></span>
			<i class="fa-solid fa-location-dot"></i>
		</div>
		<ul id="prayer-list" class="prayer-list">
			<!-- Prayer times will be rendered here by JavaScript -->
		</ul>
		<div class="input-group">
			<input type="text" id="city-input" placeholder="المدينة">
			<input type="text" id="country-input" placeholder="الدولة">
			<button onclick="fetchPrayerTimesByInput()"><i class="fa-solid fa-magnifying-glass"></i> بحث</button>
		</div>
	</div>

	<script>
		// Moved to top for definition before use
		async function fetchPrayerTimes(city, country) {
			try {
				const result = await window.getPrayerTimes(city, country);
				if (result && result.times) {
					renderPrayerTimes(result.times, result.city, result.country);
				} else if (result && result.error) {
					alert("Error: " + result.error);
				}
			} catch (e) {
				console.error("Error fetching prayer times:", e);
				alert("An error occurred while fetching prayer times.");
			}
		}

		// Moved to top for definition before use
		function fetchPrayerTimesByInput() {
			const city = document.getElementById("city-input").value || "Cairo";
			const country = document.getElementById("country-input").value || "Egypt";
			fetchPrayerTimes(city, country);
		}

		const prayerNames = {
			Fajr: "الفجر", Dhuhr: "الظهر", Asr: "العصر", Maghrib: "المغرب", Isha: "العشاء",
			Sunrise: "الشروق", Midnight: "منتصف الليل", Imsak: "الإمساك",
		};

		function escapeHTML(str) {
			const div = document.createElement("div");
			div.appendChild(document.createTextNode(str));
			return div.innerHTML;
		}

		function convertToArabicNumerals(numberString) {
			const arabicNumerals = "٠١٢٣٤٥٦٧٨٩";
			return String(numberString).replace(/\d/g, d => arabicNumerals[d]);
		}

		function formatTimeToArabic12Hour(time24) {
			const [hourStr, minuteStr] = time24.split(":");
			let hour = parseInt(hourStr, 10);
			const minute = parseInt(minuteStr, 10);

			const ampm = hour >= 12 ? "مساءً" : "صباحًا";
			hour = hour % 12;
			hour = hour === 0 ? 12 : hour; // Convert 0 to 12 for 12-hour format

			const formattedHour = hour.toString().padStart(2, "0");
			const formattedMinute = minute.toString().padStart(2, "0");

			return `${formattedHour}:${formattedMinute} ${ampm}`;
		}

		function localizePrayerName(name) {
			return escapeHTML(prayerNames[name] || name);
		}

		function getRemainingTime(targetTime) {
			const now = new Date();
			const target = new Date(now.toDateString() + " " + targetTime);
			let diff = target - now;

			if (diff < 0) { // If prayer time has passed, calculate for next day
				target.setDate(target.getDate() + 1);
				diff = target - now;
			}

			const hours = Math.floor(diff / (1000 * 60 * 60));
			const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
			const seconds = Math.floor((diff % (1000 * 60)) / 1000);

			const formattedHours = convertToArabicNumerals(String(hours).padStart(2, "0"));
			const formattedMinutes = convertToArabicNumerals(String(minutes).padStart(2, "0"));
			const formattedSeconds = convertToArabicNumerals(String(seconds).padStart(2, "0"));

			return `${formattedHours}:${formattedMinutes}:${formattedSeconds}`;
		}

		let countdownInterval;

		function renderPrayerTimes(times, city, country) {
			const prayerListUl = document.getElementById("prayer-list");
			prayerListUl.innerHTML = "";
			document.getElementById("current-city").textContent = city;
			document.getElementById("current-country").textContent = country;

			const now = new Date();
			let nextPrayerKey = null;
			let nextPrayerDate = null;

			const prayersToDisplay = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha", "Midnight", "Imsak"];
			const filteredTimes = {};
			for (const prayerName of prayersToDisplay) {
				if (times.hasOwnProperty(prayerName)) {
					filteredTimes[prayerName] = times[prayerName];
				}
			}

			// Find the next upcoming prayer
			for (const key of prayersToDisplay) {
				if (filteredTimes.hasOwnProperty(key)) {
					const prayerTimeDate = new Date(now.toDateString() + " " + filteredTimes[key]);
					if (prayerTimeDate > now && (nextPrayerDate === null || prayerTimeDate < nextPrayerDate)) {
						nextPrayerKey = key;
						nextPrayerDate = prayerTimeDate;
					}
				}
			}

			// If no next prayer for today, find the first prayer for tomorrow
			if (!nextPrayerKey) {
				const tomorrow = new Date(now);
				tomorrow.setDate(tomorrow.getDate() + 1);
				for (const key of prayersToDisplay) {
					if (filteredTimes.hasOwnProperty(key)) {
						const prayerTimeDate = new Date(tomorrow.toDateString() + " " + filteredTimes[key]);
						if (nextPrayerDate === null || prayerTimeDate < nextPrayerDate) {
							nextPrayerKey = key;
							nextPrayerDate = prayerTimeDate;
						}
					}
				}
			}
			
			for (const key of prayersToDisplay) {
				if (filteredTimes.hasOwnProperty(key)) {
					const time = filteredTimes[key];
					const li = document.createElement("li");
					li.className = "prayer-item";

					const displayTime = formatTimeToArabic12Hour(time);
					let prayerTimeHtml = `<span class="prayer-time">${convertToArabicNumerals(displayTime)}</span>`;

					if (key === nextPrayerKey) {
						li.classList.add("next-prayer");
						prayerTimeHtml = `<span class="prayer-time">
											<span>${convertToArabicNumerals(displayTime)}</span>
											<span class="countdown" id="countdown-${key}">متبقي: ${getRemainingTime(filteredTimes[key])}</span>
										</span>`;
					}

					li.innerHTML = `
							<span class="prayer-name">${localizePrayerName(key)}</span>
							${prayerTimeHtml}
						`;
					prayerListUl.appendChild(li);
				}
			}

			// Update countdown every second
			if (countdownInterval) {
				clearInterval(countdownInterval);
			}
			countdownInterval = setInterval(() => {
				if (nextPrayerKey) {
					const countdownElement = document.getElementById(`countdown-${nextPrayerKey}`);
					if (countdownElement) {
						countdownElement.textContent = `متبقي: ${getRemainingTime(times[nextPrayerKey])}`;
					} else {
						// If the element is no longer there, clear interval and re-render
						clearInterval(countdownInterval);
						fetchPrayerTimes(city, country); // Re-fetch to update times for next day/prayer
					}
				}
			}, 1000);
		}

		window.onload = () => {
			fetchPrayerTimes("القاهرة", "مصر");
		};
		
	</script>
</body>
</html>'
	
	oWebView.setHtml(cHTML)

# Handles requests from JavaScript to get prayer times for a specified city and country.
func handleGetPrayerTimes(id, req)
	cCity = "القاهرة"
	cCountry = "مصر"
	
	aReq = json2list(req)[1]
	cCity = aReq[1]
	if len(aReq) > 1
		cCountry = aReq[2]
	ok

	# Construct the API URL. Method 5 for Egyptian prayer times.
	cUrl = cPrayerTimesAPI + "?city=" + substr(cCity," ", "%20") + "&country=" + substr(cCountry," ", "%20") + "&method=5"
	
	see "Fetching prayer times from: " + cUrl + nl
	
	cResponse = ""
	try
		cResponse = download(cUrl)
	catch
		see "HTTP GET Error: " + ccatcherror + nl
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json([:error = "Failed to fetch data: " + ccatcherror]))
		return
	done
	
	aJson = json2list(cResponse)
	
	# Check if the API response indicates success (code 200) and contains timings data.
	if isList(aJson) and aJson["code"] = 200
		aTimings = aJson["data"]["timings"]

		aReturn = [
			:times = aTimings,
			:city = cCity,
			:country = cCountry
		]
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json(aReturn))
	else
		cErrorMsg = "Failed to get prayer times."
		if isList(aJson) and isString(aJson["status"])
			cErrorMsg += " Status: " + aJson["status"]
		ok
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json([:error = cErrorMsg]))
	ok