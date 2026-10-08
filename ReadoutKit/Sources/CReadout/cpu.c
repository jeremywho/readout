#include "readout.h"
#include "internal.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <string.h>

int readout_read_core_ticks(readout_core_ticks *out, int capacity) {
    natural_t cpu_count = 0;
    processor_info_array_t info = NULL;
    mach_msg_type_number_t info_count = 0;
    if (host_processor_info(readout_host(), PROCESSOR_CPU_LOAD_INFO, &cpu_count, &info, &info_count) != KERN_SUCCESS) {
        return -1;
    }
    int count = (int)cpu_count < capacity ? (int)cpu_count : capacity;
    for (int i = 0; i < count; i++) {
        integer_t *ticks = info + i * CPU_STATE_MAX;
        out[i].user = (uint32_t)ticks[CPU_STATE_USER];
        out[i].system = (uint32_t)ticks[CPU_STATE_SYSTEM];
        out[i].idle = (uint32_t)ticks[CPU_STATE_IDLE];
        out[i].nice = (uint32_t)ticks[CPU_STATE_NICE];
    }
    vm_deallocate(mach_task_self(), (vm_address_t)info, info_count * sizeof(integer_t));
    return count;
}

static int readout_cpu_id(CFTypeRef value, uint32_t *id) {
    if (value == NULL) {
        return -1;
    }
    if (CFGetTypeID(value) == CFNumberGetTypeID()) {
        int32_t number = 0;
        if (!CFNumberGetValue((CFNumberRef)value, kCFNumberSInt32Type, &number) || number < 0) {
            return -1;
        }
        *id = (uint32_t)number;
        return 0;
    }
    if (CFGetTypeID(value) == CFDataGetTypeID() && CFDataGetLength((CFDataRef)value) >= 4) {
        uint32_t number = 0;
        CFDataGetBytes((CFDataRef)value, CFRangeMake(0, 4), (UInt8 *)&number);
        *id = number;
        return 0;
    }
    return -1;
}

int readout_read_core_kinds(char *out, int capacity) {
    io_registry_entry_t cpus = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/cpus");
    if (cpus == MACH_PORT_NULL) {
        return -1;
    }
    io_iterator_t children = MACH_PORT_NULL;
    if (IORegistryEntryGetChildIterator(cpus, kIODeviceTreePlane, &children) != KERN_SUCCESS) {
        IOObjectRelease(cpus);
        return -1;
    }
    memset(out, 0, (size_t)capacity);
    int count = 0;
    io_registry_entry_t child;
    while ((child = IOIteratorNext(children)) != MACH_PORT_NULL) {
        CFTypeRef id_value = IORegistryEntryCreateCFProperty(child, CFSTR("logical-cpu-id"), kCFAllocatorDefault, 0);
        CFTypeRef type_value = IORegistryEntryCreateCFProperty(child, CFSTR("cluster-type"), kCFAllocatorDefault, 0);
        uint32_t id = 0;
        if (readout_cpu_id(id_value, &id) == 0 && type_value != NULL && CFGetTypeID(type_value) == CFDataGetTypeID() &&
            CFDataGetLength((CFDataRef)type_value) > 0 && id < (uint32_t)capacity) {
            out[id] = (char)CFDataGetBytePtr((CFDataRef)type_value)[0];
            if ((int)id + 1 > count) {
                count = (int)id + 1;
            }
        }
        if (id_value != NULL) {
            CFRelease(id_value);
        }
        if (type_value != NULL) {
            CFRelease(type_value);
        }
        IOObjectRelease(child);
    }
    IOObjectRelease(children);
    IOObjectRelease(cpus);
    for (int i = 0; i < count; i++) {
        if (out[i] != 'P' && out[i] != 'E') {
            return -1;
        }
    }
    return count > 0 ? count : -1;
}
