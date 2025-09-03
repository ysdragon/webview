aPackageInfo = [
	:name = "webview",
	:description = "A powerful Ring library for building modern, cross-platform desktop applications with web technologies and Ring.",
	:folder = "webview",
	:developer = "ysdragon",
	:email = "youssefelkholey@gmail.com",
	:license = "MIT License",
	:version = "1.3.5",
	:ringversion = "1.23",
	:versions = 	[
		[
			:version = "1.3.5",
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
			:name = "jsonlib",
			:version = "1.0.16",
			:providerusername = "ringpackages"
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
		"examples/06_showcase.ring",
		"examples/07_digital_clock.ring",
		"examples/08_counter_sync.ring",
		"examples/09_form_input.ring",
		"examples/10_login_form.ring",
		"examples/11_theme_switcher.ring",
		"examples/12_unbind.ring",
		"examples/13_to_do_list.ring",
		"examples/14_live_markdown_editor.ring",
		"examples/assets/ring.js",
		"examples/15_color_palette.ring",
		"examples/16_qr_code_generator.ring",
		"examples/17_chart.ring",
		"examples/18_http_fetch.ring",
		"examples/19_quote_generator.ring",
		"examples/20_avatar_quotes.ring",
		"examples/21_prayer_times.ring",
		"examples/22_chat_bot.ring",
		"examples/23_mock_pos.ring",
		"examples/24_ringfetch.ring",
		"examples/25_drawing.ring",
		"examples/26_using_weblib.ring",
		"examples/27_adhkar_counter.ring",
		"examples/28_ring_playground.ring",
		"examples/29_notes.ring",
		"examples/30_bind_many.ring",
		"examples/31_threaded_counter.ring",
		"examples/32_tic_tac_toe.ring",
		"examples/33_webview_all_demo.ring",
		"examples/34_using_class_methods.ring",
		"examples/35_using_dialog.ring",
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