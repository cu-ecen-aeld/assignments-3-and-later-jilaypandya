#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
export ARCH=arm64
export CROSS_COMPILE=aarch64-none-linux-gnu-


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    #  Add your kernel build steps here
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make -j10 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE Image modules dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image "${OUTDIR}/"
echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

#  Create necessary base directories
mkdir -p ${OUTDIR}/rootfs && cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib64 proc sbin sys tmp usr var
ln -s lib64 lib
mkdir -p usr/bin usr/sbin usr/lib
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    #   Configure busybox
    make distclean
    make defconfig
    make
else
    cd busybox
    make distclean
    make defconfig
    make
fi

echo "Make and install busybox"
make CONFIG_PREFIX="${OUTDIR}/rootfs" install
echo "Library dependencies"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

#  Add library dependencies to rootfs
TOOL_CHAIN_DIR="$(dirname $(which ${CROSS_COMPILE}gcc))/../"
LD_LOC=$(find ${TOOL_CHAIN_DIR} -iname 'ld-linux-aarch64.so.1')
cp $LD_LOC ${OUTDIR}/rootfs/lib64

for  lib in $("$CROSS_COMPILE"readelf -a  busybox  | grep 'Shared lib'  | grep -o -e '\[.*\]' | tr -d '[]'); do cp "$(find "$TOOL_CHAIN_DIR" -iname $lib)" "${OUTDIR}/rootfs/lib64"; done
#  Make device nodes
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/console" c 1 5
#  Clean and build the writer utility
cd ${FINDER_APP_DIR}
pwd
make clean
make writer
#  Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -Lr conf/ "${OUTDIR}/rootfs/home/"
cp -Lr conf/ "${OUTDIR}/rootfs/"
cp ./*.sh "${OUTDIR}/rootfs/home/"
cp writer "${OUTDIR}/rootfs/home/"
# Chown the root directory
sudo chown -R root:root "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -ov --owner root:root > $OUTDIR/initramfs.cpio
# Create initramfs.cpio.gz
gzip -f "$OUTDIR/initramfs.cpio"
