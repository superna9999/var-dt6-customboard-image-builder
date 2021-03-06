#!/bin/bash
set -x
export PATH=$PWD/gcc-linaro-7.1.1-2017.08-x86_64_arm-linux-gnueabihf/bin:$PATH
#RAM=1
RAM=0
#PROXY="http://127.0.0.1:3142"
PROXY=""
IMAGE_FOLDER="img/"
IMAGE_VERSION="linux-4.16-rc3"
IMAGE_DEVICE_TREE="imx6q-var-dt6customboard"
if [ ! -z "$1" ]; then
	IMAGE_VERSION="$1"
fi
if [ ! -z "$2" ]; then
	IMAGE_DEVICE_TREE="$2"
fi
if [ ! -f "$IMAGE_VERSION/arch/arm/boot/dts/$IMAGE_DEVICE_TREE.dts" ]; then
	echo "Missing Device Tree"
	exit 1
fi
set -eux -o pipefail
IMAGE_LINUX_VERSION=`head -n 1 $IMAGE_VERSION/include/config/kernel.release | xargs echo -n`
IMAGE_FILE_SUFFIX="$(date +%F)"
IMAGE_FILE_NAME="imx6-ubuntu-xenial-${IMAGE_VERSION}-${IMAGE_LINUX_VERSION}-${IMAGE_FILE_SUFFIX}.img"
if [ $RAM -ne 0 ]; then
	IMAGE_FOLDER="ram/"
fi
mkdir -p "$IMAGE_FOLDER"
if [ $RAM -ne 0 ]; then
	mount -t tmpfs -o size=1G tmpfs $IMAGE_FOLDER
fi
truncate -s 3G "${IMAGE_FOLDER}${IMAGE_FILE_NAME}"
fdisk "${IMAGE_FOLDER}${IMAGE_FILE_NAME}" <<EOF
o
n
p
1
2048
524287
a
t
b
n
p
2
524288

p
w

EOF
IMAGE_LOOP_DEV="$(losetup --show -f ${IMAGE_FOLDER}${IMAGE_FILE_NAME})"
IMAGE_LOOP_DEV_BOOT="${IMAGE_LOOP_DEV}p1"
IMAGE_LOOP_DEV_ROOT="${IMAGE_LOOP_DEV}p2"
partprobe "${IMAGE_LOOP_DEV}"
mkfs.vfat -n BOOT "${IMAGE_LOOP_DEV_BOOT}"
mkfs.btrfs -f -L ROOT "${IMAGE_LOOP_DEV_ROOT}"
mkdir -p p1 p2
mount "${IMAGE_LOOP_DEV_BOOT}" p1
mount "${IMAGE_LOOP_DEV_ROOT}" p2
btrfs subvolume create p2/@
sync
umount p2
mount -o compress=lzo,noatime,subvol=@ "${IMAGE_LOOP_DEV_ROOT}" p2

PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- install INSTALL_PATH=$PWD/p1/
cp ${IMAGE_VERSION}/arch/arm/boot/uImage p1/uImage
cp ${IMAGE_VERSION}/arch/arm/boot/dts/$IMAGE_DEVICE_TREE.dtb p1/
PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- headers_install INSTALL_HDR_PATH=$PWD/p2/usr/
PATH=$PWD/gcc/bin:$PATH make -C ${IMAGE_VERSION} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- modules_install INSTALL_MOD_PATH=$PWD/p2/

mkdir -p p2/etc/apt/apt.conf.d p2/etc/dpkg/dpkg.cfg.d
echo "force-unsafe-io" > "p2/etc/dpkg/dpkg.cfg.d/dpkg-unsafe-io"
if [ -n "$PROXY" ] ; then
	http_proxy="$PROXY" qemu-debootstrap --arch armhf xenial p2
else
	qemu-debootstrap --arch armhf xenial p2
fi
tee p2/etc/apt/sources.list.d/ubuntu-ports.list <<EOF
deb http://ports.ubuntu.com/ubuntu-ports/ xenial universe multiverse restricted
deb http://ports.ubuntu.com/ubuntu-ports/ xenial-updates main universe multiverse restricted
deb http://ports.ubuntu.com/ubuntu-ports/ xenial-security main universe multiverse restricted
EOF
tee p2/etc/fstab <<EOF
/dev/root	/	btrfs	defaults,compress=lzo,noatime,subvol=@ 0 1
EOF
if [ -n "$PROXY" ] ; then
	tee "p2/etc/apt/apt.conf.d/30proxy" <<EOF
Acquire::http::proxy "http://127.0.0.1:3142";
EOF
fi

cp /usr/bin/qemu-arm-static p2/usr/bin/
cp stage2.sh p2/root
mount -o bind /dev p2/dev
mount -o bind /dev/pts p2/dev/pts
chroot p2 /root/stage2.sh
umount p2/dev/pts
umount p2/dev
rm p2/root/stage2.sh
if [ -n "$PROXY" ] ; then
	rm p2/etc/apt/apt.conf.d/30proxy
fi
rm p2/etc/dpkg/dpkg.cfg.d/dpkg-unsafe-io

mkdir -p p2/lib/firmware/
cp -ar firmware/* p2/lib/firmware/

mkimage -C none -A arm -T script -d boot.cmd p1/boot.scr

btrfs filesystem defragment -f -r p2

umount p2
umount p1

dd if=SPL of="${IMAGE_LOOP_DEV}" conv=fsync bs=1k seek=1
dd if=u-boot.img of="${IMAGE_LOOP_DEV}" conv=fsync bs=1k seek=69

losetup -d "${IMAGE_LOOP_DEV}"
mv "${IMAGE_FOLDER}${IMAGE_FILE_NAME}" "${IMAGE_FILE_NAME}"
if [ $RAM -ne 0 ]; then
	umount "${IMAGE_FOLDER}"
fi
rmdir "${IMAGE_FOLDER}"
rmdir p1 p2
