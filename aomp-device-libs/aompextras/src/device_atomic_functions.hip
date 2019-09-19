//===----------------------------------------------------------------------===//
//
// device_atomic_functions.hip: Defs for overloaded atomic opearions in hip.
//
// This file is dual licensed under the MIT and the University of Illinois Open
// Source Licenses. See LICENSE.txt for details.
//
//===----------------------------------------------------------------------===//

#ifndef __OVERL__
#define __OVERL__ __attribute__((device,always_inline, overloadable)) const
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
__OVERL__ unsigned atomicAdd(unsigned *address,
                                        unsigned val) {
  return atomic_add_unsigned(address, val);
}

__NOOVL__ int atomic_add_int(int *addr, int val);
__OVERL__ int atomicAdd(int *address, int val) {
  return atomic_add_int(address, val);
}

__NOOVL__ unsigned long long atomic_add_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long
atomicAdd(unsigned long long *address, unsigned long long val) {
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

// atomicMax()
// ------ support for overloaded atomicMax ------
__NOOVL__ unsigned long long atomic_max_uint64(unsigned long long *addr,
                                               unsigned long long val);
__OVERL__ unsigned long long atomicMax(unsigned long long *address,
                                           unsigned long long val) {
  return atomic_max_uint64(address, val);
}

// atomicInc()
// ------ support for overloaded atomicInc ------
__NOOVL__ unsigned atomic_inc_unsigned(unsigned *addr);
__OVERL__ unsigned atomicInc(unsigned *address, unsigned max) {
  if (*address>=max)
    return *address;
  else
    return atomic_inc_unsigned(address);
}

#ifdef __cplusplus
}
#endif
