extern "C" {
#include "minimal_atmi.h"
}

#include <vector>

#undef NDEBUG
#include <cassert>

#if 1

const char *get_error_string(hsa_status_t) { return ""; }

#define ErrorCheck(msg, status)                                                \
  if (status != HSA_STATUS_SUCCESS) {                                          \
    printf("[%s:%d] %s failed: %s / %lu\n", __FILE__, __LINE__, #msg,          \
           get_error_string(status), (uint64_t)status);                        \
    exit(1);                                                                   \
  } else {                                                                     \
    /*  printf("%s succeeded.\n", #msg);*/                                     \
  }

static hsa_agent_t find_cpu_agent() {
  hsa_agent_t res;
  hsa_status_t (*callback)(hsa_agent_t, void *) = [](hsa_agent_t agent,
                                                     void *data) {
    hsa_agent_t *rdata = static_cast<hsa_agent_t *>(data);

    hsa_status_t err = HSA_STATUS_SUCCESS;
    hsa_device_type_t device_type;
    err = hsa_agent_get_info(agent, HSA_AGENT_INFO_DEVICE, &device_type);
    ErrorCheck(Get device type info, err);

    if (device_type == HSA_DEVICE_TYPE_CPU) {
      *rdata = agent;
      // printf("found a cpu agent\n");
      return HSA_STATUS_INFO_BREAK;
    }

    return err;
  };

  hsa_status_t status = hsa_iterate_agents(callback, static_cast<void *>(&res));
  assert(status == HSA_STATUS_INFO_BREAK);
  return res;
}

static std::vector<hsa_agent_t> find_all_gpu_agents() {
  std::vector<hsa_agent_t> res;

  hsa_status_t (*callback)(hsa_agent_t, void *) = [](hsa_agent_t agent,
                                                     void *data) {
    std::vector<hsa_agent_t> *rdata =
        static_cast<std::vector<hsa_agent_t> *>(data);

    hsa_status_t err = HSA_STATUS_SUCCESS;
    hsa_device_type_t device_type;
    err = hsa_agent_get_info(agent, HSA_AGENT_INFO_DEVICE, &device_type);
    ErrorCheck(Get device type info, err);

    if (device_type == HSA_DEVICE_TYPE_GPU) {
      rdata->push_back(agent);
      // printf("found a gpu agent\n");
      return HSA_STATUS_SUCCESS;
    }

    return err;
  };

  hsa_status_t status = hsa_iterate_agents(callback, static_cast<void *>(&res));
  assert(status == HSA_STATUS_SUCCESS);
  return res;
}

// Find a fine grained  memory pool
static hsa_status_t get_memory_pool_info(hsa_amd_memory_pool_t memory_pool,
                                         void *data) {
  auto vec = static_cast<hsa_amd_memory_pool_t *>(data);
  hsa_status_t err = HSA_STATUS_SUCCESS;
  // Check if the memory_pool is allowed to allocate, i.e. do not return group
  // memory
  bool alloc_allowed = false;
  err = hsa_amd_memory_pool_get_info(
      memory_pool, HSA_AMD_MEMORY_POOL_INFO_RUNTIME_ALLOC_ALLOWED,
      &alloc_allowed);

  if (alloc_allowed) {
    uint32_t global_flag = 0;
    err = hsa_amd_memory_pool_get_info(
        memory_pool, HSA_AMD_MEMORY_POOL_INFO_GLOBAL_FLAGS, &global_flag);
    ErrorCheck(Get memory pool info, err);
    if (HSA_AMD_MEMORY_POOL_GLOBAL_FLAG_FINE_GRAINED & global_flag) {
      // printf("found a fine grained memory pool\n");
      *vec = memory_pool;
      return HSA_STATUS_INFO_BREAK;
    }
  }

  // can return hsa_status_info_break here to only get one pool
  return err;
}

atmi_status_t atmi_malloc_hostcall(void **ptr, size_t size) {

  atmi_status_t ret = ATMI_STATUS_SUCCESS;

  hsa_agent_t agent = find_cpu_agent();
  hsa_amd_memory_pool_t pool;
  auto r = hsa_amd_agent_iterate_memory_pools(agent, get_memory_pool_info,
                                              static_cast<void *>(&pool));

  assert(r == HSA_STATUS_INFO_BREAK);
  hsa_status_t err = hsa_amd_memory_pool_allocate(pool, size, 0, ptr);
  ErrorCheck(atmi_malloc, err);

  // printf("allocated pointer at %p\n", *ptr);

  // may need to stash some metadata in a map as well

  auto gpus = find_all_gpu_agents();

  err = hsa_amd_agents_allow_access(gpus.size(), gpus.data(), NULL, *ptr);
  ErrorCheck(allow_access, err);

#if 0

  DEBUG_PRINT("Malloced [%s %d] %p\n",
              place.dev_type == ATMI_DEVTYPE_CPU ? "CPU" : "GPU", place.dev_id,
              *ptr);
#endif
  if (err != HSA_STATUS_SUCCESS)
    ret = ATMI_STATUS_ERROR;

  return ret;
}

atmi_status_t atmi_free_hostcall(void *ptr) {
  atmi_status_t ret = ATMI_STATUS_SUCCESS;
  // printf("freeing pointer %p\n", ptr);
  hsa_status_t err = hsa_amd_memory_pool_free(ptr);
  ErrorCheck(atmi_free, err);

  if (err != HSA_STATUS_SUCCESS)
    ret = ATMI_STATUS_ERROR;
  return ret;
}

#endif
