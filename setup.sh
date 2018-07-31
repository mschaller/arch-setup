#!/bin/bash

loadkeys de
timedatectl set-ntp true
parted /dev/sda mklabel msdos
parted /dev/sda mkpart primary ext4 0% 100%
parted /dev/sda set 1 boot on
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
cat /etc/pacman.d/mirrorlist | grep .de/ > /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel wget
genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash
