aPackageInfo = [
	:name = "webview",
	:description = "A powerful Ring library for building modern, cross-platform desktop applications with web technologies and Ring.",
	:folder = "webview",
	:developer = "ysdragon",
	:email = "youssefelkholey@gmail.com",
	:license = "MIT License",
	:version = "1.3.9",
	:ringversion = "1.23",
	:versions = 	[
		[
			:version = "1.3.9",
			:branch = "main"
		]
	],
	:libs = 	[
		[
			:name = "dialog",
			:version = "1.0.0",
			:providerusername = "ysdragon"
		],
		[
			:name = "simplejson",
			:version = "1.0.0",
			:providerusername = "ysdragon"
		],
		[
			:name = "markdown",
			:version = "1.1.0",
			:providerusername = "ysdragon"
		],
		[
			:name = "ringcurl",
			:version = "1.0.15",
			:providerusername = "ringpackages"
		],
		[
			:name = "ringthreads",
			:version = "1.0.6",
			:providerusername = "ringpackages"
		],
		[
			:name = "SysInfo",
			:version = "1.3.0",
			:providerusername = "ysdragon"
		],
		[
			:name = "weblib",
			:version = "1.0.7",
			:providerusername = "ringpackages"
		]
	],
	:files = 	[
		"src/ring_webview.c",
		"CMakeLists.txt",
		"lib.ring",
		"main.ring",
		"src/webview.ring",
		"src/webview.rh",
		"src/utils/color.ring",
		"src/utils/install.ring",
		"src/utils/uninstall.ring",
		"examples/01_basic.ring",
		"examples/02_navigate.ring",
		"examples/03_local_html.ring",
		"examples/assets/index.html",
		"examples/04_callbacks.ring",
		"examples/05_inject_eval_callback.ring",
		"examples/06_digital_clock.ring",
		"examples/07_form_input.ring",
		"examples/08_counter_sync.ring",
		"examples/09_showcase.ring",
		"examples/10_theme_switcher.ring",
		"examples/11_unbind.ring",
		"examples/12_color_palette.ring",
		"examples/13_qr_code_generator.ring",
		"examples/14_chart.ring",
		"examples/15_login_form.ring",
		"examples/16_to_do_list.ring",
		"examples/17_live_markdown_editor.ring",
		"examples/assets/ring.js",
		"examples/18_http_fetch.ring",
		"examples/19_drawing.ring",
		"examples/20_tic_tac_toe.ring",
		"examples/21_bind_many.ring",
		"examples/22_using_class_methods.ring",
		"examples/23_threaded_counter.ring",
		"examples/24_using_dialog.ring",
		"examples/25_ringfetch.ring",
		"examples/26_webview_all_demo.ring",
		"examples/27_prayer_times.ring",
		"examples/28_chat_bot.ring",
		"examples/29_mock_pos.ring",
		"examples/30_quote_generator.ring",
		"examples/31_avatar_quotes.ring",
		"examples/32_using_weblib.ring",
		"examples/33_adhkar_counter.ring",
		"examples/34_ring_playground.ring",
		"examples/35_notes.ring",
		"examples/36_file_explorer.ring",
		"examples/37_weather_app.ring",
		"README.md",
		"docs/REFERENCE.md",
		"docs/USAGE.md",
		"LICENSE"
	],
	:ringfolderfiles = 	[

	],
	:windowsfiles = 	[
		"lib/windows/i386/ring_webview.dll",
		"lib/windows/amd64/ring_webview.dll",
		"lib/windows/arm64/ring_webview.dll"
	],
	:linuxfiles = 	[
		"lib/linux/amd64/libring_webview.so",
		"lib/linux/arm64/libring_webview.so"
	],
	:ubuntufiles = 	[

	],
	:fedorafiles = 	[

	],
	:freebsdfiles = 	[
		"lib/freebsd/amd64/libring_webview.so",
		"lib/freebsd/arm64/libring_webview.so"
	],
	:macosfiles = 	[
		"lib/macos/amd64/libring_webview.dylib",
		"lib/macos/arm64/libring_webview.dylib"
	],
	:windowsringfolderfiles = 	[

	],
	:linuxringfolderfiles = 	[

	],
	:ubunturingfolderfiles = 	[

	],
	:fedoraringfolderfiles = 	[

	],
	:freebsdringfolderfiles = 	[

	],
	:macosringfolderfiles = 	[

	],
	:run = "ring main.ring",
	:windowsrun = "",
	:linuxrun = "",
	:macosrun = "",
	:ubunturun = "",
	:fedorarun = "",
	:setup = "ring src/utils/install.ring",
	:windowssetup = "",
	:linuxsetup = "",
	:macossetup = "",
	:ubuntusetup = "",
	:fedorasetup = "",
	:remove = "ring src/utils/uninstall.ring",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = ""
]