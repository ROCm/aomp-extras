
cmake_minimum_required(VERSION 3.0)
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  project(hostcall-project)
  message("--------------------------------------------")
endif()

find_package(Threads REQUIRED)

if (NOT UNIX)
    message(FATAL_ERROR "No Windows support due to lack of signals")
endif()

find_path(HSA_HEADER hsa/hsa.h PATHS 
  $ENV{AOMP}/include
  $ENV{HOME}/rocm/aomp/include
  /opt/rocm/aomp/include
  /usr/lib/rocm/aomp/include
  /opt/rocm/include)

if (NOT EXISTS ${HSA_HEADER})
    message(FATAL_ERROR "Cannot find HSA headers. Please check the CMAKE_PREFIX_PATH")
endif()
message("   -- Using HSA headers from ${HSA_HEADER}")
include_directories(${HSA_HEADER})

set(WITH_HSA 1)
configure_file(../include/hostcall-config.h.in include/hostcall-config.h)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/../include)

file(GLOB SOURCES "src/*.cpp" "src/*.c" )

set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/hostcall.so.def")

add_library(hostcall SHARED ${SOURCES})
set_target_properties(hostcall PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED Yes
    CXX_EXTENSIONS No)

set(HOSTCALL_PRIVATE_COMPILE_OPTIONS)
set(HOSTCALL_PRIVATE_COMPILE_DEFINITIONS)

list(APPEND HOSTCALL_PRIVATE_COMPILE_OPTIONS -Wall -Werror)
list(APPEND HOSTCALL_PRIVATE_COMPILE_DEFINITIONS HOSTCALL_EXPORT)

target_compile_options(hostcall
  PRIVATE "${HOSTCALL_PRIVATE_COMPILE_OPTIONS}")
target_compile_definitions(hostcall
  PRIVATE "${HOSTCALL_PRIVATE_COMPILE_DEFINITIONS}")

set(INCLUDE_INSTALL_DIR include)
set(LIB_INSTALL_DIR lib)
set(SHARE_INSTALL_DIR share)
set(CONFIG_INSTALL_DIR cmake)

target_link_libraries(
  hostcall 
  -L${CMAKE_INSTALL_PREFIX}/lib -lhsa-runtime64 -Wl,-rpath,${CMAKE_INSTALL_PREFIX}/lib
  -L${CMAKE_INSTALL_PREFIX}/lib -lhsakmt -Wl,-rpath,${CMAKE_INSTALL_PREFIX}/lib
)

target_link_libraries(hostcall Threads::Threads)

install(TARGETS hostcall LIBRARY DESTINATION "lib" COMPONENT runtime)
install(TARGETS hostcall LIBRARY DESTINATION "lib-debug" COMPONENT runtime)

#install(EXPORT hostcall_export
#    DESTINATION ${CONFIG_INSTALL_DIR})

install(FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/../include/hostcall.h"
    DESTINATION include)

install(FILES
    "README.md"
    "LICENSE.txt"
    DESTINATION ${SHARE_INSTALL_DIR}/hostcall)

set(HOSTCALL_VERSION_MAJOR "0")
set(HOSTCALL_VERSION_MINOR "1")
set(HOSTCALL_VERSION_STRING "${HOSTCALL_VERSION_MAJOR}.${HOSTCALL_VERSION_MINOR}")

include(CMakePackageConfigHelpers)

configure_package_config_file(hostcall-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/hostcall-config.cmake
    INSTALL_DESTINATION ${CONFIG_INSTALL_DIR}
    PATH_VARS LIB_INSTALL_DIR INCLUDE_INSTALL_DIR)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/hostcall-config-version.cmake
    VERSION "${HOSTCALL_VERSION_MAJOR}.${HOSTCALL_VERSION_MINOR}"
    COMPATIBILITY SameMajorVersion)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/hostcall-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/hostcall-config-version.cmake
    DESTINATION
    ${CONFIG_INSTALL_DIR})


enable_testing()
add_custom_target(build-tests)
add_dependencies(build-tests hostcall)
add_subdirectory(tests)

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
  message("-------- DONE hostcall host cmake ----------")
endif()
