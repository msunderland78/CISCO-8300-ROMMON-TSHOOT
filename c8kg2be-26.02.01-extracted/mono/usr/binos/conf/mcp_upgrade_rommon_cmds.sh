#!/bin/sh
#------------------------------------------------------------------
# mcp_upgrade_rommon_cmds.sh -
#    Script which runs on the RP that handles the CLI commands
#       upgrade rom-monitor filename <fname> [FRU | all]
#
# The filename passed to this script is expected to be 
# rommon package, not an individual rommon binary.
#
# This script mounts the rommon package and then forwards
# the request (over brelay) to the FRU to be upgraded.
#
# The target FRU will then rsync the rommon binary that is
# appropriate for that FRU type and subtype, and then will
# run the mcp_upgrade_rommon.sh script.
#
# August 2007, Matt Bookman
#
# Copyright (c) 2007-2013, 2015-2020, 2025 by Cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

readonly SCRIPTS=/usr/binos/conf
# get the common functions
source /common
get_fru_env

source $SCRIPTS/hwutil.sh
source $SCRIPTS/commsutil.sh
source $SCRIPTS/chasutils.sh
source $SCRIPTS/psimple.sh
source $SCRIPTS/pglobals.sh
source $SCRIPTS/mcp_script_defs.sh
source $SCRIPTS/mcp_file_lib.sh
if [[ -e $SCRIPTS/boothelper_stack.sh ]]; then
    source $SCRIPTS/boothelper_stack.sh
fi

# Global .pkginfo constants
readonly PKGVAL_RP_PEGM="pegm"
readonly PKGVAL_RP_CRT="crt"
readonly PKGVAL_RP_RSP1="rudy"
readonly PKGVAL_RP_RSP2="rudy2"
readonly PKGVAL_RP_RSP3="rsp3"


# Instruct the target fru (via the upgrade helper script) to rsync down
# the rommon file from us (the active RP)
readonly RSYNC_HOST=rp-active
readonly RSYNC_ROOT=rommon_upgrade_pub
uuid=$(uuidgen)
# need to know if we need to send 
# status updates to the console or over vconfd
declare notification="console"

# The files of interest in the package are in
#   rommon/mcp/<fru-type>/<fru-subtype>
#
# Older esg platforms use 'rommon/mcp' instead of 'rommon/esg'
# All new esg platforms must use 'rommon/esg'
#
if chasfs_is_uea3ru || chasfs_is_uea2ru || chasfs_is_uea7ru || chasfs_is_dominica ; then
    readonly ROMMON_PACKAGE_MCP_ROOT=rommon/uea
elif chasfs_is_cbr_13ru; then
    readonly ROMMON_PACKAGE_MCP_ROOT=rommon/ubr
elif chasfs_is_family_esg; then
    if chasfs_is_ovld || chasfs_is_family_usd; then
        # Old ISR platforms use 'mcp'
        readonly ROMMON_PACKAGE_MCP_ROOT=rommon/mcp
    else
        # New ISR platforms use 'esg'
        readonly ROMMON_PACKAGE_MCP_ROOT=rommon/esg
    fi
else
    readonly ROMMON_PACKAGE_MCP_ROOT=rommon/mcp
fi

readonly ROMMON_BINARY=latest.bin
readonly ROMMON_CAPSULE=capsule.bin

readonly ROMMON_UPGRADE_HELPER_PARAM_HOST="--host"
readonly ROMMON_UPGRADE_HELPER_PARAM_PATH="--path"
readonly ROMMON_UPGRADE_HELPER_PARAM_FILE="--file"
readonly ROMMON_UPGRADE_HELPER_PARAM_CPSL="--cpsl"

if chasfs_is_family_ngwc; then
    source $SCRIPTS/ngwc_upgrade_rommon_cmds.sh
    exit 0
 
fi

# show_help
#
# Display usage
function show_help () {
    echo "$0: --package <rommon_package> [ --all | --fru <fru> --slot <slot> ]"
    echo ""
    exit 1;
}
readonly -f show_help;

