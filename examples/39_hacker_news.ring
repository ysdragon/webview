# Hacker News Reader
# This example demonstrates a Hacker News reader that fetches stories
# from the HN Algolia API and displays them in a clean interface.

load "webview.ring"
load "simplejson.ring"
load "libcurl.ring"
load "threads.ring"

# Global Variables
oWebView = NULL
aBindList = [
	["fetchStories", :handleFetchStories],
	["searchStories", :handleSearchStories],
	["getItem", :handleGetItem]
]
cBaseAPI = "https://hn.algolia.com/api/v1/"

func main()
	? "Starting Hacker News Reader..."
	oWebView = new WebView()

	oWebView {
		setTitle("Hacker News Reader")
		setSize(900, 700, WEBVIEW_HINT_NONE)
		loadHNHTML()
		run()
	}

# Ring Callback Handlers

# Fetch stories by type (front_page, story, show_hn, ask_hn)
func handleFetchStories(id, req)
	aParams = json_decode(req)
	cType = aParams[1]
	nPage = aParams[2]
		
	cURL = ""
	if cType = "front_page"
		cURL = cBaseAPI + "search_by_date?tags=front_page&page=" + nPage
	else
		cURL = cBaseAPI + "search_by_date?tags=" + cType + "&page=" + nPage
	ok
	
	fetchAndReturn(id, cURL)

# Search stories by query
func handleSearchStories(id, req)
	aParams = json_decode(req)
	cQuery = aParams[1]
	nPage = aParams[2]
		
	cURL = cBaseAPI + "search?query=" + urlencode(cQuery) + "&tags=story&page=" + nPage
	
	fetchAndReturn(id, cURL)

# Get item details (for comments)
func handleGetItem(id, req)
	aParams = json_decode(req)
	cItemId = string(aParams[1])
		
	cURL = cBaseAPI + "items/" + cItemId
	
	fetchAndReturn(id, cURL)

# Helper function to start threaded fetch
func fetchAndReturn(id, cURL)
	oFetchThread = new_thrd_t()
	thrd_create(oFetchThread, "fetchWorkerThread('" + id + "', '" + cURL + "')")
	thrd_detach(oFetchThread)

# Worker thread function
func fetchWorkerThread(id, cURL)
	cResponse = NULL
	bError = false
	cErrorMessage = ""
	
	try
		cResponse = request(cURL)
		aJson = json_decode(cResponse)
		
		if isList(aJson)
			cJsonResult = json_encode(aJson)
			oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResult)
		else
			bError = true
			cErrorMessage = "Invalid API response"
		ok
	catch
		bError = true
		cErrorMessage = "Network Error: " + cCatchError
		? "Error: " + cErrorMessage
	end
	
	if bError
		oWebView.wreturn(id, WEBVIEW_ERROR_OK, json_encode([:error = cErrorMessage]))
	ok

# URL encode helper
func urlencode(cStr)
	cResult = ""
	for i = 1 to len(cStr)
		c = cStr[i]
		if isalnum(c) or c = "-" or c = "_" or c = "." or c = "~"
			cResult += c
		else
			cResult += "%" + upper(hex(ascii(c)))
		ok
	next
	return cResult

# HTTP request using RingLibCurl
func request(url)
	curl = curl_easy_init()
	curl_easy_setopt(curl, CURLOPT_USERAGENT, "RingLibCurl")
	curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)
	curl_easy_setopt(curl, CURLOPT_URL, url)
	
	if isWindows()
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, false)
	ok

	cOutput = curl_easy_perform_silent(curl)
	curl_easy_cleanup(curl)
	return cOutput

# HTML Content

