# KeyGenerator -- Qt 5 desktop tool for issuing X.509 leaf
# certificates that bind a device fingerprint to a license. See
# README.md and docs/0525/17_license_plan.md.
#
# Build with VS 2022 + CMake (run build_KeyGenerator.bat for a
# one-shot wrapper that locates VS, Qt5, OpenSSL, and vcpkg).

cmake_minimum_required(VERSION 3.22)
project(KeyGenerator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Qt boilerplate: moc / uic / rcc on, autogen in BUILD_DIR.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# ---------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------
# Qt5 -- pinned to 5.15 LTS but any 5.x with Widgets + Sql works.
find_package(Qt5 5.15 COMPONENTS Widgets Sql REQUIRED)

# OpenSSL -- libcrypto only, for X.509 signing. On Windows the
# vcpkg toolchain file usually does the discovery; otherwise set
# OPENSSL_ROOT_DIR before configuring.
find_package(OpenSSL 1.1.1 REQUIRED)

# Nayuki QR-Code-generator -- single-file public-domain C++ port,
# pulled at configure time so we don't vendor a 1500-line library
# into the repo. Pin to a release tag for reproducibility.
include(FetchContent)
FetchContent_Declare(
    nayuki_qr
    GIT_REPOSITORY https://github.com/nayuki/QR-Code-generator.git
    GIT_TAG v1.8.0
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(nayuki_qr)

# The upstream repo ships sources without a CMakeLists, so build it
# ourselves -- just the two C++ files under cpp/.
add_library(qrcodegen STATIC
    "${nayuki_qr_SOURCE_DIR}/cpp/qrcodegen.cpp"
)
target_include_directories(qrcodegen PUBLIC
    "${nayuki_qr_SOURCE_DIR}/cpp"
)
target_compile_features(qrcodegen PUBLIC cxx_std_17)

# ---------------------------------------------------------------
# Executable
# ---------------------------------------------------------------
add_executable(KeyGenerator WIN32
    src/main.cpp
    src/MainWindow.h
    src/MainWindow.cpp
    src/MainWindow.ui
    src/LeafCa.h
    src/LeafCa.cpp
    src/CertIssuer.h
    src/CertIssuer.cpp
    src/QrWriter.h
    src/QrWriter.cpp
    src/LicenseLog.h
    src/LicenseLog.cpp
)

target_include_directories(KeyGenerator PRIVATE src)

target_link_libraries(KeyGenerator PRIVATE
    Qt5::Widgets
    Qt5::Sql
    OpenSSL::Crypto
    qrcodegen
)

# Deploy Qt DLLs next to the exe on Windows so the build output is
# directly runnable. windeployqt lives under <QTDIR>/bin.
if(WIN32)
    get_target_property(_qmake_executable Qt5::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")
    if(WINDEPLOYQT_EXECUTABLE)
        add_custom_command(TARGET KeyGenerator POST_BUILD
            COMMAND "${WINDEPLOYQT_EXECUTABLE}"
                    --no-translations
                    --no-system-d3d-compiler
                    --no-opengl-sw
                    "$<TARGET_FILE:KeyGenerator>"
            COMMENT "Deploying Qt runtime DLLs next to KeyGenerator.exe")
    endif()
endif()

# MSVC: warning level + treat warnings as errors -- the project is
# small enough to keep clean. /utf-8 keeps string literals correct
# when the source files are UTF-8 (which they are).
if(MSVC)
    target_compile_options(KeyGenerator PRIVATE /W4 /WX /permissive- /utf-8)
endif()
