#ifndef __ATMI_HOSTCALL_H__
#define __ATMI_HOSTCALL_H__

#ifdef __cplusplus
extern "C" {
#endif

unsigned long atmi_hostcall_assign_buffer(unsigned int minpackets,
                hsa_queue_t * this_Q, hsa_amd_memory_pool_t finegrain_pool,
		uint32_t device_id); 
hsa_status_t atmi_hostcall_init();
hsa_status_t atmi_hostcall_terminate();

#ifdef __cplusplus
} // extern "C"
#endif

#endif // __ATMI_HOSTCALL_H__
