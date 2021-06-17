`ifndef __VIRTIO_VH__
    `define __VIRTIO_VH__

`define VIRTIO_ID_NET               'd1  /* virtio net */
`define VIRTIO_ID_BLOCK             'd2  /* virtio block */
`define VIRTIO_ID_CONSOLE           'd3  /* virtio console */
`define VIRTIO_ID_RNG               'd4  /* virtio rng */
`define VIRTIO_ID_BALLOON           'd5  /* virtio balloon */
`define VIRTIO_ID_IOMEM             'd6  /* virtio ioMemory */
`define VIRTIO_ID_RPMSG             'd7  /* virtio remote processor messaging */
`define VIRTIO_ID_SCSI              'd8  /* virtio scsi */
`define VIRTIO_ID_9P                'd9  /* 9p virtio console */
`define VIRTIO_ID_MAC80211_WLAN     'd10 /* virtio WLAN MAC */
`define VIRTIO_ID_RPROC_SERIAL      'd11 /* virtio remoteproc serial link */
`define VIRTIO_ID_CAIF              'd12 /* Virtio caif */
`define VIRTIO_ID_MEMORY_BALLOON    'd13 /* virtio memory balloon */
`define VIRTIO_ID_GPU               'd16 /* virtio GPU */
`define VIRTIO_ID_CLOCK             'd17 /* virtio clock/timer */
`define VIRTIO_ID_INPUT             'd18 /* virtio input */
`define VIRTIO_ID_VSOCK             'd19 /* virtio vsock transport */
`define VIRTIO_ID_CRYPTO            'd20 /* virtio crypto */
`define VIRTIO_ID_SIGNAL_DIST       'd21 /* virtio signal distribution device */
`define VIRTIO_ID_PSTORE            'd22 /* virtio pstore device */
`define VIRTIO_ID_IOMMU             'd23 /* virtio IOMMU */
`define VIRTIO_ID_MEM               'd24 /* virtio mem */
`define VIRTIO_ID_FS                'd26 /* virtio filesystem */
`define VIRTIO_ID_PMEM              'd27 /* virtio pmem */
`define VIRTIO_ID_MAC80211_HWSIM    'd29 /* virtio mac80211-hwsim */

/*
 * MMIO control registers
 */

/* Magic value ("virt" string) - Read Only */
`define VIRTIO_MMIO_MAGIC_VALUE         'h000

/* Virtio device version - Read Only */
`define VIRTIO_MMIO_VERSION             'h004

/* Virtio device ID - Read Only */
`define VIRTIO_MMIO_DEVICE_ID           'h008

/* Virtio vendor ID - Read Only */
`define VIRTIO_MMIO_VENDOR_ID           'h00c

/* Bitmask of the features supported by the device (host)
 * (32 bits per set) - Read Only */
`define VIRTIO_MMIO_DEVICE_FEATURES	    'h010

/* Device (host) features set selector - Write Only */
`define VIRTIO_MMIO_DEVICE_FEATURES_SEL	'h014

/* Bitmask of features activated by the driver (guest)
 * (32 bits per set) - Write Only */
`define VIRTIO_MMIO_DRIVER_FEATURES	'h020

/* Activated features set selector - Write Only */
`define VIRTIO_MMIO_DRIVER_FEATURES_SEL	'h024

/* Guest's memory page size in bytes - Write Only */
`define VIRTIO_MMIO_GUEST_PAGE_SIZE	'h028

/* Queue selector - Write Only */
`define VIRTIO_MMIO_QUEUE_SEL		'h030

/* Maximum size of the currently selected queue - Read Only */
`define VIRTIO_MMIO_QUEUE_NUM_MAX	'h034

/* Queue size for the currently selected queue - Write Only */
`define VIRTIO_MMIO_QUEUE_NUM		'h038

/* Used Ring alignment for the currently selected queue - Write Only */
`define VIRTIO_MMIO_QUEUE_ALIGN		'h03c

/* Guest's PFN for the currently selected queue - Read Write */
`define VIRTIO_MMIO_QUEUE_PFN		'h040

/* Ready bit for the currently selected queue - Read Write */
`define VIRTIO_MMIO_QUEUE_READY		'h044

/* Queue notifier - Write Only */
`define VIRTIO_MMIO_QUEUE_NOTIFY	'h050

/* Interrupt status - Read Only */
`define VIRTIO_MMIO_INTERRUPT_STATUS	'h060

/* Interrupt acknowledge - Write Only */
`define VIRTIO_MMIO_INTERRUPT_ACK	'h064

/* Device status register - Read Write */
`define VIRTIO_MMIO_STATUS		'h070

/* Selected queue's Descriptor Table address, 64 bits in two halves */
`define VIRTIO_MMIO_QUEUE_DESC_LOW	'h080
`define VIRTIO_MMIO_QUEUE_DESC_HIGH	'h084

/* Selected queue's Available Ring address, 64 bits in two halves */
`define VIRTIO_MMIO_QUEUE_AVAIL_LOW	'h090
`define VIRTIO_MMIO_QUEUE_AVAIL_HIGH	'h094

/* Selected queue's Used Ring address, 64 bits in two halves */
`define VIRTIO_MMIO_QUEUE_USED_LOW	'h0a0
`define VIRTIO_MMIO_QUEUE_USED_HIGH	'h0a4

/* Configuration atomicity value */
`define VIRTIO_MMIO_CONFIG_GENERATION	'h0fc

/* The config space is defined by each driver as
 * the per-driver configuration space - Read Write */
`define VIRTIO_MMIO_CONFIG		'h100

/*
 * Interrupt flags (re: interrupt status & acknowledge registers)
 */

`define VIRTIO_MMIO_INT_VRING		'b01
`define VIRTIO_MMIO_INT_CONFIG		'b10

`endif
