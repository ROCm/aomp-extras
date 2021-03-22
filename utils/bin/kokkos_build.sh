#!/bin/bash
#
#  kokkos_build.sh: Script to clone and build kokkos for a specific GPU 
#                   This will build kokkos in directory $HOME/kokkos_build.<GPUNAME>
#
#
#  Written by Greg Rodgers  Gregory.Rodgers@amd.com
#
PROGVERSION="X.Y-Z"
#
# Copyright (c) 2020 ADVANCED MICRO DEVICES, INC.  
# 
# AMD is granting you permission to use this software and documentation (if any) (collectively, the 
# Materials) pursuant to the terms and conditions of the Software License Agreement included with the 
# Materials.  If you do not have a copy of the Software License Agreement, contact your AMD 
# representative for a copy.
# 
# You agree that you will not reverse engineer or decompile the Materials, in whole or in part, except for 
# example code which is provided in source code form and as allowed by applicable law.
# 
# WARRANTY DISCLAIMER: THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
# KIND.  AMD DISCLAIMS ALL WARRANTIES, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING BUT NOT 
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
# PURPOSE, TITLE, NON-INFRINGEMENT, THAT THE SOFTWARE WILL RUN UNINTERRUPTED OR ERROR-
# FREE OR WARRANTIES ARISING FROM CUSTOM OF TRADE OR COURSE OF USAGE.  THE ENTIRE RISK 
# ASSOCIATED WITH THE USE OF THE SOFTWARE IS ASSUMED BY YOU.  Some jurisdictions do not 
# allow the exclusion of implied warranties, so the above exclusion may not apply to You. 
# 
# LIMITATION OF LIABILITY AND INDEMNIFICATION:  AMD AND ITS LICENSORS WILL NOT, 
# UNDER ANY CIRCUMSTANCES BE LIABLE TO YOU FOR ANY PUNITIVE, DIRECT, INCIDENTAL, 
# INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING FROM USE OF THE SOFTWARE OR THIS 
# AGREEMENT EVEN IF AMD AND ITS LICENSORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH 
# DAMAGES.  In no event shall AMD's total liability to You for all damages, losses, and 
# causes of action (whether in contract, tort (including negligence) or otherwise) 
# exceed the amount of $100 USD.  You agree to defend, indemnify and hold harmless 
# AMD and its licensors, and any of their directors, officers, employees, affiliates or 
# agents from and against any and all loss, damage, liability and other expenses 
# (including reasonable attorneys' fees), resulting from Your use of the Software or 
# violation of the terms and conditions of this Agreement.  
# 
# U.S. GOVERNMENT RESTRICTED RIGHTS: The Materials are provided with "RESTRICTED RIGHTS." 
# Use, duplication, or disclosure by the Government is subject to the restrictions as set 
# forth in FAR 52.227-14 and DFAR252.227-7013, et seq., or its successor.  Use of the 
# Materials by the Government constitutes acknowledgement of AMD's proprietary rights in them.
# 
# EXPORT RESTRICTIONS: The Materials may be subject to export restrictions as stated in the 
# Software License Agreement.
# 

AOMP=${AOMP:-_AOMP_INSTALL_DIR_}
if [ ! -d $AOMP ] ; then
   echo "ERROR:  AOMP is not installed in $AOMP"
   exit 1
fi

GIT_DIR=${GIT_DIR:-$HOME/git}
KOKKOS_SOURCE_DIR=${KOKKOS_SOURCE_DIR:-$GIT_DIR/kokkos}
KOKKOS_URL=https://github.com/kokkos/kokkos.git
KOKKOS_BRANCH=develop
KOKKOS_TAG=3.3.01
NUM_THREADS=${NUM_THREADS:-8}

if [[ "$AOMP" =~ "opt" ]]; then
  echo Set AOMP_GPU with rocm_agent_enumerator.
  export DETECTED_GPU=$($AOMP/../bin/rocm_agent_enumerator | grep -m 1 -E gfx[^0]{1}.{2})
else
  echo Set AOMP_GPU with mygpu.
  if [ -a $AOMP/bin/mygpu ]; then
    export DETECTED_GPU=$($AOMP/bin/mygpu)
  else
    export DETECTED_GPU=$($AOMP/../bin/mygpu)
  fi
