#!/bin/bash
set -euv

basedir=$(cd $(dirname $0); pwd)

abs_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

iso="archlinux-2018.01.01-x86_64.iso"
arch="x86_64"
confdir="$basedir/config"
workdir="$basedir/build"
output_dir="$basedir/release"

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	exit 1
fi

! rm -rf $workdir
! rm -rf $output_dir
mkdir -p $workdir
mkdir -p $output_dir

! git submodule update --remote --merge

# build iPXE
! source $basedir/config/pxe.sh
cat > $workdir/boot.cfg.head <<-EOF
	#!ipxe
	
	set http_root ${pxe_http_root}
	set xmr_http_root ${xmr_stak_http_root}
	EOF
cat $workdir/boot.cfg.head $confdir/boot.cfg > $output_dir/boot.cfg

cat > $workdir/ipxe_embed.ipxe <<-EOF
	#!ipxe
	
	:retry
	prompt --key 0x02 --timeout 2000 Press Ctrl-B to cancel auto boot and launch the iPXE command line... && shell ||
	dhcp || goto retry
	boot ${pxe_script}
	EOF
pushd $basedir/ipxe/src
! git reset --hard
make bin-x86_64-efi/ipxe.efi EMBED=$workdir/ipxe_embed.ipxe
cp bin-x86_64-efi/ipxe.efi $output_dir/ipxe.efi
make bin/undionly.kpxe EMBED=$workdir/ipxe_embed.ipxe
cp bin/undionly.kpxe $output_dir/undionly.kpxe
! git reset --hard
popd

# build xmr-stak
pushd $basedir/xmr-stak
! git reset --hard
! sed -ie "s/2\.0/0\.0/g" xmrstak/donate-level.hpp
popd
mkdir -p $workdir/xmr-stak
pushd $workdir/xmr-stak
cmake $basedir/xmr-stak -DXMR-STAK_COMPILE=generic -DCMAKE_LINK_STATIC=ON -DCMAKE_BUILD_TYPE=Release -DMICROHTTPD_ENABLE=ON -DOpenSSL_ENABLE=ON -DCPU_ENABLE=ON -DHWLOC_ENABLE=ON -DOpenCL_ENABLE=OFF -DCUDA_ENABLE=OFF
make
popd

# extract iso
7z x -o$workdir/iso $iso

# extract rootfs
unsquashfs -f -d $workdir/squashfs-root $workdir/iso/arch/$arch/airootfs.sfs

# set mirror preference
cat config/mirrorlist $workdir/squashfs-root/etc/pacman.d/mirrorlist > $workdir/mirrorlist
mv $workdir/mirrorlist $workdir/squashfs-root/etc/pacman.d/mirrorlist

# install xmr-stak
mv $workdir/xmr-stak/bin/xmr-stak $workdir/squashfs-root/usr/bin
mv $workdir/xmr-stak/bin/libxmr-*.a $workdir/squashfs-root/usr/lib
mkdir -p $workdir/squashfs-root/etc/xmr-stak
cp config/config.txt $workdir/squashfs-root/etc/xmr-stak
cp config/miner.conf $workdir/squashfs-root/etc/sysctl.d
cp config/xmr-stak-pxe $workdir/squashfs-root/usr/bin
cp config/xmr-stak.service $workdir/squashfs-root/usr/lib/systemd/system
cp config/dhcp.network $workdir/squashfs-root/etc/systemd/network

# setup rootfs
cat <<-EOF | $workdir/squashfs-root/bin/arch-chroot $workdir/squashfs-root/ /bin/bash
	set -euv

	pacman-key --init 
	pacman-key --populate archlinux
	pacman -Sy
	
	pacman --noconfirm -S openssh avahi hwloc libmicrohttpd lm_sensors i7z w3m htop

	# fix libmicrohttpd version problem between build and destination device
	ln -s /usr/lib/libmicrohttpd.so	/usr/lib/libmicrohttpd.so.10

	systemctl enable sshd
	systemctl enable dbus
	systemctl enable avahi-daemon
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved
	systemctl enable xmr-stak.service
	
	# Clear package cache
	pacman -Scc --noconfirm
	EOF

# Copy authorized_keys
mkdir -p $workdir/squashfs-root/root/.ssh
! cp $confdir/authorized_keys $workdir/squashfs-root/root/.ssh/authorized_keys
chown -R root:root $workdir/squashfs-root/root/.ssh
chmod 700 $workdir/squashfs-root/root/.ssh
! chmod 600 $workdir/squashfs-root/root/.ssh/authorized_keys

# build rootfs
mksquashfs $workdir/squashfs-root $workdir/airootfs.sfs

# copy build result to release folder
mkdir -p $output_dir/arch/boot/$arch
mkdir -p $output_dir/arch/$arch
mv $workdir/iso/arch/boot/intel_ucode.{img,LICENSE} $output_dir/arch/boot
mv $workdir/iso/arch/boot/$arch/{vmlinuz,archiso.img} $output_dir/arch/boot/$arch
mv $workdir/airootfs.sfs $output_dir/arch/$arch

# clear build temp files
rm -rf $workdir

echo "Build finished. Now set up a HTTP server at $output_dir and point your iPXE client to http://your_server/boot.cfg."
