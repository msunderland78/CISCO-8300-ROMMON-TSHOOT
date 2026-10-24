#!/bin/sh
#------------------------------------------------------------------
# mcp_upgrade_rommon_cmds_helper.sh -
#   rsync's a rommon image from the active rp and then
#   calls the mcp_upgrade_rommon.sh script to do the upgrade.
#
# Input arguments:
#   --host: expected to be rp-active
#   --path: rsync path
#   --file: the rommon file (.bin) to get
#   --cpsl: the capsule file (.bin) to get
#
# The rsync path is concatenated with the board_type/subtype/
# to produce the full rsync path to the file.
#
# August 2007, Matt Bookman
#
# Copyright (c) 2007, 2010-2013, 2015, 2017-2020, 2023, 2025 by Cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

set -e
set -u

readonly SCRIPTS=/usr/binos/conf

source $SCRIPTS/mcp_script_defs.sh
source $SCRIPTS/psimple.sh
source $SCRIPTS/hwutil.sh

# Set the BOARD_TYPE, BOARD_SUBTYPE, etc.
hwutil_set_plat_board_fru_slot_bay;
source $SCRIPTS/pglobals.sh
source $SCRIPTS/chasutils.sh

# For now, we always simply get the "latest"
readonly BOARD_CC_SUBTYPE_DEFAULT=10G

# show_help
#
# Display usage
function show_help () {
    echo "$0: --host <rsync_host> --path <rsync_path> --file <rsync_file> --cpsl \
<rsync_cpsl>"
    echo ""
    exit 1;
}
readonly -f show_help;

# cleanup
#
# Upon exit, cleanup the directory in which we mounted the rommmon package
function cleanup () {
    if chasfs_has_capsule_support; then
        if [ -n "${rsync_cpsl:-}" ]; then
            rm -f $rommon_upgrade_cpslpath
        fi
    fi
    rm -f $rommon_upgrade_filepath
    rmdir $ROMMON_UPGRADE_TEMP_DIR 2> /dev/null
}

trap 'cleanup' EXIT

#
# --------------  process command line options -----------------
#
readonly longopts="host:,path:,file:,cpsl:,uuid:,remote,debug,help"

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

declare rsync_host
declare rsync_path
declare rsync_file
declare rsync_cpsl
declare uuid=""
declare notification="console"
# Give ovld_params something so it will get passed
# to the called script
declare ovld_params="console"

for i
do
  case "$i" in
      --host)     shift; rsync_host=$1; shift;;
      --path)     shift; rsync_path=$1; shift;;
      --file)     shift; rsync_file=$1; shift;;
      --cpsl)     shift; rsync_cpsl=$1; shift;;
      --uuid)     shift; uuid=$1; shift;;
      --debug)    shift; debug=1; set -x; set -v;;
      --remote)   shift; notification="remote";;
      --help)     show_help;;
      -h)         show_help;;
  esac
done

# Mark all the parameters as readonly now that they are set
readonly rsync_host rsync_path rsync_file rsync_cpsl

if [[ $notification == "remote" ]];then
    ovld_params=" --remote --uuid $uuid"
fi

# Verify that we have everything we need
if chasfs_has_capsule_support; then
    readonly required_vars="rsync_host rsync_path rsync_file rsync_cpsl"
else
    readonly required_vars="rsync_host rsync_path rsync_file"
fi

for required_var in $required_vars; do
    if [ -z "${!required_var}" ]; then
        show_help;
    fi
done

if [ -d /tmp/chassis/cpld/chasfs ]; then
    CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
else
    CPLD_DIR="/sys/bus/platform/devices/cpld/"
fi

declare board_type=$(<$CPLD_DIR/board_type)
declare board_subtype=$(<$CPLD_DIR/board_subtype)

if [ -z "$board_subtype" ]; then
    if [ "$board_type" == "CC" ]; then
        board_subtype=$BOARD_CC_SUBTYPE_DEFAULT
    else
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "Board subtype unknown.  Upgrade cannot proceed"
        exit 0
    fi
fi

# Now let's get to it
declare rommon_upgrade_filepath=$ROMMON_UPGRADE_TEMP_DIR/$rsync_file

if chasfs_has_capsule_support; then
    if [ -n "${rsync_cpsl:-}" ]; then
        declare rommon_upgrade_cpslpath=$ROMMON_UPGRADE_TEMP_DIR/$rsync_cpsl
    fi
fi

mkdir -p $ROMMON_UPGRADE_TEMP_DIR

notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Target copying $ROMMON_NAME image file"

# rsync the file down.
# -L indicates to follow symbolic links, rather than copying down the link.
rsync_hostname=$(chasfs_resolve_role_based_hostname $rsync_host)

# Promethium and Promethium-L use the same rommon,
# so change the image path to use the same as Promethium.
    if [[ $board_subtype == "PROMETHIUM-L" ]];then
        board_subtype="PROMETHIUM"
    fi

    set +e
    rsync_output=$(rsync \
    rsync://$rsync_hostname/$rsync_path/$board_type/$board_subtype/$rsync_file \
    $ROMMON_UPGRADE_TEMP_DIR 2>&1)
    rsync_res=$?
    set -e

    if [[ $rsync_res -ne 0  ]]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "Unsupported package. Upgrade cannot proceed"
        exit 0
    fi

if chasfs_has_capsule_support; then
    # Do not exit immediately if rsync encounters an error
    set +e
    rsync_output=$(rsync \
rsync://$rsync_hostname/$rsync_path/$board_type/$board_subtype/$rsync_cpsl \
                   $ROMMON_UPGRADE_TEMP_DIR 2>&1)
    rsync_res=$?
    set -e

    if [[ $rsync_res -ne 0 ]]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail ""
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "Warning - Didn't find capsule file."
        # notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "$rsync_output"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail ""
    fi
fi

if chasfs_is_vxe; then
    vxe_upgrade_rommon.sh $rommon_upgrade_filepath
elif chasfs_is_family_esg || chasfs_is_fugazi || chasfs_is_bender || chasfs_is_fry; then
    if chasfs_has_capsule_support; then
        ovld_upgrade_rommon.sh $ovld_params $rommon_upgrade_filepath $rommon_upgrade_cpslpath
    else
        ovld_upgrade_rommon.sh $ovld_params $rommon_upgrade_filepath
    fi
elif chasfs_is_cbr_13ru; then
    cbr_upgrade_rommon.sh $rommon_upgrade_filepath
else
    if chasfs_has_capsule_support; then
        if [ -n "${rsync_cpsl:-}" ]; then
            mcp_upgrade_rommon.sh $rommon_upgrade_filepath $rommon_upgrade_cpslpath
        fi
    else
        mcp_upgrade_rommon.sh $rommon_upgrade_filepath
    fi
fi

