#!/bin/bash
# AI-assisted original diagnostic, only for confirmed C8235-A/FGL2835L42B.
# Run from RAM after the existing, independently verified A recovery hook.
# Reads selected status attributes; never writes sysfs, configuration or flash.
# Explicit --live is required; default invocation has no hardware side effects.
[[ ${1:-} == --live ]] || { echo 'Plan only: C8235-A PoE status observer'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
# The launch requires a fresh A ROMMON UUID/console identity check. Chasfs may
# live in a later per-RP namespace, so it cannot gate global sysfs observation.
exec </dev/null
exec 3>/dev/ttyAMA0
echo C8235_A_POE_OBSERVER_STARTED >&3
[[ $(uname -r) == 6.6.95 ]] || { echo C8235_A_POE_KERNEL_MISMATCH >&3; exit 1; }
grep -q 'board=arata ' /proc/cmdline || { echo C8235_A_POE_BOARD_MISMATCH >&3; exit 1; }
chasfs=/tmp/chassis/local/rp/chasfs
echo C8235_A_POE_OBSERVER_PLATFORM_PASS >&3

delays=(10 30 60 60)
[[ ${4:-} != --once ]] || delays=(0)
for delay in "${delays[@]}"; do
    sleep "$delay"
    echo C8235_A_POE_SNAPSHOT_BEGIN >&3
    cat /proc/uptime >&3
    for item in midplane/chassis_serial_number midplane/serial_number cpa/chassis/pd_type cpa/pf/0/product_id; do
        if [[ -r $chasfs/$item ]]; then
            printf 'CHASFS %s: ' "$item" >&3
            tr -d '\000' < "$chasfs/$item" >&3
            echo >&3
        fi
    done
    [[ -r $chasfs/midplane/chassis_serial_number ]] || echo CHASFS_NOT_VISIBLE_IN_OBSERVER_NAMESPACE >&3
    count=0
    while IFS= read -r attribute; do
        ((count+=1))
        [[ $count -le 16 ]] || break
        printf 'SYSFS %s: ' "$attribute" >&3
        cat -- "$attribute" >&3
        printf 'READ_EXIT=%s\n' "$?" >&3
    done < <(find /sys/devices -type f \( -name poe_status -o -name poe_ctrl -o -name fpga_revision \) 2>/dev/null)
    printf 'MATCHED_ATTRIBUTES=%s\n' "$count" >&3
    for module in /usr/lib/modules/6.6.95/extra/dash_fpga/core/iocomp/dash_fpga_iocomp.ko /usr/lib/modules/6.6.95/extra/iocomp/iocomp.ko; do
        [[ ! -r $module ]] || busybox sha256sum "$module" >&3
    done
    dmesg | grep -Ei 'iocomp|dash|32120|poe|regmap' | tail -60 >&3
    echo C8235_A_POE_SNAPSHOT_END >&3
done
echo C8235_A_POE_OBSERVER_DONE >&3
