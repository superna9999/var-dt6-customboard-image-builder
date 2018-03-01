git clone https://github.com/torvalds/linux.git -b master --depth 1 linux-src
cp defconfig linux-src/.config
cd linux-src
make ARCH=arm CROSS_COMPILE=$PWD/../../gcc-linaro-7.1.1-2017.08-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf- modules dtbs uImage LOADADDR=0x12000000 -j4
cd -
