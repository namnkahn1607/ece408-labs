cmake_minimum_required(VERSION 3.28)

set(CMAKE_CUDA_ARCHITECTURES 86)

project(cs483_labs LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CUDA_STANDARD 20)

# Always from the Debug tree.
if(CMAKE_EXPORT_COMPILE_COMMANDS AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    file(CREATE_LINK "${CMAKE_BINARY_DIR}/compile_commands.json"
                     "${CMAKE_SOURCE_DIR}/compile_commands.json" SYMBOLIC)
endif()

add_subdirectory(thirdparty)
