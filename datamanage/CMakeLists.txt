cmake_minimum_required(VERSION 3.20)
project(DataManage VERSION 0.1.0 LANGUAGES CXX RC)

# C++20 — std::filesystem, ranges, designated initializers. MSVC 19.30+
# (VS 2022 17.0+) is fine. Both x64 and x86 (Win32) targets supported.
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

if(MSVC)
    # /utf-8 makes string literals UTF-8 regardless of source encoding —
    # important because manifest entries and pack paths may be non-ASCII.
    # /permissive- enforces standard C++.
    add_compile_options(/W4 /utf-8 /permissive- /Zc:__cplusplus)
    add_compile_definitions(
        _CRT_SECURE_NO_WARNINGS
        NOMINMAX
        WIN32_LEAN_AND_MEAN
        UNICODE
        _UNICODE
    )
endif()

# Vendored single-header JSON library — used by manifest.cpp to
# round-trip the .ddp manifest. INTERFACE library: header-only, no
# compiled translation units.
add_library(nlohmann_json INTERFACE)
target_include_directories(nlohmann_json INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/vendor/nlohmann_json
)

# Future vendored libraries (each lands offline in its own stage):
#   add_subdirectory(vendor/mbedtls)            # Stage 4, 6, 7
#   add_subdirectory(vendor/zstd/build/cmake)   # Stage 4

# WIN32 subsystem: no console window pops on launch. The exe falls back
# to AttachConsole(ATTACH_PARENT_PROCESS) when invoked from a shell with
# positional args (CLI mode). See src/main.cpp.
add_executable(DataManage WIN32
    src/main.cpp
    src/app.cpp
    src/cli.cpp
    src/manifest.cpp
    resources/app.rc
)

target_include_directories(DataManage PRIVATE src)
target_link_libraries(DataManage PRIVATE nlohmann_json)

# rc.exe needs to find app.manifest as a sibling of app.rc. CMake invokes
# rc from the build dir, so point it at the source dir explicitly.
set_source_files_properties(resources/app.rc PROPERTIES
    COMPILE_FLAGS "/I\"${CMAKE_CURRENT_SOURCE_DIR}/resources\"")

target_link_libraries(DataManage PRIVATE
    comctl32   # themed Common Controls v6 (status bar, etc.)
    user32     # CreateWindowEx, MessageBox, ...
    gdi32      # DrawText, SetTextColor, ...
    shell32    # CommandLineToArgvW
)

# MSVC auto-injects its own RT_MANIFEST resource. We supply ours via
# resources/app.rc (Common Controls v6 + PerMonitorV2 DPI + UTF-8 active
# code page), so disable the auto-generated one to avoid CVT1100
# "duplicate resource. type:MANIFEST" at link time.
if(MSVC)
    target_link_options(DataManage PRIVATE /MANIFEST:NO)
endif()

set_target_properties(DataManage PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY                "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin"
)

# Console-subsystem smoke test for the manifest round-trip. Built
# alongside the main GUI target; pipes stdout/stderr normally so CI
# (and humans running it from PowerShell) get clean output. Exits 0
# on success, non-zero on any assertion failure.
add_executable(manifest_smoke_test
    src/manifest_smoke_test.cpp
    src/manifest.cpp
)
target_include_directories(manifest_smoke_test PRIVATE src)
target_link_libraries(manifest_smoke_test PRIVATE nlohmann_json)
set_target_properties(manifest_smoke_test PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY                "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin"
)
