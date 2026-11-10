#include "readout.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <string.h>

static int readout_dictionary_int64(CFDictionaryRef dictionary, CFStringRef key, int64_t *value) {
    CFTypeRef number = CFDictionaryGetValue(dictionary, key);
    if (number == NULL || CFGetTypeID(number) != CFNumberGetTypeID()) {
        return -1;
    }
    return CFNumberGetValue((CFNumberRef)number, kCFNumberSInt64Type, value) ? 0 : -1;
}

static void readout_copy_model(io_registry_entry_t accelerator, char *out, size_t capacity) {
    out[0] = '\0';
    CFTypeRef model = IORegistryEntryCreateCFProperty(accelerator, CFSTR("model"), kCFAllocatorDefault, 0);
    if (model == NULL) {
        return;
    }
    if (CFGetTypeID(model) == CFStringGetTypeID()) {
        if (!CFStringGetCString((CFStringRef)model, out, (CFIndex)capacity, kCFStringEncodingUTF8)) {
            out[0] = '\0';
        }
    } else if (CFGetTypeID(model) == CFDataGetTypeID()) {
        size_t length = (size_t)CFDataGetLength((CFDataRef)model);
        if (length > capacity - 1) {
            length = capacity - 1;
        }
        memcpy(out, CFDataGetBytePtr((CFDataRef)model), length);
        out[length] = '\0';
    }
    CFRelease(model);
}

int readout_read_gpu(readout_gpu *out) {
    io_iterator_t accelerators = MACH_PORT_NULL;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &accelerators) !=
        KERN_SUCCESS) {
        return -1;
    }
    int found = -1;
    io_registry_entry_t accelerator;
    while ((accelerator = IOIteratorNext(accelerators)) != MACH_PORT_NULL) {
        CFTypeRef statistics =
            IORegistryEntryCreateCFProperty(accelerator, CFSTR("PerformanceStatistics"), kCFAllocatorDefault, 0);
        if (statistics != NULL && CFGetTypeID(statistics) == CFDictionaryGetTypeID()) {
            int64_t utilization = 0;
            int64_t memory = 0;
            if (readout_dictionary_int64((CFDictionaryRef)statistics, CFSTR("Device Utilization %"), &utilization) == 0 &&
                (found != 0 || utilization > out->utilization_percent)) {
                out->utilization_percent = (int32_t)utilization;
                out->has_memory_in_use =
                    readout_dictionary_int64((CFDictionaryRef)statistics, CFSTR("In use system memory"), &memory) == 0 &&
                    memory >= 0;
                out->memory_in_use = out->has_memory_in_use ? (uint64_t)memory : 0;
                readout_copy_model(accelerator, out->model, sizeof(out->model));
                found = 0;
            }
        }
        if (statistics != NULL) {
            CFRelease(statistics);
        }
        IOObjectRelease(accelerator);
    }
    IOObjectRelease(accelerators);
    return found;
}
