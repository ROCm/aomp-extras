#ifndef __HOSTCALL_H__
#define __HOSTCALL_H__

#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint64_t handle;
} signal_t;

typedef struct {
    uint64_t next;
    uint64_t activemask;
    uint32_t service;
    uint32_t control;
} header_t;

typedef struct {
    // 64 slots of 8 ulongs each
    uint64_t slots[64][8];
} payload_t;

typedef struct {
    header_t *headers;
    payload_t *payloads;
    signal_t doorbell;
    uint64_t free_stack;
    uint64_t ready_stack;
    uint32_t index_size;
} hostcall_buffer_t;

/** \file Support library for invoking host services from the device.
 *
 *  The hostcall consumer defined here is used by the language runtime
 *  to serve requests originating from kernels running on GPU
 *  devices. A typical flow is as follows:
 *
 *  - Create and launch one or more hostcall consumers.
 *  - Create and initialize a hostcall buffer per command queue.
 *  - Register these buffers with the appropriate consumer.
 *  - When a buffer is no longer used, deregister and then free it.
 *  - Destroy the consumer(s) when they are no longer required. Must be
 *    done before exiting the application, so that the consumer
 *    threads can join() correctly.
 *
 *  For a more information, see the accompanying README and the
 *  comments associated with each of the API functions.
 */

typedef enum {
    HOSTCALL_SUCCESS,
    HOSTCALL_ERROR_CONSUMER_ACTIVE,
    HOSTCALL_ERROR_CONSUMER_INACTIVE,
    HOSTCALL_ERROR_INVALID_REQUEST,
    HOSTCALL_ERROR_SERVICE_UNKNOWN,
    HOSTCALL_ERROR_INCORRECT_ALIGNMENT,
    HOSTCALL_ERROR_NULLPTR
} hostcall_error_t;

/// Opaque struct that encapsulates a consumer thread.
typedef struct hostcall_consumer_t hostcall_consumer_t;

#ifdef __cplusplus
extern "C" {
#endif

const char * hostcall_error_string(hostcall_error_t error);

/** \brief Create a consumer instance that tracks a single consumer thread.
 *
 *  Each instance manages a unique consumer thread, along with a list
 *  of hostcall buffers that this thread processes. The consumer does
 *  not occupy any resources other than it's own memory footprint
 *  until it is launched.
 *
 *  The corresponding consumer thread must be launched for the
 *  consumer to perform any actual work. The consumer thread can be
 *  launched even without any buffers registered with the
 *  consumer. The API provides thread-safe methods to register buffers
 *  with an active consumer.
 *
 *  A single consumer is sufficient to correctly handle all hostcall
 *  buffers created in the application. The client may safely launch
 *  multiple consumers based on factors external to this library.
 */
hostcall_consumer_t * hostcall_create_consumer(void);

/** \brief Destroy a consumer instance.
 *
 *  If the consumer is active, the corresponding thread is terminated
 *  and join()'ed to the current thread.
 *
 *  Behavious is undefined when called multiple times on the same
 *  pointer, or using a pointer that was not previously created by
 *  hostcall_create_consumer().
 */
void hostcall_destroy_consumer(hostcall_consumer_t *consumer);

/** \brief Function invoked on each workitem payload.
 *  \param cbdata  Additional data provided by the client.
 *  \param service Service ID received on the packet. This allows a
 *                 single function to be registered for multiple service IDs
 *  \param payload Pointer to an array of eight 64-bit integer values.
 */
typedef void (*hostcall_service_handler_t)(void *cbdata, uint32_t service,
                                           uint64_t *payload);

/** \brief Register a service handler.
 *
 *  The handler is invoked when the consumer receives a packet with
 *  the indicated service on any of its registered buffers. #cbdata
 *  and #service are passed to the handler along with the payload of
 *  one workitem at a time.
 *
 *  Registering a handler for a service silently over-rides any
 *  previously registered handler for the same service.
 *
 *  The service ID "0" (zero)
 *  is reserved as the default handler. The default handler is
 *  invoked when a received packet specifies a service with no
 *  registered handler.
 */
void hostcall_register_service(hostcall_consumer_t *consumer, uint32_t service,
                              hostcall_service_handler_t handler, void *cbdata);

/** \brief Determine the buffer size to be allocated for the given
 *         number of packets.
 *
 *  The reported size includes any internal padding required for the
 *  packets and their headers.
 */
const size_t hostcall_get_buffer_size(uint32_t num_packets);

/** \brief Alignment required for the start of the buffer.
 */
uint32_t hostcall_get_buffer_alignment(void);

/** \brief Initialize the buffer data-structure.
 *  \param buffer      Pointer to allocated buffer.
 *  \param num_packets Number of packets to be created in the buffer.
 *  \return Error code indicating success or specific failure.
 *
 *  The function assumes that the supplied buffer is sufficiently
 *  large to accomodate the specified number of packets. The value
 *  returned is one of:
 *
 *  \li \c HOSTCALL_SUCCESS on successful initialization.
 *  \li \c HOSTCALL_ERROR_NULLPTR if the supplied pointer is NULL.
 *  \li \c HOSTCALL_ERROR_INCORRECT_ALIGNMENT if the supplied
 *      pointer is not aligned to the value returned by
 *      hostcall_get_buffer_alignment().
 */
hostcall_error_t hostcall_initialize_buffer(void *buffer, uint32_t num_packets);

/** \brief Register a buffer with a consumer.
 *
 *  Behaviour is undefined if:
 *  - hostcall_initialize_buffer() was not invoked successfully on
 *    the buffer prior to registration.
 *  - The same buffer is registered with multiple consumers.
 *
 *  The function has no effect if the a buffer is registered multiple
 *  times with the same consumer.
 *
 *  The client must register a buffer before launching any kernel that
 *  accesses that buffer. The client must further ensure that each
 *  buffer is associated with a unique command queue across all
 *  devices.
 */
void hostcall_register_buffer(hostcall_consumer_t *consumer, void *buffer);

/** \brief Deregister a buffer that is no longer in use.
 *
 *  The client may free this buffer after deregistering it from the
 *  corresponding consumer. Behaviour is undefined if the buffer is
 *  freed without first deregistering it from the consumer.
 *
 *  The value returned is one of:
 *  \li \c HOSTCALL_SUCCESS on success.
 *  \li \c HOSTCALL_ERROR_INVALID_REQUEST if the buffer was
 *      previously deregistered or not registered with this consumer.
 */
hostcall_error_t hostcall_deregister_buffer(hostcall_consumer_t *consumer, void *buffer);

/** \brief Launch the consumer in its own thread.
 *
 *  The consumer itself manages its std::thread, and this function has
 *  no effect if the consumer is alreary running.
 */
void hostcall_launch_consumer(hostcall_consumer_t *consumer);

typedef void (*hostcall_error_callback_t)(hostcall_error_t, void *cbdata);

/** \brief Register a handler for non-recoverable errors.
 *
 *  If the consumer cannot find a service handler for a received
 *  packet, it causes the application to exit after invoking the
 *  registered handler.
 *
 *  The error callback can be registered only before the consumer is
 *  launched. Calling this function on a consumer with an active
 *  thread returns HOSTCALL_ERROR_CONSUMER_INACTIVE.
 */
hostcall_error_t hostcall_on_error(hostcall_consumer_t *consumer, hostcall_error_callback_t fptr,
                  void *cbdata);

/** \brief Print debug messages to standard output.
 *
 *  Enabling debug in a release build has no effect.
 *
 *  TODO: Implement logging that can be controlled by the client.
 */
void hostcall_enable_debug(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // __HOSTCALL_H__
