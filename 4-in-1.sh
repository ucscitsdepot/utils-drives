#!/bin/bash

# check if the script is run as root (necessary for dd)
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

# script must be run w/ 1 argument (the target device)
if [ $# -lt 1 ]; then
    echo "Usage: sudo ./4-in-1.sh /dev/sdX" >&2
    exit 1
fi

TGTDEV=$1

# TODO: verify that the target device exists, is a usb drive with a /dev/sdX path, is writable, etc

# dd command to write the image to the target device
dd if=/home/depot/utils/4-in-1-mac.img of=$TGTDEV bs=4M status=progress
