/*
	Ring WebView Library Install Script
	----------------------------------
	Installs Ring WebView library for the current platform.
	Detects OS and architecture, then copies or symlinks the library
	to the appropriate system location.
*/

load "stdlibcore.ring"
load "src/utils/color.ring"

# ============================================================================
# Constants
# ============================================================================

C_PRETTY_NAME      = "WebView"
C_PACKAGE_NAME     = "webview"
C_NEW_PACKAGE_NAME = C_PACKAGE_NAME
C_LIB_NAME         = "ring_" + C_PACKAGE_NAME
C_SAMPLES_DIR      = "Using" + C_PRETTY_NAME

# ============================================================================
# Main Entry Point
# ============================================================================

func main
	new Installer()

# ============================================================================
# Installer Class
# ============================================================================

class Installer

	# Platform configuration
	cOSName    = ""
	cArchName  = ""
	cLibPrefix = ""
	cLibExt    = ""
	cPathSep   = "/"
	lIsMusl    = false

	# Paths
	cPackagePath  = ""
	cLibPath      = ""
	cSamplesPath  = ""
	cExamplesPath = ""

	func init
		if not detectPlatform()
			return
		ok

		if not detectArchitecture()
			return
		ok

		initializePaths()

		if not verifyLibrary()
			return
		ok

		performInstallation()

	# ========================================================================
	# Platform Detection
	# ========================================================================

	func detectPlatform
		if isWindows()
			configurePlatform("windows", "", ".dll", "\\")
		but isLinux()
			configurePlatform("linux", "lib", ".so", "/")
			detectMusl()
		but isFreeBSD()
			configurePlatform("freebsd", "lib", ".so", "/")
		but isMacOSX()
			configurePlatform("macos", "lib", ".dylib", "/")
		else
			printError("Unsupported operating system detected!")
			return false
		ok
		return true

	func detectMusl
		# Detect musl libc by checking ldd output
		cOutput = systemCmd("sh -c 'ldd 2>&1'")
		if substr(cOutput, "musl")
			lIsMusl = true
		ok

	func configurePlatform osName, libPrefix, libExt, pathSep
		cOSName    = osName
		cLibPrefix = libPrefix
		cLibExt    = libExt
		cPathSep   = pathSep

	func detectArchitecture
		cArchName = getarch()

		switch cArchName
			on "x86"
				cArchName = "i386"
			on "x64"
				cArchName = "amd64"
			on "arm64"
			other
				printError("Unsupported architecture: " + cArchName)
				return false
		off

		return true

	# ========================================================================
	# Path Configuration
	# ========================================================================

	func initializePaths
		cPackagePath = buildPath([
			exefolder(), "..", "tools", "ringpm", "packages", C_PACKAGE_NAME
		])

		# Build library path - use musl subdirectory on Linux if musl is detected
		if lIsMusl
			cLibPath = buildPath([
				cPackagePath, "lib", cOSName, "musl", cArchName,
				cLibPrefix + C_LIB_NAME + cLibExt
			])
		else
			cLibPath = buildPath([
				cPackagePath, "lib", cOSName, cArchName,
				cLibPrefix + C_LIB_NAME + cLibExt
			])
		ok

		cExamplesPath = buildPath([cPackagePath, "examples"])
		cSamplesPath  = buildPath([exefolder(), "..", "samples", C_SAMPLES_DIR])

	func verifyLibrary
		if fexists(cLibPath)
			return true
		ok

		printError(C_PRETTY_NAME + " library not found!")
		printSubStep("Expected location: " + cLibPath)
		if lIsMusl
			printInfo("Detected musl libc environment (Alpine Linux, etc.)")
			printSubStep("Ensure library is built for: " + cOSName + "/musl/" + cArchName)
		else
			printSubStep("Ensure library is built for: " + cOSName + "/" + cArchName)
		ok
		printInfo("See build instructions: " + buildPath([cPackagePath, "README.md"]))
		return false

	# ========================================================================
	# Installation
	# ========================================================================

	func performInstallation
		printHeader("Installing " + C_PRETTY_NAME)
		
		try
			printStep("Installing library for " + cOSName + "/" + cArchName + "…")
			installLibrary()
			printSuccess("Library installed")
			
			printStep("Copying examples…")
			copyExamples()
			printSuccess("Examples copied")
			
			printStep("Updating Ring configuration…")
			updateRingConfig()
			printSuccess("Configuration updated")
			
			printStep("Setting up Ring2EXE…")
			setupRing2EXE()
			printSuccess("Ring2EXE configured")
			
			showSuccessMessage()
		catch
			printError("Failed to install " + C_PRETTY_NAME + "!")
			printSubStep("Details: " + cCatchError)
		done

	func installLibrary
		if isWindows()
			installWindowsLibrary()
		else
			installUnixLibrary()
		ok

	func installWindowsLibrary
		systemSilent('copy /y "' + cLibPath + '" "' + exefolder() + '"')

	func installUnixLibrary
		cRingLibDir = buildPath([exefolder(), "..", "lib"])

		# Determine system library directory
		if isFreeBSD() or isMacOSX()
			cSystemLibDir = "/usr/local/lib"
		else
			cSystemLibDir = "/usr/lib"
		ok

		# Symlink to Ring lib directory
		system('ln -sf "' + cLibPath + '" "' + cRingLibDir + '"')

		# Symlink to system lib directory (with privilege escalation fallback)
		cLinkCmd = 'ln -sf "' + cLibPath + '" "' + cSystemLibDir + '"'
		system(buildElevatedCommand(cLinkCmd))

	func buildElevatedCommand baseCmd
		return 'which sudo >/dev/null 2>&1 && sudo ' + baseCmd +
			   ' || (which doas >/dev/null 2>&1 && doas ' + baseCmd +
			   ' || ' + baseCmd + ')'

	# ========================================================================
	# Examples & Configuration
	# ========================================================================

	func copyExamples
		cOriginalDir = currentdir()

		ensureDirectory(buildPath([exefolder(), "..", "samples"]))
		makeDir(cSamplesPath)
		chdir(cSamplesPath)

		aItems = dir(cExamplesPath)
		if aItems = NULL
			chdir(cOriginalDir)
			return
		ok

		for item in aItems
			cSourcePath = cExamplesPath + cPathSep
			if item[2]
				OSCopyFolder(cSourcePath, item[1])
			else
				OSCopyFile(cSourcePath + item[1])
			ok
		next

		chdir(cOriginalDir)

	func updateRingConfig
		cOldConfigPath = buildPath([exefolder(), C_PACKAGE_NAME + ".ring"])

		if fexists(cOldConfigPath)
			remove(cOldConfigPath)
		ok

		# Ensure load directory exists
		cLoadDir = buildPath([exefolder(), "load"])
		ensureDirectory(cLoadDir)

		cNewConfigPath = buildPath([cLoadDir, C_NEW_PACKAGE_NAME + ".ring"])
		cLoadStatement = 'load "../../tools/ringpm/packages/' + C_PACKAGE_NAME + '/lib.ring"'
		write(cNewConfigPath, cLoadStatement)

	func setupRing2EXE
		cLibsDir = buildPath([exefolder(), "..", "tools", "ring2exe", "libs"])

		if not direxists(cLibsDir)
			return
		ok

		cConfigPath = buildPath([cLibsDir, C_NEW_PACKAGE_NAME + ".ring"])
		write(cConfigPath, generateRing2EXEConfig())

	func generateRing2EXEConfig
		return 'aLibrary = [
	:name         = :' + C_NEW_PACKAGE_NAME + ',
	:title        = "' + C_PRETTY_NAME + '",
	:windowsfiles = ["' + C_LIB_NAME + '.dll"],
	:linuxfiles   = ["lib' + C_LIB_NAME + '.so"],
	:macosxfiles  = ["lib' + C_LIB_NAME + '.dylib"],
	:freebsdfiles = ["lib' + C_LIB_NAME + '.so"],
	:ubuntudep = "libgtk-4-1 libwebkitgtk-6.0-4",
	:fedoradep = "gtk4 webkitgtk6.0",
	:macosxdep = "",
	:freebsddep = "webkit2-gtk_60"
]'

	func showSuccessMessage
		? ""
		printSuccess(C_PRETTY_NAME + " installed successfully!")
		? ""
		printInfo("Samples: " + cSamplesPath)
		printInfo("Examples: " + cExamplesPath)
		? ""

	# ========================================================================
	# Utility Methods
	# ========================================================================

	func buildPath aComponents
		cResult = ""
		nCount  = len(aComponents)

		for i = 1 to nCount
			cResult += aComponents[i]
			if i < nCount
				cResult += cPathSep
			ok
		next

		return cResult

	func ensureDirectory cPath
		if not direxists(cPath)
			makeDir(cPath)
		ok