#!/bin/bash
source /root/stage2.env

pacman --noconfirm -Sy grub openssh sudo

sed -i '/^# %wheel ALL=(ALL:ALL) ALL/s/^# //g' /etc/sudoers

systemctl enable sshd

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc --utc

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

echo "LANG=$NAMELOCALE" >/etc/locale.conf
echo "KEYMAP=$NAMEKEYMAP" >/etc/vconsole.conf

systemctl enable dhcpcd@$(ls /sys/class/net | egrep "en" | awk '{print $1}').service
if [[ $? != 0 ]]; then
	echo Failed to enable dhcpcd
	exit
fi

echo $NAMEHOST >/etc/hostname

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
echo "/swapfile none swap defaults 0 0" >>/etc/fstab

printf "$NAMEROOTPWD\n$NAMEROOTPWD\n" | passwd root
if [[ $? != 0 ]]; then
	echo Failed to set password for root
	exit 1
fi

useradd -m -G wheel -s /bin/bash $NAMEUSER

printf "$NAMEUSERPWD\n$NAMEUSERPWD\n" | passwd $NAMEUSER
if [[ $? != 0 ]]; then
	echo Failed to set password for $NAMEUSER
fi

# prepare mirrorlist
pacman --noconfirm -Sy reflector
reflector --country 'Germany' --sort rate --protocol https --save /etc/pacman.d/mirrorlist
