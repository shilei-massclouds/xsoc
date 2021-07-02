#include <svdpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <elf.h>

static uint32_t _max;
static uint64_t *_pg;

void
init_cells(uint32_t max)
{
    _max = max;
    _pg = calloc(1024, sizeof(uint64_t));
}

static uint64_t *
lookup(uint32_t addr)
{
    uint32_t pg_idx;
    uint32_t pd_idx;
    uint32_t pt_idx;
    uint64_t *pd;
    uint64_t *pt;

    if (addr >= _max) {
        printf("Warning: addr %llx is out of limit (%llx)", addr, _max);
        return NULL;
    }

    pg_idx = (addr >> 22);
    if (_pg[pg_idx] == NULL)
        _pg[pg_idx] = calloc(1024, sizeof(uint64_t));
    pd = _pg[pg_idx];

    pd_idx = (addr >> 12) & 0x3FF;
    if (pd[pd_idx] == NULL)
        pd[pd_idx] = calloc(512, sizeof(uint64_t));
    pt = pd[pd_idx];

    pt_idx = (addr >> 3) & 0x1FF;

    return pt + pt_idx;
}

uint64_t
get_cell(uint32_t addr)
{
    uint64_t *ptr;
    ptr = lookup(addr);
    if (ptr == NULL) {
        return 0;
    }

    return *ptr;
}

void
set_cell(uint32_t addr, uint64_t data)
{
    uint64_t *ptr;
    ptr = lookup(addr);
    if (ptr == NULL) {
        return;
    }

    *ptr = data;
}
