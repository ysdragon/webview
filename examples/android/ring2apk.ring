/*
    ring2apk configuration file — Ring WebView Android example
*/

# App configuration
Ring2ApkConfig = [
    # App identity
    :name = "webviewdemo",
    :packageId = "io.github.ysdragon.webview",
    :versionCode = 1,
    :versionName = "1.0.0",

    # Android SDK versions
    :minSdk = 21,
    :targetSdk = 36,
    :compileSdk = 36,

    # Target architectures
    :targets = ["arm64-v8a"],

    # Directories
    :assetsDir = "assets",
    :resDir = "res",
    :srcDir = "src",
    :outputDir = "build",

    # Entry point Ring file
    :entryPoint = "main.ring",

    :ringSrcDir = "ring",

    # App display settings
    :label = "Ring WebView",
    :orientation = "unspecified",
    :theme = "@style/AppTheme",

    # Permissions
    :permissions = [
        "android.permission.INTERNET"
    ]
]
