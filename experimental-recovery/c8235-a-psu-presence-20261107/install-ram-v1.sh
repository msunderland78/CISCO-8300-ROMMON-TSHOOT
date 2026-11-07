#!/bin/bash
# AI-assisted original experiment, only for freshly confirmed C8235-A.
# Explicit supervised arming in the pre-init maintenance shell is required.
# Invoke from the verified launch_net hook after native package mounts exist.
# Install a separate RAM copy via a bind mount; never edit the source library,
# IOS package, persistent configuration, board identity or hardware registers.
[[ ${1:-} == --live ]] || { echo 'Plan only: temporary C8235-A PSU-presence experiment'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
set -Eeuo pipefail
trap 'echo C8235_PSU_RAM_INSTALL_FAILED; exit 1' ERR
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
exec </dev/null >/dev/ttyAMA0 2>&1
echo C8235_PSU_RAM_INSTALL_BEGIN
target=/usr/binos/lib64/libdash_fpga_api.so
original=ea570d093bdcbfb34edc534e1e4615e0ad7d32b01e78d0554b02952d65bcf791
candidate=8f9da1b458718001a537fabcbcd4def6267a83ece5fdc9967cd30fab33399ff0
patch=3d70331915eae857494ce4beb99bcdb522b2445015d32df9c9886ec08c39b472
[[ -f $target && ! -L $target ]]
[[ $(busybox sha256sum "$target" | awk '{print $1}') == "$original" ]]
# Only the destination copy must be RAM. The source arrives through the native
# read-only package mounts. A bind mount does not write its underlying file.
case $(stat -f -c %T /) in ramfs|tmpfs) ;; *) exit 1;; esac
[[ $(cat /c8235-psu-armed) == 'FGL2835L42B 13 FF FF 78 86 52 04 83 8A BF FF 48' ]]
# Refuse if an intended consumer has already started with the original file.
for comm in /proc/[0-9]*/comm; do
    name=$(cat "$comm" 2>/dev/null) || continue
    case "$name" in cmand|iomd*|linux_iosd*) echo C8235_PSU_CONSUMER_ALREADY_RUNNING; exit 1;; esac
done
for maps in /proc/[0-9]*/maps; do
    if grep -q '/libdash_fpga_api.so' "$maps" 2>/dev/null; then
        echo C8235_PSU_ORIGINAL_LIBRARY_ALREADY_MAPPED
        exit 1
    fi
done
[[ ! -e /c8235-psu-test ]]
mkdir /c8235-psu-test
cp -p "$target" /c8235-psu-test/original-libdash_fpga_api.so
cp -p "$target" /c8235-psu-test/libdash_fpga_api.so
busybox base32 -d /c8235-psu-function.base32 > /c8235-psu-test/function-patch.bin
[[ $(busybox sha256sum /c8235-psu-test/function-patch.bin | awk '{print $1}') == "$patch" ]]
[[ $(wc -c < /c8235-psu-test/function-patch.bin) == 192 ]]
dd if=/c8235-psu-test/function-patch.bin of=/c8235-psu-test/libdash_fpga_api.so bs=1 seek=48324 conv=notrunc
[[ $(busybox sha256sum /c8235-psu-test/libdash_fpga_api.so | awk '{print $1}') == "$candidate" ]]
[[ $(busybox sha256sum /c8235-psu-test/original-libdash_fpga_api.so | awk '{print $1}') == "$original" ]]
chmod 444 /c8235-psu-test/libdash_fpga_api.so
mount --bind /c8235-psu-test/libdash_fpga_api.so "$target"
[[ $(busybox sha256sum "$target" | awk '{print $1}') == "$candidate" ]]
busybox sha256sum "$target" /c8235-psu-test/original-libdash_fpga_api.so
echo C8235_PSU_RAM_INSTALL_COMPLETE
