#!/bin/bash
# Read-only startup evidence for the explicitly selected temporary RAM test.
[[ ${1:-} == --live ]] || { echo 'Plan only: C8235-A PSU RAM audit'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
set -Eeuo pipefail
exec </dev/null >/dev/ttyAMA0 2>&1
trap 'echo C8235_PSU_RAM_AUDIT_FAILED; exit 1' ERR
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
echo C8235_PSU_RAM_AUDIT_BEGIN
cat /proc/uptime
target=/usr/binos/lib64/libdash_fpga_api.so
[[ $(busybox sha256sum "$target" | awk '{print $1}') == 8f9da1b458718001a537fabcbcd4def6267a83ece5fdc9967cd30fab33399ff0 ]]
busybox sha256sum "$target" /c8235-psu-test/original-libdash_fpga_api.so
grep ' /usr/binos/lib64/libdash_fpga_api.so ' /proc/mounts
for attribute in poe_status poe_ctrl fpga_revision; do
    printf 'RAW_FPGA %s=' "$attribute"
    cat "/sys/devices/platform/dash_fpga/$attribute"
done
echo C8235_PSU_RAM_AUDIT_COMPLETE
