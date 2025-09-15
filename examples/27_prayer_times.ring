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
	oWebView.setSize(500, 700, WEBVIEW_HINT_NONE)

	# Bind Ring functions to be callable from JavaScript.
	oWebView.bind("getPrayerTimes", :handleGetPrayerTimes)
	oWebView.bind("getLocation", :handleGetLocation)

	# Load the HTML content for the prayer times UI.
	loadPrayerTimesHTML()
	
	# Run the webview's main event loop. This is a blocking call.
	oWebView.run()

# Defines the HTML structure.
func loadPrayerTimesHTML()
	cHTML = '<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
	<title>Ring Prayer Times</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
	<style>
		@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&family=Tajawal:wght@400;500;700&display=swap");
		:root {
			--bg-primary: #0f172a;
			--bg-secondary: #1e293b;
			--card-bg: rgba(15, 23, 42, 0.8);
			--card-border: rgba(148, 163, 184, 0.1);
			--text-primary: #f1f5f9;
			--text-secondary: #94a3b8;
			--text-muted: #64748b;
			--accent-primary: #3b82f6;
			--accent-secondary: #8b5cf6;
			--accent-success: #10b981;
			--accent-warning: #f59e0b;
			--accent-cyan: #06b6d4;
			--shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
			--blur-sm: 4px;
			--blur-md: 12px;
			--blur-lg: 16px;
		}
		html {
			background: var(--bg-primary);
		}
		body {
			font-family: "Tajawal", "Inter", sans-serif;
			background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
			color: var(--text-primary);
			margin: 0;
			padding: 0;
			height: 100vh;
			overflow: hidden;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			position: relative;
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
			width: 60vw;
			height: 60vh;
			background: radial-gradient(ellipse at center, rgba(59, 130, 246, 0.3) 0%, rgba(139, 92, 246, 0.2) 40%, transparent 70%);
			top: -10%;
			left: -15%;
			animation: aurora-drift 20s ease-in-out infinite;
		}
		.aurora-shape2 {
			position: absolute;
			width: 50vw;
			height: 50vh;
			background: radial-gradient(ellipse at center, rgba(6, 182, 212, 0.25) 0%, rgba(16, 185, 129, 0.15) 50%, transparent 70%);
			bottom: -10%;
			right: -15%;
			animation: aurora-drift 25s ease-in-out infinite reverse;
		}
		@keyframes aurora-drift {
			0%, 100% { transform: translate(0, 0) rotate(0deg) scale(1); }
			25% { transform: translate(10px, -15px) rotate(1deg) scale(1.05); }
			50% { transform: translate(-5px, 10px) rotate(-0.5deg) scale(0.95); }
			75% { transform: translate(-15px, -5px) rotate(0.5deg) scale(1.02); }
		}
		.prayer-times-container {
			background: var(--card-bg);
			padding: clamp(1.5rem, 4vw, 2.5rem);
			border-radius: 20px;
			box-shadow: var(--shadow-lg), 0 0 0 1px var(--card-border);
			backdrop-filter: blur(var(--blur-lg));
			-webkit-backdrop-filter: blur(var(--blur-lg));
			border: 1px solid var(--card-border);
			position: relative;
			z-index: 10;
			width: min(90vw, 28rem);
			height: min(85vh, 42rem);
			display: flex;
			flex-direction: column;
			gap: clamp(1rem, 3vw, 1.5rem);
			overflow: hidden;
			transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
		}
		.prayer-times-container:hover {
			transform: translateY(-2px);
			box-shadow: var(--shadow-lg), 0 25px 50px -12px rgba(0, 0, 0, 0.25);
		}
		h1 {
			font-size: clamp(1.5rem, 5vw, 2rem);
			color: var(--text-primary);
			margin: 0;
			text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
			text-align: center;
			font-weight: 700;
			letter-spacing: 0.5px;
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
			flex-shrink: 0;
		}
		.location-display {
			font-size: clamp(0.9rem, 2.5vw, 1.1rem);
			color: var(--text-secondary);
			text-align: center;
			font-weight: 500;
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
			flex-shrink: 0;
			padding: 0.75rem 1rem;
			background: rgba(148, 163, 184, 0.05);
			border-radius: 12px;
			border: 1px solid var(--card-border);
		}
		.prayer-list {
			list-style: none;
			padding: 0;
			margin: 0;
			flex: 1;
			overflow-y: auto;
			scrollbar-width: thin;
			scrollbar-color: var(--accent-primary) transparent;
			border-radius: 12px;
			background: rgba(148, 163, 184, 0.02);
			border: 1px solid var(--card-border);
			padding: 0.5rem;
		}
		.prayer-list::-webkit-scrollbar {
			width: 6px;
		}
		.prayer-list::-webkit-scrollbar-track {
			background: transparent;
		}
		.prayer-list::-webkit-scrollbar-thumb {
			background: var(--accent-primary);
			border-radius: 3px;
		}
		.prayer-item {
			display: flex;
			justify-content: space-between;
			align-items: center;
			padding: clamp(0.75rem, 2vw, 1rem);
			border-radius: 12px;
			margin-bottom: 0.5rem;
			background: rgba(148, 163, 184, 0.03);
			border: 1px solid var(--card-border);
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
			backdrop-filter: blur(var(--blur-sm));
		}
		.prayer-item:hover {
			background: rgba(59, 130, 246, 0.08);
			transform: translateY(-1px);
			box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
		}
		.prayer-item:last-child {
			margin-bottom: 0;
		}
		.prayer-name {
			font-weight: 600;
			font-size: clamp(1rem, 2.5vw, 1.1rem);
			color: var(--text-primary);
			letter-spacing: 0.3px;
			text-align: left;
		}
		.prayer-time {
			font-family: "Tajawal", "Fira Code", monospace;
			font-size: clamp(0.9rem, 2.5vw, 1rem);
			color: var(--accent-success);
			background: rgba(16, 185, 129, 0.1);
			padding: 0.5rem 0.75rem;
			text-align: center;
			border-radius: 8px;
			font-weight: 500;
			border: 1px solid rgba(16, 185, 129, 0.2);
			backdrop-filter: blur(var(--blur-sm));
		}
		.current-prayer .prayer-name,
		.current-prayer .prayer-time {
			color: var(--accent-cyan);
			font-weight: 700;
			background: rgba(6, 182, 212, 0.15);
			border-color: rgba(6, 182, 212, 0.3);
		}
		.next-prayer .prayer-name,
		.next-prayer .prayer-time {
			color: var(--accent-secondary);
			font-weight: 700;
			background: rgba(139, 92, 246, 0.15);
			border-color: rgba(139, 92, 246, 0.3);
			box-shadow: 0 0 20px rgba(139, 92, 246, 0.2);
		}
		.next-prayer .prayer-time {
			display: flex;
			flex-direction: column;
			align-items: center;
		}
		.countdown {
			font-size: clamp(0.85rem, 2.5vw, 1rem);
			color: var(--text-muted);
			margin-top: 0.25rem;
			direction: rtl;
			text-align: center;
			width: 100%;
			font-weight: 400;
			font-family: "Tajawal", "Fira Code", monospace;
		}
		
		.input-group {
			display: flex;
			gap: 0.75rem;
			flex-shrink: 0;
			flex-direction: row-reverse;
			padding: 0.5rem;
			background: rgba(148, 163, 184, 0.03);
			border-radius: 12px;
			border: 1px solid var(--card-border);
			max-width: 100%;
			width: 100%;
			box-sizing: border-box;
		}
		.input-group input {
			flex: 1 1 auto;
			min-width: 0;
			max-width: 40%;
			padding: clamp(0.6rem, 2vw, 0.75rem) clamp(0.9rem, 3vw, 1.1rem);
			border-radius: 10px;
			border: 1px solid var(--card-border);
			background: rgba(148, 163, 184, 0.05);
			color: var(--text-primary);
			font-size: clamp(0.9rem, 2.5vw, 1rem);
			outline: none;
			text-align: right;
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
			backdrop-filter: blur(var(--blur-sm));
			box-sizing: border-box;
			font-family: "Tajawal", sans-serif;
		}
		.input-group input:focus {
			border-color: var(--accent-primary);
			box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
			background: rgba(59, 130, 246, 0.05);
		}
		.input-group button {
			background: linear-gradient(135deg, var(--accent-primary), var(--accent-secondary));
			color: white;
			border: none;
			border-radius: 10px;
			padding: clamp(0.6rem, 2vw, 0.75rem) clamp(1rem, 3vw, 1.2rem);
			cursor: pointer;
			transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
			flex-shrink: 0;
			font-weight: 600;
			font-size: clamp(0.9rem, 2.5vw, 1rem);
			box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
			backdrop-filter: blur(var(--blur-sm));
			border: 1px solid rgba(255, 255, 255, 0.1);
			white-space: nowrap;
			min-width: fit-content;
			font-family: "Tajawal", sans-serif;
		}
		.input-group button:hover {
			transform: translateY(-2px);
			box-shadow: 0 8px 20px rgba(59, 130, 246, 0.4);
		}
		.input-group button:active {
			transform: translateY(0);
		}
		.loading-spinner {
			position: absolute;
			top: 50%;
			left: 50%;
			transform: translate(-50%, -50%);
			width: 40px;
			height: 40px;
			border: 3px solid rgba(59, 130, 246, 0.2);
			border-top: 3px solid var(--accent-primary);
			border-radius: 50%;
			animation: spin 1s linear infinite;
			z-index: 1000;
			opacity: 0;
			visibility: hidden;
			transition: all 0.3s ease;
		}
		.loading-spinner.show {
			opacity: 1;
			visibility: visible;
		}
		@keyframes spin {
			0% { transform: translate(-50%, -50%) rotate(0deg); }
			100% { transform: translate(-50%, -50%) rotate(360deg); }
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
		<div id="loading-spinner" class="loading-spinner"></div>
	</div>

	<script>
		async function fetchPrayerTimes(city, country) {
			showLoadingSpinner();
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
			} finally {
				hideLoadingSpinner();
			}
		}

		function fetchPrayerTimesByInput() {
			const city = document.getElementById("city-input").value || "Cairo";
			const country = document.getElementById("country-input").value || "Egypt";
			fetchPrayerTimes(city, country);
		}

		async function fetchLocationAndPrayerTimes() {
			showLoadingSpinner();
			try {
				const loc = await window.getLocation();
				if (loc && loc.city && loc.country) {
					document.getElementById("city-input").value = loc.city;
					document.getElementById("country-input").value = loc.country;
					fetchPrayerTimes(loc.city, loc.country);
				} else {
					fetchPrayerTimes("Cairo", "Egypt");
				}
			} catch (e) {
				fetchPrayerTimes("Cairo", "Egypt");
			}
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
			hour = hour === 0 ? 12 : hour;

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

			// If prayer time has passed, calculate for next day
			if (diff < 0) {
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

			for (const key of prayersToDisplay) {
				if (filteredTimes.hasOwnProperty(key)) {
					const prayerTimeDate = new Date(now.toDateString() + " " + filteredTimes[key]);
					if (prayerTimeDate > now && (nextPrayerDate === null || prayerTimeDate < nextPrayerDate)) {
						nextPrayerKey = key;
						nextPrayerDate = prayerTimeDate;
					}
				}
			}

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
			
			let nextPrayerElement = null;
			for (const key of prayersToDisplay) {
				if (filteredTimes.hasOwnProperty(key)) {
					const time = filteredTimes[key];
					const li = document.createElement("li");
					li.className = "prayer-item";
					li.id = `prayer-${key}`;

					const displayTime = formatTimeToArabic12Hour(time);
					let prayerTimeHtml = `<span class="prayer-time">${convertToArabicNumerals(displayTime)}</span>`;

					if (key === nextPrayerKey) {
						li.classList.add("next-prayer");
						nextPrayerElement = li;
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

			if (nextPrayerElement) {
				setTimeout(() => {
					nextPrayerElement.scrollIntoView({
						behavior: "smooth",
						block: "center"
					});
				}, 100);
			}

			if (countdownInterval) {
				clearInterval(countdownInterval);
			}
			countdownInterval = setInterval(() => {
				if (nextPrayerKey) {
					const countdownElement = document.getElementById(`countdown-${nextPrayerKey}`);
					if (countdownElement) {
						countdownElement.textContent = `متبقي: ${getRemainingTime(times[nextPrayerKey])}`;
					} else {
						clearInterval(countdownInterval);
						fetchPrayerTimes(city, country);
					}
				}
			}, 1000);
		}

		window.onload = () => {
			fetchLocationAndPrayerTimes();
		};
		
		function showLoadingSpinner() {
			const spinner = document.getElementById("loading-spinner");
			spinner.classList.add("show");
		}

		function hideLoadingSpinner() {
			const spinner = document.getElementById("loading-spinner");
			spinner.classList.remove("show");
		}
		
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

	# Select calculation method based on country
	aMethodList = getCalculationMethods()
	nMethod = 3
	for item in aMethodList
		if lower(item[:country]) = lower(cCountry)
			nMethod = item[:method]
			exit
		ok
	next

	# Construct the API URL with the selected method.
	cUrl = cPrayerTimesAPI + "?city=" + substr(cCity," ", "%20") + "&country=" + substr(cCountry," ", "%20") + "&method=" + nMethod
	
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

# Handles requests from JavaScript to get location using ip-api.com
func handleGetLocation(id, req)
	cUrl = "http://ip-api.com/json/"
	cResponse = ""
	cCity = ""
	cCountry = ""
	try
		cResponse = download(cUrl)
		aJson = json2list(cResponse)
		if isList(aJson)
			if isString(aJson["city"])
				cCity = aJson["city"]
			ok
			if isString(aJson["country"])
				cCountry = aJson["country"]
			ok
		ok
	catch
		cCity = ""
		cCountry = ""
	done
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, list2json([:city = cCity, :country = cCountry]))


func getCalculationMethods()
	return [
		[:country = "Egypt", :method = 5], [:country = "مصر", :method = 5],
		[:country = "Saudi Arabia", :method = 4], [:country = "السعودية", :method = 4],
		[:country = "Turkey", :method = 13], [:country = "تركيا", :method = 13],
		[:country = "Morocco", :method = 21], [:country = "المغرب", :method = 21],
		[:country = "Algeria", :method = 19], [:country = "الجزائر", :method = 19],
		[:country = "Tunisia", :method = 18], [:country = "تونس", :method = 18],
		[:country = "UAE", :method = 16], [:country = "الإمارات", :method = 16],
		[:country = "Kuwait", :method = 9], [:country = "الكويت", :method = 9],
		[:country = "Qatar", :method = 10], [:country = "قطر", :method = 10],
		[:country = "Jordan", :method = 23], [:country = "الأردن", :method = 23],
		[:country = "Singapore", :method = 11], [:country = "سنغافورة", :method = 11],
		[:country = "France", :method = 12], [:country = "فرنسا", :method = 12],
		[:country = "Russia", :method = 14], [:country = "روسيا", :method = 14],
		[:country = "Malaysia", :method = 17], [:country = "ماليزيا", :method = 17],
		[:country = "Indonesia", :method = 20], [:country = "إندونيسيا", :method = 20],
		[:country = "USA", :method = 2], [:country = "United States", :method = 2], [:country = "أمريكا", :method = 2],
		[:country = "UK", :method = 3], [:country = "United Kingdom", :method = 3], [:country = "بريطانيا", :method = 3],
		[:country = "Pakistan", :method = 1], [:country = "باكستان", :method = 1],
		[:country = "Iran", :method = 7], [:country = "إيران", :method = 7],
		[:country = "Portugal", :method = 22], [:country = "البرتغال", :method = 22],
		[:country = "Worldwide", :method = 15], [:country = "العالم", :method = 15]
	]