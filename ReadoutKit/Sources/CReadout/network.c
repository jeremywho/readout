#include "readout.h"

#include <net/if.h>
#include <net/route.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

int readout_read_interface_counters(readout_interface_counters *out, int capacity) {
    int mib[6] = {CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0};
    size_t length = 0;
    if (sysctl(mib, 6, NULL, &length, NULL, 0) != 0) {
        return -1;
    }
    length += 4096;
    char *buffer = malloc(length);
    if (buffer == NULL) {
        return -1;
    }
    if (sysctl(mib, 6, buffer, &length, NULL, 0) != 0) {
        free(buffer);
        return -1;
    }
    int count = 0;
    for (char *cursor = buffer; cursor + sizeof(struct if_msghdr) <= buffer + length && count < capacity;) {
        struct if_msghdr *header = (struct if_msghdr *)cursor;
        if (header->ifm_msglen == 0) {
            break;
        }
        if (header->ifm_type == RTM_IFINFO2) {
            struct if_msghdr2 *info = (struct if_msghdr2 *)cursor;
            char name[IF_NAMESIZE];
            if (if_indextoname(info->ifm_index, name) != NULL) {
                strlcpy(out[count].name, name, sizeof out[count].name);
                out[count].bytes_in = info->ifm_data.ifi_ibytes;
                out[count].bytes_out = info->ifm_data.ifi_obytes;
                count++;
            }
        }
        cursor += header->ifm_msglen;
    }
    free(buffer);
    return count;
}
