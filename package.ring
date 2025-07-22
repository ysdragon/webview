aPackageInfo = [
	:name = "webview",
	:description = "A powerful Ring library for building modern, cross-platform desktop applications with web technologies and Ring.",
	:folder = "webview",
	:developer = "ysdragon",
	:email = "youssefelkholey@gmail.com",
	:license = "MIT License",
	:version = "1.0.0",
	:ringversion = "1.23",
	:versions = 	[
		[
			:version = "1.0.0",
			:branch = "main"
		]
	],
	:libs = 	[
		[
			:name = "",
			:version = "",
			:providerusername = ""
		]
	],
	:files = 	[
		"src/ring_webview.c",
		"CMakeLists.txt",
		"lib.ring",
		"main.ring",
		"src/webview.ring",
		"src/webview.rh",
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
		"examples/15_color_palette.ring",
		"examples/16_qr_code_generator.ring",
		"examples/17_chart.ring",
		"examples/18_http_fetch.ring",
		"examples/19_quote_generator.ring",
		"examples/20_avatar_quotes.ring",
		"src/utils/color.ring",
		"src/utils/install.ring",
		"README.md",
		"docs/REFERENCE.md",
		"docs/USAGE.md",
		"LICENSE"
	],
	:ringfolderfiles = 	[

	],
	:windowsfiles = 	[
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
	:remove = "",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = ""
]