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

# Vendored zlib v1.3.1 — DEFLATE compression for the .ddp data blobs.
# Suppress install rules and exclude from ALL so its own example
# binaries don't build unless something depends on them.
set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory(vendor/zlib EXCLUDE_FROM_ALL)
# zlib's CMakeLists builds `zlib` (shared) and `zlibstatic` (static).
# We link the static one — keeps DataManage.exe single-file and
# avoids the dance of shipping zlib1.dll alongside the binary.

# Vendored mbedTLS v3.6.2 — SHA-256 (Stage 5+), ECDSA P-256 signing
# (Stage 6), AES-256-GCM + ECDH (Stage 7), X.509 chain validation
# (Stage 6/8). Replaces the Windows CNG path so the crypto stack is
# fully readable source — portable to non-Windows later if we want.
set(ENABLE_PROGRAMS               OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTING                OFF CACHE BOOL "" FORCE)
set(USE_SHARED_MBEDTLS_LIBRARY    OFF CACHE BOOL "" FORCE)
set(USE_STATIC_MBEDTLS_LIBRARY    ON  CACHE BOOL "" FORCE)
set(MBEDTLS_FATAL_WARNINGS        OFF CACHE BOOL "" FORCE)
set(DISABLE_PACKAGE_CONFIG_AND_INSTALL ON CACHE BOOL "" FORCE)
add_subdirectory(vendor/mbedtls EXCLUDE_FROM_ALL)
# mbedTLS creates three targets: mbedcrypto (primitives), mbedx509
# (cert parsing), mbedtls (SSL/TLS). We link the first two; we have
# no TLS connections to make so mbedtls proper is unused.

# WIN32 subsystem: no console window pops on launch. The exe falls back
# to AttachConsole(ATTACH_PARENT_PROCESS) when invoked from a shell with
# positional args (CLI mode). See src/main.cpp.
add_executable(DataManage WIN32
    src/main.cpp
    src/app.cpp
    src/cli.cpp
    src/compress.cpp
    src/config.cpp
    src/manifest.cpp
    src/packer.cpp
    src/sha256.cpp
    src/signer.cpp
    resources/app.rc
)

target_include_directories(DataManage PRIVATE src)
target_link_libraries(DataManage PRIVATE nlohmann_json zlibstatic)
# zlib's own include dirs need to reach our compress.cpp — zlibstatic
# carries them transitively, but EXCLUDE_FROM_ALL strips transitive
# usage requirements from the install side. The library targets
# themselves still export INTERFACE_INCLUDE_DIRECTORIES, so the link
# alone is enough; this comment is just a marker for future readers.

# rc.exe needs to find app.manifest as a sibling of app.rc. CMake invokes
# rc from the build dir, so point it at the source dir explicitly.
set_source_files_properties(resources/app.rc PROPERTIES
    COMPILE_FLAGS "/I\"${CMAKE_CURRENT_SOURCE_DIR}/resources\"")

target_link_libraries(DataManage PRIVATE
    comctl32      # themed Common Controls v6 (status bar, etc.)
    user32        # CreateWindowEx, MessageBox, ...
    gdi32         # DrawText, SetTextColor, ...
    shell32       # CommandLineToArgvW
    comdlg32      # GetOpenFileName
    mbedcrypto    # SHA-256 today; ECDSA/AES-GCM/ECDH in Stage 6/7
    mbedx509      # X.509 cert parsing + chain validation (Stage 6+)
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

# Console-subsystem smoke tests. Each builds alongside the main GUI
# target; both pipe stdout/stderr normally so PowerShell / CI gets
# clean output. Exit 0 on success, non-zero on any assertion failure.
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

add_executable(packer_smoke_test
    src/packer_smoke_test.cpp
    src/compress.cpp
    src/config.cpp
    src/manifest.cpp
    src/packer.cpp
    src/sha256.cpp
    src/signer.cpp
)
target_include_directories(packer_smoke_test PRIVATE src)
target_link_libraries(packer_smoke_test PRIVATE
    nlohmann_json
    zlibstatic
    mbedcrypto
    mbedx509
)
set_target_properties(packer_smoke_test PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY                "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin"
)
