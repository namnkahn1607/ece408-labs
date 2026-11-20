cmake_minimum_required(VERSION 3.28)

set(CMAKE_CUDA_ARCHITECTURES 86)

project(ece408_labs LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Enable ncu/compute-sanitizer mapping SASS back to source lines.
string(APPEND CMAKE_CUDA_FLAGS " -lineinfo")

# Always from the Debug tree.
if(CMAKE_EXPORT_COMPILE_COMMANDS AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    file(CREATE_LINK "${CMAKE_BINARY_DIR}/compile_commands.json"
                     "${CMAKE_SOURCE_DIR}/compile_commands.json" SYMBOLIC)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(Lab)

enable_testing()
add_subdirectory(common)
add_subdirectory(thirdparty)
add_subdirectory(code)
