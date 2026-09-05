# Nota: glassmorphism notes app for Ring WebView on Android.
# Ring owns the notes list and persists it to notes.db (length-prefixed
# flat file in filesDir). The bridge carries JSON both ways, so Ring only
# ever handles lists: binds wreturn the full state, JS re-renders from it.

load "webview.ring"

aNotes = []
nNextId = 1
cDbFile = "notes.db"

aBindList = [
	["getState", :fetchNotes],
	["note_save", :storeNote],
	["note_delete", :removeNote],
	["note_pin", :toggleNotePin]
]

loadNotes()

oWebView = new WebView()

oWebView {
	setTitle("Nota")

	onLoad(:handleLoad)
	onDomReady(:handleDomReady)
	onClose(:handleClose)

	bindMany(NULL)

	setHtml(`
		<!DOCTYPE html>
		<html lang="en">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
			<title>Nota</title>
			<style>
				:root {
					--accent: #34d399;
					--accent-deep: #059669;
					--ink: #ecfdf5;
					--ink-dim: rgba(236, 253, 245, 0.62);
					--glass: rgba(255, 255, 255, 0.07);
					--stroke: rgba(255, 255, 255, 0.13);
					--radius: 20px;
				}
				* { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
				html, body { margin: 0; padding: 0; }
				body {
					font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
					color: var(--ink);
					min-height: 100dvh;
					background: #06110d;
					padding-bottom: 110px;
				}
				/* One fixed layer: no repaint-on-scroll like background-attachment: fixed. */
				body::before {
					content: "";
					position: fixed;
					inset: 0;
					z-index: -1;
					background:
						radial-gradient(120% 60% at 85% -5%, rgba(52, 211, 153, 0.20), transparent 60%),
						radial-gradient(100% 55% at -10% 25%, rgba(56, 189, 248, 0.14), transparent 60%),
						radial-gradient(120% 70% at 50% 110%, rgba(167, 139, 250, 0.12), transparent 60%);
				}
				header {
					position: sticky;
					top: 0;
					z-index: 5;
					padding: calc(14px + env(safe-area-inset-top)) 20px 14px;
					background: rgba(6, 17, 13, 0.55);
					backdrop-filter: blur(18px) saturate(150%);
					-webkit-backdrop-filter: blur(18px) saturate(150%);
					border-bottom: 1px solid var(--stroke);
				}
				.brand { display: flex; align-items: baseline; gap: 10px; }
				.brand h1 { margin: 0; font-size: 1.6rem; letter-spacing: -0.02em; }
				.brand h1 em { font-style: normal; color: var(--accent); }
				.brand span { font-size: 0.8rem; color: var(--ink-dim); }
				.search {
					display: flex;
					align-items: center;
					gap: 10px;
					margin-top: 12px;
					background: var(--glass);
					border: 1px solid var(--stroke);
					border-radius: 16px;
					padding: 0 14px;
				}
				.search svg { flex: none; opacity: 0.6; }
				.search input {
					flex: 1;
					min-height: 48px;
					background: none;
					border: none;
					outline: none;
					color: var(--ink);
					font-size: 1rem;
				}
				.search input::placeholder { color: var(--ink-dim); }
				main { padding: 16px 16px 0; max-width: 640px; margin: 0 auto; }
				.section-title {
					font-size: 0.78rem;
					text-transform: uppercase;
					letter-spacing: 0.12em;
					color: var(--ink-dim);
					margin: 18px 4px 10px;
				}
				/* No per-card blur: one blur per card recomposites every scroll
				   frame. Blur stays on header + sheet only (two layers). */
				.note {
					background: rgba(255, 255, 255, 0.055);
					border: 1px solid var(--stroke);
					border-left: 4px solid var(--accent);
					border-radius: var(--radius);
					padding: 14px 16px;
					margin-bottom: 12px;
					box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
					content-visibility: auto;
					contain-intrinsic-size: auto 120px;
				}
				.note.c-sky { border-left-color: #38bdf8; }
				.note.c-violet { border-left-color: #a78bfa; }
				.note.c-amber { border-left-color: #fbbf24; }
				.note.c-rose { border-left-color: #fb7185; }
				.note h3 { margin: 0 0 4px; font-size: 1.02rem; letter-spacing: -0.01em; }
				.note p {
					margin: 0 0 10px;
					font-size: 0.92rem;
					line-height: 1.5;
					color: var(--ink-dim);
					white-space: pre-wrap;
					word-break: break-word;
				}
				.note .row { display: flex; align-items: center; gap: 8px; }
				.note time { flex: 1; font-size: 0.72rem; color: var(--ink-dim); }
				.iconbtn {
					min-width: 44px;
					min-height: 44px;
					display: inline-flex;
					align-items: center;
					justify-content: center;
					background: rgba(255, 255, 255, 0.06);
					border: 1px solid var(--stroke);
					border-radius: 12px;
					color: var(--ink);
					cursor: pointer;
				}
				.iconbtn:active { transform: scale(0.94); }
				.iconbtn.on { color: var(--accent); border-color: rgba(52, 211, 153, 0.5); }
				.empty {
					text-align: center;
					padding: 48px 24px;
					color: var(--ink-dim);
					border: 1px dashed var(--stroke);
					border-radius: var(--radius);
					background: rgba(255, 255, 255, 0.03);
				}
				.empty .ring {
					width: 56px;
					height: 56px;
					margin: 0 auto 14px;
					border-radius: 50%;
					border: 2px solid rgba(52, 211, 153, 0.35);
					border-top-color: var(--accent);
				}
				.fab {
					position: fixed;
					right: 20px;
					bottom: calc(24px + env(safe-area-inset-bottom));
					width: 60px;
					height: 60px;
					border-radius: 50%;
					border: none;
					background: linear-gradient(135deg, var(--accent), var(--accent-deep));
					color: #052e22;
					cursor: pointer;
					box-shadow: 0 12px 32px rgba(52, 211, 153, 0.35);
				}
				.fab:active { transform: scale(0.93); }
				.sheet-wrap {
					position: fixed;
					inset: 0;
					z-index: 10;
					background: rgba(0, 0, 0, 0.5);
					opacity: 0;
					pointer-events: none;
					transition: opacity 0.22s ease;
				}
				.sheet-wrap.open { opacity: 1; pointer-events: auto; }
				.sheet {
					position: absolute;
					left: 0;
					right: 0;
					bottom: 0;
					max-width: 640px;
					margin: 0 auto;
					background: rgba(16, 28, 24, 0.92);
					backdrop-filter: blur(24px) saturate(160%);
					-webkit-backdrop-filter: blur(24px) saturate(160%);
					border: 1px solid var(--stroke);
					border-bottom: none;
					border-radius: 24px 24px 0 0;
					padding: 12px 20px calc(20px + env(safe-area-inset-bottom));
					transform: translateY(100%);
					transition: transform 0.26s ease;
				}
				.sheet-wrap.open .sheet { transform: translateY(0); }
				.grip {
					width: 40px;
					height: 4px;
					border-radius: 2px;
					background: rgba(255, 255, 255, 0.25);
					margin: 4px auto 14px;
				}
				.sheet label { display: block; font-size: 0.78rem; color: var(--ink-dim); margin: 12px 0 6px; }
				.sheet input[type=text], .sheet textarea {
					width: 100%;
					background: rgba(255, 255, 255, 0.06);
					border: 1px solid var(--stroke);
					border-radius: 14px;
					color: var(--ink);
					font-size: 1rem;
					font-family: inherit;
					padding: 13px 14px;
					outline: none;
				}
				.sheet input[type=text]:focus, .sheet textarea:focus { border-color: rgba(52, 211, 153, 0.6); }
				.sheet textarea { min-height: 120px; resize: vertical; }
				.dots { display: flex; gap: 12px; align-items: center; }
				.dot {
					width: 44px;
					height: 44px;
					border-radius: 50%;
					border: 2px solid transparent;
					cursor: pointer;
				}
				.dot.sel { border-color: #fff; }
				.sheet .actions { display: flex; gap: 10px; margin-top: 18px; }
				.btn {
					flex: 1;
					min-height: 52px;
					border-radius: 16px;
					border: 1px solid var(--stroke);
					background: rgba(255, 255, 255, 0.06);
					color: var(--ink);
					font-size: 1rem;
					font-weight: 600;
					cursor: pointer;
				}
				.btn:active { transform: scale(0.98); }
				.btn.primary { background: linear-gradient(135deg, var(--accent), var(--accent-deep)); color: #052e22; border: none; }
				.btn.danger { color: #fda4af; }
				.pinrow { display: flex; align-items: center; gap: 10px; margin-top: 14px; font-size: 0.92rem; }
				.pinrow input { width: 24px; height: 24px; accent-color: var(--accent); }
				#toast {
					position: fixed;
					left: 50%;
					bottom: calc(100px + env(safe-area-inset-bottom));
					transform: translateX(-50%) translateY(20px);
					background: rgba(16, 28, 24, 0.95);
					border: 1px solid rgba(52, 211, 153, 0.45);
					color: var(--ink);
					padding: 12px 20px;
					border-radius: 999px;
					font-size: 0.9rem;
					opacity: 0;
					pointer-events: none;
					transition: opacity 0.2s ease, transform 0.2s ease;
					z-index: 20;
					white-space: nowrap;
				}
				#toast.show { opacity: 1; transform: translateX(-50%) translateY(0); }
				@media (prefers-reduced-transparency: reduce) {
					header, .note, .sheet { backdrop-filter: none; -webkit-backdrop-filter: none; }
					.note, .search { background: rgba(20, 34, 29, 0.97); }
					.sheet { background: #101c18; }
				}
				@media (prefers-reduced-motion: reduce) {
					.sheet, .sheet-wrap, #toast, .fab, .btn, .iconbtn { transition: none; }
				}
			</style>
		</head>
		<body>
			<header>
				<div class="brand"><h1>Nota<em>.</em></h1><span id="meta">loading</span></div>
				<div class="search">
					<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><line x1="16.5" y1="16.5" x2="21" y2="21"/></svg>
					<input id="q" type="text" placeholder="Search notes" oninput="render()">
				</div>
			</header>
			<main>
				<div id="pinned"></div>
				<div id="list"></div>
			</main>
			<button class="fab" onclick="openSheet(0)" aria-label="New note">
				<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
			</button>
			<div class="sheet-wrap" id="sheetWrap" onclick="if(event.target===this)closeSheet()">
				<div class="sheet">
					<div class="grip"></div>
					<input type="hidden" id="f_id" value="0">
					<label for="f_title">Title</label>
					<input type="text" id="f_title" placeholder="Untitled" maxlength="120">
					<label for="f_body">Note</label>
					<textarea id="f_body" placeholder="Write something worth keeping"></textarea>
					<label>Color</label>
					<div class="dots" id="dots"></div>
					<div class="pinrow">
						<input type="checkbox" id="f_pin">
						<label for="f_pin" style="margin:0">Pin to top</label>
					</div>
					<div class="actions">
						<button class="btn danger" id="btnDel" onclick="delCurrent()">Delete</button>
						<button class="btn" onclick="closeSheet()">Cancel</button>
						<button class="btn primary" onclick="saveCurrent()">Save</button>
					</div>
				</div>
			</div>
			<div id="toast"></div>
			<script>
				var state = [];
				var COLORS = ["emerald", "sky", "violet", "amber", "rose"];
				var COLOR_HEX = { emerald: "#34d399", sky: "#38bdf8", violet: "#a78bfa", amber: "#fbbf24", rose: "#fb7185" };
				var toastTimer = null;

				function esc(s) {
					return String(s == null ? "" : s)
						.replace(/&/g, "&amp;").replace(/</g, "&lt;")
						.replace(/>/g, "&gt;").replace(/"/g, "&quot;");
				}
				function toast(msg) {
					var t = document.getElementById("toast");
					t.textContent = msg;
					t.className = "show";
					if (toastTimer) clearTimeout(toastTimer);
					toastTimer = setTimeout(function() { t.className = ""; }, 1800);
				}
				// Called by native onDomReady, after the shim is injected.
				function refresh() {
					getState().then(function(notes) {
						state = notes || [];
						render();
					}).catch(function() { toast("Could not load notes"); });
				}
				function card(n) {
					var pinned = n[4] === 1;
					var h = "<article class='note c-" + n[3] + "'>";
					h += "<h3>" + esc(n[1] || "Untitled") + "</h3>";
					h += "<p>" + esc(n[2]) + "</p>";
					h += "<div class='row'><time>" + esc(n[5]) + "</time>";
					h += "<button class='iconbtn" + (pinned ? " on" : "") + "' aria-label='Pin' onclick='togglePin(" + n[0] + ")'>";
					h += "<svg width='18' height='18' viewBox='0 0 24 24' fill='" + (pinned ? "currentColor" : "none") + "' stroke='currentColor' stroke-width='2'><path d='M9 4h6l1 7 3 3v2H5v-2l3-3z'/><line x1='12' y1='16' x2='12' y2='21'/></svg></button>";
					h += "<button class='iconbtn' aria-label='Edit' onclick='openSheet(" + n[0] + ")'>";
					h += "<svg width='18' height='18' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2'><path d='M17 3l4 4L8 20l-5 1 1-5z'/></svg></button>";
					h += "</div></article>";
					return h;
				}
				function render() {
					var q = document.getElementById("q").value.toLowerCase();
					var pin = "", rest = "", nPin = 0;
					for (var i = 0; i < state.length; i++) {
						var n = state[i];
						var hay = (n[1] + " " + n[2]).toLowerCase();
						if (q && hay.indexOf(q) < 0) continue;
						if (n[4] === 1) { pin += card(n); nPin++; }
						else rest += card(n);
					}
					var pinnedEl = document.getElementById("pinned");
					pinnedEl.innerHTML = pin ? "<div class='section-title'>Pinned</div>" + pin : "";
					var listEl = document.getElementById("list");
					if (!rest && !pin) {
						listEl.innerHTML = "<div class='empty'><div class='ring'></div>" +
							(q ? "No notes match your search." : "No notes yet. Tap + to write your first one.") + "</div>";
					} else {
						listEl.innerHTML = (pin && rest ? "<div class='section-title'>All notes</div>" : "") + rest;
					}
					var total = state.length;
					document.getElementById("meta").textContent =
						total + (total === 1 ? " note" : " notes") + (nPin ? ", " + nPin + " pinned" : "");
				}
				function findNote(id) {
					for (var i = 0; i < state.length; i++)
						if (state[i][0] === id) return state[i];
					return null;
				}
				function paintDots(sel) {
					var d = document.getElementById("dots");
					var h = "";
					for (var i = 0; i < COLORS.length; i++) {
						h += "<button class='dot" + (COLORS[i] === sel ? " sel" : "") + "' aria-label='" + COLORS[i] + "' " +
							"style='background:" + COLOR_HEX[COLORS[i]] + "' data-c='" + COLORS[i] + "' onclick='paintDots(this.dataset.c)'></button>";
					}
					d.innerHTML = h;
					d.dataset.sel = sel;
				}
				function openSheet(id) {
					var n = id ? findNote(id) : null;
					document.getElementById("f_id").value = id || 0;
					document.getElementById("f_title").value = n ? n[1] : "";
					document.getElementById("f_body").value = n ? n[2] : "";
					document.getElementById("f_pin").checked = n ? n[4] === 1 : false;
					document.getElementById("btnDel").style.display = n ? "" : "none";
					paintDots(n ? n[3] : "emerald");
					document.getElementById("sheetWrap").className = "sheet-wrap open";
					setTimeout(function() { document.getElementById("f_title").focus(); }, 280);
				}
				function closeSheet() {
					document.getElementById("sheetWrap").className = "sheet-wrap";
				}
				function saveCurrent() {
					var id = parseInt(document.getElementById("f_id").value, 10) || 0;
					var title = document.getElementById("f_title").value;
					var body = document.getElementById("f_body").value;
					if (!title && !body) { toast("Empty note discarded"); closeSheet(); return; }
					var color = document.getElementById("dots").dataset.sel || "emerald";
					var pinned = document.getElementById("f_pin").checked ? 1 : 0;
					note_save([id, title, body, color, pinned]).then(function(notes) {
						state = notes || [];
						render();
						closeSheet();
						toast(id ? "Note updated" : "Note saved");
					}).catch(function() { toast("Save failed"); });
				}
				function delCurrent() {
					var id = parseInt(document.getElementById("f_id").value, 10) || 0;
					if (!id) { closeSheet(); return; }
					note_delete([id]).then(function(notes) {
						state = notes || [];
						render();
						closeSheet();
						toast("Note deleted");
					}).catch(function() { toast("Delete failed"); });
				}
				function togglePin(id) {
					note_pin([id]).then(function(notes) {
						state = notes || [];
						render();
					}).catch(function() { toast("Could not pin"); });
				}
			</script>
		</body>
		</html>
	`)

	run()
}

