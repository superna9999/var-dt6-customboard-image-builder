setenv bootargs console=ttymxc0 root=/dev/mmcblk1p2 rootfstype=btrfs rootflags=subvol=@ rootwait no_console_suspend
fatload mmc ${mmcdev}:${mmcpart} $fdt_addr imx6q-var-dt6customboard.dtb
fatload mmc ${mmcdev}:${mmcpart} $loadaddr uImage
bootm ${loadaddr} - ${fdt_addr}
