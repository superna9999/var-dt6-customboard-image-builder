#!/bin/bash
set -eux -o pipefail

mount -t proc proc proc/
mount -t sysfs sys sys/

export DEBIAN_FRONTEND="noninteractive"
locale-gen "en_US.UTF-8"
dpkg-reconfigure locales
echo -n 'dt6-customboard' > /etc/hostname
sed -i '1 a 127.0.1.1	dt6-customboard' /etc/hosts
apt-get update
apt-get -y dist-upgrade

apt-get install -y vim ssh

# Clean up packages
apt-get -y clean
apt-get -y autoclean

adduser baylibre --gecos "Baylibre,,," --disabled-password
echo "baylibre:baylibre" | chpasswd
adduser baylibre sudo
adduser baylibre audio
adduser baylibre dialout
adduser baylibre video

umount /proc /sys
