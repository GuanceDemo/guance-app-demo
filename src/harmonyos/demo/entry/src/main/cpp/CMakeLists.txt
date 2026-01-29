    # CMakeLists.txt for FT Crash Native Module

cmake_minimum_required(VERSION 3.4.1)
project(FTCrash)

# Set NDK API level
set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

# Add source files
set(SOURCE_LIST
    ft_crash_napi.cpp
    CrashTest.cpp
)

# Define the native library
add_library(ftcrash SHARED ${SOURCE_LIST})

# Include directories
target_include_directories(ftcrash PRIVATE
    ${NATIVERENDER_ROOT_PATH}
    ${OH_SDK_NATIVE_PATH}/include
)

# Link libraries
target_link_libraries(ftcrash PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# Set output directory
set_target_properties(ftcrash PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}
)
