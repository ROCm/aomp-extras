 
/*   
 *   atmi_hostcall.c: atmi integration of hostcall.
 *                    This source implements a linked list queue in c.
 *                    hostcall buffers and pointer to their consumer
 *                    are placed on the linked list queue (hcb).
 *
 *   Written by Greg Rodgers

MIT License

Copyright © 2019 Advanced Micro Devices, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#include <stdio.h>
#include <stdlib.h>
#include "hsa/hsa_ext_amd.h"
#include "hostcall.h"
#include "atmi_hostcall.h"
#include "hostcall_service_id.h"
#include "hostcall_internal.h"
#include "atmi_runtime.h"

static int atl_hcq_size() { return atl_hcq_count ;}

atl_hcq_element_t * atl_hcq_push(hostcall_buffer_t * hcb, hostcall_consumer_t * consumer, 
		                 hsa_queue_t * hsa_q, uint32_t devid) {
  // FIXME , check rc of these mallocs
  if (atl_hcq_rear == NULL) {
    atl_hcq_rear = (atl_hcq_element_t *) malloc(sizeof(atl_hcq_element_t));
    atl_hcq_front = atl_hcq_rear;
  } else {
    atl_hcq_element_t * new_rear = (atl_hcq_element_t *) malloc(sizeof(atl_hcq_element_t));
    atl_hcq_rear->next_ptr = new_rear;
    atl_hcq_rear = new_rear;
  }
  atl_hcq_rear->next_ptr  = NULL;
  atl_hcq_rear->hcb       = hcb; 
  atl_hcq_rear->hsa_q     = hsa_q;
  atl_hcq_rear->consumer  = consumer;
  atl_hcq_rear->device_id = devid;
  atl_hcq_count++;
  return atl_hcq_rear;
}

#if 0
// we are not using hcq as a true queue so we do not need the pop operation
static void atl_hcq_pop() {
  if (atl_hcq_front  == NULL) {
    printf("\n Error: Trying to pop an element from empty queue");
    return;
  } else {
    if (atl_hcq_front->next_ptr != NULL) {
      atl_hcq_element_t * new_front = atl_hcq_front->next_ptr;
      free(atl_hcq_front);
      atl_hcq_front = new_front;
    } else {
      free(atl_hcq_front);
      atl_hcq_front = NULL;
      atl_hcq_rear = NULL;
    }
    atl_hcq_count--;
  }
}
#endif
 
static atl_hcq_element_t  * atl_hcq_find_by_hsa_q(hsa_queue_t * hsa_q) {
  atl_hcq_element_t * this_front = atl_hcq_front;
  int reverse_counter = atl_hcq_size();
  while (reverse_counter) {
    if (this_front->hsa_q == hsa_q)
       return this_front;
    this_front = this_front->next_ptr;
    reverse_counter--;
  }
  return NULL;
}

static hostcall_buffer_t * atl_hcq_create_buffer(unsigned int num_packets,
	 hsa_amd_memory_pool_t finegrain_pool) {
    if (num_packets == 0) {
	printf("num_packets cannot be zero \n");
	abort();
    }
    size_t size  = hostcall_get_buffer_size(num_packets);
    uint32_t align = hostcall_get_buffer_alignment();
    void *newbuffer = NULL;
    hsa_status_t err = hsa_amd_memory_pool_allocate(finegrain_pool, size+align, 0, &newbuffer);
    if (!newbuffer || (err != HSA_STATUS_SUCCESS) ) {
	    printf("call to  hsa_amd_memory_pool_allocate failed \n");
	    abort();
    }
    if (hostcall_initialize_buffer(newbuffer, num_packets) != HOSTCALL_SUCCESS) {
	    printf("call to  hostcall_initialize_buffer failed \n");
	    abort();
    }
    // printf("created hostcall buffer %p with %d packets \n", newbuffer, num_packets);
    return (hostcall_buffer_t *) newbuffer;
}


void hostcall_register_all_handlers(hostcall_consumer_t * c, void * cbdata);

// These three external functions are called by atmi.
// ATMI uses the header atmi_hostcall.h to reference these. 
//
unsigned long atmi_hostcall_assign_buffer(unsigned int minpackets, 
		hsa_queue_t * this_Q, hsa_amd_memory_pool_t finegrain_pool,
		uint32_t device_id) {
    atl_hcq_element_t * llq_elem ;
    llq_elem  = atl_hcq_find_by_hsa_q(this_Q);
    if (!llq_elem) {
       //  For now, we create one bufer and one consumer per ATMI hsa queue
       hostcall_buffer_t * hcb  = atl_hcq_create_buffer(minpackets, finegrain_pool) ;
       hostcall_consumer_t * c = hostcall_create_consumer();
       hostcall_register_buffer(c,hcb);
       // create element of linked list hcq. This will also be the callback data
       llq_elem = atl_hcq_push( hcb , c, this_Q, device_id);
       hostcall_register_all_handlers(c, (void*) llq_elem);
       hostcall_launch_consumer(c);
    }
    return (unsigned long) llq_elem->hcb;
}

hsa_status_t atmi_hostcall_init() {
   atl_hcq_count = 0;
   atl_hcq_front = atl_hcq_rear = NULL;
   return HSA_STATUS_SUCCESS;
}

hsa_status_t atmi_hostcall_terminate() {
   hostcall_consumer_t * c;
   atl_hcq_element_t * this_front = atl_hcq_front;
   atl_hcq_element_t * last_front;
   int reverse_counter = atl_hcq_size();
   while (reverse_counter) {
      c = this_front->consumer;
      if (c)
        hostcall_destroy_consumer(c);
      hsa_memory_free(this_front->hcb);
      last_front = this_front;
      this_front = this_front->next_ptr;
      free(last_front);
      reverse_counter--;
   }
   atl_hcq_count = 0;
   atl_hcq_front = atl_hcq_rear = NULL;
   return HSA_STATUS_SUCCESS;
}
