# Building Android Apps with Ring WebView

Write `main.ring` once, ship it on desktop and Android. On Android the same
Ring C-API is backed by `android.webkit.WebView` through JNI — no Java and
no Gradle required from you.

## Prerequisites

- Ring 1.27+, Android SDK + NDK + JDK, CMake + Ninja
- [ring2apk](https://github.com/ysdragon/ring2apk): `ringpm install ring2apk from ysdragon`

## Start

```sh
ring2apk init myapp        # scaffold, or copy examples/android/
cd myapp
ring2apk build             # → build/myapp-debug.apk
ring2apk run               # build + install + launch + logcat
adb logcat -s RingOutput:D # `see` output
```

Config lives in `ring2apk.ring` (`:packageId`, `:targets`, `:permissions`,
`:entryPoint`). The working reference is
[`examples/android/`](../examples/android/) — a notes
app; its [README](../examples/android/README.md) covers the layout.

## Write the app

`ring/main.ring` is compiled to embedded bytecode and linked into
`libmain.so` — no `.ring` files ship. The API matches desktop, so most of
[USAGE](USAGE.md) and [REFERENCE](REFERENCE.md) apply as-is:

```ring
load "webview.ring"

aBindList = [["getState", :fetchNotes]]

oWebView = new WebView()
oWebView {
    setTitle("My App")
    onLoad(:handleLoad)
    onDomReady(:handleDomReady)
    onClose(:handleClose)
    bindMany(NULL)
    setHtml(`<h1>Hello Android</h1><script>...</script>`)
    run()
}

func fetchNotes(cId, aReq)
    oWebView.wreturn(cId, WEBVIEW_ERROR_OK, aNotes)
```

Bridge rules that matter on mobile:

- Binds receive Ring lists (JS argument array, JSON-decoded) and should
  `wreturn` results; JS gets promises. See the example's bridge table.
- Drive the first render from `onDomReady` (`evalJS("refresh()")`) — it runs
  strictly after the bind shim is injected.
- Files persist in the app's `filesDir` (the worker starts there); use
  relative paths.
- Window-management calls (`setSize`, `minimize`, …) are desktop no-ops
  that return safely — guard mobile layouts with responsive CSS instead.

## Under the hood

UI thread owns the WebView and only enqueues; a worker thread owns the Ring
VM and runs a bounded job queue. Rotation re-attaches without destroying;
a killed renderer rebuilds the view and reloads the last HTML/URL (poison
pages stop after 3 crashes in 10s). Single webview per process.
`RingBridge` is callable by any loaded page JS, remote included — validate
bind arguments.

Backend sources: `src/c_src/ring_webview_android.c`,
`src/android/io/github/ysdragon/webview/MainActivity.java`.
