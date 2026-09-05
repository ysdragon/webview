# assets.ring — embedded-assets API for Ring WebView (embed.FS-style).
#
# In dev (`ring main.ring`) assets are read from disk ($cAssetsDir, default
# "frontend/dist"). In an exe produced by webview-bake they are read from the
# binary (zero-copy), via the exe-provided C functions:
#   assets_read / assets_exists / assets_count / assets_list
# App code should always use the Assets* wrappers — never the primitives.

$cAssetsDir = "frontend/dist"
$bAssetsProbeInit = 0
$bAssetsPacked = 0

func IsPackedAssets
	if $bAssetsProbeInit = 0
		$bAssetsProbeInit = 1
		$bAssetsPacked = iscfunction("assets_read")
	ok
	return $bAssetsPacked

func AssetsDir cDir
	$cAssetsDir = cDir

func AssetsRead cPath
	if IsPackedAssets()
		return assets_read(cPath)
	ok
	return read($cAssetsDir + "/" + cPath)

func AssetsExists cPath
	if IsPackedAssets()
		return assets_exists(cPath)
	ok
	return fexists($cAssetsDir + "/" + cPath)

func AssetsList
	aOut = []
	if IsPackedAssets()
		aOut = assets_list()
	else
		assetsScan($cAssetsDir, "", aOut)
	ok
	return sort(aOut)

func assetsScan cAbsDir, cRel, aOut
	# Mirrors webview-bake's walk: relative slash-separated keys, empty files skipped.
	for aItem in dir(cAbsDir)
		cName = substr(aItem[1], char(92), "/")
		cKey = cName
		if cRel != ""
			cKey = cRel + "/" + cName
		ok
		cFull = cAbsDir + "/" + aItem[1]
		if aItem[2] = 1
			assetsScan(cFull, cKey, aOut)
		else
			if getfilesize(cFull) > 0
				aOut + cKey
			ok
		ok
	next
