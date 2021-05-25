#include <svdpi.h>
#include <stdio.h>
#include <elf.h>

typedef enum _MemImageType
{
    MEM_IMAGE_NONE = 0,
    MEM_IMAGE_ELF,
    MEM_IMAGE_BIN,
    MEM_IMAGE_LAST
} MemImageType;

typedef struct _ELFInfo
{
    Elf64_Phdr *phdr;
    int ph_num;
    int ph_index;
    int offset_in;
} ELFInfo;

typedef struct _BINInfo
{
    int base;
    int offset;
} BINInfo;

typedef struct _MemImage
{
    FILE *handle;
    MemImageType type;
    union {
        ELFInfo elf;
        BINInfo bin;
    } u;
} MemImage;

static MemImage _img;

static int
parse_phdrs(FILE *handle, ELFInfo *img);

static int
load_elf(FILE *handle, ELFInfo *info,
         uint64_t *addr, uint64_t *data);

static int
load_bin(FILE *handle, BINInfo *info,
         uint64_t *addr, uint64_t *data);


uint64_t
open_img(const char *filename, uint64_t base)
{
    const char *ext;

    if (_img.handle || _img.type)
        return 0;

    ext = strchr(filename, '.');
    if (ext == NULL)
        return 0;

    if (!strncmp(ext+1, "elf", 3))
        _img.type = MEM_IMAGE_ELF;
    else if (!strncmp(ext+1, "bin", 3) || !strncmp(ext+1, "dtb", 3))
        _img.type = MEM_IMAGE_BIN;
    else
        return 0;

    _img.handle = fopen(filename, "r");
    if (_img.handle == NULL) {
        printf("ERROR: Open %s failed!\n", filename);
        goto error;
    }

    if (_img.type == MEM_IMAGE_ELF) {
        if (parse_phdrs(_img.handle, &_img.u.elf) < 0)
            goto error;
    } else if (_img.type == MEM_IMAGE_BIN) {
        _img.u.bin.base = base;
        _img.u.bin.offset = 0;
    }

    return _img.handle;

 error:
    if (_img.handle) fclose(_img.handle);
    memset(&_img, 0, sizeof(_img));

    return 0;
}

int
close_img()
{
    int ret = 0;

    if (_img.handle) {
        ret = ftell(_img.handle);
        fclose(_img.handle);
    }

    if (_img.type == MEM_IMAGE_ELF)
        if (_img.u.elf.phdr)
            free(_img.u.elf.phdr);

    memset(&_img, 0, sizeof(_img));

    return ret;
}

int
load_img(uint64_t handle, uint64_t *addr, uint64_t *data)
{
    if (handle != _img.handle)
        return -1;

    if (_img.type == MEM_IMAGE_ELF)
        return load_elf(_img.handle, &_img.u.elf, addr, data);
    else if (_img.type == MEM_IMAGE_BIN)
        return load_bin(_img.handle, &_img.u.bin, addr, data);
}

static int
parse_phdrs(FILE *handle, ELFInfo *info)
{
    Elf64_Ehdr ehdr;
    if (fread(&ehdr, sizeof(ehdr), 1, handle) != 1)
        goto error;

    if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 ||
        ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3)
        goto error;

    if (fseek(handle, ehdr.e_phoff, SEEK_SET) < 0)
        goto error;

    info->phdr = calloc(ehdr.e_phnum, sizeof(Elf64_Phdr));
    if (info->phdr == NULL)
        goto error;

    if (fread(info->phdr, sizeof(Elf64_Phdr),
              ehdr.e_phnum, handle) != ehdr.e_phnum)
        goto error;

    info->ph_num = ehdr.e_phnum;
    info->ph_index = 0;
    info->offset_in = 0;
    return 0;

 error:
    if (info->phdr) free(info->phdr);
    info->phdr = NULL;
    info->ph_num = 0;
    info->ph_index = 0;
    info->offset_in = 0;
    return -1;
}

static int
load_elf(FILE *handle, ELFInfo *info, uint64_t *addr, uint64_t *data)
{
    *addr = 0;
    *data = 0;

    if (info->ph_index >= info->ph_num)
        return -1;

    Elf64_Phdr *phdr = info->phdr + info->ph_index;
    fseek(handle, phdr->p_offset + info->offset_in, SEEK_SET);

    uint64_t dw = 0;
    if (fread(&dw, 1, sizeof(dw), handle) == 0)
        return -1;

    *data = dw;
    *addr = (phdr->p_paddr + info->offset_in) >> 3;

    info->offset_in += sizeof(uint64_t);
    if (info->offset_in >= phdr->p_filesz) {
        info->offset_in = 0;
        info->ph_index++;
    }

    return 0;
}

static int
load_bin(FILE *handle, BINInfo *info, uint64_t *addr, uint64_t *data)
{
    *addr = 0;
    *data = 0;

    uint64_t dw = 0;
    if (fread(&dw, 1, sizeof(dw), handle) == 0)
        return -1;

    *data = dw;
    *addr = (info->base + info->offset) >> 3;
    info->offset += sizeof(uint64_t);
    return 0;
}