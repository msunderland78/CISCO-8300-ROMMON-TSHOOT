#!/bin/bash
# AI-assisted original RAM overlay for the package view actually mapped by
# cmand, established with native IOS process-memory maps on this exact router.
# Sourced hook invokes this child before cmand starts. No package bytes change.
[[ ${1:-} == --live ]] || { echo 'Plan only: C8235-A package-view RAM overlay'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
set -Eeuo pipefail
exec </dev/null >/dev/ttyAMA0 2>&1
trap 'echo C8235_PSU_PACKAGE_OVERLAY_FAILED line=$LINENO; exit 1' ERR
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
[[ $(cat /c8235-psu-armed) == 'FGL2835L42B 13 FF FF 78 86 52 04 83 8A BF FF 48' ]]
echo C8235_PSU_PACKAGE_OVERLAY_BEGIN
target=/tmp/sw/mount/c8kg2be-mono-universalk9.26.02.01.SPA.pkg/usr/binos/lib64/libdash_fpga_api.so
candidate=/c8235-psu-test/libdash_fpga_api.so
original=ea570d093bdcbfb34edc534e1e4615e0ad7d32b01e78d0554b02952d65bcf791
patched=8f9da1b458718001a537fabcbcd4def6267a83ece5fdc9967cd30fab33399ff0
[[ -f $target && ! -L $target ]]
[[ $(busybox sha256sum "$target" | awk '{print $1}') == "$original" ]]
[[ $(busybox sha256sum "$candidate" | awk '{print $1}') == "$patched" ]]
case $(stat -f -c %T "$candidate") in ramfs|tmpfs) ;; *) exit 1;; esac
for comm in /proc/[0-9]*/comm; do
    name=$(cat "$comm" 2>/dev/null) || continue
    case "$name" in *cmand*|*iomd*|*iosd*)
        echo C8235_PSU_PACKAGE_CONSUMER_ALREADY_RUNNING
        exit 1;;
    esac
done
printf 'PACKAGE_SOURCE_FILESYSTEM '
stat -f -c %T "$target"
busybox sha256sum "$target"
mount --bind "$candidate" "$target"
[[ $(busybox sha256sum "$target" | awk '{print $1}') == "$patched" ]]
busybox sha256sum "$target"
grep " $target " /proc/mounts
echo C8235_PSU_PACKAGE_OVERLAY_COMPLETE
