#!/bin/bash
set -euv

basedir=$(cd $(dirname $0); pwd)

abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

iso="archlinux-2018.01.01-x86_64.iso"
arch="x86_64"
workdir="build"

sudo rm -rf $workdir || true
mkdir $workdir
7z x -o$workdir $iso
cd $workdir

pushd arch/$arch
sudo unsquashfs airootfs.sfs
cat <<-EOF | sudo arch-chroot squashfs-root/ /bin/bash
	echo "pacman-key takes awhile sometimes, please be patient..."
	pacman-key --init 
	pacman-key --populate archlinux
	pacman -Sy
	
	pacman --noconfirm -S openssh dbus util-linux gptfdisk avahi hwloc libmicrohttpd lm_sensors i7z w3m
	systemctl enable sshd
	systemctl enable dbus
	systemctl enable avahi-daemon
	# ln -s /usr/lib/systemd/system/sshd.service /etc/systemd/system/multi-user.target.wants/sshd.service
	
	# Create root ssh folder (copy authorized_keys here later)
	mkdir -p /root/.ssh
	chmod 700 /root/.ssh
	
	# Avahi
	#pacman --noconfirm -S avahi dbus
	#ln -s /usr/lib/systemd/system/avahi-daemon.service /etc/systemd/system/multi-user.target.wants/avahi-daemon.service
	#ln -s /usr/lib/systemd/system/dbus.service /etc/systemd/system/multi-user.target.wants/dbus.service
	
	LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
	pacman -Scc --noconfirm
	EOF
cp squashfs-root/pkglist.txt ../pkglist.$arch.txt
# Copy authorized_keys
# sudo cp $asset_dir/authorized_keys squashfs-root/root/.ssh/authorized_keys
# sudo chmod 600 squashfs-root/root/.ssh/authorized_keys

# sudo rm airootfs.sfs
sudo mksquashfs squashfs-root airootfs.sfs
# sudo rm -rf squashfs-root

