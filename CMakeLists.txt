cmake_minimum_required(VERSION 3.16)
project(RingWebView)

include(FetchContent)

set(RING_ROOT_DEFAULT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
if(DEFINED ENV{RING})
    set(RING_ROOT_DEFAULT "$ENV{RING}")
endif()
set(RING_ROOT "${RING_ROOT_DEFAULT}" CACHE PATH "Path to the Ring project root directory.")
message(STATUS "Using Ring from: ${RING_ROOT}")

if(NOT TARGET Ring::Ring)
    add_library(Ring::Ring UNKNOWN IMPORTED)
    find_path(RING_INCLUDE_DIR ring.h PATHS "${RING_ROOT}/language/include")
    find_library(RING_LIBRARY_PATH NAMES ring PATHS "${RING_ROOT}/lib")

    if(NOT RING_INCLUDE_DIR OR NOT RING_LIBRARY_PATH)
        message(FATAL_ERROR "Could not find Ring headers or library in ${RING_ROOT}. "
                            "Please set the RING_ROOT cache variable correctly.")
    endif()

    set_target_properties(Ring::Ring PROPERTIES
        IMPORTED_LOCATION "${RING_LIBRARY_PATH}"
        INTERFACE_INCLUDE_DIRECTORIES "${RING_INCLUDE_DIR}"
    )
endif()

# Set paths
set(RING_INCLUDE "${RING_ROOT}/language/include")
set(RING_LIB "${RING_ROOT}/lib")
set(RING_BIN "${RING_ROOT}/bin")

set(RING_WEBVIEW_C_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/src/c_src/ring_webview.c")
set(RING_WEBVIEW_MACOS_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/src/c_src/ring_webview_macos.m")

# Determine OS and Architecture specific paths
string(TOLOWER "${CMAKE_SYSTEM_NAME}" OS_DIR)
if(OS_DIR STREQUAL "darwin")
    set(OS_DIR "macos")
endif()

string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" ARCH_DIR_RAW)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND DEFINED CMAKE_GENERATOR_PLATFORM)
    if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
        set(ARCH_DIR_RAW "i386")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
        set(ARCH_DIR_RAW "amd64")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
        set(ARCH_DIR_RAW "arm64")
    else()
        message(WARNING "Unsupported CMAKE_GENERATOR_PLATFORM: ${CMAKE_GENERATOR_PLATFORM}, falling back to CMAKE_SYSTEM_PROCESSOR")
    endif()
endif()

if(NOT DEFINED ARCH_DIR)
    if(ARCH_DIR_RAW MATCHES "x86_64|amd64")
        set(ARCH_DIR "amd64")
    elseif(ARCH_DIR_RAW MATCHES "aarch64|arm64")
        set(ARCH_DIR "arm64")
    elseif(ARCH_DIR_RAW MATCHES "riscv64")
        set(ARCH_DIR "riscv64")
    elseif(ARCH_DIR_RAW MATCHES "i386|i686|x8x")
        set(ARCH_DIR "i386")
    else()
        set(ARCH_DIR "${ARCH_DIR_RAW}")
        message(WARNING "Unsupported architecture: ${ARCH_DIR_RAW}. Using as directory name.")
    endif()
endif()

# Detect musl libc
option(MUSL "Build for musl libc" OFF)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # Auto-detect musl if not explicitly set
    if(NOT MUSL)
        execute_process(
            COMMAND ldd --version
            OUTPUT_VARIABLE LDD_OUTPUT
            ERROR_VARIABLE LDD_OUTPUT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(LDD_OUTPUT MATCHES "musl")
            set(MUSL ON)
            message(STATUS "Detected musl libc")
        endif()
    endif()
endif()

# Set the destination directory for the built library
if(MUSL AND OS_DIR STREQUAL "linux")
    set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/musl/${ARCH_DIR}")
else()
    set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/${ARCH_DIR}")
endif()

# Configure webview build options
set(WEBVIEW_BUILD_SHARED_LIBRARY OFF)
set(BUILD_TESTING OFF CACHE BOOL "Disable building tests for webview")

# Explicitly set WebKitGTK API version for Linux and FreeBSD (6.0 = webkitgtk-6.0/GTK4)
if(CMAKE_SYSTEM_NAME STREQUAL "Linux"  OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    set(WEBVIEW_WEBKITGTK_API "6.0" CACHE STRING "WebKitGTK API version")
endif()

# Add webview as a subdirectory to build it
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/c_src/webview/CMakeLists.txt")
    message(STATUS "webview source not found, fetching from GitHub...")
    FetchContent_Declare(
        webview
        GIT_REPOSITORY https://github.com/webview/webview.git
        GIT_TAG        master
    )
    FetchContent_MakeAvailable(webview)
else()
    message(STATUS "webview found locally, adding as subdirectory.")
    add_subdirectory(src/c_src/webview)
endif()

# Create the Ring webview extension shared library
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	add_library(ring_webview SHARED
		${RING_WEBVIEW_C_SOURCE}
		${RING_WEBVIEW_MACOS_SOURCE}
	)
else()
	add_library(ring_webview SHARED
		${RING_WEBVIEW_C_SOURCE}
	)
endif()

# Include directories
target_include_directories(ring_webview PRIVATE
	${RING_INCLUDE}
)

# Link libraries
target_link_libraries(ring_webview PRIVATE
	Ring::Ring
	webview::core_static
)

# Add libadwaita for Linux and FreeBSD
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
	find_package(PkgConfig REQUIRED)
	pkg_check_modules(LIBADWAITA REQUIRED IMPORTED_TARGET libadwaita-1)
	target_link_libraries(ring_webview PRIVATE PkgConfig::LIBADWAITA)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
	target_link_libraries(ring_webview PRIVATE
		"-framework Cocoa"
		"-framework WebKit"
	)
endif()

target_compile_options(ring_webview PRIVATE
    $<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:
        $<$<C_COMPILER_ID:MSVC>:/O2>
        $<$<NOT:$<C_COMPILER_ID:MSVC>>:-O3>
        -DNDEBUG
    >
)

# Set target properties for output name and prefix
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set_target_properties(ring_webview PROPERTIES
		OUTPUT_NAME "ring_webview"
	)
else()
	set_target_properties(ring_webview PROPERTIES
		PREFIX "lib"
		OUTPUT_NAME "ring_webview"
	)
endif()

# Move built library to lib directory
add_custom_command(
	TARGET ring_webview
	POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E make_directory ${LIB_DEST_DIR}
	COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:ring_webview> ${LIB_DEST_DIR}/$<TARGET_FILE_NAME:ring_webview>
	COMMENT "Moving built library to ${LIB_DEST_DIR}"
	VERBATIM
)

# Copy to bin directory on Windows
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	add_custom_command(
		TARGET ring_webview
		POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E make_directory ${RING_BIN}
		COMMAND ${CMAKE_COMMAND} -E copy ${LIB_DEST_DIR}/$<TARGET_FILE_NAME:ring_webview> ${RING_BIN}/$<TARGET_FILE_NAME:ring_webview>
		COMMENT "Copying built library to bin directory"
		VERBATIM
	)
endif()

install(TARGETS ring_webview
    LIBRARY DESTINATION "${RING_ROOT}/lib"
)

message(STATUS "Ring Webview Extension Configuration:")
message(STATUS "  - Ring Include Dir: ${RING_INCLUDE_DIR}")
message(STATUS "  - Ring Library Path: ${RING_LIBRARY_PATH}")