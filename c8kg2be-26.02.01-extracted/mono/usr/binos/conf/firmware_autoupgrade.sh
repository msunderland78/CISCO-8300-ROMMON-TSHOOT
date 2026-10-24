#!/bin/sh
#------------------------------------------------------------------
# crankshaft_auto_firmware_upgrade.sh
#
# Run during early stages of boot to check whether the system
# requires a rommon upgrade using the packaged rommon binary.
#
# This script mounts the rommon package and then after
# sanity checks calls ovld_upgrade_rommon.sh to do the work.
#
# Copyright (c) 2016-2026 by Cisco Systems, Inc.
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
source /tmp/sw/boot/rmonbifo/env_var.sh

set -eu -o pipefail


#systemd service is set for stdout to ttyS0 (IOS console line) and 
#stderr to go to journal.  Use this function for case when it is
#desired to print to both.
function echo_tty_journal {
    printf "%s\n" "$*"
    printf "%s\n" "$*" >&2
}
function echo_journal {
    printf "%s\n" "$*" >&2
}
function upgrade_abort {
    echo_tty_journal "$*"
    echo_tty_journal "ROMMON upgrade failed.  Proceeding to boot.  A manual ROMMON upgrade is required for the system to function correctly."
    exit 1
}


#Check the version of ROMMON to determine whether to upgrade.
declare rom_ver_file=/tmp/chassis/local/rp/chasfs/rp/0/fw_verinfo
if [ ! -f "$rom_ver_file" ]; then 
    echo_journal "No ROMMON version info, skipping upgrade checks."
    exit 1
fi

# Note, currently we do not have good versioning info in rommon packages for
# comparing versions.  Presently, the only version in the field is 15.x
# and internally we have 12.x versions.  For now, just detect if installed
# rommon is 12.x - 15.x or if they are 16.0 to 16.6 then upgrade
declare rom_installed_ver=$(< $rom_ver_file)
declare update_required=false
declare manual_update_required=false