# cleanup
#
# Upon exit, cleanup the directory in which we mounted the rommmon package
function cleanup () {
    unmount_binos_pkg $ROMMON_MOUNT
    
    # Did something go wrong? 
    if [ -d $ROMMON_MOUNT ]; then
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "Removal of $ROMMON_NAME package mount point failed"
        rm -rf $ROMMON_MOUNT
    fi
}
readonly -f cleanup;

# rommon_upgrade_fru_params
#
# Builds the parameters to pass down to the rommon upgrade helper script:
#   --host: rp-active
#   --path: rsync path
#   --file: the rommon file (.bin) to get
#   --cpsl: the capsule file (.bin) to get
function rommon_upgrade_fru_params () {
    echo -n " ${ROMMON_UPGRADE_HELPER_PARAM_HOST} ${RSYNC_HOST}"
    echo -n " ${ROMMON_UPGRADE_HELPER_PARAM_PATH} ${RSYNC_ROOT}/${ROMMON_PACKAGE_MCP_ROOT}"
    echo -n " ${ROMMON_UPGRADE_HELPER_PARAM_FILE} ${ROMMON_BINARY}"
    echo -n " ${ROMMON_UPGRADE_HELPER_PARAM_CPSL} ${ROMMON_CAPSULE}"
    if [[ $notification == "remote" ]];then
        echo -n " --uuid ${uuid} --remote"
    fi
}
readonly -f rommon_upgrade_fru_params;

# rommon_upgrade_fru_slot
#
# Instructing the fru (via the rommon upgrade helper script) to upgrade
# the rommon.
function rommon_upgrade_fru_slot () {
    local fru_lower=$1
    local -i slot=$2

    local fru_params
    local cmd_param="${MCP_UPGRADE_ROMMON_HELPER} $(rommon_upgrade_fru_params)"

    local fru_display=$(binos_fru_to_display_name "$fru_lower")

    if chasfs_is_uea3ru || chasfs_is_uea2ru || chasfs_is_uea7ru; then
        if   [ "$fru_lower" != "$BINOS_RP_LOWER" -a "$fru_lower" != "$BINOS_RP_UPPER" ]; then
            notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "Invalid FRU \"$fru_lower\" - ROMMON upgrade available only for RP"
            exit 1
        fi
    fi

    # We have no mechanism for knowing if the target fru is available
    # for brelay.  Essentially all that is needed is that linux is up,
    # but we need not be to the stage where pvp has started.
    # So we simply try each fru and will clearly display a message
    # indicating that we could not connect to any fru that is not running.

    if hwutil_is_fru_present $fru_lower $slot ; then
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status ""
        if chasfs_is_consolidated; then
            notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status "Upgrade $ROMMON_NAME"
        else
            notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status "Upgrade $ROMMON_NAME on $fru_display $slot"
        fi
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status ""

        # call remote execution wrapper 
        fru_param="${fru_lower} ${slot}"

        comms_run_on_remote_fru "${fru_param}" "${cmd_param}"
    elif [ $all -eq 0 ]; then
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail ""
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "$fru_display $slot is not present for upgrade"
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail ""
    fi
}
readonly -f rommon_upgrade_fru_slot;

# rommon_upgrade_fru_slots
#
# Iterates through the list of slots for the specified fru, instructing
# the fru (via the rommon upgrade helper script) to upgrade the rommon.
function rommon_upgrade_fru_slots () {
    local fru_lower=$1
    local -i slot_max=$2
    local slot
    
    for ((slot = 0; slot <= $slot_max; slot++)); do
        rommon_upgrade_fru_slot "$fru_lower" "$slot" | tee -a /tmp/biosupgrade/rommon_upgrade.log
    done
}
readonly -f rommon_upgrade_fru_slots;

