/*
	Ring WebView Library Install Script
	----------------------------------
	This script installs the Ring WebView library for the current platform.
	It detects the OS and architecture, then copies or symlinks the library to the 
	appropriate system location.
*/

load "stdlibcore.ring"
load "src/utils/color.ring"

# Default library settings
cLibPrefix = "lib"
cPathSep = "/"

# Platform detection and configuration
switch true
	on isWindows()
		cLibPrefix = ""
		cPathSep = "\\"
		cLibExt = ".dll"
		cOSName = "windows"
	on isLinux()
		cLibExt = ".so"
		cOSName = "linux"
	on isFreeBSD()
		cLibExt = ".so"
		cOSName = "freebsd"
	on isMacOSX()
		cLibExt = ".dylib"
		cOSName = "macos"
	other
		? colorText([:text = "Error: Unsupported operating system detected!", :color = :BRIGHT_RED, :style = :BOLD])
		return

off

# Get system architecture
cArchName = getarch()
switch cArchName
	on "x86"
		cArchName = "i386"
	on "x64"
		cArchName = "amd64"
	on "arm64"
		cArchName = "arm64"
	other
		? colorText([:text = "Error: Unsupported architecture: " + cArchName, :color = :BRIGHT_RED, :style = :BOLD])
		return
off

# Construct the package path
cPackagePath = exefolder() + ".." + cPathSep + "tools" + cPathSep + "ringpm" + cPathSep + "packages" + cPathSep + "webview"

# Construct the library path
cLibPath = cPackagePath + cPathSep + "lib" + cPathSep + 
		cOSName + cPathSep + cArchName + cPathSep + cLibPrefix + "ring_webview" + cLibExt

# Verify library exists
if not fexists(cLibPath)
	? colorText([:text = "Error: WebView library not found!", :color = :BRIGHT_RED, :style = :BOLD])
	? colorText([:text = "Expected location: ", :color = :YELLOW]) + colorText([:text = cLibPath, :color = :CYAN])
	? colorText([:text = "Please ensure the library is built for your platform (" + cOSName + "/" + cArchName + ")", :color = :BRIGHT_MAGENTA])
	? colorText([:text = "You can refer to README.md for build instructions: ", :color = :CYAN]) + colorText([:text = cPackagePath + cPathSep + "README.md", :color = :YELLOW])
	return
ok

# Install library based on platform
try
	if isWindows()
		systemSilent("copy /y " + '"' + cLibPath + '" "' + exefolder() + '"')
	else
		if isFreeBSD() or isMacOSX()
			cDestDir = "/usr/local/lib"
		but isLinux()
			cDestDir = "/usr/lib"
		ok
		cCommand = 'which sudo >/dev/null 2>&1 && sudo ln -sf "' + cLibPath + '" "' + cDestDir + 
				'" || (which doas >/dev/null 2>&1 && doas ln -sf "' + cLibPath + '" "' + cDestDir + 
				'" || ln -sf "' + cLibPath + '" "' + cDestDir + '")'
		system(cCommand)
	ok

	# Copy examples to the samples/UsingWebView directory
	cCurrentDir = currentdir()
	cExamplesPath = cPackagePath + cPathSep + "examples"
	cSamplesPath = exefolder() + ".." + cPathSep + "samples" + cPathSep + "UsingWebView"

	# Ensure the samples directory exists and create it if not
	if not direxists(exefolder() + ".." + cPathSep + "samples")
		makeDir(exefolder() + ".." + cPathSep + "samples")
	ok

	# Create the UsingWebView directory
	makeDir(cSamplesPath)

	# Change to the samples directory
	chdir(cSamplesPath)

	# Loop through the examples and copy them to the samples directory
	for item in dir(cExamplesPath) 
		if item[2]
			OSCopyFolder(cExamplesPath + cPathSep, item[1])
		else
			OSCopyFile(cExamplesPath + cPathSep + item[1])
		ok
	next

	# Change back to the original directory
	chdir(cCurrentDir)

	? colorText([:text = "Successfully installed Ring WebView!", :color = :BRIGHT_GREEN, :style = :BOLD])
	? colorText([:text = "You can refer to samples in: ", :color = :CYAN]) + colorText([:text = cSamplesPath, :color = :YELLOW])
	? colorText([:text = "Or in the package directory: ", :color = :CYAN]) + colorText([:text = cExamplesPath, :color = :YELLOW])
catch
	? colorText([:text = "Error: Failed to install Ring WebView!", :color = :BRIGHT_RED, :style = :BOLD])
	? colorText([:text = "Details: ", :color = :YELLOW]) + colorText([:text = cCatchError, :color = :CYAN])
done