# This file is part of the Ring WebView library.
# It provides functionality to remove the library files and clean up the environment.

load "stdlibcore.ring"

cPathSep = "/"

if isWindows()
	cPathSep = "\\"
ok

# Remove the webview.ring file from the load directory
remove(exefolder() + "load" + cPathSep + "webview.ring")

# Remove the webview.ring file from the Ring2EXE libs directory
remove(exefolder() + ".." + cPathSep + "tools" + cPathSep + "ring2exe" + cPathSep + "libs" + cPathSep + "webview.ring")

# Change current directory to the samples directory
chdir(exefolder() + ".." + cPathSep + "samples")

# Remove the UsingWebView directory if it exists
if direxists("UsingWebView")
	OSDeleteFolder("UsingWebView")
ok