# Ring WebView Examples

Examples organized by learning curve - start from basics and progress to advanced topics.

## 🟢 Beginner - Getting Started (01-10)

| # | Example | Description |
|---|---------|-------------|
| 01 | basic.ring | Minimal webview with HTML content |
| 02 | navigate.ring | Load external URLs |
| 03 | local_html.ring | Load local HTML files |
| 04 | callbacks.ring | JavaScript to Ring communication |
| 05 | inject_eval_callback.ring | Inject JS and evaluate code |
| 06 | digital_clock.ring | Real-time updates with dispatch |
| 07 | form_input.ring | Handle form data |
| 08 | counter_sync.ring | Two-way data binding |
| 09 | showcase.ring | Feature showcase demo |
| 10 | theme_switcher.ring | Dynamic theme switching |

## 🟡 Intermediate - Core Features (11-25)

| # | Example | Description |
|---|---------|-------------|
| 11 | unbind.ring | Remove JavaScript bindings |
| 12 | color_palette.ring | Color picker app |
| 13 | qr_code_generator.ring | QR code generation |
| 14 | chart.ring | Chart visualization |
| 15 | login_form.ring | Login form handling |
| 16 | to_do_list.ring | Todo list app |
| 17 | live_markdown_editor.ring | Markdown editor |
| 18 | http_fetch.ring | HTTP requests |
| 19 | drawing.ring | Canvas drawing |
| 20 | tic_tac_toe.ring | Game example |
| 21 | bind_many.ring | Batch function binding |
| 22 | using_class_methods.ring | Bind class methods |
| 23 | threaded_counter.ring | Multi-threading |
| 24 | using_dialog.ring | Native dialogs |
| 25 | ringfetch.ring | Ring HTTP library |

## 🟠 Advanced - Complete Applications (26-39)

| # | Example | Description |
|---|---------|-------------|
| 26 | webview_all_demo.ring | Comprehensive API demo |
| 27 | prayer_times.ring | Prayer times app |
| 28 | chat_bot.ring | Chat bot interface |
| 29 | mock_pos.ring | Point of sale system |
| 30 | quote_generator.ring | Quote generator |
| 31 | avatar_quotes.ring | Avatar with quotes |
| 32 | using_weblib.ring | Ring WebLib integration |
| 33 | adhkar_counter.ring | Counter app |
| 34 | ring_playground.ring | Code playground |
| 35 | notes.ring | Notes application |
| 36 | file_explorer.ring | File browser |
| 37 | weather_app.ring | Weather application |
| 38 | using_htmx.ring | HTMX integration |
| 39 | hacker_news.ring | Hacker News client |

## 🔴 Expert - Platform APIs (40-44)

| # | Example | Description | Features |
|---|---------|-------------|----------|
| 40 | window_appearance.ring | Window appearance controls | setDecorated, setOpacity, setBackgroundColor, setAlwaysOnTop |
| 41 | window_management.ring | Window state & geometry | hide/show/focus, minimize/maximize/restore, position, size constraints, fullscreen |
| 42 | webview_features.ring | WebView & system features | navigation, devtools, context menu, dark mode, screens info |
| 43 | event_callbacks.ring | Event handling | onDomReady, onLoad, onTitle, onNavigate, onFocus |
| 44 | custom_titlebar.ring | Frameless window | Custom titlebar with drag & resize zones |

## Platform Support

| Feature | Windows | Linux/FreeBSD | macOS |
|---------|:-------:|:-------------:|:-----:|
| All basic features | ✅ | ✅ | ✅ |
| Custom titlebar | ✅ | ✅ | ✅ |
| setPosition/getPosition | ✅ | ❌ (Wayland) | ✅ |
| setAlwaysOnTop | ✅ | ❌ | ✅ |
| setClickThrough | ✅ | ❌ | ❌ |
| setForceDark | ❌ | ✅ | ❌ |
| Event callbacks | ⏳ | ✅ | ⏳ |
