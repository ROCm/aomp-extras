#!/bin/bash
#
#  rocprim_build.sh: Script to clone and build rocprim for a specific GPU
#                 This will build rocprim in directory $HOME/rocprim_build.<GPUNAME>
#
#
#  Written by Greg Rodgers  Gregory.Rodgers@amd.com
#
PROGVERSION="X.Y-Z"
#
# Copyright (c) 2019 ADVANCED MICRO DEVICES, INC.
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
aomp_repos=$HOME/git/aomp
rocprim_source_dir=$aomp_repos/rocPRIM
rocprim_url=https://github.com/ROCmSoftwarePlatform/rocPRIM.git
ROCPRIM_BUILD_PREFIX=${ROCPRIM_BUILD_PREFIX:-$HOME}
ROCPRIM_BUILD_DIR=${ROCPRIM_BUILD_DIR:-$ROCPRIM_BUILD_PREFIX/rocprim_build}

mkdir -p $aomp_repos
cd $aomp_repos
if [ ! -d $rocprim_source_dir ] ; then
  echo git clone --recursive -b develop $rocprim_url
  git clone --recursive -b develop $rocprim_url
  if [ $? != 0 ] ; then
     echo
     echo "ERROR  could not git clone $rocprim_url "
     echo
     exit 1
  fi
fi
cd $rocprim_source_dir

# Ensure latest revision
git pull

mkdir -p $ROCPRIM_BUILD_DIR
cd $ROCPRIM_BUILD_DIR

CXX=${AOMP}/bin/hipcc cmake -DCMAKE_INSTALL_PREFIX=${AOMP} -DBUILD_BENCHMARK=OFF -DBUILD_TEST=OFF ${rocprim_source_dir}

if [ $? != 0 ] ; then
   echo "ERROR in Rocprim cmake"
   exit 1
fi

echo
echo "CMAKE done in directory $rocprim_build_dir"
echo
echo "Starting build ..."

make -j8
if [ $? != 0 ] ; then
   echo "ERROR in Rocprim build"
   exit 1
fi

make install
if [ $? != 0 ] ; then
   echo "ERROR in Rocprim install"
   exit 1
fi

echo
echo "Rocprim build has successfully completed into directory $rocprim_build_dir"
echo
