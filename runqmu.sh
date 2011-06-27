#!/bin/bash

vdisk=$1
isofile=$2

Usage() {
echo "usage...."
echo "  $0 <HD_img> [OS_ISO]"
echo "    <HD_img>  Pass the name of your virtual HD within the ./vdisk dir"
echo "    [OS_ISO]  Optional param, use only when attempting to install a"
echo "              virtual OS onto a new ./vdisk image. Pass ISO filename."
echo ""
}

if [ -z $vdisk ]; then
	Usage
	exit
fi

if [ -z $isofile ]; then
	../qemu/x86_64-softmmu/qemu-system-x86_64 -m 2048 -hda ./vdisk/${vdisk} -device nvme
else
	../qemu/x86_64-softmmu/qemu-system-x86_64 -m 2048 -cdrom ./vkernel/${isofile} -hda ./vdisk/${vdisk} -device nvme
fi

exit
