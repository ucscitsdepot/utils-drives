#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root." >&2
    exit 1
fi

if [ $# -lt 1 ]; then
    echo "Usage: sudo ./4-in-1.sh /dev/sdX" >&2
    exit 1
fi

TGTDEV=$1

dd if=/home/depot/utils/4-in-1-mac.img of=$TGTDEV bs=4M status=progress
