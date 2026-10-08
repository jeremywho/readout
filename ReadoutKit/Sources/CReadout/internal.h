#ifndef READOUT_INTERNAL_H
#define READOUT_INTERNAL_H

#include <mach/mach.h>

static inline mach_port_t readout_host(void) {
    static mach_port_t host = MACH_PORT_NULL;
    if (host == MACH_PORT_NULL) {
        host = mach_host_self();
    }
    return host;
}

#endif
