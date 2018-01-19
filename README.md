# archlinux-xmr-stak-pxe

Arch linux image with xmr-stak installed. A PXE-and-mine solution for batch deployment.

## Requirements

PXE client need at least 1792GiB RAM. 

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

## Build Dependency (on where you execute `build.sh`)

Ubuntu:

```shell
apt-get install p7zip-full squashfs-tools git-core cmake build-essential libmicrohttpd-dev libssl-dev libhwloc-dev
```

OpenSuSE:

(I haven't tested from a clean install, so the following is just for reference)

```shell
zypper install -t pattern devel_C_C++
zypper install p7zip squashfs git cmake libmicrohttpd-devel hwloc libssl44
```

## Runtime Dependency (on PXE HTTP server)

 * python3
 * pip packages: uwsgi hug (install use `sudo -H pip3 install uwsgi hug`)

## Donation

Please donate if you like my work!

 * BTC `1Cm42dB58VcHFC4HZSToMESGbXJr82JaSZ`
 * ETH `0x6fDEb40271b9E027CAF6Fb4feBF5432a9F36EF1F`
