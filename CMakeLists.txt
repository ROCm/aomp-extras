cmake_minimum_required(VERSION 3.0 FATAL_ERROR)

set(PREPARE_BUILTINS "${CMAKE_CURRENT_BINARY_DIR}/utils/prepare-builtins")
set(AOMPEXTRAS_BC_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/aomp-device-libs/aompextras")
add_subdirectory(utils)
add_subdirectory(aomp-device-libs)
add_subdirectory(hostcall)
