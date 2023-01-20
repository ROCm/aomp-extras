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
  export DETECTED_GPU=$($AOMP/bin/rocminfo | grep -m 1 -E gfx[^0]{1}.{2} | awk '{print $2}')
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

cd $KOKKOS_BUILD_DIR || exit 1

cd core/unit_test

# Run the top-level summary version of the tests
OMP_NUM_THREADS=2 ctest --timeout 180 -j 4

declare -a EXE_FILES
for EXE in $(find . -maxdepth 1 -perm -111 -type f); do
  echo "$EXE"
  EXE_FILES+=("$EXE")
done

for UT in "${EXE_FILES[@]}"; do
  ${UT}
done
