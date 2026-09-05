# Ring WebView Android backend — ProGuard / R8 keep rules.
#
# The native backend (ring_webview_android.c) looks up MainActivity methods by
# string name via GetMethodID, and the JS bridge entry point is reached by
# reflection (@JavascriptInterface). With minification enabled, R8 would rename
# or strip them and the bridge would break silently at runtime (UnsatisfiedLink
# errors never fire — calls just stop arriving).
#
# Pass this file to the APK packager (ring2apk) whenever minify is enabled.
# Without minification it is inert documentation of the reflective boundary.

-keep class io.github.ysdragon.webview.MainActivity {
    *;
}
-keepclassmembers class io.github.ysdragon.webview.MainActivity$RingBridge {
    *;
}
