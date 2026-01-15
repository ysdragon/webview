# This file is part of the Ring WebView library.

load "stdlibcore.ring"

# Enable unicode support in Windows CMD/PowerShell
if isWindows()
	systemSilent("chcp 65001")
ok

# ============================================================================
# Constants
# ============================================================================

# Color list
cColors = [
	:RED = "31",
	:GREEN = "32",
	:YELLOW = "33",
	:BLUE = "34",
	:MAGENTA = "35",
	:CYAN = "36",
	:WHITE = "37",
	:BLACK = "30",
	:BRIGHT_RED = "1;31",
	:BRIGHT_GREEN = "1;32",
	:BRIGHT_YELLOW = "1;33",
	:BRIGHT_BLUE = "1;34",
	:BRIGHT_MAGENTA = "1;35",
	:BRIGHT_CYAN = "1;36",
	:BRIGHT_WHITE = "1;37"
]

# Style list
cStyles = [
	:RESET = "0",
	:BOLD = "1",
	:DIM = "2",
	:UNDERLINE = "4",
	:BLINK = "5",
	:REVERSE = "7",
	:HIDDEN = "8"
]

# Unicode symbols for CLI output
cSymbols = [
	# Status indicators
	:TICK       = "✔",
	:CROSS      = "✖",
	:WARNING    = "⚠",
	:INFO       = "ℹ",
	:STAR       = "★",
	:BULLET     = "•",
	:POINTER    = "❯",
	:ELLIPSIS   = "…",
	
	# Progress indicators
	:CIRCLE_EMPTY    = "◯",
	:CIRCLE_FILLED   = "◉",
	:CIRCLE_DOTTED   = "◌",
	:SQUARE_FILLED   = "◼",
	:SQUARE_EMPTY    = "◻",
	
	# Decorative
	:ARROW_RIGHT = "→",
	:ARROW_LEFT  = "←",
	:ARROW_UP    = "↑",
	:ARROW_DOWN  = "↓",
	:LINE        = "─",
	:DOUBLE_LINE = "═",
	:HEART       = "♥",
	:PLAY        = "▶",
	:STOP        = "■"
]

# ============================================================================
# Color functions
# ============================================================================

func setColor(colorCode)
	return char(27) + "[" + colorCode + "m"

func resetColor()
	return char(27) + "[0m"

# Color text with optional style
func colorText(params)
	text = params[:text]
	colorKey = params[:color]
	styleCode = ""
	if not isNull(params[:style])
		styleCode = cStyles[params[:style]]
	ok
	if isString(colorKey)
		colorCode = cColors[colorKey]
	else
		colorCode = colorKey
	ok
	fullCode = colorCode
	if styleCode != NULL
		fullCode = styleCode + ";" + colorCode
	ok
	return setColor(fullCode) + text + resetColor()


# ============================================================================
# Colored Log functions
# ============================================================================

func printError cMessage
	? colorText([:text = " " + cSymbols[:CROSS] + " ", :color = :BRIGHT_RED, :style = :BOLD]) +
	  colorText([:text = cMessage, :color = :BRIGHT_RED])

func printWarning cMessage
	? colorText([:text = " " + cSymbols[:WARNING] + " ", :color = :YELLOW, :style = :BOLD]) +
	  colorText([:text = cMessage, :color = :YELLOW])

func printSuccess cMessage
	? colorText([:text = " " + cSymbols[:TICK] + " ", :color = :BRIGHT_GREEN, :style = :BOLD]) +
	  colorText([:text = cMessage, :color = :BRIGHT_GREEN])

func printInfo cMessage
	? colorText([:text = " " + cSymbols[:INFO] + " ", :color = :CYAN]) +
	  colorText([:text = cMessage, :color = :WHITE])

func printStep cMessage
	? colorText([:text = " " + cSymbols[:POINTER] + " ", :color = :BRIGHT_BLUE, :style = :BOLD]) +
	  colorText([:text = cMessage, :color = :WHITE])

func printSubStep cMessage
	? colorText([:text = "   " + cSymbols[:ARROW_RIGHT] + " ", :color = :WHITE, :style = :DIM]) +
	  colorText([:text = cMessage, :color = :WHITE, :style = :DIM])

func printHeader cMessage
	cLine = ""
	for i = 1 to len(cMessage) + 4
		cLine += cSymbols[:LINE]
	next
	? ""
	? colorText([:text = " " + cLine, :color = :BRIGHT_BLUE, :style = :DIM])
	? colorText([:text = "  " + cMessage, :color = :BRIGHT_WHITE, :style = :BOLD])
	? colorText([:text = " " + cLine, :color = :BRIGHT_BLUE, :style = :DIM])
	? ""
