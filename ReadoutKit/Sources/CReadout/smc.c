#include "readout.h"

#include <IOKit/IOKitLib.h>
#include <string.h>

typedef struct {
    char major;
    char minor;
    char build;
    char reserved;
    uint16_t release;
} readout_smc_version;

typedef struct {
    uint16_t version;
    uint16_t length;
    uint32_t cpu_limit;
    uint32_t gpu_limit;
    uint32_t memory_limit;
} readout_smc_limit;

typedef struct {
    uint32_t size;
    uint32_t type;
    char attributes;
} readout_smc_info_block;

typedef struct {
    uint32_t key;
    readout_smc_version version;
    readout_smc_limit limit;
    readout_smc_info_block info;
    char result;
    char status;
    char command;
    uint32_t data32;
    uint8_t bytes[32];
} readout_smc_param;

_Static_assert(sizeof(readout_smc_param) == 80, "AppleSMC user client expects an 80-byte parameter block");

enum {
    readout_smc_selector = 2,
    readout_smc_read_bytes = 5,
    readout_smc_read_index = 8,
    readout_smc_read_info = 9,
};

static kern_return_t readout_smc_call(uint32_t connection, readout_smc_param *input, readout_smc_param *output) {
    size_t size = sizeof *output;
    return IOConnectCallStructMethod(connection, readout_smc_selector, input, sizeof *input, output, &size);
}

int readout_smc_open(readout_smc *smc) {
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (service == MACH_PORT_NULL) {
        return -1;
    }
    io_connect_t connection = MACH_PORT_NULL;
    kern_return_t result = IOServiceOpen(service, mach_task_self(), 0, &connection);
    IOObjectRelease(service);
    if (result != KERN_SUCCESS) {
        return -1;
    }
    smc->connection = connection;
    return 0;
}

void readout_smc_close(readout_smc *smc) {
    if (smc->connection != 0) {
        IOServiceClose(smc->connection);
        smc->connection = 0;
    }
}

int readout_smc_key_info(const readout_smc *smc, uint32_t key, uint32_t *size, uint32_t *type) {
    readout_smc_param input = {0};
    readout_smc_param output = {0};
    input.key = key;
    input.command = readout_smc_read_info;
    if (readout_smc_call(smc->connection, &input, &output) != KERN_SUCCESS || output.result != 0) {
        return -1;
    }
    if (output.info.size == 0 || output.info.size > 32) {
        return -1;
    }
    *size = output.info.size;
    *type = output.info.type;
    return 0;
}

int readout_smc_read_known(const readout_smc *smc, uint32_t key, uint32_t size, uint8_t *bytes) {
    if (size == 0 || size > 32) {
        return -1;
    }
    readout_smc_param input = {0};
    readout_smc_param output = {0};
    input.key = key;
    input.info.size = size;
    input.command = readout_smc_read_bytes;
    if (readout_smc_call(smc->connection, &input, &output) != KERN_SUCCESS || output.result != 0) {
        return -1;
    }
    memcpy(bytes, output.bytes, size);
    return 0;
}

int readout_smc_read(const readout_smc *smc, uint32_t key, uint8_t *bytes, uint32_t *size, uint32_t *type) {
    if (readout_smc_key_info(smc, key, size, type) != 0) {
        return -1;
    }
    return readout_smc_read_known(smc, key, *size, bytes);
}

int readout_smc_key_count(const readout_smc *smc, uint32_t *count) {
    uint8_t bytes[32] = {0};
    uint32_t size = 0;
    uint32_t type = 0;
    uint32_t key = ((uint32_t)'#' << 24) | ((uint32_t)'K' << 16) | ((uint32_t)'E' << 8) | (uint32_t)'Y';
    if (readout_smc_read(smc, key, bytes, &size, &type) != 0 || size < 4) {
        return -1;
    }
    *count = ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) | ((uint32_t)bytes[2] << 8) | (uint32_t)bytes[3];
    return 0;
}

int readout_smc_key_at(const readout_smc *smc, uint32_t index, uint32_t *key) {
    readout_smc_param input = {0};
    readout_smc_param output = {0};
    input.command = readout_smc_read_index;
    input.data32 = index;
    if (readout_smc_call(smc->connection, &input, &output) != KERN_SUCCESS || output.key == 0) {
        return -1;
    }
    *key = output.key;
    return 0;
}
