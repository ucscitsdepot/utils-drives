#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root." >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: sudo ./utils_drive.sh /dev/sdX [n] (n is current partition number if preserving _Temp folder)" >&2
  exit 1
fi

TGTDEV=$1
PART=$2

if [ -n "$PART" ]; then
  mkdir -p /mnt/utils
  mount ${TGTDEV}${PART} /mnt/utils
  rm -rf /tmp/_Temp
  rsync -avhP --exclude=".DS_Store" --delete /mnt/utils/_Temp /tmp
  umount /mnt/utils
else
  read -p "Skipping _Temp folder copy, is this ok? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi
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

mkdir -p /mnt/au
if [ -z "$(ls -A /mnt/au)" ]; then
  echo "Need to mount AU share"
  read -p "Enter AU admin username (admin.cruzid): " AU_USER
  mount -t cifs -o username="$AU_USER" //au.ucsc.edu/Org /mnt/au
else
  echo "AU share already mounted"
fi

mkdir -p /mnt/utils
mount ${TGTDEV}1 /mnt/utils
rsync -avhP --exclude="_Temp" --exclude=".DS_Store" /mnt/au/ITS\ Depot/Utils\ Drive/ /mnt/utils
if [ -n "$PART" ]; then
  mv /tmp/_Temp /mnt/utils/
else
  mkdir -p /mnt/utils/_Temp
fi
umount /mnt/utils
umount /mnt/au
echo "Done"
