cmake_minimum_required(VERSION 3.20)
project(DataManage VERSION 0.1.0 LANGUAGES CXX)

# C++20 — needed for std::filesystem path::u8string, ranges, designated
# initializers, and source_location. MSVC 19.30+ (VS 2022 17.0+) is fine.
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Force a real release build by default when CMake is invoked without
# --config (i.e. via the Ninja generator or VS Open Folder).
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "" FORCE)
endif()

if(MSVC)
    # /utf-8 makes string literals UTF-8 regardless of source encoding —
    # important for any non-ASCII paths we'll see during packing.
    # /permissive- enforces standard C++, no MSVC quirks.
    add_compile_options(/W4 /utf-8 /permissive- /Zc:__cplusplus)
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX WIN32_LEAN_AND_MEAN)
endif()

# Vendored third-party libraries get pulled in here in later stages.
# Each lands under vendor/<name>/ and is committed to the repo so the
# project builds offline on a fresh Windows 10 machine.
#
#   add_subdirectory(vendor/mbedtls)           # Stage 4, 6, 7
#   add_subdirectory(vendor/zstd/build/cmake)  # Stage 4
#   add_subdirectory(vendor/nlohmann_json)     # Stage 2

add_executable(DataManage
    src/main.cpp
    src/cli.cpp
)

target_include_directories(DataManage PRIVATE src)

# Where the .exe lands. Keeps the output predictable for the README and
# for any scripts the admin builds around it.
set_target_properties(DataManage PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY            "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG      "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE    "${CMAKE_BINARY_DIR}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_BINARY_DIR}/bin"
)
