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

#  FIXME DELETE THESE COMMENTS
# Assome rocm-device-libs repository is next to aomp-extras repository
#set(ROCDL ${CMAKE_CURRENT_SOURCE_DIR}/../../../rocm-device-libs)
#set(ROCDL_INC_OCKL ${ROCDL}/ockl/inc)
#set(ROCDL_INC_OCML ${ROCDL}/ocml/inc)
#set(ROCDL_INC_IRIF ${ROCDL}/irif/inc)
#set(HIPINC ${CMAKE_CURRENT_SOURCE_DIR}/../../../hip/include)

#optimization level
set(optimization_level 2)

set(OUTPUTDIR ${CMAKE_CURRENT_BINARY_DIR})

macro(build_static_device_bc_lib)
foreach(mcpu ${gpulist})
	#  set(bundled_filename bundle_cpp.${mcpu}.bc)
	#  set(bundled_c_filename bundle_c.${mcpu}.bc)
  set(bc_filename libm_cpp.${mcpu}.bc)
  set(bc_c_filename libm_c.${mcpu}.bc)
  set(cpu_target x86_64-pc-linux-gnu)
  if(${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "ppc64le")
    set(cpu_target powerpc64le-linux-gnu)
  endif()

  set(omp_common_args
    -c 
    --cuda-device-only
    -target ${cpu_target}
    -fopenmp 
    -fopenmp-targets=${triple}
    -Xopenmp-target=${triple}
    -march=${mcpu}
    -emit-llvm 
    -DNO_LIBM_HEADER_DEFS=1
    -O${optimization_level}
    -I${CMAKE_CURRENT_SOURCE_DIR}/src
    -I${LLVM_LIBRARY_DIRS}/libdevice/include)
  set(openmp_cmd ${LLVM_INSTALL_PREFIX}/bin/clang++ -std=c++11 ${omp_common_args}
      ${CMAKE_CURRENT_SOURCE_DIR}/src/libm.cpp -o ${bc_filename})
  set(openmp_c_cmd ${LLVM_INSTALL_PREFIX}/bin/clang ${omp_common_args}
      ${CMAKE_CURRENT_SOURCE_DIR}/src/libm.c -o ${bc_c_filename})
  set(bc_files ${bc_filename} ${bc_c_filename})
  file(GLOB h_files "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h")

  # Compile cpp code with openmp to make bundled_filename 
  add_custom_command(
      OUTPUT ${bc_filename}
      COMMAND ${openmp_cmd}
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/libm.cpp" ${h_files})
  add_custom_command(
      OUTPUT ${bc_c_filename}
      COMMAND ${openmp_c_cmd}
      DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/libm.c" ${h_files})
  add_custom_command(
    OUTPUT libm-${systemarch}-${mcpu}.bc
    COMMAND ${LLVM_INSTALL_PREFIX}/bin/llvm-link ${bc_files} -o ${OUTPUTDIR}/libm-${systemarch}-${mcpu}.bc
    DEPENDS ${bc_files}
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
if(nvptx_numbers)
  message("   -- Building libm for nvptx GPUS set by NVPTXGPUS : ${nvptxgpu}")
else()
  set(nvptx_numbers "30,35,50,60,61,70")
  message("   -- Building default set of NVPTX GPUs: ${nvptx_numbers}")
  message("   -- You may override default with NVPTXGPUS environment variable ")
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
message(" ------------ SKIPPING nvptxgpus :${gpulist}")
#build_static_device_bc_lib()


if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  message("--------------------------------------------")
endif()
