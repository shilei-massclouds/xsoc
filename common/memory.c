#include <svdpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <elf.h>

#define X_PG_NUM    1024
#define X_PD_NUM    1024
#define X_PAGE_SIZE 4096

static uint32_t _max;
static uint64_t *_pg;

void
init_cells(uint32_t max)
{
    _max = max;
    _pg = calloc(X_PG_NUM, sizeof(uint64_t));
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
        _pg[pg_idx] = calloc(X_PD_NUM, sizeof(uint64_t));
    pd = _pg[pg_idx];

    pd_idx = (addr >> 12) & 0x3FF;
    if (pd[pd_idx] == NULL)
        pd[pd_idx] = calloc(X_PAGE_SIZE, sizeof(uint8_t));
    pt = pd[pd_idx];

    pt_idx = (addr >> 3) & 0x1FF;

    return pt + pt_idx;
}

uint64_t
get_cell(uint32_t addr)
{
    uint64_t *ptr = lookup(addr);
    if (ptr == NULL) {
        return 0;
    }

    return *ptr;
}

uint64_t
set_cell(uint32_t addr, uint64_t data)
{
    uint64_t ret;
    uint64_t *ptr;
    ptr = lookup(addr);
    if (ptr == NULL) {
        return 0;
    }

    if (addr == 0x7ffff000)
        printf("### set_cell [0x7ffff000]: (%x)!\n", data);

    ret = *ptr;
    *ptr = data;

    return ret;
}

void
dump_mem()
{
    int i;
    int j;
    FILE *fp;

    if (_pg == NULL)
        return;

    fp = fopen("/tmp/xsoc_mem.dump", "wb");

    for (i = 0; i < X_PG_NUM; i++) {
        if (_pg[i]) {
            uint64_t *pd = _pg[i];
            for (j = 0; j < X_PD_NUM; j++) {
                if (pd[j]) {
                    uint32_t addr = (i << 22) | (j << 12);
                    printf("dump_mem: %llx\n", addr);
                    fwrite(&addr, sizeof(addr), 1, fp);
                    fwrite(pd[j], 1, X_PAGE_SIZE, fp);
                }
            }
        }
    }

    fclose(fp);
    fp = NULL;
}

void
restore_mem(uint32_t max)
{
    uint32_t pg_idx;
    uint32_t pd_idx;
    uint64_t *pd;
    uint64_t *page;
    uint32_t addr;
    FILE *fp;

    fp = fopen("/tmp/xsoc_mem.dump", "rb");
    if (fp == NULL)
        return;

    _max = max;
    _pg = calloc(X_PG_NUM, sizeof(uint64_t));

    printf("restore: mem 1 _max(%x)\n", _max);
    while(fread(&addr, sizeof(addr), 1, fp) == 1) {
        printf("restore: mem addr(%llx)\n", addr);
        page = calloc(X_PAGE_SIZE, sizeof(uint8_t));
        if (fread(page, 1, X_PAGE_SIZE, fp) != X_PAGE_SIZE)
            break;

        pg_idx = (addr >> 22);
        if (_pg[pg_idx] == NULL)
            _pg[pg_idx] = calloc(X_PD_NUM, sizeof(uint64_t));
        pd = _pg[pg_idx];

        pd_idx = (addr >> 12) & 0x3FF;
        pd[pd_idx] = page;
    }

    printf("restore: mem ok!\n");

    fclose(fp);
    fp = NULL;
}

void
dump_reg(svBitVecVal data[32])
{
    int i;
    FILE *fp;

    fp = fopen("/tmp/xsoc_reg.dump", "wb");

    for (i = 0; i < 32; i++) {
        fwrite(&data[i], sizeof(uint64_t), 1, fp);
    }

    fclose(fp);
    fp = NULL;
}

void
restore_reg(svBitVecVal data[32])
{
    int i;
    FILE *fp;

    fp = fopen("/tmp/xsoc_reg.dump", "rb");

    for (i = 0; i < 32; i++) {
        fread(&data[i], sizeof(uint64_t), 1, fp);
        printf("restore: reg[%d]: (%llx)\n", i, data[i]);
    }

    fclose(fp);
    fp = NULL;
}

void
dump_csr(svBitVecVal data[4096])
{
    int i;
    FILE *fp;

    fp = fopen("/tmp/xsoc_csr.dump", "wb");

    for (i = 0; i < 4096; i++) {
        fwrite(&data[i], sizeof(uint64_t), 1, fp);
    }

    fclose(fp);
    fp = NULL;
}

void
restore_csr(svBitVecVal data[4096])
{
    int i;
    FILE *fp;

    fp = fopen("/tmp/xsoc_csr.dump", "rb");

    for (i = 0; i < 4096; i++) {
        fread(&data[i], sizeof(uint64_t), 1, fp);
        if (data[i])
            printf("restore: csr[%d]: (%llx)\n", i, data[i]);
    }

    fclose(fp);
    fp = NULL;
}

void
dump_priv(uint32_t priv)
{
    FILE *fp;
    fp = fopen("/tmp/xsoc_priv.dump", "wb");
    fwrite(&priv, sizeof(uint32_t), 1, fp);
    fclose(fp);
    fp = NULL;
}

uint32_t
restore_priv()
{
    uint32_t priv;
    FILE *fp;
    fp = fopen("/tmp/xsoc_priv.dump", "rb");
    fread(&priv, sizeof(uint32_t), 1, fp);
    fclose(fp);
    fp = NULL;
    printf("restore: priv(%llx)\n", priv);
    return priv;
}

void
dump_pc(uint64_t pc, uint32_t normal)
{
    FILE *fp;
    uint64_t next_pc;

    next_pc = normal ? (pc + 4) : (pc + 2);

    fp = fopen("/tmp/xsoc_pc.dump", "wb");
    fwrite(&next_pc, sizeof(uint64_t), 1, fp);
    fwrite(&pc, sizeof(uint64_t), 1, fp);
    fclose(fp);
    fp = NULL;
}

uint64_t
restore_pc()
{
    uint64_t next_pc;
    FILE *fp;
    fp = fopen("/tmp/xsoc_pc.dump", "rb");
    fread(&next_pc, sizeof(uint64_t), 1, fp);
    fclose(fp);
    fp = NULL;
    printf("restore: PC(%llx)\n", next_pc);
    return next_pc;
}