see "Nota closed." + nl

# --- Persistence: length-prefixed flat file, no escaping needed ---
# note block: id LF titleLen:title bodyLen:body color LF pinned LF updated LF

func loadNotes
	if not fexists(cDbFile)
		return
	ok
	c = read(cDbFile)
	aPos = [1]
	while aPos[1] <= len(c)
		cId = takeLine(c, aPos)
		if cId = ""
			exit
		ok
		cTitle = takeField(c, aPos)
		cBody = takeField(c, aPos)
		cColor = takeLine(c, aPos)
		cPinned = takeLine(c, aPos)
		cUpdated = takeLine(c, aPos)
		if cColor = "" or cPinned = "" or cUpdated = ""
			exit
		ok
		aNotes + [number(cId), cTitle, cBody, cColor, number(cPinned), cUpdated]
		if number(cId) >= nNextId
			nNextId = number(cId) + 1
		ok
	end

func takeLine(cText, aPos)
	nStart = aPos[1]
	nEnd = nStart
	while nEnd <= len(cText) and ascii(cText[nEnd]) != 10
		nEnd = nEnd + 1
	end
	cLine = ""
	if nEnd > nStart
		cLine = substr(cText, nStart, nEnd - nStart)
	ok
	aPos[1] = nEnd + 1
	return cLine

