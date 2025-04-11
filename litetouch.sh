#!/bin/bash

# if an error occurs, exit immediately
set -e

# check if the script is run as root (necessary for disk operations)
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

# script must be run w/ 1 argument (the target device)
if [ $# -lt 1 ]; then
    echo "Usage: sudo ./litetouch.sh /dev/sdX" >&2
    exit 1
fi

# check if another LiteTouch installation is in progress (is the /mnt/tmp directory empty?)
if [ ! -z "$(ls -A '/mnt/tmp')" ]; then
    echo "Another LiteTouch installation is in progress. Please wait until it is finished. If you're sure there isn't another LiteTouch install in progress, unmount the device at /mnt/tmp" >&2
    exit 1
fi

# get target device
TGTDEV=$1

# find the latest LiteTouch ISO
ISO="$(find ~+ -type f -name "SDSLiteTouch*" -print0 | xargs -r -0 ls -1 -t | head -1)"

# if ISO is found
if [ -n $ISO ]; then
    echo "Found LiteTouch at ${ISO}"

    # wipe the target device
    wipefs -a ${TGTDEV}
    echo "Wiped ${TGTDEV}"

    # pass input to fdisk to create a new partition
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' <<EOF | fdisk ${TGTDEV}
g # clear the in memory partition table
n # new partition
    # partition number 1
    # default - start at beginning of disk 
    # default - end at ending of disk 
Y # might get a request to remove exfat signature
t # change partition type
11 # Microsoft basic data
p # print the in-memory partition table
w # write the partition table and exit
EOF

    echo "Formatted ${TGTDEV}"

    # create & check a FAT32 filesystem
    mkfs.vfat -n DVD_ROM ${TGTDEV}1
    fsck.vfat ${TGTDEV}1

    echo "Created filesystem"

    # create mount points (if they don't exist)
    mkdir -p /mnt/tmp
    mkdir -p /mnt/iso

    # mount the target device and the ISO
    mount ${TGTDEV}1 /mnt/tmp
    mount -o loop,ro $ISO /mnt/iso/

    echo "Begin copying files"

    # copy the files from the ISO to the target device
    cp -r /mnt/iso/* /mnt/tmp

    echo "Finished copying files"
    echo "Unmounting..."

    # unmount both filesystems
    umount /mnt/tmp
    umount /mnt/iso

    echo "Done"
else
    # if no ISO is found
    echo "No LiteTouch ISO found"
    exit 1
fi
