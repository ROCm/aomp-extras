find_package(Threads REQUIRED)

#find_library(HSA_LIBRARY hsa-runtime64 PATHS ${CMAKE_INSTALL_PATH}/lib)

#if (NOT EXISTS ${HSA_LIBRARY})
#    message(STATUS "HSA runtime not found. Tests disabled.")
#endif()

#find_library(HOSTCALL_LIBRARY hostcall PATHS ${CMAKE_INSTALL_PATH}/lib)
#if (NOT EXISTS ${HOSTCALL_LIBRARY})
#   message(STATUS "HOSTCALL_LIBRARY not found. Tests disabled.")
#endif()

function(hostcall_add_test retval filename language install_lib )
    get_filename_component(basename_we ${filename} NAME_WE)
    get_filename_component(basename ${filename} NAME)
    set(testname ${basename_we})
    set(${retval} ${testname} PARENT_SCOPE)
    add_executable(${testname} EXCLUDE_FROM_ALL ${filename})

    add_dependencies(build-tests ${testname})

    add_test(${testname} ${testname})
    target_link_libraries(${testname} -L${install_lib} -lhostcall -Wl,-rpath,${install_lib})
    target_link_libraries(${testname} -L${install_lib} -lhsa-runtime64 -Wl,-rpath,${install_lib})
    target_link_libraries(${testname} ${CMAKE_DL_LIBS} )
    target_link_libraries(${testname} Threads::Threads)

    if(${language} STREQUAL "C++")
        set_target_properties(${testname} PROPERTIES
        CXX_STANDARD 11
        CXX_STANDARD_REQUIRED Yes
        CXX_EXTENSIONS No)
    endif()
endfunction()

# no-hsa.c is built without linking the HSA runtime
#hostcall_add_test(testname no-hsa.c "C" "" ${HOSTCALL_LIBRARY})

# Don't add any more tests if HSA is missing
if (NOT ${WITH_HSA})
    return()
endif()

file(GLOB files *.c)
list(REMOVE_ITEM files ${CMAKE_CURRENT_SOURCE_DIR}/no-hsa.c)
foreach(file ${files})
	hostcall_add_test(testname ${file} "C" "${CMAKE_INSTALL_PREFIX}/lib")
endforeach()

file(GLOB files *.cpp)
foreach(file ${files})
	hostcall_add_test(testname ${file} "C++" "${CMAKE_INSTALL_PREFIX}/lib")
endforeach()

# Negative test that checks for a non-recoverable error
set_tests_properties(no-handler PROPERTIES
  PASS_REGULAR_EXPRESSION "HOSTCALL_ERROR_SERVICE_UNKNOWN")

# Trivial test that does not depend on third-party headers and always
# returns success. It is meant to perform catch pedantic compiler
# checks on the exported C header.
target_compile_options(check-header PRIVATE -Wall -Werror -Wpedantic -Wstrict-prototypes)
