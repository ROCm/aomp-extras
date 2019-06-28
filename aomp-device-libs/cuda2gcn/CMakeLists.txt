##===--------------------------------------------------------------------------
##                   ROCm Device Libraries
##
## This file is distributed under the University of Illinois Open Source
## License. See LICENSE.TXT for details.
##===--------------------------------------------------------------------------

file(GLOB cl_sources
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cl
)

file(GLOB ll_sources
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.ll
)

file(GLOB sources ${cl_sources} ${ll_sources})


message(" ----------------- include ${ROCDL}/ocml/inc")
include_directories(${ROCDL}/ocml/inc)
include_directories(${ROCDL}/ockl/inc)
include_directories(${ROCDL}/irif/inc)
opencl_bc_lib(NAME cuda2gcn
              SOURCES ${sources})
