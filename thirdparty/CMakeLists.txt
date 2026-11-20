set(WB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libwb")
if(NOT EXISTS "${WB_DIR}/wb.h")
  message(FATAL_ERROR "libwb missing. Run: git submodule update --init --recursive")
endif()

find_package(CUDAToolkit REQUIRED)

file(GLOB WB_SOURCES CONFIGURE_DEPENDS "${WB_DIR}/*.cpp")
list(FILTER WB_SOURCES EXCLUDE REGEX "(_test|wbMPI)\\.cpp$")   # unit tests, MPI support

add_library(wb STATIC ${WB_SOURCES})

set_target_properties(wb PROPERTIES CXX_STANDARD 14 CXX_STANDARD_REQUIRED ON)
target_include_directories(wb SYSTEM PUBLIC "${WB_DIR}")
target_compile_options(wb PRIVATE -w)              # third-party warnings are not to fix
target_link_libraries(wb PUBLIC CUDA::cudart)
# First build may need: vendor/*.c(pp) added to the glob (undefined symbols), pthread, etc.
