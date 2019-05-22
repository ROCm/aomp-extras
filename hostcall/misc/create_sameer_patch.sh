
# 
#  We need to track changes to hostcall sources in other directories.
#  This script creates a patch from those other directories to hostcall sources managed in 
#  the hostcall directory of the aomp-extras repository. 
#  After there have been significant updates to either sources, rerun this diff an 
#  compare it to the current patch.
#
#  To create a new patch.
# 
#  cd PATH_TO_REPOS/aomp-extras/hostcall
#  . misc/create_sameer_patch.sh >misc/new_sameer.patch
#

diff -Naur /home/grodgers/git/aomp/TEMP/support/lib/hostcall/CMakeLists.txt lib/CMakeLists.txt
diff -Naur /home/grodgers/git/aomp/TEMP/support/lib/hostcall/include/amd_hostcall.h lib/include/amd_hostcall.h
diff -Naur /home/grodgers/git/aomp/TEMP/support/lib/hostcall/src/hostcall.cpp lib/src/hostcall.cpp
diff -Naur /home/grodgers/git/aomp/TEMP/hostcall/ockl/src/hostcall_impl.cl libdevice/src/hostcall_invoke.cl
