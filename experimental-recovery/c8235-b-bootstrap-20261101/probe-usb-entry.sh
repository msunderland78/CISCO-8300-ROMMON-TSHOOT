#!/bin/bash
# AI-assisted, unproven USB-entry diagnostic for C8235-B/FGL2835LBHU only.
# Run explicitly as a child of the captured PID-1 shell in exact IOS26.2.1.
# Reads identity/profile/files; mounts proc/sys only if absent. No patch,
# startup save, storage write, firmware write, or normal-init continuation.
# Caller must retain a console shell after this child returns or fails.
if [[ ${1:-} != --probe-only && ${1:-} != -p ]]; then
    echo 'Usage: bash probe-usb-entry.sh --probe-only (confirmed B maintenance only)'
    exit 0
fi
if [[ $$ == 1 ]]; then
    echo 'C8235_USB_PROBE_REFUSED_PID1; retaining shell'
    exec /bin/bash
fi
set -Eeuo pipefail
trap 'echo C8235_USB_PROBE_FAILED' ERR
echo "C8235_USB_PROBE_BEGIN pid=$$ parent=$PPID"
[[ -r /proc/self/status ]] || mount -t proc proc /proc
[[ -d /sys/bus/pci ]] || mount -t sysfs sysfs /sys
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
[[ $(od -An -tx1 /sys/firmware/devicetree/base/soc@0/pci@878020000000/rvu-admin@0/num-rvu-vfs | tr -d ' \n') == 00000020 ]]
[[ $(busybox sha256sum /usr/binos/bin/launch_net.sh | awk '{print $1}') == f7d617bd80362c4bc564fc2c848bd95ecf84251be0d11e1707a95ca301d8cdc4 ]]
echo 'C8235_USB_PROBE_PROFILE_PASS'
echo 'PID1 command:'
tr '\000' ' ' < /proc/1/cmdline
echo
echo 'Storage mount:'
grep -E ' /u | /mnt ' /proc/mounts || true
echo 'C8235_USB_PROBE_COMPLETE; returning to captured parent shell'
