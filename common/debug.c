#include <svdpi.h>
#include <stdlib.h>

int
check_verbose(uint64_t pc)
{
    uint64_t r_start = 0;
    uint64_t r_end = 0;

    if (getenv("VERBOSE") == NULL)
        return 0;

    if (getenv("START") && getenv("END")) {
        r_start = strtoul(getenv("START"), NULL, 16);
        r_end = strtoul(getenv("END"), NULL, 16);
    }

    return ((!r_start && !r_end) || (r_start <= pc && pc <= r_end));
}

int
wait_breakpoint(uint64_t pc)
{
    if (getenv("DUMP_PC") == NULL)
        return 0;

    return (strtoul(getenv("DUMP_PC"), NULL, 16) == pc);
}
