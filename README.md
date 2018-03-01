Variscite DT6-CustomBoard Ubuntuu 16.04 Image Build Script
==========================================================

Prerequesite
============

On an Ubuntu 16.04 x86_64/AMD64 system :

```
# sudo apt install build-essential bc git qemu debootstrap qemu-user-static
```

Steps
=====

```
# ./init.sh
# ./build_linux.sh
# sudo ./linux-image.sh
# sudo ./clean.sh
```

Image will be in the same directory.

Simply dd it onto an SDCard like :

```
# sudo dd if=imx6-ubuntu-xenial-linux-src-4.13.3-gf3afe53-2017-09-21.img of=/dev/mmcblk0 bs=8M
```

Enjoy !
