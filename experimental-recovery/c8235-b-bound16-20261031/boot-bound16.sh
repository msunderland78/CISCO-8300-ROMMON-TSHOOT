#!/bin/bash
# AI-assisted diagnostic for physically confirmed C8235-B / FGL2835LBHU only.
# Invoke explicitly as PID 1 from the verified 26.2.1 initramfs. Experimental.
# Edits the RAM copy of launch_net.sh, never an image or internal filesystem.
# A reboot without this wrapper restores ordinary startup.
set -Eeuo pipefail

[[ $$ == 1 ]] || { echo 'Refusing: this diagnostic must be initramfs PID 1'; exit 1; }
exec </dev/ttyAMA0 >/dev/ttyAMA0 2>&1
stty 115200
trap 'echo "C8235_BOUND16_BOOTSTRAP_FAILED; maintenance shell only"; exec /bin/bash' ERR
echo C8235_BOUND16_BOOTSTRAP_BEGIN
mkdir -p /proc /sys
[[ -r /proc/self/status ]] || mount -t proc proc /proc
[[ -d /sys/bus/pci ]] || mount -t sysfs sysfs /sys
[[ $(uname -r) == 6.6.95 ]]
grep -q 'board=arata ' /proc/cmdline
[[ $(od -An -tx1 /sys/firmware/devicetree/base/soc@0/pci@878020000000/rvu-admin@0/num-rvu-vfs | tr -d ' \n') == 00000020 ]]

target=/usr/binos/bin/launch_net.sh
expected=f7d617bd80362c4bc564fc2c848bd95ecf84251be0d11e1707a95ca301d8cdc4
[[ $(busybox sha256sum "$target" | awk '{print $1}') == "$expected" ]]
[[ $(sed -n '93p' "$target") == '    BP_VFS=$(basename -a /sys/bus/pci/drivers/rvu_nicvf/0002*)' ]]

cat > /c8235-bound16-hook.sh <<'BOUND16_HOOK'
# Sourced only inside Cisco configure_mcam_rules, before BP_VFS discovery.
if [[ $FRU_SUB != ARATA ]]; then
    echo 'C8235_BOUND16_HOOK_REFUSED: unexpected platform'
    exit 1
fi
echo C8235_BOUND16_HOOK_BEGIN
for c8235_vf in $(seq 16 31); do
    c8235_link=/sys/bus/pci/devices/0002:01:00.0/virtfn$c8235_vf
    [[ -L $c8235_link ]] || { echo 'C8235_BOUND16_HOOK_REFUSED: missing VF'; exit 1; }
    c8235_bdf=$(basename "$(readlink -f "$c8235_link")")
    c8235_driver=/sys/bus/pci/devices/$c8235_bdf/driver
    if [[ -L $c8235_driver ]]; then
        [[ $(basename "$(readlink -f "$c8235_driver")") == rvu_nicvf ]] || exit 1
        echo -n "$c8235_bdf" > /sys/bus/pci/drivers/rvu_nicvf/unbind || exit 1
    fi
done
for c8235_vf in $(seq 0 15); do
    c8235_bdf=$(basename "$(readlink -f /sys/bus/pci/devices/0002:01:00.0/virtfn$c8235_vf)")
    [[ $(basename "$(readlink -f /sys/bus/pci/devices/$c8235_bdf/driver)") == rvu_nicvf ]] || exit 1
done
echo C8235_BOUND16_HOOK_COMPLETE
unset c8235_vf c8235_link c8235_bdf c8235_driver
BOUND16_HOOK

sed '93i\    source /c8235-bound16-hook.sh' "$target" > /launch_net.bound16
bash -n /launch_net.bound16
chmod 755 /launch_net.bound16
mv /launch_net.bound16 "$target"
busybox sha256sum "$target" /c8235-bound16-hook.sh
echo C8235_BOUND16_BOOTSTRAP_READY
cd /
umount /mnt/diagnostic
trap - ERR
exec /init
