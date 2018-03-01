IMAGE_VERSION="linux-4.16-rc3"
git clone https://github.com/torvalds/linux.git -b master --depth 1 $IMAGE_VERSION
cp defconfig $IMAGE_VERSION/.config
cd $IMAGE_VERSION
make ARCH=arm CROSS_COMPILE=$PWD/../gcc-linaro-7.1.1-2017.08-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf- modules dtbs uImage LOADADDR=0x12000000 -j4
cd -
