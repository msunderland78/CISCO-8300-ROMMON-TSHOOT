#!/bin/bash
# AI-assisted read-only diagnostic. Run as a separate temporary RAM systemd
# service so launch_net service cleanup cannot terminate the delayed samples.
[[ ${1:-} == --live ]] || { echo 'Plan only: C8235-A library-consumer observer'; exit 0; }
[[ ${2:-} == --confirmed-chassis && ${3:-} == FGL2835L42B ]] || exit 1
[[ $(uname -r) == 6.6.95 ]] || exit 1
grep -q 'board=arata ' /proc/cmdline || exit 1
exec </dev/null
exec 3>/dev/ttyAMA0
echo C8235_PSU_PROCESS_OBSERVER_STARTED >&3
for delay in 30 30 45; do
    sleep "$delay"
    echo C8235_PSU_PROCESS_SNAPSHOT_BEGIN >&3
    cat /proc/uptime >&3
    declare -A selected=()
    while IFS= read -r maps; do
        pid=${maps#/proc/}; pid=${pid%/maps}
        selected[$pid]=1
    done < <(grep -l '/libdash_fpga_api.so' /proc/[0-9]*/maps 2>/dev/null)
    for comm in /proc/[0-9]*/comm; do
        IFS= read -r name < "$comm" 2>/dev/null || continue
        case "$name" in *cmand*|*iomd*|*iosd*)
            pid=${comm#/proc/}; pid=${pid%/comm}; selected[$pid]=1;;
        esac
    done
    count=0
    for pid in "${!selected[@]}"; do
        ((count+=1)); [[ $count -le 20 ]] || break
        printf 'PROCESS pid=%s comm=' "$pid" >&3
        cat "/proc/$pid/comm" >&3 2>/dev/null
        printf 'MOUNT_NAMESPACE ' >&3
        readlink "/proc/$pid/ns/mnt" >&3
        printf 'ROOT_VIEW_LIBRARY ' >&3
        busybox sha256sum "/proc/$pid/root/usr/binos/lib64/libdash_fpga_api.so" >&3 2>&3
        while read -r range perms offset device inode pathname; do
            case "$pathname" in */libdash_fpga_api.so*)
                printf 'LIBRARY_MAP %s %s %s %s %s\n' "$range" "$perms" "$offset" "$inode" "$pathname" >&3
                if [[ $offset == 00000000 ]]; then
                    printf 'MAPPED_FILE ' >&3
                    busybox sha256sum "/proc/$pid/map_files/$range" >&3 2>&3
                fi;;
            esac
        done < "/proc/$pid/maps"
        grep -E 'libdash_fpga_api.so|/tmp/sw|/usr/binos' "/proc/$pid/mounts" | head -35 >&3
    done
    printf 'MATCHED_PROCESSES=%s\n' "${#selected[@]}" >&3
    echo C8235_PSU_PROCESS_SNAPSHOT_END >&3
done
echo C8235_PSU_PROCESS_OBSERVER_DONE >&3
