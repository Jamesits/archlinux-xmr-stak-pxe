# archlinux-xmr-stak-pxe

Arch linux image with xmr-stak installed. A PXE-and-mine solution for batch deployment.

## Usage

Pre-compile:

 * download https://mirrors.ustc.edu.cn/archlinux/iso/2018.01.01/archlinux-2018.01.01-x86_64.iso
 * determine your PXE server: you need one port for HTTP on it.
 * edit `config/pxe.sh` to point to your PXE server

Compile:

 * run `sudo ./build.sh`

Post-compile: 

 * run `./server.sh` to start PXE server
 * copy `release/ipxe.efi` to your DHCP server
 * configure PXE to `ipxe.efi` on your DHCP server

## Build Dependency

Packages needed to build this (on Ubuntu):

 * p7zip-full
 * squashfs-tools
 * git-core
 * cmake
 * build-essential
 * libmicrohttpd-dev
 * libssl-dev
 * libhwloc-dev

## Runtime Dependency (on PXE server)

 * python3-pip
 * pip packages: uwsgi hug

## Donation

Please donate if you like my work!

 * BTC `1Cm42dB58VcHFC4HZSToMESGbXJr82JaSZ`
 * ETH `0x6fDEb40271b9E027CAF6Fb4feBF5432a9F36EF1F`
