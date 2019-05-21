#include "hostcall.h"
#include "hostcall_service_id.h"

#include <hsa/hsa.h>
#include <assert.h>
#include <atomic>
#include <cstring>
#include <dlfcn.h>
#include <functional>
#include <iostream>
#include <mutex>
#include <thread>
#include <unordered_map>

#ifndef NDEBUG
bool debug_mode;
#define WHEN_DEBUG(xxx)                                                        \
    do {                                                                       \
        if (debug_mode) {                                                      \
            xxx;                                                               \
        }                                                                      \
    } while (false)
#else
#define WHEN_DEBUG(xxx)
#endif // NDEBUG

#define GET_FUNCTION(ptr, name)                                                \
    auto ptr = (decltype(name) *)dlsym(RTLD_DEFAULT, #name);

GET_FUNCTION(my_hsa_signal_wait, hsa_signal_wait_acquire);

enum { SIGNAL_INIT = UINT64_MAX, SIGNAL_DONE = UINT64_MAX - 1 };

typedef enum {
    CONTROL_OFFSET_READY_FLAG = 0,
    CONTROL_OFFSET_RESERVED0 = 1,
} control_offset_t;

typedef enum {
    CONTROL_WIDTH_READY_FLAG = 1,
    CONTROL_WIDTH_RESERVED0 = 31,
} control_width_t;

static uint32_t set_control_field(uint32_t control, uint8_t offset, uint8_t width,
                  uint32_t value) {
    uint32_t mask = ~(((1 << width) - 1) << offset);
    control &= mask;
    return control | (value << offset);
}

static uint32_t reset_ready_flag(uint32_t control) {
    return set_control_field(control, CONTROL_OFFSET_READY_FLAG,
                             CONTROL_WIDTH_READY_FLAG, 0);
}

static uint64_t get_ptr_index(uint64_t ptr, uint32_t index_size) {
    return ptr & ((1UL << index_size) - 1);
}

static uintptr_t align_to(uintptr_t value, uint32_t alignment) {
    if (value % alignment == 0)
        return value;
    return value - (value % alignment) + alignment;
}

static uintptr_t get_header_start() {
    return align_to(sizeof(hostcall_buffer_t), alignof(header_t));
}

static uintptr_t get_payload_start(uint32_t num_packets) {
    auto header_start = get_header_start();
    auto header_end = header_start + sizeof(header_t) * num_packets;
    return align_to(header_end, alignof(payload_t));
}

static signal_t create_signal() {
    GET_FUNCTION(hsc, hsa_signal_create);
    if (!hsc) {
        return {0};
    }
    hsa_signal_t hs;
    hsa_status_t status = hsc(SIGNAL_INIT, 0, NULL, &hs);
    if (status != HSA_STATUS_SUCCESS)
        return {0};
    return {hs.handle};
}

static uint64_t wait_on_signal(signal_t doorbell, uint64_t timeout,
	       	uint64_t old_value) {
    WHEN_DEBUG(std::cout << std::endl
                         << "old signal value: " << (int64_t)old_value
                         << std::endl);
    hsa_signal_t hs{doorbell.handle};
    assert(my_hsa_signal_wait);
    while (true) {
        uint64_t new_value =
            my_hsa_signal_wait(hs, HSA_SIGNAL_CONDITION_NE, old_value, timeout,
                               HSA_WAIT_STATE_BLOCKED);
        WHEN_DEBUG(std::cout << "\nnew signal value: " << new_value
                             << std::endl);
        if (new_value != old_value)
            return new_value;
    }
}

/** \brief Locked reference to critical data.
 *
 *         Simpler version of the LockedAccessor in HIP sources.
 *
 *         Protects access to the member _data with a lock acquired on
 *         contruction/destruction. T must contain a _mutex field
 *         which meets the BasicLockable requirements (lock/unlock)
 */
template <typename T> struct locked_accessor_t {
    locked_accessor_t(T &criticalData) : _criticalData(&criticalData)
    {
        _criticalData->_mutex.lock();
    };

    ~locked_accessor_t() { _criticalData->_mutex.unlock(); }

    // Syntactic sugar so -> can be used to get the underlying type.
    T *operator->() { return _criticalData; };

  private:
    T *_criticalData;
};

struct record_t {
    bool discarded;
};

typedef std::function<void(uint64_t *)> service_handler_t;

struct critical_data_t {
    std::unordered_map<hostcall_buffer_t *, record_t> buffers;
    std::unordered_map<uint32_t, service_handler_t> handlers;
    std::mutex _mutex;
};

typedef locked_accessor_t<critical_data_t> locked_critical_data_t;

/** \brief Encapsulates the entire consumer thread functionality.
 *
 *  The C API exposed in the header is a thin wrapper around this
 *  class. This ensures that the C++ interface is easy to expose if
 *  required.
 */
class hostcall_consumer_t {
    signal_t doorbell;
    std::thread thread;
    hostcall_error_callback_t handle_error;
    void *error_callback_data;
    critical_data_t critical_data;

    hostcall_consumer_t(signal_t _doorbell) : doorbell(_doorbell) {}

  public:
    void register_service(uint32_t service, hostcall_service_handler_t handler,
                          void *cbdata);

    void register_buffer(void *buffer);
    hostcall_error_t deregister_buffer(void *buffer);

    void process_packets(hostcall_buffer_t *buffer, uint64_t F) const;
    // FIXME: This cannot be const because it locks critical data. A
    // lock-free implementaiton might make that possible.
    void consume_packets();

    void launch();
    hostcall_error_t terminate();

    hostcall_error_t on_error(hostcall_error_callback_t handler, void *cbdata);

    static hostcall_consumer_t *create();
    ~hostcall_consumer_t();
};

static uint64_t grab_ready_stack(hostcall_buffer_t *buffer) {
    return __atomic_exchange_n(&buffer->ready_stack, 0, std::memory_order_acquire);
}

static header_t * get_header(hostcall_buffer_t *buffer, ulong ptr) {
    return buffer->headers + get_ptr_index(ptr, buffer->index_size);
}

static payload_t * get_payload(hostcall_buffer_t *buffer, ulong ptr) {
    return buffer->payloads + get_ptr_index(ptr, buffer->index_size);
}

// FIXME: Clean up this diagnostic and die properly
void hostcall_version_check(uint device_vrm) {
    uint device_version_release = device_vrm >> 8;
    if (device_version_release != HOSTCALL_VERSION_RELEASE ) {
      printf("ERROR Incompatible device and host release\n      Device release(%hd)\n      Host release(%d)\n",device_version_release, HOSTCALL_VERSION_RELEASE);
      exit(1);
    }
    if (device_vrm > HOSTCALL_VRM) {
      printf("ERROR Incompatible device and host version \n       Device version(%hd)\n      Host version(%d)\n",device_vrm, HOSTCALL_VERSION_RELEASE);
      exit(2);
    }
    if (device_vrm < HOSTCALL_VRM) {
      unsigned int host_ver = ((unsigned int) HOSTCALL_VRM) >> 16;
      unsigned int host_rel = (((unsigned int) HOSTCALL_VRM) << 16) >>24  ;
      unsigned int host_mod = (((unsigned int) HOSTCALL_VRM) << 24) >>24 ;
      unsigned int dev_ver = ((unsigned int) device_vrm) >> 16;
      unsigned int dev_rel = (((unsigned int) device_vrm) << 16) >>24  ;
      unsigned int dev_mod = (((unsigned int) device_vrm) << 24) >>24 ;
      printf("WARNING:  Device mod version < host mod version \n          Device version: %d.%d.%d\n          Host version:   %d.%d.%d\n",
         dev_ver,dev_rel,dev_mod, host_ver,host_rel,host_mod);
      printf("          Please consider upgrading hostcall on your host\n");
    }
}

static bool hostcall_version_checked;

void hostcall_consumer_t::process_packets(hostcall_buffer_t *buffer,
                                     uint64_t ready_stack) const {
    // This function is always called from consume_packets, which owns
    // the lock for the critical data.

    WHEN_DEBUG(std::cout << "process packets starting with " << ready_stack
                         << std::endl);

    // Each wave can submit at most one packet at a time, and all
    // waves independently push ready packets. The stack of packets at
    // this point cannot contain multiple packets from the same wave,
    // so consuming ready packets in a latest-first order does not
    // affect any wave.
    for (decltype(ready_stack) iter = ready_stack, next = 0; iter;
         iter = next) {
        WHEN_DEBUG(std::cout << "processing ptr: " << iter << std::endl);
        WHEN_DEBUG(std::cout << "packet index: " << std::dec
                             << get_ptr_index(iter, buffer->index_size)
                             << std::endl);

        // Remember the next packet pointer. The current packet will
        // get reused from the free stack after we process it.
        auto header = get_header(buffer, iter);
        next = header->next;

        uint service = ((uint) header->service <<16 ) >> 16;
        if (!hostcall_version_checked) {
           uint device_vrm = ((uint) header->service >> 16 );
	   hostcall_version_check(device_vrm);
	   hostcall_version_checked = true;
	}

        WHEN_DEBUG(std::cout << "packet service: " << (uint32_t)service
                             << std::endl);

        auto h_iter = critical_data.handlers.find(service);
        if (h_iter == critical_data.handlers.end())
            h_iter = critical_data.handlers.find(0);
        if (h_iter == critical_data.handlers.end()) {
            std::cerr << std::endl
                      << "hostcall fatal error: no service found for service ID "
                      << (uint32_t)service << std::endl;
            if (handle_error) {
                handle_error(HOSTCALL_ERROR_SERVICE_UNKNOWN,
                             error_callback_data);
            }
            std::quick_exit(EXIT_FAILURE);
        }
        auto handler = h_iter->second;
        auto payload = get_payload(buffer, iter);
        uint64_t activemask = header->activemask;
        WHEN_DEBUG(std::cout << "activemask: " << std::hex << activemask
                             << std::endl);

        for (uint32_t wi = 0; wi != 64; ++wi) {
            uint64_t flag = activemask & ((uint64_t)1 << wi);
            if (flag == 0)
                continue;
            uint64_t *slot = payload->slots[wi];
            handler(slot);
        }

        __atomic_store_n(&header->control, reset_ready_flag(header->control),
                         std::memory_order_release);
    }
}

void
hostcall_consumer_t::consume_packets()
{
    /* TODO: The consumer iterates over all registered buffers in an
       unspecified order, and for each buffer, processes packets also
       in an unspecified order. This may need a more efficient
       strategy based on the turnaround time for the services
       requested by all these packets.
     */
    WHEN_DEBUG(std::cout << "launched consumer" << std::endl);
    uint64_t signal_value = SIGNAL_INIT;
    uint64_t timeout = 1024 * 1024;
    hostcall_version_checked = false;

    while (true) {
        signal_value = wait_on_signal(doorbell, timeout, signal_value);

        if (signal_value == SIGNAL_DONE) {
            return;
        }

        locked_critical_data_t data(critical_data);

        for (auto ii = data->buffers.begin(), ie = data->buffers.end();
             ii != ie;
             /* don't increment here */) {
            auto record = ii->second;
            if (record.discarded) {
                ii = data->buffers.erase(ii);
                continue;
            }

            hostcall_buffer_t *buffer = ii->first;
            uint64_t F = grab_ready_stack(buffer);
            WHEN_DEBUG(std::cout << "grabbed ready stack: " << F << std::endl);
            if (F) {
                process_packets(buffer, F);
            }
            ++ii;
        }
        signal_value = SIGNAL_INIT;
    }

    return;
}

void
hostcall_consumer_t::launch() {
    if (thread.joinable()) {
        return;
    }
    thread = std::thread(&hostcall_consumer_t::consume_packets, this);
}

hostcall_error_t
hostcall_consumer_t::terminate()
{
    if (!thread.joinable())
        return HOSTCALL_ERROR_CONSUMER_INACTIVE;
    hsa_signal_t signal = {doorbell.handle};
    GET_FUNCTION(hssr, hsa_signal_store_release);
    assert(hssr);
    hssr(signal, SIGNAL_DONE);
    thread.join();
    return HOSTCALL_SUCCESS;
}

void
hostcall_consumer_t::register_service(uint32_t service,
                                      hostcall_service_handler_t handler,
                                      void *cbdata)
{
    locked_critical_data_t data(critical_data);
    using namespace std::placeholders;
    // Silently over-ride an older entry if present.
    data->handlers[service] = std::bind(handler, cbdata, service, _1);
}

void
hostcall_consumer_t::register_buffer(void *b)
{
    locked_critical_data_t data(critical_data);
    auto buffer = reinterpret_cast<hostcall_buffer_t *>(b);

    auto &record = data->buffers[buffer];
    WHEN_DEBUG(std::cout << "registered buffer: " << std::hex << b
                         << std::endl);
    record.discarded = false;
    buffer->doorbell = doorbell;
    WHEN_DEBUG(std::cout << "signal: " << buffer->doorbell.handle << std::endl);
}

hostcall_error_t hostcall_consumer_t::deregister_buffer(void *b) {
    locked_critical_data_t data(critical_data);
    auto buffer = reinterpret_cast<hostcall_buffer_t *>(b);
    if (data->buffers.count(buffer) == 0)
        return HOSTCALL_ERROR_INVALID_REQUEST;
    auto &record = data->buffers[buffer];
    if (record.discarded)
        return HOSTCALL_ERROR_INVALID_REQUEST;
    record.discarded = true;
    return HOSTCALL_SUCCESS;
}

hostcall_consumer_t::~hostcall_consumer_t() {
    terminate();
    critical_data.buffers.clear();
    critical_data.handlers.clear();
    GET_FUNCTION(hsd, hsa_signal_destroy);
    assert(hsd);
    hsa_signal_t hs{doorbell.handle};
    hsd(hs);
}

hostcall_consumer_t * hostcall_consumer_t::create() {
    signal_t doorbell = create_signal();
    if (doorbell.handle == 0)
        return nullptr;
    return new hostcall_consumer_t(doorbell);
}

hostcall_error_t hostcall_consumer_t::on_error(hostcall_error_callback_t handler, void *cbdata) {
    if (thread.joinable())
        return HOSTCALL_ERROR_CONSUMER_ACTIVE;
    handle_error = handler;
    error_callback_data = cbdata;
    return HOSTCALL_SUCCESS;
}

#define EXTERN extern "C"
EXTERN hostcall_consumer_t * hostcall_create_consumer() {
    return hostcall_consumer_t::create();
}

EXTERN void hostcall_register_service(hostcall_consumer_t *consumer, uint32_t service, hostcall_service_handler_t handler, void *cbdata) {
    consumer->register_service(service, handler, cbdata);
}

EXTERN const size_t hostcall_get_buffer_size(uint32_t num_packets) {
    WHEN_DEBUG(std::cout << "header start: " << get_header_start()
                         << std::endl);
    WHEN_DEBUG(std::cout << "payload start: " << get_payload_start(num_packets)
                         << std::endl);
    size_t buffer_size = get_payload_start(num_packets);
    buffer_size += num_packets * sizeof(payload_t);
    return buffer_size;
}

EXTERN uint32_t hostcall_get_buffer_alignment() {
    return alignof(payload_t);
}

EXTERN hostcall_error_t hostcall_initialize_buffer(void *buffer, uint32_t num_packets) {
    if (!buffer) {
        return HOSTCALL_ERROR_NULLPTR;
    }

    if ((uintptr_t)buffer % hostcall_get_buffer_alignment() != 0) {
        return HOSTCALL_ERROR_INCORRECT_ALIGNMENT;
    }

    hostcall_buffer_t *hb = (hostcall_buffer_t *)buffer;

    hb->headers = (header_t *)((uint8_t *)hb + get_header_start());
    hb->payloads =
        (payload_t *)((uint8_t *)hb + get_payload_start(num_packets));

    uint32_t index_size = 1;
    if (num_packets > 2)
        index_size = 32 - __builtin_clz(num_packets);
    WHEN_DEBUG(std::cout << "index size: " << index_size << std::endl);
    hb->index_size = index_size;
    hb->headers[0].next = 0;

    uint64_t next = 1UL << index_size;
    for (uint32_t ii = 1; ii != num_packets; ++ii) {
        hb->headers[ii].next = next;
        next = ii;
    }
    hb->free_stack = next;
    hb->ready_stack = 0;

    return HOSTCALL_SUCCESS;
}

EXTERN void hostcall_register_buffer(hostcall_consumer_t *consumer, void *buffer) {
    consumer->register_buffer(buffer);
}

EXTERN hostcall_error_t hostcall_deregister_buffer( hostcall_consumer_t *consumer, void *buffer) {
    return consumer->deregister_buffer(buffer);
}

EXTERN void hostcall_launch_consumer(hostcall_consumer_t *consumer) {
    consumer->launch();
}

EXTERN void hostcall_destroy_consumer(hostcall_consumer_t *consumer) {
    delete consumer;
}

EXTERN hostcall_error_t hostcall_on_error(hostcall_consumer_t *consumer, hostcall_error_callback_t handler, void *cbdata) {
    return consumer->on_error(handler, cbdata);
}

EXTERN void hostcall_enable_debug() {
#ifndef NDEBUG
    debug_mode = true;
#endif
}

EXTERN const char * hostcall_error_string(hostcall_error_t error) {
    switch (error) {
    case HOSTCALL_SUCCESS:
        return "HOSTCALL_SUCCESS";
    case HOSTCALL_ERROR_CONSUMER_ACTIVE:
        return "HOSTCALL_ERROR_CONSUMER_ACTIVE";
    case HOSTCALL_ERROR_INVALID_REQUEST:
        return "HOSTCALL_ERROR_INVALID_REQUEST";
    case HOSTCALL_ERROR_SERVICE_UNKNOWN:
        return "HOSTCALL_ERROR_SERVICE_UNKNOWN";
    case HOSTCALL_ERROR_INCORRECT_ALIGNMENT:
        return "HOSTCALL_ERROR_INCORRECT_ALIGNMENT";
    case HOSTCALL_ERROR_NULLPTR:
        return "HOSTCALL_ERROR_NULLPTR";
    default:
        return "HOSTCALL_ERROR_UNKNOWN";
    }
}
