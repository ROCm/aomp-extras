// compile with
// /home/rlieberm/rocm/aomp_13.0-2/bin/clang  -O2  -target x86_64-pc-linux-gnu -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=gfx906 -c cprint.c -emit-llvm  -o cprint.bc  -save-temps

// dump the ll
// cp cprint-openmp-amdgcn-amd-amdhsa-gfx906.tmp.ll ~/git/aomp12/aomp-extras/aomp-device-libs/aompextras/src/cprint.ll


#include <stdio.h>
#pragma omp declare target
void f90print_(char *s) {
  printf("%s\n", s);
}
void f90printi_(char *s, int *i) {
  printf("%s %d\n", s, *i);
}
void f90printf_(char *s, float *f) {
  printf("%s %f\n", s, *f);
}
void f90printd_(char *s, double *d) {
  printf("%s %g\n", s, *d);
}
#pragma omp end declare target
