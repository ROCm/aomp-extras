//===----------------------------------------------------------------------===//
//
// device_atomic_functions.cpp: Defs for overloaded atomic opearions in hip.
//
// This file is dual licensed under the MIT and the University of Illinois Open
// Source Licenses. See LICENSE.txt for details.
//
//===----------------------------------------------------------------------===//


#ifndef __OVERL__
#define __OVERL__ __attribute__((device, always_inline, overloadable)) const
#endif

#ifndef __NOOVL__
#define __NOOVL__ extern "C" __attribute__((device, always_inline)) const
#endif

#ifdef __cplusplus
extern "C" {
#endif

// atomicAdd()
// ------ support for overloaded atomicAdd ------
__NOOVL__ unsigned atomic_add_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicAdd(unsigned *address, unsigned val) {
  return atomic_add_unsigned(address, val);
}

__NOOVL__ int atomic_add_int(int *addr, int val);
__OVERL__ int atomicAdd(int *address, int val) {
  return atomic_add_int(address, val);
}

__NOOVL__ float atomic_add_float(float *addr, float val);
__OVERL__ float atomicAdd(float *address, float val) {
  return atomic_add_float(address, val);
}

__NOOVL__ unsigned long long atomic_add_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicAdd(unsigned long long *address,
                                       unsigned long long val) {
  return atomic_add_uint64(address, val);
}

// atomicCAS()
// ------ support for overloaded atomicCAS ------
__NOOVL__ unsigned atomic_compare_exchange_unsigned(unsigned *addr,
                                                    unsigned compare,
                                                    unsigned val);
__OVERL__ unsigned atomicCAS(unsigned *address, unsigned compare,
                             unsigned val) {
  return atomic_compare_exchange_unsigned(address, compare, val);
}

__NOOVL__ int atomic_compare_exchange_int(int *addr, int compare, int val);
__OVERL__ int atomicCAS(int *address, int compare, int val) {
  return atomic_compare_exchange_int(address, compare, val);
}

__NOOVL__ unsigned long long
atomic_compare_exchange_uint64(unsigned long long *addr,
                               unsigned long long compare,
                               unsigned long long val);
__OVERL__ unsigned long long atomicCAS(unsigned long long *address,
                                       unsigned long long compare,
                                       unsigned long long val) {
  return atomic_compare_exchange_uint64(address, compare, val);
}

// atomicSub()
// ------ support for overloaded atomicSub ------
__NOOVL__ int atomic_sub_int(int *addr, int val);
__OVERL__ int atomicSub(int *address, int val) {
  return atomic_sub_int(address, val);
}

__NOOVL__ unsigned atomic_sub_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicSub(unsigned *address, unsigned val) {
  return atomic_sub_unsigned(address, val);
}

// atomicExch()
// ------ support for overloaded atomicExch ------
__NOOVL__ int atomic_exchange_int(int *addr, int val);
__OVERL__ int atomicExch(int *address, int val) {
  return atomic_exchange_int(address, val);
}

__NOOVL__ unsigned atomic_exchange_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicExch(unsigned *address, unsigned val) {
  return atomic_exchange_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_exchange_uint64(unsigned long long *addr,
                                                    unsigned long long val);
__OVERL__ unsigned long long atomicExch(unsigned long long *address,
                                        unsigned long long val) {
  return atomic_exchange_uint64(address, val);
}

__NOOVL__ float atomic_exchange_float(float *addr, float val);
__OVERL__ float atomicExch(float *address, float val) {
  return atomic_exchange_float(address, val);
}

// atomicMin()
// ------ support for overloaded atomicMin ------
__NOOVL__ int atomic_min_int(int *addr, int val);
__OVERL__ int atomicMin(int *address, int val) {
  return atomic_min_int(address, val);
}

__NOOVL__ unsigned atomic_min_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicMin(unsigned *address, unsigned val) {
  return atomic_min_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_min_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicMin(unsigned long long *address,
                                       unsigned long long val) {
  return atomic_min_uint64(address, val);
}

// atomicMax()
// ------ support for overloaded atomicMax ------
__NOOVL__ int atomic_max_int(int *addr, int val);
__OVERL__ int atomicMax(int *address, int val) {
  return atomic_max_int(address, val);
}

__NOOVL__ unsigned atomic_max_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicMax(unsigned *address, unsigned val) {
  return atomic_max_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_max_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicMax(unsigned long long *address,
                                       unsigned long long val) {
  return atomic_max_uint64(address, val);
}

// atomicAnd()
// ------ support for overloaded atomicAnd ------
__NOOVL__ int atomic_and_int(int *addr, int val);
__OVERL__ int atomicAnd(int *address, int val) {
  return atomic_and_int(address, val);
}

__NOOVL__ unsigned atomic_and_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicAnd(unsigned *address, unsigned val) {
  return atomic_and_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_and_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicAnd(unsigned long long *address,
                                       unsigned long long val) {
  return atomic_and_uint64(address, val);
}

// atomicOr()
// ------ support for overloaded atomicOr ------
__NOOVL__ int atomic_or_int(int *addr, int val);
__OVERL__ int atomicOr(int *address, int val) {
  return atomic_or_int(address, val);
}

__NOOVL__ unsigned atomic_or_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicOr(unsigned *address, unsigned val) {
  return atomic_or_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_or_uint64(unsigned long long *addr,
                                              unsigned long long val);
__OVERL__ unsigned long long atomicOr(unsigned long long *address,
                                      unsigned long long val) {
  return atomic_or_uint64(address, val);
}

// atomicXor()
// ------ support for overloaded atomicXOr ------
__NOOVL__ int atomic_xor_int(int *addr, int val);
__OVERL__ int atomicXor(int *address, int val) {
  return atomic_xor_int(address, val);
}

__NOOVL__ unsigned atomic_xor_unsigned(unsigned *addr, unsigned val);
__OVERL__ unsigned atomicXor(unsigned *address, unsigned val) {
  return atomic_xor_unsigned(address, val);
}

__NOOVL__ unsigned long long atomic_xor_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicXor(unsigned long long *address,
                                       unsigned long long val) {
  return atomic_xor_uint64(address, val);
}

// atomicInc()
// ------ support for overloaded atomicInc ------
__NOOVL__ unsigned atomic_inc_unsigned(unsigned *addr);
__OVERL__ unsigned atomicInc(unsigned *address) {
  return atomic_inc_unsigned(address);
}

__NOOVL__ unsigned atomic_inc_unsigned(unsigned *addr);
__OVERL__ unsigned atomicInc(unsigned *address, unsigned max) {
  if (*address >= max)
    return *address;
  else
    return atomic_inc_unsigned(address);
}

__NOOVL__ int atomic_inc_int(int *addr);
__OVERL__ int atomicInc(int *address) { return atomic_inc_int(address); }

// atomicDec()
// ------ support for overloaded atomicDec ------
__NOOVL__ unsigned atomic_dec_unsigned(unsigned *addr);
__OVERL__ unsigned atomicDec(unsigned *address) {
  return atomic_dec_unsigned(address);
}

__NOOVL__ int atomic_dec_int(int *addr);
__OVERL__ int atomicDec(int *address) { return atomic_dec_int(address); }

#ifdef __cplusplus
}
#endif
