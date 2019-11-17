#!/bin/bash
#
#  raja_build.sh: Script to clone and build raja for a specific GPU 
#                 This will build raja in directory $HOME/raja_build.<GPUNAME>
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

function getdname(){
   local __DIRN=`dirname "$1"`
   if [ "$__DIRN" = "." ] ; then 
      __DIRN=$PWD; 
   else
      if [ ${__DIRN:0:1} != "/" ] ; then 
         if [ ${__DIRN:0:2} == ".." ] ; then 
               __DIRN=`dirname $PWD`/${__DIRN:3}
         else
            if [ ${__DIRN:0:1} = "." ] ; then 
               __DIRN=$PWD/${__DIRN:2}
            else
               __DIRN=$PWD/$__DIRN
            fi
         fi
      fi
   fi
   echo $__DIRN
}

function patchrepo(){
   cd $patchdir
   echo "Testing patch $patchfile to $patchdir"
   applypatch="yes"
   patch -p1 -t -N --dry-run <$patchfile >/dev/null
   if [ $? != 0 ] ; then
      applypatch="no"
      # Check to see if reverse patch applies cleanly
      patch -p1 -R --dry-run -t <$patchfile >/dev/null
      if [ $? == 0 ] ; then
         echo "patch $patchfile was already applied to $patchdir"
      else
         echo
         echo "ERROR: Patch $patchfile will not apply"
         echo "       cleanly to directory $patchdir"
         echo "       Check if it was already applied."
         echo
         exit 1
      fi
   fi
   if [ "$applypatch" == "yes" ] ; then
      echo "Applying patch $patchfile to $patchdir"
      patch -p1 <$patchfile
   fi
}


thisdir=$(getdname $0)
AOMP=${AOMP:-/usr/lib/aomp}
aomp_repos=$HOME/git/aomp
raja_source_dir=$aomp_repos/raja
raja_url=https://github.com/llnl/raja
mygpu=`$thisdir/mygpu`
AOMP_GPU=${AOMP_GPU:-$mygpu}
RAJA_BUILD_PREFIX=${RAJA_BUILD_PREFIX:-$HOME}
RAJA_BUILD_DIR=${RAJA_BUILD_DIR:-$RAJA_BUILD_PREFIX/raja_build.$AOMP_GPU}

mkdir -p $aomp_repos
cd $aomp_repos
if [ ! -d $raja_source_dir ] ; then 
  echo git clone --recursive -b master $raja_url 
  git clone --recursive -b master $raja_url 
  if [ $? != 0 ] ; then 
     echo
     echo "ERROR  could not git clone $raja_url "
     echo
     exit 1
  fi
else
  cd $raja_source_dir
  echo "git submodule update"
  git submodule update
  echo "git pull"
  git pull
fi

patchdir=$raja_source_dir
patchfile=$thisdir/raja.patch
patchrepo
patchdir=$raja_source_dir/blt
patchfile=$thisdir/blt.patch
patchrepo

mkdir -p $RAJA_BUILD_DIR
cd $RAJA_BUILD_DIR

cmake -DOpenMP_C_FLAGS="-w;--target=x86_64-pc-linux-gnu;-fopenmp;-fopenmp-targets=amdgcn-amd-amdhsa;-Xopenmp-target=amdgcn-amd-amdhsa;-march=$AOMP_GPU" \
      -DOpenMP_CXX_FLAGS="-w;--target=x86_64-pc-linux-gnu;-fopenmp;-fopenmp-targets=amdgcn-amd-amdhsa;-Xopenmp-target=amdgcn-amd-amdhsa;-march=$AOMP_GPU" \
      -DENABLE_TARGET_OPENMP=On \
      -DENABLE_CUDA=Off \
      -DENABLE_CLANG_CUDA=Off \
      -DCMAKE_EXE_LINKER_FLAGS="" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=$AOMP/bin/clang \
      -DCMAKE_CXX_COMPILER=$AOMP/bin/clang++ \
      -DCMAKE_POSITION_INDEPENDENT_CODE=FALSE \
      -Wno-dev \
      -DRAJA_ENABLE_OPENMP=On \
      $raja_source_dir
if [ $? != 0 ] ; then 
   echo "ERROR in Raja cmake"
   exit 1
fi

echo
echo "CMAKE done in directory $raja_build_dir"
echo
echo "Starting build ..."

make -j8
if [ $? != 0 ] ; then 
   echo "ERROR in Raja build"
   exit 1
fi

echo
echo "Raja build has successfully completed into directory $raja_build_dir"
echo
