#!/bin/bash
# AI-assisted experimental loader for physically confirmed C8235-B/FGL2835LBHU.
# USB deployment name B3 is deliberately dot-free for Linux init-argument parsing.
# Applies only the established RAM correction; never writes firmware or config.
# Default invocation is inert. Live entry requires explicit mode and PID 1.
case ${1:-} in
    -b|--boot|--ram) ;;
    *) echo 'Experimental C8235-B loader: explicit --boot and PID 1 required'; exit 0 ;;
esac
if [[ $$ != 1 ]]; then
    echo 'C8235_AUTO_REFUSED: requires PID 1'
    exit 1
fi

exec </dev/ttyAMA0 >/dev/ttyAMA0 2>&1
set -Eeuo pipefail
maintenance() {
    trap - ERR
    set +e
    echo 'C8235_AUTO_FAILED: maintenance only; do not exit PID 1'
    while :; do /bin/bash; done
}
trap maintenance ERR
stty 115200

if [[ $1 != --ram ]]; then
    echo 'C8235_AUTO_USB_ENTRY'
    self_hash=$(busybox sha256sum "$0" | awk '{print $1}')
    cp -- "$0" /c8235-auto1
    [[ $(busybox sha256sum /c8235-auto1 | awk '{print $1}') == "$self_hash" ]]
    exec /bin/bash /c8235-auto1 --ram
fi

echo "C8235_AUTO_RAM_ENTRY pid=$$"
cd /
mkdir -p /proc /sys
[[ -r /proc/self/status ]] || mount -t proc proc /proc
[[ -d /sys/bus/pci ]] || mount -t sysfs sysfs /sys
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
[[ $(od -An -tx1 /sys/firmware/devicetree/base/soc@0/pci@878020000000/rvu-admin@0/num-rvu-vfs | tr -d ' \n') == 00000020 ]]

image=/u/c8kg2be-universalk9.26.02.01.SPA.bin
image_hash=0842a7210a2a0933f0a823bbe71c5ba2109f276ee49635a59ba0a26f17f0f456
source_hash=45af8d05ca9a954bef83a2d59be9951391d322010a0b809304760fc3b875a052
patch_hash=32ce11a07bde1fd610b1951a4c143217daec1d3458440bbcbd1fc3ca2c39f857
hook_hash=ca13a2513a367cb9451fcc554432fd520aa8c42d0d59d61b5cd386e7f2efffa4

[[ $(busybox sha256sum "$image" | awk '{print $1}') == "$image_hash" ]]
[[ $(busybox sha256sum /u/C8235FIX1 | awk '{print $1}') == "$source_hash" ]]
cp /u/C8235FIX1 /c8235-fix1
[[ $(busybox sha256sum /c8235-fix1 | awk '{print $1}') == "$source_hash" ]]
echo 'C8235_AUTO_INPUT_HASHES_PASS'
/bin/bash /c8235-fix1 --prepare-only
[[ $(busybox sha256sum /usr/binos/bin/launch_net.sh | awk '{print $1}') == "$patch_hash" ]]
[[ $(busybox sha256sum /c8235-bound16-hook.sh | awk '{print $1}') == "$hook_hash" ]]
umount /u
echo 'C8235_AUTO_READY: USB unmounted; exec /init from PID 1'
exec /init
