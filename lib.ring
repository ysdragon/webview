# This file is part of the Ring WebView library.

# Load the Ring WebView library based on the operating system.
if isWindows()
	loadlib("ring_webview.dll")
but isLinux() or isFreeBSD()
	loadlib("libring_webview.so")
but isMacOSX()
	loadlib("libring_webview.dylib")
else
	raise("Unsupported OS! You need to build the library for your OS.")
ok

# Load the Ring WebView Class and Constants.
load "src/webview.ring"
load "src/webview.rh"