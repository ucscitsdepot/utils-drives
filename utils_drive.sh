#!/bin/bash

# check if the script is run as root (necessary for disk operations)
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root." >&2
  exit 1
fi

# TODO: autodetect if the target device is a current utils drive and ask if user wants to preserve the _Temp folder

# script must be run w/ 1 required argument (the target device) and 1 optional argument (current partition number)
if [ $# -lt 1 ]; then
  echo "Usage: sudo ./utils_drive.sh /dev/sdX [n] (n is current partition number if preserving _Temp folder)" >&2
  exit 1
fi

# get target device & current partition number (if provided)
TGTDEV=$1
PART=$2

# if current partition number is provided
if [ -n "$PART" ]; then
  # create a mount point for current partition
  mkdir -p /mnt/utils

  # mount the current partition
  mount ${TGTDEV}${PART} /mnt/utils

  # remove the _Temp folder if it exists
  rm -rf /tmp/_Temp

  # copy the _Temp folder to /tmp
  rsync -avhP --exclude=".DS_Store" --delete /mnt/utils/_Temp /tmp

  # unmount the current partition
  umount /mnt/utils
else
  # if current partition number is not provided, ensure this is ok with the user
  read -p "Skipping _Temp folder copy, is this ok? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi

# erase the target device
wipefs -a $TGTDEV

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

# create and check exFAT filesystem
mkfs.exfat -n DEPOTUTILS ${TGTDEV}1 # requires apt install exfat-fuse exfatprogs
fsck.exfat ${TGTDEV}1

# create mount point for AU share
mkdir -p /mnt/au

# if AU share is not mounted, prompt for credentials and mount
if [ -z "$(ls -A /mnt/au)" ]; then
  echo "Need to mount AU share"
  read -p "Enter AU admin username (admin.cruzid): " AU_USER
  mount -t cifs -o username="$AU_USER" //au.ucsc.edu/Org /mnt/au
else
  echo "AU share already mounted"
fi

# create mount point & mount the utils drive
mkdir -p /mnt/utils
mount ${TGTDEV}1 /mnt/utils

# sync everything but the _Temp folder from the AU share to the utils drive
rsync -avhP --exclude="_Temp" --exclude=".DS_Store" /mnt/au/ITS\ Depot/Utils\ Drive/ /mnt/utils

# move the _Temp folder back if it was preserved
if [ -n "$PART" ]; then
  mv /tmp/_Temp /mnt/utils/
else
  # create a new _Temp folder if it wasn't preserved
  mkdir -p /mnt/utils/_Temp
fi

# unmount both filesystems
umount /mnt/utils
umount /mnt/au
echo "Done"