# Defines the HTML structure and inline JavaScript for the HN reader
func loadHNHTML()
	cHTML = '
	<!DOCTYPE html>
	<html>
	<head>
		<title>Hacker News Reader</title>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/7.0.0/css/all.min.css">
		<style>
			:root {
				--bg-color: #0f0f0f;
				--panel-bg: rgba(30, 30, 32, 0.8);
				--border-color: rgba(255, 255, 255, 0.1);
				--text-primary: #f8fafc;
				--text-secondary: #a1a1aa;
				--accent-orange: #ff6600;
				--accent-blue: #3b82f6;
				--accent-cyan: #22d3ee;
				--accent-green: #4ade80;
				--accent-red: #f87171;
			}
			* { box-sizing: border-box; }
			::-webkit-scrollbar {
				width: 10px;
				height: 10px;
			}
			::-webkit-scrollbar-track {
				background: var(--bg-color);
				border-radius: 5px;
			}
			::-webkit-scrollbar-thumb {
				background: linear-gradient(180deg, var(--accent-orange), #cc5200);
				border-radius: 5px;
				border: 2px solid var(--bg-color);
			}
			::-webkit-scrollbar-thumb:hover {
				background: linear-gradient(180deg, #ff8533, var(--accent-orange));
			}
			::-webkit-scrollbar-corner {
				background: var(--bg-color);
			}
			body {
				font-family: "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
				background-color: var(--bg-color);
				color: var(--text-primary);
				margin: 0;
				min-height: 100vh;
				position: relative;
			}
			.background-container {
				position: fixed; top: 0; left: 0; width: 100%; height: 100%;
				z-index: -1; overflow: hidden;
			}
			.aurora {
				position: relative; width: 100%; height: 100%;
				filter: blur(150px); opacity: 0.4;
			}
			.aurora-shape1 {
				position: absolute; width: 50vw; height: 50vh;
				background: radial-gradient(circle, var(--accent-orange), transparent 60%);
				top: 5%; left: 5%;
			}
			.aurora-shape2 {
				position: absolute; width: 40vw; height: 40vh;
				background: radial-gradient(circle, var(--accent-cyan), transparent 60%);
				bottom: 10%; right: 10%;
			}

			.container {
				max-width: 900px;
				margin: 0 auto;
				padding: 20px;
			}
			header {
				background-color: var(--accent-orange);
				padding: 15px 20px;
				display: flex;
				align-items: center;
				justify-content: space-between;
				flex-wrap: wrap;
				gap: 15px;
			}
			.logo {
				display: flex;
				align-items: center;
				gap: 10px;
				color: white;
				font-weight: bold;
				font-size: 1.3em;
			}
			.logo i { font-size: 1.5em; }
			
			.search-box {
				display: flex;
				gap: 10px;
				flex: 1;
				max-width: 400px;
			}
			.search-box input {
				flex: 1;
				padding: 10px 15px;
				border: none;
				border-radius: 6px;
				font-size: 0.95em;
				background: rgba(255,255,255,0.9);
				color: #333;
			}
			.search-box input:focus { outline: none; }
			.search-box button {
				padding: 10px 20px;
				border: none;
				border-radius: 6px;
				background: rgba(0,0,0,0.3);
				color: white;
				cursor: pointer;
				font-size: 0.95em;
				transition: background 0.2s;
			}
			.search-box button:hover { background: rgba(0,0,0,0.5); }

			.tabs {
				display: flex;
				gap: 5px;
				padding: 15px 0;
				border-bottom: 1px solid var(--border-color);
				flex-wrap: wrap;
			}
			.tab-btn {
				padding: 10px 20px;
				border: 1px solid var(--border-color);
				border-radius: 8px;
				background: var(--panel-bg);
				color: var(--text-secondary);
				cursor: pointer;
				font-size: 0.9em;
				transition: all 0.2s;
			}
			.tab-btn:hover {
				border-color: var(--accent-orange);
				color: var(--text-primary);
			}
			.tab-btn.active {
				background: var(--accent-orange);
				border-color: var(--accent-orange);
				color: white;
			}

			.stories-list {
				margin-top: 20px;
			}
			.story-item {
				background: var(--panel-bg);
				border: 1px solid var(--border-color);
				border-radius: 10px;
				padding: 15px 20px;
				margin-bottom: 12px;
				transition: all 0.2s;
				backdrop-filter: blur(10px);
			}
			.story-item:hover {
				border-color: var(--accent-orange);
				transform: translateY(-2px);
			}
			.story-title {
				font-size: 1.1em;
				margin-bottom: 8px;
				display: flex;
				align-items: center;
				gap: 10px;
			}
			.story-title a {
				color: var(--text-primary);
				text-decoration: none;
			}
			.story-title a:hover { color: var(--accent-orange); }
			.story-title .external-link {
				color: var(--text-secondary);
				font-size: 0.8em;
			}
			.story-title .external-link:hover { color: var(--accent-cyan); }
			.story-url {
				font-size: 0.85em;
				color: var(--text-secondary);
				margin-bottom: 8px;
			}
			.story-meta {
				display: flex;
				gap: 20px;
				font-size: 0.85em;
				color: var(--text-secondary);
				flex-wrap: wrap;
			}
			.story-meta span { display: flex; align-items: center; gap: 5px; }
			.story-meta .points { color: var(--accent-orange); }
			.story-meta .comments { color: var(--accent-cyan); cursor: pointer; }
			.story-meta .comments:hover { text-decoration: underline; }

			.loading {
				display: flex;
				flex-direction: column;
				align-items: center;
				justify-content: center;
				padding: 60px 40px;
				color: var(--text-secondary);
				gap: 15px;
			}
			.loading i { 
				font-size: 2.5em; 
				color: var(--accent-orange);
				animation: spin 1s linear infinite;
			}
			.loading span {
				font-size: 1em;
			}
			@keyframes spin {
				0% { transform: rotate(0deg); }
				100% { transform: rotate(360deg); }
			}

			.error-message {
				text-align: center;
				padding: 40px;
				color: var(--accent-red);
			}

			.pagination {
				display: flex;
				justify-content: center;
				gap: 10px;
				padding: 20px 0;
			}
			.pagination button {
				padding: 10px 20px;
				border: 1px solid var(--border-color);
				border-radius: 6px;
				background: var(--panel-bg);
				color: var(--text-primary);
				cursor: pointer;
				transition: all 0.2s;
			}
			.pagination button:hover:not(:disabled) {
				border-color: var(--accent-orange);
			}
			.pagination button:disabled {
				opacity: 0.5;
				cursor: not-allowed;
			}
			.pagination .page-info {
				display: flex;
				align-items: center;
				gap: 6px;
				color: var(--text-secondary);
				font-size: 0.95em;
				padding: 0 10px;
			}
			.pagination .page-info span {
				color: var(--accent-orange);
				font-weight: 600;
			}

			.modal {
				display: none;
				position: fixed;
				top: 0; left: 0;
				width: 100%; height: 100%;
				background: rgba(0,0,0,0.8);
				z-index: 1000;
				overflow-y: auto;
			}
			.modal.show { display: block; }
			.modal-content {
				background: var(--panel-bg);
				max-width: 700px;
				margin: 50px auto;
				border-radius: 15px;
				border: 1px solid var(--border-color);
				backdrop-filter: blur(15px);
				overflow: hidden;
			}
			.modal-header {
				background: var(--accent-orange);
				padding: 15px 20px;
				display: flex;
				justify-content: space-between;
				align-items: center;
			}
			.modal-header h2 {
				margin: 0;
				font-size: 1.1em;
				color: white;
			}
			.modal-close {
				background: none;
				border: none;
				color: white;
				font-size: 1.5em;
				cursor: pointer;
			}
			.modal-body {
				padding: 20px;
				max-height: 70vh;
				overflow-y: auto;
			}
			.comment {
				border-left: 3px solid var(--accent-orange);
				padding-left: 15px;
				margin-bottom: 15px;
			}
			.comment-meta {
				font-size: 0.85em;
				color: var(--text-secondary);
				margin-bottom: 8px;
			}
			.comment-text {
				font-size: 0.95em;
				line-height: 1.6;
			}
			.comment-text a { color: var(--accent-cyan); }
			.nested-comments {
				margin-left: 20px;
				margin-top: 15px;
			}
			.post-content {
				margin-bottom: 20px;
				padding-bottom: 20px;
				border-bottom: 1px solid var(--border-color);
			}
			.post-meta {
				display: flex;
				gap: 20px;
				font-size: 0.9em;
				color: var(--text-secondary);
				margin-bottom: 15px;
				flex-wrap: wrap;
			}
			.post-meta span {
				display: flex;
				align-items: center;
				gap: 5px;
			}
			.post-url {
				margin-bottom: 15px;
				word-break: break-all;
			}
			.post-url a {
				color: var(--accent-cyan);
				text-decoration: none;
				font-size: 0.9em;
			}
			.post-url a:hover { text-decoration: underline; }
			.post-text {
				background: rgba(0,0,0,0.2);
				padding: 15px;
				border-radius: 8px;
				line-height: 1.7;
				font-size: 0.95em;
			}
			.post-text a { color: var(--accent-cyan); }
			.comments-section h3 {
				color: var(--accent-orange);
				font-size: 1em;
				margin-bottom: 15px;
				display: flex;
				align-items: center;
				gap: 8px;
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>

		<header>
			<div class="logo">
				<i class="fa-brands fa-y-combinator"></i>
				Hacker News Reader
			</div>
			<div class="search-box">
				<input type="text" id="searchInput" placeholder="Search stories...">
				<button onclick="doSearch()"><i class="fa-solid fa-search"></i></button>
			</div>
		</header>

		<div class="container">
			<div class="tabs">
				<button class="tab-btn active" data-type="front_page" onclick="switchTab(this)">
					<i class="fa-solid fa-fire"></i> Front Page
				</button>
				<button class="tab-btn" data-type="story" onclick="switchTab(this)">
					<i class="fa-solid fa-newspaper"></i> Latest
				</button>
				<button class="tab-btn" data-type="show_hn" onclick="switchTab(this)">
					<i class="fa-solid fa-lightbulb"></i> Show HN
				</button>
				<button class="tab-btn" data-type="ask_hn" onclick="switchTab(this)">
					<i class="fa-solid fa-circle-question"></i> Ask HN
				</button>
			</div>

			<div id="storiesList" class="stories-list"></div>

			<div id="pagination" class="pagination" style="display: none;">
				<button onclick="prevPage()" id="prevBtn"><i class="fa-solid fa-chevron-left"></i> Previous</button>
				<span class="page-info">Page <span id="currentPage">1</span> of <span id="totalPages">1</span></span>
				<button onclick="nextPage()" id="nextBtn">Next <i class="fa-solid fa-chevron-right"></i></button>
			</div>
		</div>

		<!-- Comments Modal -->
		<div id="commentsModal" class="modal">
			<div class="modal-content">
				<div class="modal-header">
					<h2 id="modalTitle">Comments</h2>
					<button class="modal-close" onclick="closeModal()">&times;</button>
				</div>
				<div id="modalBody" class="modal-body"></div>
			</div>
		</div>

		<script>
			let currentType = "front_page";
			let currentPage = 0;
			let totalPages = 1;
			let isSearchMode = false;
			let searchQuery = "";

			function switchTab(btn) {
				document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));
				btn.classList.add("active");
				currentType = btn.dataset.type;
				currentPage = 0;
				isSearchMode = false;
				document.getElementById("searchInput").value = "";
				loadStories();
			}

			async function loadStories() {
				const storiesList = document.getElementById("storiesList");
				document.getElementById("pagination").style.display = "none";
				storiesList.innerHTML = `<div class="loading"><i class="fa-solid fa-spinner"></i><span>Loading stories...</span></div>`;

				try {
					const result = await window.fetchStories(currentType, currentPage);
					if (!result || result.error) {
						storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> ${result?.error || "Failed to load stories"}</div>`;
						return;
					}
					displayStories(result);
				} catch (e) {
					console.error("Error:", e);
					storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> Failed to load stories</div>`;
				}
			}

			async function doSearch() {
				const query = document.getElementById("searchInput").value.trim();
				if (!query) return;

				searchQuery = query;
				isSearchMode = true;
				currentPage = 0;

				document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));

				const storiesList = document.getElementById("storiesList");
				document.getElementById("pagination").style.display = "none";
				storiesList.innerHTML = `<div class="loading"><i class="fa-solid fa-spinner"></i><span>Searching...</span></div>`;

				try {
					const result = await window.searchStories(query, currentPage);
					if (!result || result.error) {
						storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> ${result?.error || "Search failed"}</div>`;
						return;
					}
					displayStories(result);
				} catch (e) {
					console.error("Error:", e);
					storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> Search failed</div>`;
				}
			}

			function displayStories(data) {
				const storiesList = document.getElementById("storiesList");
				const hits = data.hits || [];
				totalPages = data.nbPages || 1;

				if (hits.length === 0) {
					storiesList.innerHTML = `<div class="error-message">No stories found</div>`;
					document.getElementById("pagination").style.display = "none";
					return;
				}

				let html = "";
				hits.forEach((story, index) => {
					const url = story.url || (story.objectID ? `https://news.ycombinator.com/item?id=${story.objectID}` : "#");
					const domain = story.url ? new URL(story.url).hostname.replace("www.", "") : "news.ycombinator.com";
					const title = story.title || story.story_title || "Untitled";
					const points = story.points || 0;
					const author = story.author || "unknown";
					const numComments = story.num_comments || 0;
					const createdAt = story.created_at ? timeAgo(new Date(story.created_at)) : "";

					html += `
						<div class="story-item">
							<div class="story-title">
								<a href="javascript:void(0)" onclick="openPost(${story.objectID})">${escapeHtml(title)}</a>
								${story.url ? `<a href="${url}" target="_blank" class="external-link" title="Open external link"><i class="fa-solid fa-arrow-up-right-from-square"></i></a>` : ""}
							</div>
							<div class="story-url">${domain}</div>
							<div class="story-meta">
								<span class="points"><i class="fa-solid fa-arrow-up"></i> ${points} points</span>
								<span><i class="fa-solid fa-user"></i> ${escapeHtml(author)}</span>
								<span><i class="fa-solid fa-clock"></i> ${createdAt}</span>
								<span class="comments" onclick="openComments(${story.objectID})">
									<i class="fa-solid fa-comment"></i> ${numComments} comments
								</span>
							</div>
						</div>
					`;
				});

				storiesList.innerHTML = html;

				// Update pagination
				document.getElementById("currentPage").textContent = currentPage + 1;
				document.getElementById("totalPages").textContent = totalPages;
				document.getElementById("prevBtn").disabled = currentPage === 0;
				document.getElementById("nextBtn").disabled = currentPage >= totalPages - 1;
				document.getElementById("pagination").style.display = "flex";
			}

			function prevPage() {
				if (currentPage > 0) {
					currentPage--;
					if (isSearchMode) {
						loadSearchPage();
					} else {
						loadStories();
					}
				}
			}

			function nextPage() {
				if (currentPage < totalPages - 1) {
					currentPage++;
					if (isSearchMode) {
						loadSearchPage();
					} else {
						loadStories();
					}
				}
			}

			async function loadSearchPage() {
				const storiesList = document.getElementById("storiesList");
				document.getElementById("pagination").style.display = "none";
				storiesList.innerHTML = `<div class="loading"><i class="fa-solid fa-spinner"></i><span>Loading...</span></div>`;

				try {
					const result = await window.searchStories(searchQuery, currentPage);
					if (!result || result.error) {
						storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> ${result?.error || "Failed to load"}</div>`;
						return;
					}
					displayStories(result);
				} catch (e) {
					storiesList.innerHTML = `<div class="error-message"><i class="fa-solid fa-exclamation-triangle"></i> Failed to load</div>`;
				}
			}

			async function openPost(storyId) {
				const modal = document.getElementById("commentsModal");
				const modalBody = document.getElementById("modalBody");
				const modalTitle = document.getElementById("modalTitle");

				modal.classList.add("show");
				modalBody.innerHTML = `<div class="loading"><i class="fa-solid fa-spinner"></i><span>Loading post...</span></div>`;

				try {
					const result = await window.getItem(storyId);
					if (!result || result.error) {
						modalBody.innerHTML = `<div class="error-message">${result?.error || "Failed to load post"}</div>`;
						return;
					}

					modalTitle.textContent = result.title || "Post";
					
					let html = `<div class="post-content">`;
					
					// Post metadata
					html += `<div class="post-meta">
						<span><i class="fa-solid fa-user"></i> ${escapeHtml(result.author || "unknown")}</span>
						<span><i class="fa-solid fa-arrow-up"></i> ${result.points || 0} points</span>
						<span><i class="fa-solid fa-clock"></i> ${result.created_at ? timeAgo(new Date(result.created_at)) : ""}</span>
					</div>`;
					
					// External URL if available
					if (result.url) {
						html += `<div class="post-url"><a href="${result.url}" target="_blank"><i class="fa-solid fa-link"></i> ${result.url}</a></div>`;
					}
					
					// Post text content (for Ask HN, Show HN, etc.)
					if (result.text) {
						html += `<div class="post-text">${result.text}</div>`;
					}
					
					html += `</div>`;
					
					// Comments section
					if (result.children && result.children.length > 0) {
						html += `<div class="comments-section">
							<h3><i class="fa-solid fa-comments"></i> ${result.children.length} Comments</h3>
							${renderComments(result.children)}
						</div>`;
					} else {
						html += `<div class="comments-section"><p style="color: var(--text-secondary);">No comments yet.</p></div>`;
					}
					
					modalBody.innerHTML = html;
				} catch (e) {
					console.error("Error:", e);
					modalBody.innerHTML = `<div class="error-message">Failed to load post</div>`;
				}
			}

			async function openComments(storyId) {
				const modal = document.getElementById("commentsModal");
				const modalBody = document.getElementById("modalBody");
				const modalTitle = document.getElementById("modalTitle");

				modal.classList.add("show");
				modalBody.innerHTML = `<div class="loading"><i class="fa-solid fa-spinner"></i><span>Loading comments...</span></div>`;

				try {
					const result = await window.getItem(storyId);
					if (!result || result.error) {
						modalBody.innerHTML = `<div class="error-message">${result?.error || "Failed to load comments"}</div>`;
						return;
					}

					modalTitle.textContent = result.title || "Comments";
					
					if (!result.children || result.children.length === 0) {
						modalBody.innerHTML = `<p style="color: var(--text-secondary);">No comments yet.</p>`;
						return;
					}

					modalBody.innerHTML = renderComments(result.children);
				} catch (e) {
					console.error("Error:", e);
					modalBody.innerHTML = `<div class="error-message">Failed to load comments</div>`;
				}
			}

			function renderComments(comments, depth = 0) {
				if (!comments || comments.length === 0) return "";
				if (depth > 3) return "";

				let html = "";
				comments.forEach(comment => {
					if (!comment.text) return;
					const author = comment.author || "unknown";
					const time = comment.created_at ? timeAgo(new Date(comment.created_at)) : "";

					html += `
						<div class="comment">
							<div class="comment-meta">
								<i class="fa-solid fa-user"></i> ${escapeHtml(author)} · ${time}
							</div>
							<div class="comment-text">${comment.text}</div>
							${comment.children && comment.children.length > 0 ? 
								`<div class="nested-comments">${renderComments(comment.children, depth + 1)}</div>` : ""}
						</div>
					`;
				});
				return html;
			}

			function closeModal() {
				document.getElementById("commentsModal").classList.remove("show");
			}

			function timeAgo(date) {
				const seconds = Math.floor((new Date() - date) / 1000);
				const intervals = [
					{ label: "year", seconds: 31536000 },
					{ label: "month", seconds: 2592000 },
					{ label: "day", seconds: 86400 },
					{ label: "hour", seconds: 3600 },
					{ label: "minute", seconds: 60 }
				];

				for (const interval of intervals) {
					const count = Math.floor(seconds / interval.seconds);
					if (count >= 1) {
						return `${count} ${interval.label}${count > 1 ? "s" : ""} ago`;
					}
				}
				return "just now";
			}

			function escapeHtml(text) {
				const div = document.createElement("div");
				div.textContent = text;
				return div.innerHTML;
			}

			// Close modal on escape key
			document.addEventListener("keydown", e => {
				if (e.key === "Escape") closeModal();
			});

			// Close modal on backdrop click
			document.getElementById("commentsModal").addEventListener("click", e => {
				if (e.target.id === "commentsModal") closeModal();
			});

			// Search on Enter key
			document.getElementById("searchInput").addEventListener("keypress", e => {
				if (e.key === "Enter") doSearch();
			});

			// Load initial stories
			window.onload = loadStories;
		</script>
	</body>
	</html>
	'
	oWebView.setHtml(cHTML)