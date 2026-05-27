# Builds libdevid.so — the JNI bridge plus the /proc/cpuinfo reader.
cmake_minimum_required(VERSION 3.22.1)
project(devid LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(devid SHARED
    devid.cpp
    devid_jni.cpp
)

# Android NDK ships a stripped-down stdlib; link only what we use.
find_library(log-lib log)
target_link_libraries(devid PRIVATE ${log-lib})

# Strip symbols on release for a smaller .so.
target_compile_options(devid PRIVATE
    $<$<CONFIG:Release>:-fdata-sections -ffunction-sections>
)
target_link_options(devid PRIVATE
    $<$<CONFIG:Release>:-Wl,--gc-sections -Wl,--strip-all>
)