fi

AOMP_GPU=${AOMP_GPU:-$DETECTED_GPU}

echo AOMP_GPU = $AOMP_GPU
echo AOMP     = $AOMP

if [ "$AOMP_GPU" == "" ] || [ "$AOMP_GPU" == "unknown" ]; then
  echo Error: AOMP_GPU not properly set...exiting.
  exit 1
fi

KOKKOS_BUILD_PREFIX=${KOKKOS_BUILD_PREFIX:-$HOME}

if [ -f /usr/local/cmake/bin/cmake ] ; then
  AOMP_CMAKE=${AOMP_CMAKE:-/usr/local/cmake/bin/cmake}
else
  AOMP_CMAKE=${AOMP_CMAKE:-cmake}
fi

if [ "$1" == "hip" ] ; then
   kokkos_backend="hip"
   KOKKOS_BUILD_DIR=${KOKKOS_BUILD_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_build_hip.$AOMP_GPU}
   KOKKOS_INSTALL_DIR=${KOKKOS_INSTALL_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_hip.$AOMP_GPU}
else
   kokkos_backend="openmp"
   KOKKOS_BUILD_DIR=${KOKKOS_BUILD_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_build_omp.$AOMP_GPU}
   KOKKOS_INSTALL_DIR=${KOKKOS_INSTALL_DIR:-$KOKKOS_BUILD_PREFIX/kokkos_omp.$AOMP_GPU}
fi

# Clean install, build and source directories
if [ "$1" == "clean" ] ; then
  echo Cleaning:
  echo SOURCE_DIR: $KOKKOS_SOURCE_DIR
  echo BUILD_DIR: $KOKKOS_BUILD_DIR
  echo INSTALL_DIR: $KOKKOS_INSTALL_DIR
  rm -rf $KOKKOS_SOURCE_DIR
  rm -rf $KOKKOS_BUILD_DIR
  rm -rf $KOKKOS_INSTALL_DIR
  exit 0
fi

