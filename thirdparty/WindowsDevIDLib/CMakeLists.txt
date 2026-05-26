# WindowsDevIDLib -- produces WindowsDevID.dll, the Windows
# counterpart of AndroidDevIDLib. See README.md for the design.
#
# Toolchain (matches the Flutter Windows runner: VS2022 + the same
# Windows SDK Flutter requires):
#   * CMake 3.22+
#   * MSVC v143 (VS 2022 17.4+)
#   * Windows SDK 10.0.19041+
#   * /MD dynamic CRT (default) -- same as flutter_app/windows
#     runner, so a future bundling step won't double-link the CRT.

cmake_minimum_required(VERSION 3.22)
project(WindowsDevID LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(WindowsDevID SHARED
    src/windevid.cpp
    src/windevid.h
)

target_include_directories(WindowsDevID PUBLIC src)

target_compile_definitions(WindowsDevID PRIVATE
    WINDEVID_EXPORTS
    UNICODE
    _UNICODE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)

# SHA-256 lives in Windows CNG -- no third-party crypto dependency.
target_link_libraries(WindowsDevID PRIVATE bcrypt)

# MSVC: enable a sensible warning level and treat warnings as errors
# so the .dll only ships when the source is clean.
if(MSVC)
    target_compile_options(WindowsDevID PRIVATE /W4 /WX /permissive-)
endif()

# Force the artifact name to WindowsDevID.dll across every generator
# (Ninja with the gcc-style driver would otherwise prefix `lib`).
set_target_properties(WindowsDevID PROPERTIES PREFIX "")
