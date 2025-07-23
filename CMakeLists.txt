cmake_minimum_required(VERSION 3.16)
project(RingWebview)

include(FetchContent)

# Get the Ring source directory from environment or use default
if(NOT DEFINED ENV{RING})
	set(RING "${CMAKE_CURRENT_SOURCE_DIR}/../..")
	message(STATUS "RING not defined, using default: ${RING}")
else()
	set(RING $ENV{RING})
	message(STATUS "Using RING from environment: ${RING}")
endif()

# Set paths
set(RING_INCLUDE "${RING}/language/include")
set(RING_LIB "${RING}/lib")
set(RING_BIN "${RING}/bin")

set(RING_WEBVIEW_C_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/src/ring_webview.c")

# Determine OS and Architecture specific paths
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(OS_DIR "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    set(OS_DIR "freebsd")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(OS_DIR "windows")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(OS_DIR "macos")
else()
    message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

# Determine architecture
if(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND DEFINED CMAKE_GENERATOR_PLATFORM)
    if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
        set(ARCH_DIR "i386")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
        set(ARCH_DIR "amd64")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
        set(ARCH_DIR "arm64")
    else()
        message(WARNING "Unsupported CMAKE_GENERATOR_PLATFORM: ${CMAKE_GENERATOR_PLATFORM}, falling back to CMAKE_SYSTEM_PROCESSOR")
    endif()
endif()

# Fallback to CMAKE_SYSTEM_PROCESSOR if ARCH_DIR is not set
if(NOT DEFINED ARCH_DIR)
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" CMAKE_SYSTEM_PROCESSOR_LC)
    if(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "i386|i686|x86")
        set(ARCH_DIR "i386")
    elseif(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "x86_64|amd64")
        set(ARCH_DIR "amd64")
    elseif(CMAKE_SYSTEM_PROCESSOR_LC MATCHES "aarch64|arm64")
        set(ARCH_DIR "arm64")
    else()
        message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
    endif()
endif()

# Set the destination directory for the built library
set(LIB_DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib/${OS_DIR}/${ARCH_DIR}")

# Configure webview build options
set(WEBVIEW_BUILD ON)
set(WEBVIEW_BUILD_SHARED_LIBRARY OFF)
set(WEBVIEW_BUILD_STATIC_LIBRARY ON)
set(WEBVIEW_BUILD_EXAMPLES OFF)
set(WEBVIEW_BUILD_TESTS OFF)
set(WEBVIEW_INSTALL_TARGETS OFF)
set(WEBVIEW_ENABLE_PACKAGING OFF)

# Add webview as a subdirectory to build it
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/webview/CMakeLists.txt")
    message(STATUS "webview source not found, fetching from GitHub...")
    FetchContent_Declare(
        webview
        GIT_REPOSITORY https://github.com/webview/webview.git
        GIT_TAG        master
    )
    FetchContent_MakeAvailable(webview)
else()
    add_subdirectory(src/webview)
endif()

# Create the Ring webview extension shared library
add_library(ring_webview SHARED
	${RING_WEBVIEW_C_SOURCE}
)

# Include directories
target_include_directories(ring_webview PRIVATE
	${RING_INCLUDE}
	${webview_SOURCE_DIR}/core/include
)

# Determine Ring library based on OS
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	set(RING_LIB_NAME "${RING_LIB}/ringstatic.lib")
else()
	set(RING_LIB_NAME "${RING_LIB}/libring${CMAKE_SHARED_LIBRARY_SUFFIX}")
endif()

# Link libraries - now linking against our locally built static webview
target_link_libraries(ring_webview
	${RING_LIB_NAME}
	webview::core_static
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

# Move the built library to the OS/architecture-specific directory after build
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    add_custom_command(
        TARGET ring_webview
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${LIB_DEST_DIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${RING_BIN}
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:ring_webview> ${RING_BIN}/
        COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:ring_webview> ${LIB_DEST_DIR}/$<TARGET_FILE_NAME:ring_webview>
        COMMENT "Moving library to ${LIB_DEST_DIR} and copying to ${RING_BIN}"
        VERBATIM
    )
else()
    add_custom_command(
        TARGET ring_webview
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${LIB_DEST_DIR}
        COMMAND ${CMAKE_COMMAND} -E rename $<TARGET_FILE:ring_webview> ${LIB_DEST_DIR}/$<TARGET_FILE_NAME:ring_webview>
        COMMENT "Moving built library to ${LIB_DEST_DIR}"
        VERBATIM
    )
endif()

# Install rule
get_filename_component(NORMALIZED_RING_LIB "${RING_LIB}" ABSOLUTE)
install(TARGETS ring_webview
	LIBRARY DESTINATION ${NORMALIZED_RING_LIB}
)

# Print info message
message(STATUS "Ring Webview Extension Configuration:")
message(STATUS "  - Ring Include Dir: ${RING_INCLUDE}")
message(STATUS "  - Ring Library Dir: ${RING_LIB}")
