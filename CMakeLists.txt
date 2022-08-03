# Copyright(C) 2019 Advanced Micro Devices, Inc. All rights reserved.
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(aomp-extras)
include(GNUInstallDirs)
if(${ENABLE_DEVEL_PACKAGE})
  set(DEVEL_PACKAGE "devel/")
endif()
add_subdirectory(utils)
