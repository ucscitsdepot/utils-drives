#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage: sudo ./litetouch.sh /dev/sdX" >&2
    exit 1
fi

TGTDEV=$1
ISO="$(find ~+ -type f -name "SDSLiteTouch*" -print0 | xargs -r -0 ls -1 -t | head -1)"

if [ -n $ISO ]; then

    echo "Found LiteTouch at ${ISO}"

    wipefs -a ${TGTDEV}
    echo "Wiped ${TGTDEV}"
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | fdisk ${TGTDEV}
g # clear the in memory partition table
n # new partition
    # partition number 1
    # default - start at beginning of disk 
    # default - end at ending of disk 
Y # might get a request to remove exfat signature
t # change partition type
11 # Microsoft basic data
w # write the partition table and exit
EOF

    echo "Formatted ${TGTDEV}"

    mkfs.vfat -n DVD_ROM ${TGTDEV}1
    fsck.vfat ${TGTDEV}1

    echo "Created filesystem"

    mkdir -p /mnt/tmp
    mkdir -p /mnt/iso

    mount ${TGTDEV}1 /mnt/tmp
    mount -o loop,ro $ISO /mnt/iso/

    echo "Begin copying files"

    cp -r /mnt/iso/* /mnt/tmp

    echo "Finished copying files"
    echo "Unmounting..."

    umount /mnt/tmp
    umount /mnt/iso

    echo "Done"
else
    echo "No LiteTouch ISO found"
fi