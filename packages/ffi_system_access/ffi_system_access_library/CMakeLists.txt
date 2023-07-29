cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(ffi_system_access VERSION 1.0.0 LANGUAGES C)
add_library(ffi_system_access_library SHARED ffi_system_access.c ffi_system_access.def)
add_executable(ffi_system_access_test ffi_system_access.c)
set(CMAKE_OSX_ARCHITECTURES "arm64")
option(USE_CLANG "build application with clang" ON)
set(CMAKE_HOST_SYSTEM_PROCESSOR "arm64")
set(CMAKE_SYSTEM_PROCESSOR "arm64")
set(CMAKE_SYSTEM_PROCESSOR TRUE)
set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE INTERNAL "" FORCE)

set_target_properties(ffi_system_access_library PROPERTIES
    PUBLIC_HEADER ffi_system_access.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "ffi_system_access"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)

message("CMAKE_OSX_ARCHITECTURES: ${CMAKE_OSX_ARCHITECTURES}")
message("CMAKE_HOST_SYSTEM_PROCESSOR: ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message("CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
message("CMAKE_CROSSCOMPILING: ${CMAKE_CROSSCOMPILING}")