func takeField(cText, aPos)
	nStart = aPos[1]
	nColon = nStart
	while nColon <= len(cText) and cText[nColon] != ":"
		nColon = nColon + 1
	end
	if nColon > len(cText)
		return ""
	ok
	nFieldLen = number(substr(cText, nStart, nColon - nStart))
	nFieldStart = nColon + 1
	cField = ""
	if nFieldLen > 0
		cField = substr(cText, nFieldStart, nFieldLen)
	ok
	aPos[1] = nFieldStart + nFieldLen
	return cField

func persistNotes
	cOut = ""
	for aNote in aNotes
		cOut += "" + aNote[1] + char(10)
		cOut += "" + len(aNote[2]) + ":" + aNote[2]
		cOut += "" + len(aNote[3]) + ":" + aNote[3]
		cOut += aNote[4] + char(10)
		cOut += "" + aNote[5] + char(10)
		cOut += aNote[6] + char(10)
	next
	write(cDbFile, cOut)

# --- Binds: req[1] is the JS argument array; always wreturn the full state ---

func fetchNotes(cId, aReq)
	oWebView.wreturn(cId, WEBVIEW_ERROR_OK, aNotes)

func storeNote(cId, aReq)
	aData = aReq[1]
	nId = number(aData[1])
	cTitle = "" + aData[2]
	cBody = "" + aData[3]
	cColor = "" + aData[4]
	nPinned = number(aData[5])
	cStamp = date() + " " + time()
	if nId = 0
		aNotes + [nNextId, cTitle, cBody, cColor, nPinned, cStamp]
		nNextId++
	else
		for i = 1 to len(aNotes)
			if aNotes[i][1] = nId
				aNotes[i][2] = cTitle
				aNotes[i][3] = cBody
				aNotes[i][4] = cColor
				aNotes[i][5] = nPinned
				aNotes[i][6] = cStamp
				exit
			ok
		next
	ok
	persistNotes()
	oWebView.wreturn(cId, WEBVIEW_ERROR_OK, aNotes)

func removeNote(cId, aReq)
	nId = number(aReq[1][1])
	for i = 1 to len(aNotes)
		if aNotes[i][1] = nId
			del(aNotes, i)
			exit
		ok
	next
	persistNotes()
	oWebView.wreturn(cId, WEBVIEW_ERROR_OK, aNotes)

func toggleNotePin(cId, aReq)
	nId = number(aReq[1][1])
	for i = 1 to len(aNotes)
		if aNotes[i][1] = nId
			aNotes[i][5] = 1 - aNotes[i][5]
			exit
		ok
	next
	persistNotes()
	oWebView.wreturn(cId, WEBVIEW_ERROR_OK, aNotes)

# --- Events ---

func handleLoad(cState)
	see "load: " + cState + nl

func handleDomReady
	oWebView.evalJS("refresh()")

func handleClose
	see "close" + nl
