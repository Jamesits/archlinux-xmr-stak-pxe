#!/bin/bash
set -euv

basedir=$(cd $(dirname $0); pwd)

abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

iso="archlinux-2018.01.01-x86_64.iso"
arch="x86_64"
workdir="build"
output_dir="release"

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	exit 1
fi

sudo rm -rf $workdir || true
mkdir -p $workdir
7z x -o$workdir/iso $iso
#mv $workdir/iso/arch/boot/$arch/vmlinuz $workdir/vmlinuz
#mv $workdir/iso/arch/boot/intel_ucode.img $workdir/intel_ucode.img
#mv $workdir/iso/arch/boot/$arch/archiso.img $workdir/initrd.img
#mv $workdir/iso/arch/$arch/airootfs.sfs $workdir/archlinux.squashfs

unsquashfs -f -d $workdir/squashfs-root $workdir/iso/arch/$arch/airootfs.sfs

cat config/mirrorlist $workdir/squashfs-root/etc/pacman.d/mirrorlist > $workdir/mirrorlist
mv $workdir/mirrorlist $workdir/squashfs-root/etc/pacman.d/mirrorlist
cat <<-EOF | $workdir/squashfs-root/bin/arch-chroot $workdir/squashfs-root/ /bin/bash
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
	
	# Clear package cache
	pacman -Scc --noconfirm
	EOF

# cp squashfs-root/pkglist.txt ../pkglist.$arch.txt
# Copy authorized_keys
# sudo cp $asset_dir/authorized_keys squashfs-root/root/.ssh/authorized_keys
# sudo chmod 600 squashfs-root/root/.ssh/authorized_keys

mksquashfs $workdir/squashfs-root $workdir/airootfs.sfs

# copy build result to release folder
mkdir -p $output_dir/arch/boot/$arch
mkdir -p $output_dir/arch/$arch
mv $workdir/iso/arch/boot/intel_ucode.{img,LICENSE} $output_dir/arch/boot
mv $workdir/iso/arch/boot/$arch/{vmlinuz,archiso.img} $output_dir/arch/boot/$arch
mv $workdir/airootfs.sfs $output_dir/arch/$arch
cp config/boot.cfg $output_dir

rm -rf $workdir
