#!/bin/bash

# stop on error
set -e

if [ ! -n "${NAMEUSER+1}" ]; then
    NAMEUSER=kaputtnik
fi

if [ ! -n "${NAMEHOST+1}" ]; then
    NAMEHOST=arch-vbox
fi

if [ ! -n "${NAMEDOMAIN+1}" ]; then
    NAMEDOMAIN=0 # 0 is special, meaning none.
fi

if [ ! -n "${NAMEDEVICE+1}" ]; then
    NAMEDEVICE=/dev/sda
fi

if [ ! -n "${NAMETIMEZONE+1}" ]; then
    NAMETIMEZONE=Europe/Berlin
else
    if [ ! -f /usr/share/zoneinfo/$NAMETIMEZONE ]; then
        echo $NAMETIMEZONE is not a legal TZ value. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
        exit 2
    fi
fi

if [ ! -n "${NAMELOCALE+1}" ]; then
    NAMELOCALE=en_US.UTF-8
else
    if [[ $(grep "$NAMELOCALE" /etc/locale.gen | wc -l) == 0 ]]; then
        echo $NAMELOCALE is not legal. See /etc/locale.gen
        exit 3
    fi
fi

if [ ! -n "${NAMEKEYMAP+1}" ]; then
    NAMEKEYMAP=de-latin1
fi

timedatectl set-ntp true
parted -s $NAMEDEVICE mklabel msdos
parted -s $NAMEDEVICE mkpart primary ext4 0% 100%
parted -s $NAMEDEVICE set 1 boot on
mkfs.ext4 -F -F ${NAMEDEVICE}1
mount ${NAMEDEVICE}1 /mnt

pacman --noconfirm -S reflector
#cat /etc/pacman.d/mirrorlist | grep .de/ > /etc/pacman.d/mirrorlist
reflector --country 'Germany' --sort rate --protocol https --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel wget grub
genfstab -U /mnt > /mnt/etc/fstab

echo "NAMEUSER=$NAMEUSER\nNAMELOCALE=$NAMELOCALE\nNAMEDOMAIN=$NAMEDOMAIN\nNAMETIMEZONE=$NAMETIMEZONE\nNAMELOCALE=$NAMELOCALE\nNAMEKEYMAP=$NAMEKEYMAP\nNAMEDEVICE=$NAMEDEVICE" > /mnt/root/stage2.env

wget -nv -O /mnt/root/stage2.sh https://raw.githubusercontent.com/mschaller/arch-setup/master/stage2.sh \
    && chmod u+x /mnt/root/stage2.sh

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
arch-chroot /mnt /root/stage2.sh

rm /mnt/root/stage2.env
rm /mnt/root/stage2.sh