# rommon_validate_package
#
# It validates upgrade package from user, whether it is valid for the
# chasis or not. If it is not valid, it displays the error message 
# to user or else, it continues for upgrade.
function rommon_validate_package () {
	local pkg_rp=$1
	local rp_board=$2

	local valid_pkg_rps=""

	case $rp_board in
        PEG1M) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        PEGF2_CU) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        PEGF2_SFP) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        HOTSPRINGS2) valid_pkg_rps="$PKGVAL_RP_PEGM";;
	    STRIKER_I) valid_pkg_rps="$PKGVAL_RP_PEGM";;
	    STRIKER_C) valid_pkg_rps="$PKGVAL_RP_PEGM";;
	    STRIKER_O) valid_pkg_rps="$PKGVAL_RP_PEGM";;
	    CRETE) valid_pkg_rps="$PKGVAL_RP_CRT";;
	    HOTSPRINGS) valid_pkg_rps="$PKGVAL_RP_CRT";;
		RSP) valid_pkg_rps="$PKGVAL_RP_RSP1";;
		RSP1) valid_pkg_rps="$PKGVAL_RP_RSP1";;
		RUDY) valid_pkg_rps="$PKGVAL_RP_RSP1";;
		RSP2) valid_pkg_rps="$PKGVAL_RP_RSP2";;
		RSP3) valid_pkg_rps="$PKGVAL_RP_RSP3";;
		RSP3_200) valid_pkg_rps="$PKGVAL_RP_RSP3";;
		RSP3_400) valid_pkg_rps="$PKGVAL_RP_RSP3";;
		RSP3_907) valid_pkg_rps="$PKGVAL_RP_RSP3";;
        DOMINICA_4C) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        DOMINICA_4I) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        DOMINICA_20C) valid_pkg_rps="$PKGVAL_RP_PEGM";;
        DOMINICA_20I) valid_pkg_rps="$PKGVAL_RP_PEGM";;
    esac

    for valid_pkg_rp in $valid_pkg_rps; do
        if [[ "$pkg_rp" == "$valid_pkg_rp" ]]; then
            return 1
        fi
    done

    return 0
}
readonly -f rommon_validate_package

# rommon_verify_code_signature
#
# Verify the code signature of the ROMMON package
function rommon_verify_code_signature () {
    local pkg=$1
    local platform_type=$(cat $CPLD_DIR/platform_type)

    # mcp ("Midrange Converged Platfrom") was the original name of
    # ASR (Aggregated Services Router). This signature verification
    # only applies to ASR platforms
    if [[ $platform_type == "mcp" ]]; then
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status 'Verifying the code signature of the ROMMON package...'
        $CSVERIFY package $pkg
        if [[ "$?" != "0" ]]; then
            abort "$pkg is not code signed"
        fi
    fi
}
readonly -f rommon_verify_code_signature

#
# --------------  process command line options -----------------
#
readonly longopts="package:,fru:,slot:,all,remote,debug,help"

set +e
args=`getopt --name $(basename $0 .sh) --longoptions "$longopts" "h" "$@"`
STAT=$?
readonly args
set -e

if [ $STAT != 0 ]; then
    echo "Invalid command arguments."
    exit 1
fi

# the eval, "" for args here is to make sure that quoted strings are preserved
eval set -- "$args" 

declare physical_rommon_package
declare ifs_package
declare target_fru
declare -i target_slot=0
declare -i all=0

for i
do
  case "$i" in
      --package)   shift; ifs_package=$1; shift;;
      --fru)       shift; target_fru=$1; shift;;
      --slot)      shift; target_slot=$1; shift;;
      --all)       shift; all=1; shift;;
      --debug)     shift; debug=1; set -x; set -v;;
      --remote)    shift; notification="remote";;
      --help)      show_help;;
      -h)          show_help;;
  esac
done

# Mark all the parameters as readonly now that they are set
readonly ifs_package target_fru target_slot all

# If an upgrade is already in progress, then just exit.
# Do this here before we set our cleanup-on-exit function.
if [ -e $ROMMON_MOUNT ]; then
    notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status "Upgrade of $ROMMON_NAME already in progress."
    exit 0;
fi

if [ -d /tmp/chassis/cpld/chasfs ]; then
    CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
else
    CPLD_DIR="/sys/bus/platform/devices/cpld/"
fi

