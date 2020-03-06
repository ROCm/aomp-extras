#ifndef MINIMAL_ATMI_H
#define MINIMAL_ATMI_H

#include <stdio.h>
#include <stdlib.h>

#include "hsa.h" // probably want this too

#include "hsa/hsa_ext_amd.h"

typedef enum atmi_status_t {
  /**
   * The function has been executed successfully.
   */
  ATMI_STATUS_SUCCESS = 0,
  /**
   * A undocumented error has occurred.
   */
  ATMI_STATUS_UNKNOWN = 1,
  /**
   * A generic error has occurred.
   */
  ATMI_STATUS_ERROR = 2,
  /**
   * Too many kernel/task types have been created.
   */
  ATMI_STATUS_KERNELCOUNT_OVERFLOW = 3
} atmi_status_t;


typedef enum atmi_devtype_s {
  ATMI_DEVTYPE_CPU = 0x0001,
  ATMI_DEVTYPE_iGPU = 0x0010,                                // Integrated GPU
  ATMI_DEVTYPE_dGPU = 0x0100,                                // Discrete GPU
  ATMI_DEVTYPE_GPU = ATMI_DEVTYPE_iGPU | ATMI_DEVTYPE_dGPU,  // Any GPU
  ATMI_DEVTYPE_DSP = 0x1000,
  ATMI_DEVTYPE_ALL = 0x1111  // Union of all device types
} atmi_devtype_t;

typedef struct atmi_place_s {
  /**
   * The node in a cluster where computation should occur.
   * Default is node_id = 0 for local computations.
   */
  unsigned int node_id;
  /**
   * Device type: CPU, GPU or DSP
   */
  atmi_devtype_t type;
  /**
   * The device ordinal number ordered by runtime; -1 for any
   */
  int device_id;
  /**
   * Compute Unit Mask (advanced feature)
   */
  unsigned long cu_mask;
} atmi_place_t;

typedef struct atmi_mem_place_s {
  /**
   * The node in a cluster where computation should occur.
   * Default is node_id = 0 for local computations.
   */
  unsigned int node_id;
  /**
   * Device type: CPU, GPU or DSP
   */
  atmi_devtype_t dev_type;
  /**
   * The device ordinal number ordered by runtime; -1 for any
   */
  int dev_id;
  // atmi_memtype_t mem_type;        // Fine grained or Coarse grained
  /**
   * The memory space/region ordinal number ordered by runtime; -1 for any
   */
  int mem_id;
} atmi_mem_place_t;

// finds a corresponding gpu
//  atmi_place_t place = ATMI_PLACE_GPU(0, device_id);
atmi_status_t atmi_interop_hsa_get_agent(atmi_place_t proc,
                                         hsa_agent_t *agent);


#define ATMI_MEM_PLACE_CPU_MEM(node, cpu_id, cpu_mem_id)             \
  {                                                                  \
    .node_id = node, .dev_type = ATMI_DEVTYPE_CPU, .dev_id = cpu_id, \
    .mem_id = cpu_mem_id                                             \
  }

#define ATMI_PLACE_GPU(node, gpu_id)                                \
  {                                                                 \
    .node_id = node, .type = ATMI_DEVTYPE_GPU, .device_id = gpu_id, \
    .cu_mask = 0xFFFFFFFFFFFFFFFF                                   \
  }


// roughly atmi_malloc with place == ATMI_MEM_PLACE_CPU_MEM(0,0,0)
atmi_status_t atmi_malloc_hostcall(void **ptr, size_t size);
atmi_status_t atmi_free_hostcall(void *ptr);

// this is astonishingly complicated, but also only used by the vector
// product example
atmi_status_t atmi_memcpy(void *dest, const void *src, size_t size);

typedef unsigned long (*atmi_task_hostcall_handler_t)(void *, uint32_t);
/**
 * @brief Register a callback that performs hostcall buffer processing
 * functions with a task.
 */
atmi_status_t atmi_register_task_hostcall_handler(
    atmi_task_hostcall_handler_t fp);

#endif
