##===----------------------------------------------------------------------===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is dual licensed under the MIT and the University of Illinois Open
# Source Licenses. See LICENSE.txt for details.
##===----------------------------------------------------------------------===##
#
# aomp-extras/libm/libdevice/CMakeLists.txt
# Written by Greg Rodgers (Gregory.Rodgers@amd.com)
#
##===----------------------------------------------------------------------===##

cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  project(libm-project)
  message("--------------------------------------------")
endif()

# find the llvm compiler
find_package(LLVM QUIET CONFIG
  PATHS
  ${CMAKE_INSTALL_PREFIX}
  ${AOMP}
  ${CMAKE_CXX_COMPILER_DIR}
  NO_DEFAULT_PATH
)

if (LLVM_DIR)
  message("   -- Building libm libdevice with LLVM ${LLVM_PACKAGE_VERSION} found at ${LLVM_INSTALL_PREFIX}")
else()
  message("   ERROR: NO LLVM FOUND! Not building libm libdevice.")
  return()
endif()

#optimization level
set(optimization_level 2)

set(OUTPUTDIR ${CMAKE_CURRENT_BINARY_DIR})

macro(build_static_device_bc_lib)
foreach(mcpu ${gpulist})
  set(cpu_target x86_64-pc-linux-gnu)
  if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "ppc64le")
    set(cpu_target powerpc64le-linux-gnu)
  endif()

  set(omp_common_args
    -c 
    -fvisibility=hidden
    -emit-llvm
    -target ${cpu_target}
    -fopenmp 
    -fopenmp-targets=${triple}
    -Xopenmp-target=${triple}
    -march=${mcpu}
    --cuda-device-only
    -nocudalib
    -O${optimization_level})

  if(NOT ${AOMP_STANDALONE_BUILD})
    #FIXME Remove NEW_BC_PATH along with reference to /lib/bitcode when non-standalone build switches to new amdgcn path.
    if(${NEW_BC_PATH})
      set(BC_DIR ${ROCM_DIR}/amdgcn/bitcode)
    else()
      set(BC_DIR ${ROCM_DIR}/lib/bitcode)
    endif()
    set(omp_common_args "${omp_common_args};--hip-device-lib-path=${BC_DIR}")
  endif(NOT ${AOMP_STANDALONE_BUILD})

  set(openmp_c_cmd ${LLVM_INSTALL_PREFIX}/bin/clang ${omp_common_args}
      ${CMAKE_CURRENT_SOURCE_DIR}/src/libm.c)

  add_custom_command(
      OUTPUT libm-${systemarch}-${mcpu}.bc
      COMMAND ${openmp_c_cmd} -o ${OUTPUTDIR}/libm-${systemarch}-${mcpu}.bc
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/libm.c"
  )
  add_custom_target(libm-${systemarch}-${mcpu} ALL DEPENDS libm-${systemarch}-${mcpu}.bc)
  install(FILES ${OUTPUTDIR}/libm-${systemarch}-${mcpu}.bc 
     DESTINATION "lib/libdevice")
  install(FILES ${OUTPUTDIR}/libm-${systemarch}-${mcpu}.bc 
     DESTINATION "lib-debug/libdevice")
endforeach()
endmacro()

# Get list of AMD GPUs to build for 
set(gfxgpus $ENV{GFXLIST})
if(gfxgpus)
  message("   -- Building for devices specified by GFXLIST: ${gfxgpus}")
else()
  set(gfxgpus gfx700 gfx701 gfx801 gfx803 gfx900)
  message("   -- Building default set of AMD GPUs: ${gfxgpus}")
  message("   -- You may override default with GFXLIST environment variable ")
endif()
separate_arguments(gfxgpus)
# prepare variables used by build_static_device_bc_lib
set(triple "amdgcn-amd-amdhsa")
set(systemarch "amdgcn")
set(gpulist ${gfxgpus})
build_static_device_bc_lib()

set(nvptx_numbers $ENV{NVPTXGPUS})
if(NOT nvptx_numbers)
  set(nvptx_numbers "30,35,50,60,61,70")
endif()

set(nvptxgpus)
string(REGEX REPLACE "," ";" nvptx_numbers_list ${nvptx_numbers})
foreach(sm_number ${nvptx_numbers_list})
   list(APPEND nvptxgpus "sm_${sm_number}")
endforeach()

# prepare variables used by build_static_device_bc_lib
set(gpulist ${nvptxgpus})
set(systemarch "nvptx")
set(triple "nvptx64-nvidia-cuda ")
build_static_device_bc_lib()

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  message("--------------------------------------------")
endif()
