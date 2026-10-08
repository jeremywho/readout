#include "readout.h"
#include "internal.h"

#include <sys/sysctl.h>

int readout_read_vm_pages(readout_vm_pages *out) {
    vm_statistics64_data_t stats;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    if (host_statistics64(readout_host(), HOST_VM_INFO64, (host_info64_t)&stats, &count) != KERN_SUCCESS) {
        return -1;
    }
    vm_size_t page_size = 0;
    if (host_page_size(readout_host(), &page_size) != KERN_SUCCESS) {
        return -1;
    }
    out->internal_pages = stats.internal_page_count;
    out->purgeable_pages = stats.purgeable_count;
    out->external_pages = stats.external_page_count;
    out->wired_pages = stats.wire_count;
    out->compressor_pages = stats.compressor_page_count;
    out->page_size = page_size;
    return 0;
}

int readout_read_memorystatus_level(void) {
    int level = 0;
    size_t size = sizeof level;
    if (sysctlbyname("kern.memorystatus_level", &level, &size, NULL, 0) != 0) {
        return -1;
    }
    return level;
}

int readout_read_swap(uint64_t *used, uint64_t *total) {
    struct xsw_usage usage;
    size_t size = sizeof usage;
    if (sysctlbyname("vm.swapusage", &usage, &size, NULL, 0) != 0) {
        return -1;
    }
    *used = usage.xsu_used;
    *total = usage.xsu_total;
    return 0;
}
