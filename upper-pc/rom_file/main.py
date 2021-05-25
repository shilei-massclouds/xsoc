#!/usr/bin/python3

import sys
import ftdi1 as ftdi

rom_file = open('../../data/head.bin', 'rb')
if rom_file is None:
    print('Open rom file failed')
    sys.exit(-1)

ctx = ftdi.new()

ret, devlist = ftdi.usb_find_all(ctx, 0x0403, 0x6014)
if ret <= 0:
    print('ftdi.usb_find_all error = %s' % ftdi.get_error_string(ctx))
    sys.exit(-1)

item = devlist
while item:
    ret, vendor, desc, serial = ftdi.usb_get_strings(ctx, item.dev)
    if ret:
        sys.exit(-1)

    print('vendor="%s" desc="%s" serial="%s"\n' % (vendor, desc, serial))
    if vendor == 'FTDI':
        break

    item = item.next

if not item:
    print('Can not find FTDI')
    sys.exit(-1)

ret = ftdi.usb_open_dev(ctx, item.dev)
if ret:
    print('open: ' + ftdi.get_error_string(ctx))
    sys.exit(-1)

ret = ftdi.set_bitmode(ctx, 0xff, 0x40)
if ret:
    print(ftdi.get_error_string(ctx))
    sys.exit(-1)

while True:
    ret, buf = ftdi.read_data(ctx, 8)
    if ret != 8:
        continue

    addr = int.from_bytes(buf, 'little')
    print('addr: %x' % addr)

    rom_file.seek(addr)
    data = rom_file.read(8)

    ret = ftdi.write_data(ctx, data)
    if ret != 8:
        print('write: ' + ftdi.get_error_string(ctx))
        sys.exit(-1)

ret = ftdi.usb_close(ctx)
if ret:
    print(ftdi.get_error_string(ctx))

ftdi.free(ctx)
print('ok!')
