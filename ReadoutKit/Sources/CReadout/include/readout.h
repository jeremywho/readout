#ifndef READOUT_H
#define READOUT_H

#include <stdint.h>

typedef struct {
    char name[16];
    uint64_t bytes_in;
    uint64_t bytes_out;
} readout_interface_counters;

int readout_read_interface_counters(readout_interface_counters *out, int capacity);

typedef struct {
    uint32_t user;
    uint32_t system;
    uint32_t idle;
    uint32_t nice;
} readout_core_ticks;

int readout_read_core_ticks(readout_core_ticks *out, int capacity);
int readout_read_core_kinds(char *out, int capacity);

typedef struct {
    uint64_t internal_pages;
    uint64_t purgeable_pages;
    uint64_t external_pages;
    uint64_t wired_pages;
    uint64_t compressor_pages;
    uint64_t page_size;
} readout_vm_pages;

int readout_read_vm_pages(readout_vm_pages *out);
int readout_read_memorystatus_level(void);
int readout_read_swap(uint64_t *used, uint64_t *total);
int readout_read_disk_io(uint64_t *bytes_read, uint64_t *bytes_written);
int readout_read_volume_used(const char *path, int64_t *used);

typedef struct {
    uint32_t connection;
} readout_smc;

int readout_smc_open(readout_smc *smc);
void readout_smc_close(readout_smc *smc);
int readout_smc_read(const readout_smc *smc, uint32_t key, uint8_t *bytes, uint32_t *size, uint32_t *type);
int readout_smc_key_count(const readout_smc *smc, uint32_t *count);
int readout_smc_key_at(const readout_smc *smc, uint32_t index, uint32_t *key);

#endif
