#include "common.h"

int
no_errors(void)
{
    hostcall_consumer_t *consumer = hostcall_create_consumer();
    if (!consumer)
        return __LINE__;

    const uint32_t num_packets = 4;
    void *buffer = create_buffer(num_packets);
    if (!buffer)
        return __LINE__;
    void *aligned_buffer = realign_buffer(buffer);

    CHECK(hostcall_initialize_buffer(aligned_buffer, num_packets));

    hostcall_register_buffer(consumer, aligned_buffer);

    hostcall_launch_consumer(consumer);

    hostcall_destroy_consumer(consumer);
    free(buffer);
    return 0;
}

int
main(int argc, char *argv[])
{
    set_flags(argc, argv);
    if (debug_mode)
        hostcall_enable_debug();

    hsa_init();
    runTest(no_errors);

    return 0;
}
