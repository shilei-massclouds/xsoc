#include <svdpi.h>
#include <stdlib.h>

int
check_verbose(uint64_t pc)
{
    static int _check = 0;

    if (getenv("VERBOSE") == NULL)
        return 0;

    if (!_check && getenv("START"))
        if (pc == strtoul(getenv("START"), NULL, 16))
            _check = 1;

    if (_check && getenv("END"))
        if (pc == strtoul(getenv("END"), NULL, 16))
            _check = 0;

    if (!getenv("START") && !getenv("END"))
        _check = 1;

    return _check;
}
