##===----------------------------------------------------------------------===##
#
#                     The LLVM Compiler Infrastructure
#
# This file is dual licensed under the MIT and the University of Illinois Open
# Source Licenses. See LICENSE.txt for details.
##===----------------------------------------------------------------------===##
#
# utils/CMakeLists.txt
# Written by Greg Rodgers (Gregory.Rodgers@amd.com)
#
##===----------------------------------------------------------------------===##

cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  project(aomputils)
endif()
add_custom_target(aomputils ALL)

find_package(LLVM QUIET CONFIG
  PATHS
  $ENV{AOMP}
  ${LLVM_DIR}
  NO_DEFAULT_PATH
)

if (LLVM_DIR)
  if("{CMAKE_INSTALL_PREFIX}" STREQUAL "")
     set(CMAKE_INSTALL_PREFIX ${LLVM_INSTALL_PREFIX})
  endif()
  message("")
  message(STATUS "AOMP LLVM Found!")
  message(STATUS "     LLVM_PACKAGE_VERSION:     ${LLVM_PACKAGE_VERSION} ")
  message(STATUS "     LLVM_DIR:                 ${LLVM_DIR}")
  message(STATUS "     LLVM_INSTALL_PREFIX:      ${LLVM_INSTALL_PREFIX}")
  message(STATUS "     CMAKE_INSTALL_PREFIX:     ${CMAKE_INSTALL_PREFIX}")
  message("")
else()
  message("")
  message("  ERROR:  Could not find an AOMP version of LLVM.")
  message("          You must build AOMP before building AOMP utils")
  message("")
  error(" Could not find an AOMP version of LLVM.")
endif()

set(AOMP_DIR_FOUND ${LLVM_DIR})
set(AOMP_INSTALL_PREFIX ${LLVM_INSTALL_PREFIX})
set(AOMP_MAIN_INCDIR ${LLVM_BUILD_MAIN_INCLUDE_DIR})
set(AOMP_BINDIR ${AOMP_INSTALL_PREFIX}/bin)
set(AOMP_INCDIR ${AOMP_INSTALL_PREFIX}/include)
set(AOMP_LIBDIR ${AOMP_INSTALL_PREFIX}/lib)
set(AOMP_LIBS
  ${AOMP_LIBDIR}/libLLVMBitWriter.a
  ${AOMP_LIBDIR}/libLLVMBitReader.a
  ${AOMP_LIBDIR}/libLLVMObject.a
  ${AOMP_LIBDIR}/libLLVMCore.a
  ${AOMP_LIBDIR}/libLLVMDemangle.a
  ${AOMP_LIBDIR}/libLLVMMC.a
  ${AOMP_LIBDIR}/libLLVMMCParser.a
  ${AOMP_LIBDIR}/libLLVMSupport.a
  ${AOMP_LIBDIR}/libLLVMBinaryFormat.a )
mark_as_advanced(
  AOMP_DIR_FOUND
  AOMP_INSTALL_PREFIX
  AOMP_BINDIR
  AOMP_INCDIR
  AOMP_LIBDIR
  AOMP_MAIN_INCDIR)

# For AOMP, get the version_str from end of CMAKE_INSTALL_PREFIX
if(AOMP_VERSION_STRING)
  set(version_str ${AOMP_VERSION_STRING})
else()
  string(LENGTH ${LLVM_INSTALL_PREFIX} liplen)
  string(LENGTH ${CMAKE_INSTALL_PREFIX} ciplen)
  math(EXPR vlen "${ciplen} - ${liplen} - 1")
  math(EXPR vstart "${ciplen} - ${vlen}")
  string(SUBSTRING ${CMAKE_INSTALL_PREFIX} ${vstart} ${vlen} version_str)
endif()

set(SED_INSTALL_DIR '$ENV{SED_INSTALL_DIR}')

# edit in place to preserve permissions
add_custom_command( OUTPUT cloc.sh
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/cloc.sh ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/cloc.sh)
add_custom_command( OUTPUT cloc.sh.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh > cloc.sh.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh)

add_custom_command( OUTPUT gpurun
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/gpurun ${CMAKE_CURRENT_BINARY_DIR}/gpurun
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/gpurun)
add_custom_command( OUTPUT gpurun.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/gpurun > gpurun.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/gpurun)