if [[ "$FRU_SUB" == "OVLD" ||
      "$FRU_SUB" == "UTAH" ||
      "$FRU_SUB" == "SWORD" ||
      "$FRU_SUB" == "DAGGER" ||
      "$FRU_SUB" == "GOLDBEACH" ]]; then
    if [[ "$rom_installed_ver" =~ ^1[2-5]\. ||
          "$rom_installed_ver" =~ ^16\.[0-9]\( ||
          "$rom_installed_ver" =~ ^16\.1[0-1]\( ||
          "$rom_installed_ver" =~ ^16.12\(1[^0-9] ]]; then
        # Any version 12.x and 15.x and will upgraded
        # Any version 16.0 to 16.9 will be upgraded
        # Any version 16.10 t0 16.11 will be upgraded
        # Version 16.12(1x) will be upgraded
        update_required=true
    fi
elif [[ "$FRU_SUB" == "NEPTUNE" ]]; then
    if [[ "$rom_installed_ver" =~ ^1[2-6]\. ||
          "$rom_installed_ver" =~ ^17\.6 ]]; then
        # Any version 12.x to 16.x and 17.6 and will upgraded
        update_required=true
    fi
elif [[ "$FRU_SUB" == "TSN" ||
        "$FRU_SUB" == "STARESG" ||
        "$FRU_SUB" == "BETELGEUSE" ||
        "$FRU_SUB" == "BG_ELIXIR" ]]; then
    if [[ "$rom_installed_ver" =~ ^16\.[1-9]?[0-9] ||
          "$rom_installed_ver" =~ ^17\.[1-3] ||
          "$rom_installed_ver" =~ 10.3.2.1-20201022 ||
          "$rom_installed_ver" =~ "17.5(1r)RC" ||
          "$rom_installed_ver" =~ 17\. ]]; then
        # TSN versions 17.3 and prior will be upgraded
        update_required=true
    fi
elif [[ "$FRU_SUB" == "NANOOK_L" ||
        "$FRU_SUB" == "NANOOK_P" ||
        "$FRU_SUB" == "NANOOK_X" ]]; then
    if [[ "$rom_installed_ver" =~ 17\. ]]; then
        # Nanook versions 17.2 will be upgraded
        update_required=true
    fi
elif [[ "$FRU_SUB" == "RADIUM" || "$FRU_SUB" == "THALLIUM" ]]; then
    if [[ "$rom_installed_ver" =~ NoAikido ]]; then
        echo_journal "This platform, $FRU_SUB, has no Aikido chipset. "
    elif [[ "$rom_installed_ver" =~ 17\. ]]; then
        # C8300_1N1S_xx versions prior to 17.9(7r) to be upgraded to 26.1(1r)
		if grep -q "DEVELOPMENT" /proc/rmonbifo/bootver; then
			echo_tty_journal "Currently running DEVELOPMENT ROMMON, bypass rommon upgrade!"
		else
			update_required=true
			echo_tty_journal "This platform need to upgrade the rommon "
		fi
    fi
    ## For 2RU, URANIUM and THORIUM.
elif [[ "$FRU_SUB" == "URANIUM" || "$FRU_SUB" == "THORIUM" ]]; then
    if [[ "$rom_installed_ver" =~ 17\.3\(1\.2r || "$rom_installed_ver" =~ 17\.3\(1\.1r ||
          "$rom_installed_ver" =~ 17\.3\(1r || "$rom_installed_ver" =~ 17\.3\(4\.1r ||
          "$rom_installed_ver" =~ 17\.6\(6\.1r || "$rom_installed_ver" =~ 17\.7\(1r ]]; then
        # C8300_2N2S_xx versions of 17.6(6.1r) will be upgraded to 17.18(2r)
        update_required=true
        echo_tty_journal "This platform need to upgrade the rommon "
    elif [[ "$rom_installed_ver" =~ 17\.18\(2r ]]; then
        echo_tty_journal "This platform has latest rommon version. "
    fi  
elif [[ "$FRU_SUB" == "PROMETHIUM" ]]; then
    if [[ "$rom_installed_ver" =~ 17\. ]]; then
       # C8200-1N versions prior to 17.6(6r) or 17.6(8r) to be upgraded to 17.6(8.1r)
        if grep -q "DEVELOPMENT" /proc/rmonbifo/bootver; then
            echo_tty_journal "Currently running DEVELOPMENT ROMMON, bypass rommon upgrade!"
        else
            if [[ "$rom_installed_ver" != "17.4(2r) DEV" ]]; then
                platform_idf=$(grep 'PLATFORM_IDF' /.image_info | cut -d '=' -f2)
                if [[ "${platform_idf}" = "phx" ]]; then
                    echo_tty_journal "Bypass rommon upgrade for VG420 "
                else
                    update_required=true
                    echo_tty_journal "This platform need to upgrade the rommon "
                fi
            fi
	fi
    fi
elif [[ "$FRU_SUB" == "PROMETHIUM-L" ]]; then
    if [[ "$rom_installed_ver" =~ 17\. ]]; then
        if grep -q "DEVELOPMENT" /proc/rmonbifo/bootver; then
            echo_tty_journal "Currently running DEVELOPMENT ROMMON, bypass rommon upgrade!"
        else
            update_required=true
            echo_tty_journal "This platform need to upgrade the rommon "
		fi
    fi
elif [[ "$FRU_SUB" == "CRESTONE" || "$FRU_SUB" == "WILSON" ]]; then
    # Only upgrade r versions, d versions are likely development lab systems
    # and should be manually upgraded only
    if [[ "$rom_installed_ver" =~ 17\.15\(3\.3r ||
          "$rom_installed_ver" =~ 17\.15\(3\.2r ||
          "$rom_installed_ver" =~ 17\.15\(3\.1r ||
          "$rom_installed_ver" =~ 17\.15\(1\.18r ]]; then
        update_required=true
        echo_tty_journal "This platform needs to upgrade the rommon"
    elif [[ "$rom_installed_ver" =~ 17\.18\(3r ]]; then
        echo_tty_journal "This platform has the latest rommon version."
    else
        update_required=true
        manual_update_required=true
        echo_tty_journal "This platform requires a rommonm update but it must be done manually"
    fi
elif [[ "$FRU_SUB" == "ARATA" || "$FRU_SUB" == "ARATA_E" ||
            "$FRU_SUB" == "WHITNEY" ]]; then
    # Only upgrade r versions, d versions are likely development lab systems
    # and should be manually upgraded only
    if [[ "$rom_installed_ver" =~ 17\.18\(1\.12r ||
          "$rom_installed_ver" =~ 17\.18\(1\.10r ||
          "$rom_installed_ver" =~ 17\.18\(1\.5r ||
          "$rom_installed_ver" =~ 17\.18\(1\.4r ||
          "$rom_installed_ver" =~ 17\.18\(1r ]]; then
        update_required=true
        echo_tty_journal "This platform needs to upgrade the rommon"
    elif [[ "$rom_installed_ver" =~ 17\.18\(4\.1r ]]; then
        echo_tty_journal "This platform has the latest rommon version."
    else
        update_required=true
        manual_update_required=true
        echo_tty_journal "This platform requires a rommon update but it must be done manually"
    fi
elif [[ "$FRU_SUB" == "NUTELLA" ]]; then
    declare bios_mode=$(/usr/binos/bin/flashutil \-c getvar -N BIOS_MODE)
    #make sure migration not in progress
    if [[ "$bios_mode" == "2" &&
          ( "$rom_installed_ver" =~ ^17.3\(0[1-5]\d ||
            "$rom_installed_ver" =~ ^17.4\(0[1-5]\d ||
            "$rom_installed_ver" =~ ^17.4\([1-2]r ||
            "$rom_installed_ver" =~ ^17.7\(1r ||
	    "$rom_installed_ver" =~ ^17.15.1r ) ]]; then
        # Upgrade NUTELLA BIOS to latest release
        update_required=true
        echo_tty_journal "This platform, ISR1100, need to upgrade the rommon "
    fi
elif [[ "$FRU_SUB" == "SUMATRA" ]]; then
    if [[ "$rom_installed_ver" =~ v0\.*(4[2-9]|5[0-2]) ]]; then
        # v053 is the latest and prior will be upgraded
        update_required=true
        echo_tty_journal "This platform, IR8340, need to upgrade the rommon "
    fi
elif [[ "$FRU_SUB" == "VG410" ]]; then
    if [[ "$rom_installed_ver" =~ ^17\. ]]; then
        update_required=true
        echo_tty_journal "This platform need to upgrade the rommon "
    fi
fi

if [[ "$update_required" == false ]]; then
    echo_journal "ROMMON version up to date."
    exit 0
elif [[ "$manual_update_required" == true ]]; then
    echo_tty_journal "Detected old ROMMON version $rom_installed_ver, manual upgrade required"
    exit 0
else
    echo_tty_journal "Detected old ROMMON version $rom_installed_ver, upgrade required"
fi

#Check if user has disabled auto upgrade
if [[ ! -z ${ROMMON_FIRMWARE_UPGRADE:-} && "$ROMMON_FIRMWARE_UPGRADE" == "0" ]]; 
then
    echo_tty_journal "User has disabled firmware upgrade with FIRMWARE_UPGRADE=0"
    exit 0
fi


# If an upgrade is already in progress, then just exit.
# Do this here before we set our cleanup-on-exit function.
if [ -e $ROMMON_MOUNT ]; then
    upgrade_abort "Upgrade of $ROMMON_NAME already in progress."
fi

trap 'cleanup' EXIT

# show_help
#
# Display usage
function show_help () {
    echo_journal "$0: --package <rommon_package> "
    echo_journal ""
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
        echo_journal "Removal of $ROMMON_NAME package mount point failed"
        rm -rf $ROMMON_MOUNT
    fi
}
readonly -f cleanup;


#
# --------------  process command line options -----------------
#
readonly longopts="package:,debug,help"

set +e
args=`getopt --name $(basename $0 .sh) --longoptions "$longopts" "h" "$@"`
STAT=$?
readonly args
set -e

if [ $STAT != 0 ]; then
    upgrade_abort "Invalid command arguments."
fi

# the eval, "" for args here is to make sure that quoted strings are preserved
eval set -- "$args" 

if [[ "$FRU_SUB" == "RADIUM" || "$FRU_SUB" == "THALLIUM" ]]; then
    declare firmware_package=/firmware/host/firmware_curie1ru.pkg
elif [[ "$FRU_SUB" == "URANIUM" || "$FRU_SUB" == "THORIUM" ]]; then
    declare firmware_package=/firmware/host/firmware_curie2ru.pkg
elif [[ "$FRU_SUB" == "PROMETHIUM" ]]; then
    declare firmware_package=/firmware/host/firmware_curieprom.pkg
elif [[ "$FRU_SUB" == "PROMETHIUM-L" ]]; then
    declare firmware_package=/firmware/host/firmware_curieprom_l.pkg
elif [[ "$FRU_SUB" == "NUTELLA"  ]]; then
    declare firmware_package=/firmware/host/firmware_nutella.pkg
elif [[ "$FRU_SUB" == "SUMATRA"  ]]; then
    declare firmware_package=/firmware/host/firmware_sumatra.pkg
elif [[ "$FRU_SUB" == "CRESTONE" || "$FRU_SUB" == "WILSON" ]]; then
    declare firmware_package=/firmware/host/firmware_mirabile_soc2.pkg
elif [[ "$FRU_SUB" == "ARATA" || "$FRU_SUB" == "ARATA_E" ||
    "$FRU_SUB" == "WHITNEY" ]]; then
    declare firmware_package=/firmware/host/firmware_mirabile_soc1.pkg
else
    declare firmware_package=/firmware/host/firmware.pkg
fi

for i
do
  case "$i" in
      --package)    shift; firmware_package=$1; shift;;
      --debug)      shift; debug=1; set -x; set -v;;
      --help)       show_help;;
      -h)           show_help;;
  esac
done

readonly firmware_package

# Verify the firmware package exists
if [ ! -e "$firmware_package" ]; then
    upgrade_abort "File: $firmware_package does not exist"
fi

# Make sure the package is signed
$CSVERIFY package $firmware_package
if [[ "$?" != "0" ]]; then
    upgrade_abort "$pkg is not code signed"
fi

# Mount the rommon package
mount_binos_pkg $firmware_package $ROMMON_MOUNT

# Verify the package type is correct
declare pkg_type=$( get_pkg_pkginfo_type $ROMMON_MOUNT/.pkginfo )
if [[ $pkg_type != "rommon" ]]; then
    upgrade_abort "$firmware_package is not a rommon package: ${pkg_type}"
fi

# Set up path to the rommon data file
declare ovld_params="console"
declare board_type=$(</sys/bus/platform/devices/cpld/board_type) 
declare board_subtype=$(</sys/bus/platform/devices/cpld/board_subtype)
declare platform_type=$(</sys/bus/platform/devices/cpld/platform_type)
# Promethium and Promethium-L use the same rommon,
# so change the image path to use the same as Promethium.
if [[ $board_subtype == "PROMETHIUM-L" ]];then
    board_subtype="PROMETHIUM"
fi
declare rom_bin=$ROMMON_MOUNT/rommon/$platform_type/$board_type/$board_subtype/latest.bin

#check to see if we have capsule support for this platform
declare rommon_upgrade_cpslpath=""
if chasfs_has_capsule_support; then
    rommon_upgrade_cpslpath=$ROMMON_MOUNT/rommon/$platform_type/$board_type/$board_subtype/capsule.bin

fi

# Bail if the rommon image is not present
if [ ! -f "$rom_bin" ]; then
    upgrade_abort "Unable to locate ROMMON image file for upgrade."
fi

#Invoke rommon upgrade script with latest rommon image

echo_tty_journal "Upgrading to newer ROMMON version required by this version of IOS-XE, do not power cycle the system.  A reboot will automatically occur for the new ROMMON to take effect."
ovld_upgrade_rommon.sh $ovld_params $rom_bin $rommon_upgrade_cpslpath

if [[ "$?" != "0" ]]; then
    upgrade_abort "ROMMON firwmare image upgrade failed"
fi
    
echo_tty_journal "ROMMON upgrade successful.  Rebooting for upgrade to take effect."
systemctl --no-block reboot
exit 0