function patchkokkos(){
patchfile1=/tmp/kokkos1_$$.patch
/bin/cat >$patchfile1 <<"EOF"
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 93585c78..00ccc384 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -139,7 +139,7 @@ ENDIF()
 # I really wish these were regular variables
 # but scoping issues can make it difficult
 GLOBAL_SET(KOKKOS_COMPILE_OPTIONS)
-GLOBAL_SET(KOKKOS_LINK_OPTIONS -DKOKKOS_DEPENDENCE)
+GLOBAL_SET(KOKKOS_LINK_OPTIONS -lomptarget -DKOKKOS_DEPENDENCE)
 GLOBAL_SET(KOKKOS_CUDA_OPTIONS)
 GLOBAL_SET(KOKKOS_CUDAFE_OPTIONS)
 GLOBAL_SET(KOKKOS_XCOMPILER_OPTIONS)
diff --git a/Makefile.kokkos b/Makefile.kokkos
index 7a425e7a..9190c0c5 100644
--- a/Makefile.kokkos
+++ b/Makefile.kokkos
@@ -157,7 +157,7 @@ KOKKOS_INTERNAL_COMPILER_PGI         := $(call kokkos_has_string,$(KOKKOS_CXX_VE
 KOKKOS_INTERNAL_COMPILER_XL          := $(strip $(shell $(CXX) -qversion       2>&1 | grep XL                  | wc -l))
 KOKKOS_INTERNAL_COMPILER_CRAY        := $(strip $(shell $(CXX) -craype-verbose 2>&1 | grep "CC-"               | wc -l))
 KOKKOS_INTERNAL_COMPILER_NVCC        := $(strip $(shell echo "$(shell export OMPI_CXX=$(OMPI_CXX); export MPICH_CXX=$(MPICH_CXX); $(CXX) --version 2>&1 | grep nvcc | wc -l)>0" | bc))
-KOKKOS_INTERNAL_COMPILER_CLANG       := $(call kokkos_has_string,$(KOKKOS_CXX_VERSION),clang)
+KOKKOS_INTERNAL_COMPILER_CLANG       := 1
 KOKKOS_INTERNAL_COMPILER_APPLE_CLANG := $(call kokkos_has_string,$(KOKKOS_CXX_VERSION),Apple LLVM)
 KOKKOS_INTERNAL_COMPILER_HCC         := $(call kokkos_has_string,$(KOKKOS_CXX_VERSION),HCC)
 KOKKOS_INTERNAL_COMPILER_GCC         := $(call kokkos_has_string,$(KOKKOS_CXX_VERSION),GCC)
EOF
  echo patch -p1 $patchfile1
  patch -p1 < $patchfile1
  rm $patchfile1
}

mkdir -p $GIT_DIR
cd $GIT_DIR
if [ ! -d $KOKKOS_SOURCE_DIR ] ; then 
   echo git clone -b develop $KOKKOS_URL
   git clone -b $KOKKOS_BRANCH $KOKKOS_URL
   if [ $? != 0 ] ; then 
      echo
      echo "ERROR: Could not git clone $KOKKOS_URL "
      echo
      exit 1
   fi
   cd $KOKKOS_SOURCE_DIR
   git checkout $KOKKOS_TAG
   patchkokkos
else 
   echo
   echo "  WARNING: Directory $KOKKOS_SOURCE_DIR already exists."
   echo "           No changes will be made to the sources"
   echo
fi

if [ -d $KOKKOS_BUILD_DIR ] ; then 
   echo
   echo " FRESH START:  Removing $KOKKOS_BUILD_DIR"
   echo "               rm -rf $KOKKOS_BUILD_DIR"
   echo
   rm -rf  $KOKKOS_BUILD_DIR
fi
if [ -d $KOKKOS_INSTALL_DIR ] ; then 
   echo "               rm -rf $KOKKOS_INSTALL_DIR"
   echo
   rm -rf  $KOKKOS_INSTALL_DIR
fi
mkdir -p $KOKKOS_BUILD_DIR
cd $KOKKOS_BUILD_DIR

UNAMEP=`uname -m`
AOMP_CPUTARGET="${UNAMEP}-pc-linux-gnu"
if [ "$UNAMEP" == "ppc64le" ] ; then
   AOMP_CPUTARGET="ppc64le-linux-gnu"
fi

if [ "$kokkos_backend" == "hip" ] ; then
   echo "ERROR: hip backend for kokkos not supported yet"
   exit 1
else
   # ensure kokkos finds AOMP clang first
   export PATH=$AOMP/bin:$PATH
   $AOMP_CMAKE   \
   -DCMAKE_CXX_COMPILER=$AOMP/bin/clang++ \
   -DCMAKE_CXX_STANDARD=17 \
   -DCMAKE_CXX_FLAGS="-std=c++17" -O3 \
   -target $AOMP_CPUTARGET \
   -fopenmp \
   -fopenmp-targets=amdgcn-amd-amdhsa \
   -Xopenmp-target=amdgcn-amd-amdhsa \
   -march=$AOMP_GPU \
   -DCMAKE_INSTALL_PREFIX=$KOKKOS_INSTALL_DIR \
   -DKokkos_ENABLE_OPENMP=On \
   -DKokkos_ARCH_HSW=On \
   -DKokkos_ENABLE_HWLOC=On  \
   -DKokkos_HWLOC_DIR=$HWLOC_DIR \
   -DKokkos_ENABLE_OPENMPTARGET=On \
   -DKokkos_ENABLE_TESTS=On \
   $KOKKOS_SOURCE_DIR
fi
if [ $? != 0 ] ; then 
   echo
   echo "ERROR in Kokkos cmake"
   echo "If HWLOC is not found, set environment variable HWLOC_DIR=/path/to/hwloc."
   echo
   exit 1
fi

echo
echo "CMAKE done in directory $KOKKOS_BUILD_DIR"
echo
echo "Starting build ..."

echo make -j$NUM_THREADS
make -j$NUM_THREADS

if [ $? != 0 ] ; then 
   echo "ERROR in Kokkos build"
   exit 1
fi

make install
if [ $? != 0 ] ; then 
   echo "ERROR in Kokkos install"
   exit 1
fi
echo
echo " Kokkos Version $KOKKOS_TAG installed successfully into directory "
echo " $KOKKOS_INSTALL_DIR"
echo
