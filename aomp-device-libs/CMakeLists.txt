##===--------------------------------------------------------------------------
##                   ROCm Device Libraries
##
## This file is distributed under the University of Illinois Open Source
## License. See LICENSE.TXT for details.
##===--------------------------------------------------------------------------

cmake_minimum_required(VERSION 2.8)

cmake_policy(SET CMP0011 NEW)

# Build ROCM-Device-Libs with ccache if the package is present.
set(ROCM_DEVICE_LIBS_CCACHE_BUILD OFF CACHE BOOL "Set to ON for a ccache enabled build")
if(ROCM_DEVICE_LIBS_CCACHE_BUILD)
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_PROGRAM})
  else()
    message(FATAL_ERROR "Unable to find the program ccache. Set ROCM_DEVICE_LIBS_CCACHE_BUILD to OFF")
  endif()
endif()

#if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
#project(ROCm-Device-Libs)

#if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
#  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/dist CACHE INTERNAL "Prefix prepended to install directories")
#endif()

set(ROCDL "${CMAKE_CURRENT_SOURCE_DIR}/../../rocm-device-libs")

find_package(LLVM REQUIRED CONFIG HINTS ${LLVM_DIR})
list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(AddLLVM)

if (NOT DEFINED AMDGPU_TARGET_TRIPLE)
  set(AMDGPU_TARGET_TRIPLE "amdgcn-amd-amdhsa")
endif()

include(OCL.cmake)

set(AMDGCN_LIB_LIST)
set(AMDGCN_DEP_LIST)
add_subdirectory(irif)
# cuda2gcn and extra hip are merged into aompextras
add_subdirectory(aompextras)

#  I don't see why we need cudamath, so I am deleting for now. 
#add_subdirectory(cudamath)



