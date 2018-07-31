#!/bin/bash
source /root/stage2.env

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

pacman -S --noconfirm grub os-prober

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

echo "password" | passwd --stdin
