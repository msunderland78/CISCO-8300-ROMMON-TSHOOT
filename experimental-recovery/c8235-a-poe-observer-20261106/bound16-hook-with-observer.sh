# Sourced only inside Cisco configure_mcam_rules, before BP_VFS discovery.
if [[ $FRU_SUB != ARATA ]]; then
    echo 'C8235_BOUND16_HOOK_REFUSED: unexpected platform'
    exit 1
fi
echo C8235_BOUND16_HOOK_BEGIN
echo C8235_BOUND16_HOOK_BEGIN > /dev/ttyAMA0
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
echo C8235_BOUND16_HOOK_COMPLETE > /dev/ttyAMA0
unset c8235_vf c8235_link c8235_bdf c8235_driver
bash /c8235-a-poe-observer.sh --live --confirmed-chassis FGL2835L42B --once
(trap '' HUP; bash /c8235-a-poe-observer.sh --live --confirmed-chassis FGL2835L42B >/dev/null 2>&1) &