add_custom_command( OUTPUT raja_build.sh
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/raja_build.sh ${CMAKE_CURRENT_BINARY_DIR}/raja_build.sh
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/raja_build.sh)
add_custom_command( OUTPUT raja_build.sh.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/raja_build.sh > raja_build.sh.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/raja_build.sh)

add_custom_command( OUTPUT kokkos_build.sh
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/kokkos_build.sh ${CMAKE_CURRENT_BINARY_DIR}/kokkos_build.sh
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/kokkos_build.sh)
add_custom_command( OUTPUT kokkos_build.sh.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/kokkos_build.sh > kokkos_build.sh.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/kokkos_build.sh)

add_custom_command( OUTPUT aompcc
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompcc ${CMAKE_CURRENT_BINARY_DIR}/aompcc
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompcc)
add_custom_command( OUTPUT aompcc.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/aompcc  > aompcc.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/aompcc)

add_custom_command( OUTPUT aompExtractRegion
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompExtractRegion ${CMAKE_CURRENT_BINARY_DIR}/aompExtractRegion
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompExtractRegion)
add_custom_command( OUTPUT aompExtractRegion.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/aompExtractRegion > aompExtractRegion.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/aompExtractRegion)

add_custom_command( OUTPUT mymcpu
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/mymcpu ${CMAKE_CURRENT_BINARY_DIR}/mymcpu
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/mymcpu)
add_custom_command( OUTPUT mymcpu.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/" ${CMAKE_CURRENT_BINARY_DIR}/mymcpu > mymcpu.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/mymcpu)

add_custom_command( OUTPUT aompversion
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompversion ${CMAKE_CURRENT_BINARY_DIR}/aompversion
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/aompversion)
add_custom_command( OUTPUT aompversion.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/" ${CMAKE_CURRENT_BINARY_DIR}/aompversion > aompversion.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/aompversion)

add_custom_command( OUTPUT clang-ocl
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/clang-ocl ${CMAKE_CURRENT_BINARY_DIR}/clang-ocl
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/clang-ocl)
add_custom_command( OUTPUT clang-ocl.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/clang-ocl > clang-ocl.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/clang-ocl)

add_custom_command( OUTPUT modulefile
   COMMAND /bin/cp -p ${CMAKE_CURRENT_SOURCE_DIR}/bin/modulefile ${CMAKE_CURRENT_BINARY_DIR}/modulefile
   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/bin/modulefile)
add_custom_command( OUTPUT modulefile.phantom
   COMMAND /bin/sed -i -e "s/X\\.Y\\-Z/${version_str}/g" -e "s/_AOMP_INSTALL_DIR_/${SED_INSTALL_DIR}/g" ${CMAKE_CURRENT_BINARY_DIR}/modulefile > modulefile.phantom
   DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/modulefile)

add_custom_target(utils_scripts ALL DEPENDS gpurun.phantom cloc.sh.phantom raja_build.sh.phantom kokkos_build.sh.phantom aompcc.phantom mymcpu.phantom aompversion.phantom clang-ocl.phantom modulefile.phantom aompExtractRegion.phantom)

if(${AOMP_STANDALONE_BUILD})
  install(PROGRAMS 
     ${CMAKE_CURRENT_BINARY_DIR}/cloc.sh
     ${CMAKE_CURRENT_BINARY_DIR}/gpurun
     ${CMAKE_CURRENT_BINARY_DIR}/raja_build.sh
     ${CMAKE_CURRENT_BINARY_DIR}/kokkos_build.sh
     ${CMAKE_CURRENT_BINARY_DIR}/aompcc
     ${CMAKE_CURRENT_BINARY_DIR}/aompExtractRegion
     ${CMAKE_CURRENT_BINARY_DIR}/mymcpu
     ${CMAKE_CURRENT_BINARY_DIR}/aompversion
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/mygpu
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/openmpi_set_cu_mask
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/blt.patch
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/raja.patch
     ${CMAKE_CURRENT_BINARY_DIR}/clang-ocl
     ${CMAKE_CURRENT_BINARY_DIR}/modulefile
   DESTINATION "bin")

else()
  install(PROGRAMS
     ${CMAKE_CURRENT_BINARY_DIR}/mymcpu
     ${CMAKE_CURRENT_BINARY_DIR}/aompcc
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/mygpu
     ${CMAKE_CURRENT_SOURCE_DIR}/bin/openmpi_set_cu_mask
     ${CMAKE_CURRENT_BINARY_DIR}/gpurun
   DESTINATION "${DEVEL_PACKAGE}bin")
endif()
