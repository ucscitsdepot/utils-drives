#!/usr/bin/bash

getdevice() {
    idV=${1%:*}
    idP=${1#*:}
    for path in $(find /sys/ -name idVendor | rev | cut -d/ -f 2- | rev); do
        if grep -q $idV $path/idVendor; then
            if grep -q $idP $path/idProduct; then
                find $path -name 'device' | rev | cut -d / -f 2 | rev
            fi
        fi
    done
}

getdevice $1
# call lsusb, find the vendor and product codes, then call sudo ./usbname.sh [vendor]:[product]
# ex. sudo ./usbname.sh 21c4:0809