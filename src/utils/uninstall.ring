/*
	Ring WebView Library Uninstall Script
	-----------------------------------------
	Removes Ring WebView library files and configuration
	from the current Ring installation.
*/

load "stdlibcore.ring"
load "src/utils/color.ring"

# ============================================================================
# Constants
# ============================================================================

C_PRETTY_NAME      = "WebView"
C_PACKAGE_NAME     = "webview"
C_LIB_NAME         = "ring_" + C_PACKAGE_NAME
C_SAMPLES_DIR      = "Using" + C_PRETTY_NAME

# ============================================================================
# Main Entry Point
# ============================================================================

func main
	new Uninstaller()

# ============================================================================
# Uninstaller Class
# ============================================================================

class Uninstaller

	# Platform configuration
	cPathSep   = "/"
	cLibPrefix = ""
	cLibExt    = ""
	
	# Counters
	nRemoved = 0
	nSkipped = 0

	func init
		detectPlatform()
		performUninstallation()

	# ========================================================================
	# Platform Detection
	# ========================================================================

	func detectPlatform
		if isWindows()
			cPathSep   = "\\"
			cLibPrefix = ""
			cLibExt    = ".dll"
		but isLinux()
			cLibPrefix = "lib"
			cLibExt    = ".so"
		but isFreeBSD()
			cLibPrefix = "lib"
			cLibExt    = ".so"
		but isMacOSX()
			cLibPrefix = "lib"
			cLibExt    = ".dylib"
		ok

	# ========================================================================
	# Uninstallation
	# ========================================================================

	func performUninstallation
		printHeader("Uninstalling " + C_PRETTY_NAME)
		
		try
			removeLoadConfig()
			removeRing2EXEConfig()
			removeSamples()
			removeLibraryFiles()
			showResultMessage()
		catch
			printError("Failed to uninstall " + C_PRETTY_NAME + "!")
			printSubStep("Details: " + cCatchError)
		done

	func removeLoadConfig
		printStep("Removing load configuration…")
		cConfigPath = buildPath([exefolder(), "load", C_PACKAGE_NAME + ".ring"])
		
		if fexists(cConfigPath)
			remove(cConfigPath)
			printSuccess("Load configuration removed")
			nRemoved++
		else
			printSubStep("Load configuration not found (skipped)")
			nSkipped++
		ok

	func removeRing2EXEConfig
		printStep("Removing Ring2EXE configuration…")
		cConfigPath = buildPath([exefolder(), "..", "tools", "ring2exe", "libs", C_PACKAGE_NAME + ".ring"])
		
		if fexists(cConfigPath)
			remove(cConfigPath)
			printSuccess("Ring2EXE configuration removed")
			nRemoved++
		else
			printSubStep("Ring2EXE configuration not found (skipped)")
			nSkipped++
		ok

	func removeSamples
		printStep("Removing sample files…")
		cSamplesPath = buildPath([exefolder(), "..", "samples", C_SAMPLES_DIR])
		
		if direxists(cSamplesPath)
			cOriginalDir = currentdir()
			chdir(buildPath([exefolder(), "..", "samples"]))
			OSDeleteFolder(C_SAMPLES_DIR)
			chdir(cOriginalDir)
			printSuccess("Samples removed")
			nRemoved++
		else
			printSubStep("Samples directory not found (skipped)")
			nSkipped++
		ok

	func removeLibraryFiles
		printStep("Removing library files…")
		cLibFileName = cLibPrefix + C_LIB_NAME + cLibExt
		lAnyRemoved = false
		
		# Remove from Ring lib directory
		cRingLibPath = buildPath([exefolder(), "..", "lib", cLibFileName])
		if fexists(cRingLibPath)
			remove(cRingLibPath)
			printSubStep("Removed from Ring lib directory")
			lAnyRemoved = true
		ok
		
		# Remove from Ring bin directory (Windows)
		if isWindows()
			cBinPath = buildPath([exefolder(), cLibFileName])
			if fexists(cBinPath)
				remove(cBinPath)
				printSubStep("Removed from Ring bin directory")
				lAnyRemoved = true
			ok
		ok
		
		# Remove symlinks from system directories (Unix)
		if not isWindows()
			if isFreeBSD() or isMacOSX()
				cSystemLibDir = "/usr/local/lib"
			else
				cSystemLibDir = "/usr/lib"
			ok
			
			cSystemLibPath = cSystemLibDir + "/" + cLibFileName
			if fexists(cSystemLibPath)
				cRemoveCmd = 'rm -f "' + cSystemLibPath + '"'
				system(buildElevatedCommand(cRemoveCmd))
				printSubStep("Removed from " + cSystemLibDir)
				lAnyRemoved = true
			ok
		ok
		
		if lAnyRemoved
			printSuccess("Library files removed")
			nRemoved++
		else
			printSubStep("No library files found (skipped)")
			nSkipped++
		ok

	func showResultMessage
		? ""
		if nRemoved > 0
			printSuccess(C_PRETTY_NAME + " uninstalled successfully!")
		else
			printWarning("Nothing to uninstall - " + C_PRETTY_NAME + " was not installed")
		ok
		? ""
		printInfo("Removed: " + nRemoved + " component(s)")
		printInfo("Skipped: " + nSkipped + " component(s)")
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

	func buildElevatedCommand baseCmd
		return 'which sudo >/dev/null 2>&1 && sudo ' + baseCmd +
			   ' || (which doas >/dev/null 2>&1 && doas ' + baseCmd +
			   ' || ' + baseCmd + ')'