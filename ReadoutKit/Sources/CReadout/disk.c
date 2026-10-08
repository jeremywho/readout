#include "readout.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <string.h>
#include <sys/attr.h>
#include <unistd.h>

int readout_read_volume_used(const char *path, int64_t *used) {
    struct attrlist request;
    memset(&request, 0, sizeof request);
    request.bitmapcount = ATTR_BIT_MAP_COUNT;
    request.volattr = ATTR_VOL_INFO | ATTR_VOL_SPACEUSED;
    struct {
        uint32_t length;
        off_t space_used;
    } __attribute__((packed)) reply;
    if (getattrlist(path, &request, &reply, sizeof reply, 0) != 0 || reply.length < sizeof reply) {
        return -1;
    }
    *used = (int64_t)reply.space_used;
    return 0;
}

static uint64_t readout_statistic(CFDictionaryRef statistics, CFStringRef key) {
    CFNumberRef number = CFDictionaryGetValue(statistics, key);
    int64_t value = 0;
    if (number == NULL || CFGetTypeID(number) != CFNumberGetTypeID() ||
        !CFNumberGetValue(number, kCFNumberSInt64Type, &value) || value < 0) {
        return 0;
    }
    return (uint64_t)value;
}

int readout_read_disk_io(uint64_t *bytes_read, uint64_t *bytes_written) {
    io_iterator_t iterator = MACH_PORT_NULL;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) !=
        KERN_SUCCESS) {
        return -1;
    }
    uint64_t read_total = 0;
    uint64_t write_total = 0;
    io_registry_entry_t driver;
    while ((driver = IOIteratorNext(iterator)) != MACH_PORT_NULL) {
        CFTypeRef statistics = IORegistryEntryCreateCFProperty(driver, CFSTR("Statistics"), kCFAllocatorDefault, 0);
        if (statistics != NULL && CFGetTypeID(statistics) == CFDictionaryGetTypeID()) {
            read_total += readout_statistic((CFDictionaryRef)statistics, CFSTR("Bytes (Read)"));
            write_total += readout_statistic((CFDictionaryRef)statistics, CFSTR("Bytes (Write)"));
        }
        if (statistics != NULL) {
            CFRelease(statistics);
        }
        IOObjectRelease(driver);
    }
    IOObjectRelease(iterator);
    *bytes_read = read_total;
    *bytes_written = write_total;
    return 0;
}
