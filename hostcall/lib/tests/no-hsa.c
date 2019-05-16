#include <hostcall.h>

int
main(int argc, char *argv[])
{
    hostcall_consumer_t *consumer = hostcall_create_consumer();
    if (consumer)
        return __LINE__;

    return 0;
}
