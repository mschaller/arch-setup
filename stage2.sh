#!/bin/bash
source /root/stage2.env

pacman --noconfirm -S grub

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc -utc

sed -i "s/^#$NAMELOCALE/$NAMELOCALE/" /etc/locale.gen
if [[ $? != 0 ]]; then
    echo Failed to modify /etc/locale.gen
    exit 
fi
if [[ $(grep "^$NAMELOCALE" /etc/locale.gen | wc -l) == 0 ]]; then
    echo Failed to modify /etc/locale.gen
    exit 
fi
locale-gen

echo "LANG=$NAMELOCALE" > /etc/locale.conf
echo "KEYMAP=$NAMEKEYMAP" > /etc/vconsole.conf

echo SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"`ip addr show \`ls /sys/class/net --color=never | egrep "^wl|^en"\` | grep link/ | awk '{print $2}'`\", NAME=\"net1\" > /etc/udev/rules.d/10-network.rules && cat /etc/udev/rules.d/10-network.rules
if [[ $? != 0 ]]; then
    echo Failed to rename network device to net1
    exit
fi

systemctl enable dhcpcd@net1.service
if [[ $? != 0 ]]; then
    echo Failed to enable net1
    exit
fi

echo $NAMEHOST > /etc/hostname

mkinitcpio -p linux
if [[ $? != 0 ]]; then
    echo Failed to create initcpio
    exit
fi

grub-install --recheck $NAMEDEVICE
if [[ $? != 0 ]]; then
    echo Failed to install GRUB
    exit
fi

grub-mkconfig -o /boot/grub/grub.cfg
if [[ $? != 0 ]]; then
    echo Failed to configure GRUB
    exit
fi

fallocate -l ${NAMESWAPGB}GB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab


printf "$NAMEROOTPWD\n$NAMEROOTPWD\n" | passwd root
if [[ $? != 0 ]]; then
    echo Failed to set password for root
    exit 1
fi

# prepare mirrorlist
pacman --noconfirm -Sy reflector
reflector --country 'Germany' --sort rate --protocol https --save /etc/pacman.d/mirrorlist

