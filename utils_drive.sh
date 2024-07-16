#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root." >&2
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: sudo ./utils_drive.sh /dev/sdX n (n is current partition number)" >&2
  exit 1
fi

TGTDEV=$1
PART=$2

mkdir -p /mnt/tmp
mount ${TGTDEV}${PART} /mnt/tmp
rsync -avhP --exclude=".DS_Store" --delete /mnt/tmp/_Temp /tmp
umount /mnt/tmp
wipefs -a $TGTDEV

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

mkfs.exfat -n DEPOTUTILS ${TGTDEV}1 # requires apt install exfat-fuse exfatprogs
fsck.exfat ${TGTDEV}1
mount ${TGTDEV}1 /mnt/tmp
mv /tmp/_Temp /mnt/tmp/
rsync -avhP --exclude="_Temp" --exclude=".DS_Store" /mnt/au/ITS\ Depot/Utils\ Drive/ /mnt/tmp
mkdir /mnt/tmp/_Temp
umount /mnt/tmp
