# Tic-Tac-Toe Game
# This example demonstrates a simple Tic-Tac-Toe game where the game logic
# is handled by the Ring backend, and the UI is rendered in the webview.

load "webview.ring"
load "jsonlib.ring"

# --- Global Variables ---
oWebView = NULL
aBoard = ["", "", "", "", "", "", "", "", ""]
cCurrentPlayer = "X"

# Bind Ring functions to be callable from JavaScript.
aBindList = [
	["handlePlayerMove", :handlePlayerMove],
	["resetGame", :handleResetGame]
]

func main()
	oWebView = new WebView()

	oWebView {
		setTitle("Tic-Tac-Toe")
		setSize(400, 550, WEBVIEW_HINT_FIXED)
		loadGameHTML()
		run()
	}

# Defines the HTML structure and inline JavaScript for the game.
func loadGameHTML()
	cHTML = `
	<!DOCTYPE html>
	<html>
	<head>
		<title>Tic-Tac-Toe</title>
		<meta charset="UTF-8">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
		<style>
			@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap');
			:root {
				--bg-color: #000000; --panel-bg: rgba(30, 30, 32, 0.6);
				--border-color: rgba(255, 255, 255, 0.1); --text-primary: #f8fafc;
				--text-secondary: #a1a1aa; --accent-blue: #3b82f6;
				--accent-cyan: #22d3ee; --accent-purple: #c084fc;
			}
			body {
				font-family: 'Inter', sans-serif; background-color: var(--bg-color);
				color: var(--text-primary); margin: 0; height: 100vh;
				overflow: hidden; display: flex; flex-direction: column;
				justify-content: center; align-items: center; position: relative;
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
			.game-container {
				background-color: var(--panel-bg); padding: 30px; border-radius: 15px;
				box-shadow: 0 8px 30px rgba(0,0,0,0.3); text-align: center;
				width: 90%; max-width: 380px; position: relative; z-index: 1;
				border: 1px solid var(--border-color); backdrop-filter: blur(12px);
				-webkit-backdrop-filter: blur(12px);
			}
			h1 {
				color: var(--text-primary); margin-bottom: 20px; font-size: 2em;
			}
			#status {
				font-size: 1.2em; color: var(--text-secondary); margin-bottom: 20px;
				min-height: 25px;
			}
			.board {
				display: grid; grid-template-columns: repeat(3, 1fr);
				gap: 10px; margin-bottom: 20px;
			}
			.cell {
				width: 100px; height: 100px; background-color: rgba(255,255,255,0.05);
				border: 1px solid var(--border-color); border-radius: 10px;
				display: flex; justify-content: center; align-items: center;
				font-size: 3.5em; font-weight: bold; cursor: pointer;
				transition: background-color 0.2s;
			}
			.cell:hover { background-color: rgba(255,255,255,0.1); }
			.cell.X { color: var(--accent-cyan); }
			.cell.O { color: var(--accent-purple); }
			#reset-btn {
				background-color: var(--accent-blue); color: white; border: none;
				border-radius: 8px; padding: 12px 25px; font-size: 1.1em;
				cursor: pointer; transition: all 0.2s ease-in-out;
				box-shadow: 0 4px 10px rgba(0,0,0,0.2);
			}
			#reset-btn:hover {
				transform: translateY(-2px); box-shadow: 0 6px 15px rgba(0,0,0,0.3);
			}
		</style>
	</head>
	<body>
		<div class="background-container">
			<div class="aurora"><div class="aurora-shape1"></div><div class="aurora-shape2"></div></div>
		</div>
		<div class="game-container">
			<h1><i class="fa-solid fa-hashtag"></i> Tic-Tac-Toe</h1>
			<div id="status">Player X's turn</div>
			<div class="board" id="board"></div>
			<button id="reset-btn"><i class="fa-solid fa-arrows-rotate"></i> Reset Game</button>
		</div>

		<script>
			const boardDiv = document.getElementById('board');
			const statusDiv = document.getElementById('status');
			const resetBtn = document.getElementById('reset-btn');
			let gameActive = true;

			function createBoard() {
				boardDiv.innerHTML = '';
				for (let i = 0; i < 9; i++) {
					const cell = document.createElement('div');
					cell.className = 'cell';
					cell.dataset.index = i;
					cell.addEventListener('click', () => {
						if (gameActive && !cell.textContent) {
							window.handlePlayerMove(i);
						}
					});
					boardDiv.appendChild(cell);
				}
			}

			function updateUI(board, status) {
				const cells = document.querySelectorAll('.cell');
				cells.forEach((cell, index) => {
					cell.textContent = board[index];
					cell.classList.remove('X', 'O');
					if (board[index]) {
						cell.classList.add(board[index]);
					}
				});
				statusDiv.textContent = status;
				if (status.includes('wins') || status.includes('Draw')) {
					gameActive = false;
				}
			}

			resetBtn.addEventListener('click', async () => {
				const newState = await window.resetGame();
				gameActive = true;
				updateUI(newState.board, newState.status);
			});

			window.onload = createBoard;
		</script>
	</body>
	</html>
	`
	oWebView.setHtml(cHTML)

# --- Ring Callback Handlers ---

func handlePlayerMove(id, req)
	nIndex = json2list(req)[1][1]

	if aBoard[nIndex + 1] = "" and not checkWinner()
		aBoard[nIndex + 1] = cCurrentPlayer
		if not checkWinner() and not isBoardFull()
			cCurrentPlayer = "O"
			aiMove()
		ok
	ok
	updateGame()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, '{}')

func handleResetGame(id, req)
	aBoard = ["", "", "", "", "", "", "", "", ""]
	cCurrentPlayer = "X"
	cJson = buildStateJSON()
	oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJson)

# --- Game Logic ---

func aiMove()
	# Simple AI: find the first empty spot
	for i = 1 to len(aBoard)
		if aBoard[i] = ""
			aBoard[i] = "O"
			cCurrentPlayer = "X" # Switch back to Player
			return
		ok
	next

func checkWinner()
	aWinConditions = [
		[1,2,3], [4,5,6], [7,8,9], # Rows
		[1,4,7], [2,5,8], [3,6,9], # Columns
		[1,5,9], [3,5,7]          # Diagonals
	]
	for aCondition in aWinConditions
		if aBoard[aCondition[1]] != "" and
		   aBoard[aCondition[1]] = aBoard[aCondition[2]] and
		   aBoard[aCondition[1]] = aBoard[aCondition[3]]
			return aBoard[aCondition[1]]
		ok
	next
	return NULL

func isBoardFull()
	for cCell in aBoard
		if cCell = ""
			return false
		ok
	next
	return true

func updateGame()
	cStatus = ""
	pWinner = checkWinner()
	if pWinner
		cStatus = "Player " + pWinner + " wins!"
	elseif isBoardFull()
		cStatus = "It's a Draw!"
	else
		cStatus = "Player " + cCurrentPlayer + "'s turn"
	ok
	# Escape single quotes for JavaScript
	cStatus = substr(cStatus, "'", "\'")
	cJsCode = "updateUI(" + buildBoardJson() + ", '" + cStatus + "');"
	oWebView.evalJS(cJsCode)

func buildStateJSON()
	cStatus = "Player " + cCurrentPlayer + "'s turn"
	return list2json([
		:board = aBoard,
		:status = cStatus
	])

func buildBoardJson()
	aJsonList = []
	for i = 1 to len(aBoard)
		add(aJsonList, aBoard[i])
	next
	return list2json(aJsonList)
