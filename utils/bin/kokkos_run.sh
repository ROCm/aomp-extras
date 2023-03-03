#!/bin/bash
# Copyright(C) 2020 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#  kokkos_build.sh: Script to run Kokkos unit tests and get statistics
#                   This will run kokkos in directory $HOME/kokkos_build.<GPUNAME>
#
#  Written by Jan-Patrick Lehr JanPatrick.Lehr@amd.com
#
PROGVERSION="X.Y-Z"
#

function print_info() {
  toPrint="$1"

  echo "[Info]: $toPrint"
}
function print_error() {
  toPrint="$1"

  echo "[Error]: $toPrint"
}

## To get consistent GPU names for building and running we rely on AOMP here as well
echo "$AOMP"
AOMP="${AOMP:-_AOMP_INSTALL_DIR_}"
echo "$AOMP"
if [ ! -d $AOMP ] ; then
   print_error "AOMP is not installed in ${AOMP}. Please set the environment variable."
   exit 1
fi

if [[ "$AOMP" =~ "opt" ]]; then
  # xargs trims the string off whitespaces
  export DETECTED_GPU=$($AOMP/../bin/rocminfo | grep -m 1 -E gfx[^0]{1}.{2} | awk '{print $2}')
  print_info "Set AOMP_GPU with rocminfo: $DETECTED_GPU"
else
  print_info "Set AOMP_GPU with offload-arch."
  if [ -a $AOMP/bin/rocminfo ]; then
    export DETECTED_GPU=$($AOMP/bin/offload-arch | grep -m 1 -E gfx[^0]{1}.{2})
  else
    export DETECTED_GPU=$($AOMP/bin/offload-arch | grep -m 1 -E gfx[^0]{1}.{2})
  fi
fi

COMPILERNAME_TO_USE=${_COMPILER_TO_USE_:-clang++}
AOMP_VERSION=$($AOMP/bin/${COMPILERNAME_TO_USE} --version | head -n 1)

AOMP_GPU=${AOMP_GPU:-$DETECTED_GPU}

GIT_DIR=${GIT_DIR:-$HOME/git}
KOKKOS_BUILD_PREFIX=${KOKKOS_BUILD_PREFIX:-$HOME}

if [ "$1" == "hip" ] ; then
   kokkos_backend="hip"
   KOKKOS_BUILD_DIR=${KOKKOS_BUILD_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_build_hip.$AOMP_GPU}
   KOKKOS_INSTALL_DIR=${KOKKOS_INSTALL_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_hip.$AOMP_GPU}
else
   kokkos_backend="openmp"
   KOKKOS_BUILD_DIR=${KOKKOS_BUILD_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_build_omp.$AOMP_GPU}
   KOKKOS_INSTALL_DIR=${KOKKOS_INSTALL_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_omp.$AOMP_GPU}
fi

KOKKOS_EXAMPLES_SOURCE_DIR=${KOKKOS_EXAMPLES_SOURCE_DIR:-$GIT_DIR/kokkos-openmptarget-examples}

## We want to process the command line arguments
# The script accepts the arguments 'unittest' and 'cgsolve' for now
# It sets corresponding variables to 'yes' that indicate if these tests should
# be executed or not
KOKKOS_RUN_UNIT_TEST='no'
KOKKOS_RUN_CGSOVLE='no'

# We support summary and detail execution
KOKKOS_RUN_TYPE=${KOKKOS_RUN_TYPE:-summary}

# For the CI runs we want to move the summary to the CI folder
KOKKOS_EXTRACT_FILE_LOCATION=${AOMP_OPENMP_CI:-''}

if [ "$#" -eq 0 ]; then
  print_error "Please indicate what to run 'unittest', 'cgsolve'"
  exit 1
fi

while (( "$#" )); do
  if [ "$1" == 'unittest' ]; then
    KOKKOS_RUN_UNIT_TEST='yes'
  elif [ "$1" == 'cgsolve' ]; then
    KOKKOS_RUN_CGSOVLE='yes'
  fi
  shift
done


if [ $KOKKOS_RUN_UNIT_TEST == 'yes' ]; then
  if [ -z $KOKKOS_EXTRACT_FILE_LOCATION ]; then
    initialDir=$PWD
  else
    initialDir=$KOKKOS_EXTRACT_FILE_LOCATION
  fi

  cd $KOKKOS_BUILD_DIR || exit 1
  
  cd core/unit_test || exit 1
  
  # Run the top-level summary version of the tests
  if [ "$KOKKOS_RUN_TYPE" == "summary" ]; then
    OMP_NUM_THREADS=2 ctest --timeout 180 -j 4
    print_info "For more details, please set KOKKOS_RUN_TYPE to 'detail'"
 
  elif [ "$KOKKOS_RUN_TYPE" == "detail" ]; then
  
    declare -a EXE_FILES
    for EXE in $(find . -maxdepth 1 -perm -111 -type f); do
      echo "$EXE"
      EXE_FILES+=("$EXE")
    done
    
    for UT in "${EXE_FILES[@]}"; do
      fName=${UT/KokkosCore/RESULT}
      ${UT} --gtest_output=json:$PWD/${fName}.json
    done

    if [ ! -z "$AOMP_CI_ACCUMULATOR" ]; then
      tmpResFile=accuResult.ext
      find . -iname "RESULT_*" -exec python3 ${AOMP_CI_ACCUMULATOR} --snapshot ${KOKKOS_FAILS_SNAPSHOT} --failfile ${KOKKOS_FAIL_FILE} {} ${tmpResFile} \;
      cp ${tmpResFile}-perf.ext ${initialDir}/accumulatedResults-perf.ext
      cp ${tmpResFile}-corr.ext ${initialDir}/accumulatedResults-corr.ext
      rm ${tmpResFile}-corr.ext ${tmpResFile}-perf.ext
    fi

  else
    print_error "Please set KOKKOS_RUN_TYPE to summary or detail"
  fi
fi

if [ $KOKKOS_RUN_CGSOVLE == 'yes' ]; then
  # Switch to the example directory
  cd $KOKKOS_EXAMPLES_SOURCE_DIR/cgsolve || exit 1

  # The example runs both an OpenMP target version of cgsolve and a version using the Kokkos library
  # with the OpenMP target backend
  # We execute an increased problem size and require higher precision to provoke longer runtimes.
  ./cgsolve.ompt 400 300 0.000000001 
fi
