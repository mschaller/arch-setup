#!/bin/bash

# stop on error
set -e

if [ ! -n "${NAMEROOTPWD+1}" ]; then
    NAMEROOTPWD=password
fi

if [ ! -n "${NAMEUSER+1}" ]; then
    NAMEUSER=kaputtnik
fi

if [ ! -n "${NAMEUSERPWD+1}" ]; then
    NAMEUSERPWD=$NAMEUSER
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

if [ ! -n "${NAMESWAPGB+1}" ]; then
    NAMESWAPGB=2

fi

if [ ! -n "${NAMETIMEZONE+1}" ]; then
    NAMETIMEZONE=Europe/Berlin
else
    if [ ! -f /usr/share/zoneinfo/$NAMETIMEZONE ]; then
        echo $NAMETIMEZONE is not a legal TZ value. See https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
        exit
    fi
fi

if [ ! -n "${NAMELOCALE+1}" ]; then
    NAMELOCALE=en_US.UTF-8
else
    if [[ $(grep "$NAMELOCALE" /etc/locale.gen | wc -l) == 0 ]]; then
        echo $NAMELOCALE is not legal. See /etc/locale.gen
        exit
    fi
fi

if [ ! -n "${NAMEKEYMAP+1}" ]; then
    NAMEKEYMAP=de-latin1
fi


echo "Archlinux setup script"
echo "----------------------"
echo "Parameters:"
echo "ROOTPWD      = $NAMEROOTPWD"
echo "USER         = $NAMEUSER"
echo "USERPWD      = $NAMEUSERPWD"
echo "HOST         = $NAMEHOST"
echo "DOMAIN       = $NAMEDOMAIN"
echo "DEVICE       = $NAMEDEVICE"
echo "SWAPGB       = $NAMESWAPGB"
echo "TIMEZONE     = $NAMETIMEZONE"
echo "LOCALE       = $NAMELOCALE"
echo "KEYMAP       = $NAMEKEYMAP"
echo ""
sleep 5

timedatectl set-ntp true
parted -s $NAMEDEVICE mklabel msdos
parted -s $NAMEDEVICE mkpart primary ext4 0% 100%
parted -s $NAMEDEVICE set 1 boot on
mkfs.ext4 -m 0 -F -F ${NAMEDEVICE}1
mount ${NAMEDEVICE}1 /mnt

pacman --noconfirm -Sy reflector
reflector --country 'Germany' --sort rate --protocol https --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel wget
genfstab -U /mnt > /mnt/etc/fstab

printf "NAMEHOST=$NAMEHOST\nNAMEUSER=$NAMEUSER\nNAMEUSERPWD=$NAMEUSERPWD\nNAMELOCALE=$NAMELOCALE\nNAMEDOMAIN=$NAMEDOMAIN\nNAMETIMEZONE=$NAMETIMEZONE\nNAMELOCALE=$NAMELOCALE\nNAMEKEYMAP=$NAMEKEYMAP\nNAMEDEVICE=$NAMEDEVICE\nNAMEROOTPWD=$NAMEROOTPWD" > /mnt/root/stage2.env

wget -nv -O /mnt/root/stage2.sh https://raw.githubusercontent.com/mschaller/arch-setup/master/stage2.sh \
    && chmod u+x /mnt/root/stage2.sh

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
arch-chroot /mnt /root/stage2.sh && rm /mnt/root/stage2.env && rm /mnt/root/stage2.sh && reboot