trap 'cleanup' EXIT

# Need to overwrite abort from /common so we can send a notification
# before exiting. Only overwrite it if we are being called from viptela-actions
if [[ $notification == "remote" ]]; then
    function abort() {
        sleep 2
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "$@"
        sleep 1
        exit 1
    }
    readonly -f abort
fi

# Convert from IFS to the unix file-system
physical_rommon_package=$(ifs_path_to_disk_path "$ifs_package")

if [ "$physical_rommon_package" == "$INVAL" ]; then
    if [[ "${ifs_package:0:5}" == "stby-" ]]; then
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "Filename $ifs_package not valid for operation."
        abort "Active RP does not have access to standby RP devices"
    fi

    abort "Invalid file: $ifs_package"
fi

if [ ! -e "$physical_rommon_package" ]; then
    abort "File: $ifs_package does not exist"
fi

rommon_verify_code_signature $physical_rommon_package

mount_binos_pkg $physical_rommon_package $ROMMON_MOUNT 0 "polaris_rom_upgrade_tmp_t"

# Verify the package type is correct
declare pkg_type=$( get_pkg_pkginfo_type $ROMMON_MOUNT/.pkginfo )
if ! chasfs_is_cbr; then
    if [[ $pkg_type != "rommon" ]]; then
        abort "$ifs_package is not a rommon package: ${pkg_type}"
    fi
fi

if chasfs_is_cbr; then
    verify_pkg_platform_match $physical_rommon_package
    if [[ $pkg_type != "rommon" ]]; then   
        if [[ $pkg_type != "programmable_firmware" ]]; then
            abort "$ifs_package is not a rommon package: ${pkg_type}"
        fi
    fi
fi


# Verify the package is valid or not
declare pkg_rp=$(get_pkg_pkginfo_rp $ROMMON_MOUNT/.pkginfo)
declare board_type=$(<$CPLD_DIR/board_type) 
declare board_subtype=$(<$CPLD_DIR/board_subtype)

if (chasfs_is_pegasus || chasfs_is_uea3ru  || chasfs_is_uea2ru || chasfs_is_uea7ru); then
	if rommon_validate_package "$pkg_rp" "$board_subtype"; then 
        notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-fail "**ERROR** : Trying to upload wrong Rommon package to Route Processor"
    else 
        true #if package is intended for this RP continue for upgrade.
	fi
else	
    true #if chasis is not based on striker/crete/pegasus/RSP1/2/3 platforms just continue for upgrade.
fi

# Special handling for consolidated and only 1 slot platforms, which only have a single rommon
if chasfs_is_consolidated && ! chasfs_chassis_has_2_rp_slots; then
    notify_update $notification rommon-upgrade-status $uuid upgrade-rommon-status "Chassis model $(chasfs_get_chassis_model) has a single rom-monitor."
    rommon_upgrade_fru_slot "$BINOS_RP_LOWER" "0" | tee -a /tmp/biosupgrade/rommon_upgrade.log

    exit 0
fi

# Not consolidated ... proceed based on what was requested
if [ $all -eq 1 ]; then
    # Hit the RPs
    rommon_upgrade_fru_slots "$BINOS_RP_LOWER" "$CHASSIS_RP_SLOT_MAX"

    # DDTS :CSCuv04782 - Even though UEA platforms are consolidated platforms
    # it is not defined, so instead they are taking exception for upgrade 
    # as below, pegasus is missed so only we seeing the issue
    if ! (chasfs_is_pegasus || chasfs_is_uea3ru  || chasfs_is_uea2ru || chasfs_is_uea7ru); then
        # Hit the FPs
        rommon_upgrade_fru_slots "$BINOS_FP_LOWER" "$CHASSIS_FP_SLOT_MAX"

        # Hit the CCs
        rommon_upgrade_fru_slots "$BINOS_CC_LOWER" "$CHASSIS_CC_SLOT_MAX"
    fi
else
    rommon_upgrade_fru_slot "$target_fru" "$target_slot" | tee -a /tmp/biosupgrade/rommon_upgrade.log
fi
