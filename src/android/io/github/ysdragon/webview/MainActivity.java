/*
 * MainActivity.java
 * Copyright (c) Youssef Saeed <youssefelkholey@gmail.com>
 *             All rights reserved.
 */
package io.github.ysdragon.webview;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.webkit.ConsoleMessage;
import android.webkit.JavascriptInterface;
import android.webkit.JsPromptResult;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.EditText;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

// Android host: owns the WebView on the UI thread. Ring VM runs on a native
// worker thread; all cross-talk goes through ring_webview_android.c.
public class MainActivity extends Activity {

    private static final String TAG = "RingWebView";
    private static final long SYNC_TIMEOUT_MS = 5000;

    static {
        System.loadLibrary("main");
    }

    private WebView webView;
    private volatile String injectJs = "";
    private volatile boolean destroyed = false;
    // Last URL / HTML (crash reload; reset on rotation). Last size (resize on change).
    // UI thread only.
    private String lastUrl = "";
    private String lastHtml = "";
    private int lastW = -1, lastH = -1;
    // Crash-loop guard: a poison page must not rebuild forever.
    private int crashCount = 0;
    private long lastCrashMs = 0;

    /* ------------------------------------------------------------------ */
    /* Lifecycle                                                          */
    /* ------------------------------------------------------------------ */

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        Window window = getWindow();
        window.setStatusBarColor(Color.TRANSPARENT);
        if (Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false);
        } else {
            int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN;
            window.getDecorView().setSystemUiVisibility(flags);
        }

        webView = createWebView();
        setContentView(webView);

        // Dark page: keep light status-bar icons.
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.setSystemBarsAppearance(
                        0,
                        WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS);
            }
        }

        nativeStart();
    }

    // Fully configured WebView. Shared by onCreate and crash recovery.
    // UI thread only.
    private WebView createWebView() {
        final WebView v = new WebView(this);

        WebSettings settings = v.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);

        v.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return false;
            }

            @Override
            public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
                if (url != null) {
                    lastUrl = url;
                    // Real navigation wins over earlier setHtml content.
                    if (!url.equals("about:blank")) lastHtml = "";
                }
                nativeOnPageStarted(url);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                String js = injectJs;
                if (js != null && js.length() > 0) {
                    view.evaluateJavascript(js, null);
                }
                nativeOnPageFinished(url);
            }

            @Override
            public boolean onRenderProcessGone(WebView view, android.webkit.RenderProcessGoneDetail detail) {
                return handleRenderCrash(view, detail);
            }
        });

        v.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onReceivedTitle(WebView view, String title) {
                nativeOnTitleChanged(title);
            }

            @Override
            public boolean onConsoleMessage(ConsoleMessage cm) {
                Log.i(TAG, "JS: " + cm.message() + " @" + cm.sourceId() + ":" + cm.lineNumber());
                return true;
            }

            @Override
            public boolean onJsAlert(WebView view, String url, String message, final JsResult result) {
                new AlertDialog.Builder(MainActivity.this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
                        .setMessage(message)
                        .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                result.confirm();
                            }
                        })
                        .setCancelable(false)
                        .show();
                return true;
            }

            @Override
            public boolean onJsConfirm(WebView view, String url, String message, final JsResult result) {
                new AlertDialog.Builder(MainActivity.this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
                        .setMessage(message)
                        .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                result.confirm();
                            }
                        })
                        .setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                result.cancel();
                            }
                        })
                        .setCancelable(false)
                        .show();
                return true;
            }

            @Override
            public boolean onJsPrompt(WebView view, String url, String message, String defaultValue,
                                      final JsPromptResult result) {
                final EditText input = new EditText(MainActivity.this);
                input.setText(defaultValue);
                new AlertDialog.Builder(MainActivity.this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
                        .setMessage(message)
                        .setView(input)
                        .setPositiveButton(android.R.string.ok, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                result.confirm(input.getText().toString());
                            }
                        })
                        .setNegativeButton(android.R.string.cancel, new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                result.cancel();
                            }
                        })
                        .setCancelable(false)
                        .show();
                return true;
            }
        });

        v.addJavascriptInterface(new RingBridge(), "RingBridge");

        v.getViewTreeObserver().addOnGlobalLayoutListener(new android.view.ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                int w = v.getWidth(), h = v.getHeight();
                if (w != lastW || h != lastH) {
                    lastW = w;
                    lastH = h;
                    if (w > 0 && h > 0) nativeOnResize(w, h);
                }
            }
        });

        return v;
    }

    // Renderer gone: destroy the dead view, build an identical one, reload.
    // Inject JS persists, so bindings come back with the page. True = handled.
    // API 26+ only.
    private boolean handleRenderCrash(WebView view, android.webkit.RenderProcessGoneDetail detail) {
        boolean crashed = detail != null && detail.didCrash();
        Log.w(TAG, "WebView render process " + (crashed ? "crashed" : "killed by system")
                + "; rebuilding view, lastUrl=" + lastUrl);
        if (view != null) view.destroy();
        lastW = lastH = -1;
        webView = createWebView();
        setContentView(webView);
        long now = System.currentTimeMillis();
        if (now - lastCrashMs > 10000) crashCount = 0;
        lastCrashMs = now;
        // Same page crashing repeatedly: rebuild empty, stop reloading it.
        if (++crashCount > 3) {
            Log.e(TAG, "WebView crashed repeatedly; showing empty view");
            return true;
        }
        if (!lastHtml.isEmpty()) renderHtml(webView, lastHtml);
        else if (!lastUrl.isEmpty()) webView.loadUrl(lastUrl);
        return true;
    }

    private void renderHtml(WebView v, String html) {
        if (v != null) v.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        nativeOnFocusChanged(hasFocus);
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            nativeOnClose();
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        // Rotation destroys too; only a real finish kills the worker.
        if (isFinishing()) {
            destroyed = true;
            nativeDestroy();
        }
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    /* ------------------------------------------------------------------ */
    /* Called from native (worker thread unless noted)                    */
    /* ------------------------------------------------------------------ */

    public void evalJs(final String js) {
        if (destroyed || webView == null) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (webView != null) webView.evaluateJavascript(js, null);
            }
        });
    }

    public void loadUrl(final String url) {
        if (destroyed || webView == null) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (webView != null) webView.loadUrl(url);
            }
        });
    }

    public void loadHtml(final String html) {
        if (destroyed || webView == null) return;
        lastHtml = (html == null) ? "" : html;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                renderHtml(webView, html);
            }
        });
    }

    public void goBack() {
        if (destroyed || webView == null) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (webView != null && webView.canGoBack()) webView.goBack();
            }
        });
    }

    public void goForward() {
        if (destroyed || webView == null) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (webView != null && webView.canGoForward()) webView.goForward();
            }
        });
    }

    public void reload() {
        if (destroyed || webView == null) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (webView != null) webView.reload();
            }
        });
    }

    // Sync URL query; blocks the caller on the UI thread.
    public String getUrlSync() {
        if (destroyed || webView == null) return "";
        if (Looper.myLooper() == Looper.getMainLooper()) {
            String u = webView.getUrl();
            return u == null ? "" : u;
        }
        final AtomicReference<String> ref = new AtomicReference<String>("");
        final CountDownLatch latch = new CountDownLatch(1);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String u = (webView != null) ? webView.getUrl() : null;
                ref.set(u == null ? "" : u);
                latch.countDown();
            }
        });
        try {
            boolean ok = latch.await(SYNC_TIMEOUT_MS, TimeUnit.MILLISECONDS);
            if (!ok) {
                Log.w(TAG, "getUrlSync timed out after " + SYNC_TIMEOUT_MS + "ms; returning \"\"");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            Log.w(TAG, "getUrlSync interrupted; returning \"\"");
        }
        return ref.get();
    }

    // Sync title query; blocks the caller on the UI thread.
    public String getTitleSync() {
        if (destroyed || webView == null) return "";
        if (Looper.myLooper() == Looper.getMainLooper()) {
            String t = webView.getTitle();
            return t == null ? "" : t;
        }
        final AtomicReference<String> ref = new AtomicReference<String>("");
        final CountDownLatch latch = new CountDownLatch(1);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String t = (webView != null) ? webView.getTitle() : null;
                ref.set(t == null ? "" : t);
                latch.countDown();
            }
        });
        try {
            boolean ok = latch.await(SYNC_TIMEOUT_MS, TimeUnit.MILLISECONDS);
            if (!ok) {
                Log.w(TAG, "getTitleSync timed out after " + SYNC_TIMEOUT_MS + "ms; returning \"\"");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            Log.w(TAG, "getTitleSync interrupted; returning \"\"");
        }
        return ref.get();
    }

    public void setDebug(final boolean enabled) {
        // setWebContentsDebuggingEnabled must run on the UI thread.
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                WebView.setWebContentsDebuggingEnabled(enabled);
            }
        });
    }

    // Script re-injected after every page load.
    public void setInjectJs(String js) {
        injectJs = (js == null) ? "" : js;
    }

    public void finishApp() {
        if (destroyed) return;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                finish();
            }
        });
    }

    /* ------------------------------------------------------------------ */
    /* JavaScript bridge                                                  */
    /* ------------------------------------------------------------------ */

    // TRUST BOUNDARY: every page, remote included, can call any bound Ring
    // function by name. Validate args; no privileged ops.
    private class RingBridge {
        @JavascriptInterface
        public void call(String name, String id, String req) {
            nativeOnBridgeCall(name, id, req);
        }
    }

    /* ------------------------------------------------------------------ */
    /* Native methods (implemented in ring_webview_android.c)             */
    /* ------------------------------------------------------------------ */

    private native void nativeStart();
    private native void nativeDestroy();
    private native void nativeOnBridgeCall(String name, String id, String req);
    private native void nativeOnPageStarted(String url);
    private native void nativeOnPageFinished(String url);
    private native void nativeOnClose();
    private native void nativeOnTitleChanged(String title);
    private native void nativeOnFocusChanged(boolean focused);
    private native void nativeOnResize(int width, int height);
}
