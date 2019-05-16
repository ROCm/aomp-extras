cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(hostcall-project)

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  message("--------------------------------------------")
endif()

message("   -- Building device and host libraries for hostcall ")
add_subdirectory(libdevice)
add_subdirectory(lib)

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  message("---------- DONE hostcall cmake -------------")
endif()
