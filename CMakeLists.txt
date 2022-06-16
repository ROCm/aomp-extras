# Copyright(C) 2019 Advanced Micro Devices, Inc. All rights reserved.
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(aomp-extras)
# Set default libdir to be "lib" for ROCm, distros can override this anyway:
set(CMAKE_INSTALL_LIBDIR "lib" CACHE STRING "Library install directory")
include(GNUInstallDirs)
if(${ENABLE_DEVEL_PACKAGE})
  set(DEVEL_PACKAGE "devel/")
endif()
add_subdirectory(utils)
