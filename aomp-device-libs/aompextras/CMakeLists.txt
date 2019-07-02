##===----------------------------------------------------------------------===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is dual licensed under the MIT and the University of Illinois Open
# Source Licenses. See LICENSE.txt for details.
##===----------------------------------------------------------------------===##
#
# aomp-extras/aomp-device-libs/aompextras/CMakeLists.txt
#
##===----------------------------------------------------------------------===##

#  Try to get LLVM_COMPILER from HIP, then AOMP , then default /usr/local/hip
set(AOMP $ENV{AOMP})
if(AOMP)
  set(LLVM_COMPILER ${AOMP})
else()
  set(LLVM_COMPILER "$ENV{HOME}/rocm/aomp")
endif()

# Assome rocm-device-libs repository is next to hip repository 
set(ROCDL_INC_OCKL ${ROCDL}/ockl/inc)
set(ROCDL_INC_OCML ${ROCDL}/ocml/inc)
set(ROCDL_INC_IRIF ${CMAKE_CURRENT_SOURCE_DIR}/../irif/inc)

set(libname "aompextras")
project(${libname})

file(GLOB ll_sources "${CMAKE_CURRENT_SOURCE_DIR}/src/*.ll")
file(GLOB hip_auto_sources "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
file(GLOB hip_sources "${CMAKE_CURRENT_SOURCE_DIR}/src/*.hip")
file(GLOB ocl_sources "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cl")

get_target_property(irif_lib_output irif_lib OUTPUT_NAME)

#  OpenCL files are no longer gfx specific, so only build them one time
set(cl_cmd ${LLVM_COMPILER}/bin/clang
    -S -emit-llvm -Xclang -mlink-builtin-bitcode -Xclang "${irif_lib_output}"
    -DCL_VERSION_2_0=200 -D__OPENCL_C_VERSION__=200
    -Dcl_khr_fp64 -Dcl_khr_fp16
    -Dcl_khr_subgroups -Dcl_khr_int64_base_atomics -Dcl_khr_int64_extended_atomics
    -x cl -Xclang -cl-std=CL2.0 -Xclang -finclude-default-header
    -target amdgcn-amd-amdhsa
    -I${ROCDL_INC_OCKL}
    -I${ROCDL_INC_OCML}
    -I${ROCDL_INC_IRIF}
    -I${CMAKE_CURRENT_SOURCE_DIR}/src
    -I${LLVM_COMPILER}/include)
set(cl_ll_files)
foreach(file ${ocl_sources})
  file(RELATIVE_PATH rfile ${CMAKE_CURRENT_SOURCE_DIR}/src ${file})
  get_filename_component(fname ${rfile} NAME_WE)
  set(ll_filename ${fname}.ll)
  add_custom_command(
    OUTPUT ${ll_filename}
    COMMAND ${cl_cmd} ${file} -o ${ll_filename} 
    DEPENDS ${file} irif_lib)
  list(APPEND cl_ll_files ${ll_filename})
endforeach()

# rocm-device-libs does not have a cmake variable for mcpu so we rely on 
# sed to change "f1ji" to the actual gfx number
set(mcpus $ENV{GFXLIST})
if(mcpus)
  message("   -- Building ${libname} for devices specified by GFXLIST: ${mcpus}")
else()
  set(mcpus gfx700 gfx701 gfx801 gfx803 gfx900)
  message("   -- Building ${libname} default set of AMD GPUs: ${mcpus}")
  message("   -- You may override default with GFXLIST environment variable ")
endif()
separate_arguments(mcpus)

foreach(mcpu ${mcpus})

set(hip_bc_files)
#  Compile all .cpp files in HIP automode
# Consider adding -fcuda-rdc 
set(hip_auto_cmd ${LLVM_COMPILER}/bin/clang++ -c -emit-llvm --hip-auto-headers=cuda_open 
    --cuda-device-only --offload-arch=${mcpu} -O2 
    -I${CMAKE_CURRENT_SOURCE_DIR}/../include 
    -I${CMAKE_CURRENT_SOURCE_DIR}/src)
foreach(file ${hip_auto_sources})
    file(RELATIVE_PATH rfile ${CMAKE_CURRENT_SOURCE_DIR}/src ${file})
    get_filename_component(fname ${rfile} NAME_WE)
    set(bc_filename "${CMAKE_CURRENT_BINARY_DIR}/${fname}-${mcpu}.bc")
    add_custom_command(
      OUTPUT ${bc_filename}
      COMMAND ${hip_auto_cmd} ${file} -o ${bc_filename}
      DEPENDS ${file})
    list(APPEND hip_bc_files ${bc_filename})
endforeach()

set(hip_cmd ${LLVM_COMPILER}/bin/clang++ -c -emit-llvm -x hip
    --cuda-device-only --offload-arch=${mcpu} -O2 
    -I${CMAKE_CURRENT_SOURCE_DIR}/../include 
    -I${CMAKE_CURRENT_SOURCE_DIR}/src)
foreach(file ${hip_sources})
    file(RELATIVE_PATH rfile ${CMAKE_CURRENT_SOURCE_DIR}/src ${file})
    get_filename_component(fname ${rfile} NAME_WE)
    set(bc_filename "${CMAKE_CURRENT_BINARY_DIR}/${fname}-${mcpu}.bc")
    add_custom_command(
      OUTPUT ${bc_filename}
      COMMAND ${hip_cmd} ${file} -o ${bc_filename}
      DEPENDS ${file})
    list(APPEND hip_bc_files ${bc_filename})
endforeach()

#Link all llfiles from cl and bc files from hip compiles
add_custom_command(
    OUTPUT linkout.${mcpu}.bc
    COMMAND ${LLVM_COMPILER}/bin/llvm-link ${cl_ll_files} ${hip_bc_files} ${ll_sources} -o linkout.${mcpu}.bc
    DEPENDS ${cl_ll_files} ${hip_bc_files} ${ll_sources})
add_custom_target(linkout-${mcpu}-bc  ALL DEPENDS linkout.${mcpu}.bc)

set(final_bc_filename "${AOMPEXTRAS_BC_LIB_DIR}/lib${libname}-amdgcn-${mcpu}.bc")
add_custom_command(
    OUTPUT ${final_bc_filename}
    COMMAND ${PREPARE_BUILTINS} linkout.${mcpu}.bc -o ${final_bc_filename}
    DEPENDS linkout.${mcpu}.bc prepare-builtins-bin)

add_custom_target(lib${libname}-amdgcn-${mcpu}-bc ALL DEPENDS ${final_bc_filename})

install(FILES ${final_bc_filename} DESTINATION lib/libdevice)
install(FILES ${final_bc_filename} DESTINATION lib-debug/libdevice)

endforeach()
