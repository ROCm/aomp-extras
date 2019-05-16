#include "common.h"

int main(void)
{
    hsa_init();

    auto consumer = hostcall_create_consumer();
    if (!consumer) return __LINE__;

    const uint32_t num_packets = 3;
    void *buffer = create_buffer(num_packets);
    if (!buffer)
        return __LINE__;
    void *aligned_buffer = realign_buffer(buffer);

    if (hostcall_deregister_buffer(consumer, buffer)
        != HOSTCALL_ERROR_INVALID_REQUEST) {
        return __LINE__;
    }

    hostcall_register_buffer(consumer, buffer);

    if (hostcall_deregister_buffer(consumer, buffer)
        != HOSTCALL_SUCCESS) {
        return __LINE__;
    }

    if (hostcall_deregister_buffer(consumer, buffer)
        != HOSTCALL_ERROR_INVALID_REQUEST) {
        return __LINE__;
    }

    free(buffer);
    hostcall_destroy_consumer(consumer);

    return 0;
}
