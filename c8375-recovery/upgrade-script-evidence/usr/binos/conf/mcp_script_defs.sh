#!/bin/sh

#---------------------------------------------------------
# mcp_script_defs.sh - Basic readonly variable definitions
#                      and utility functions which depend
#                      only upon those definitions.
#
# June 2007, Matt Bookman
#
# Copyright (c) 2007-2026 by cisco Systems, Inc.
# All rights reserved.
#---------------------------------------------------------

# --------------------------------------------
# Paths to scripts or executables 
# --------------------------------------------

readonly BEXECUTE=/usr/binos/conf/bexecute.sh
readonly BSHELL=/usr/binos/conf/bshell.sh
readonly BTELNET=/usr/binos/conf/btelnet.sh
readonly MCP_CHVRF=/usr/binos/conf/mcp_chvrf.sh
readonly VTYC=/usr/binos/conf/vtyc.sh
readonly IOUCON=/usr/binos/conf/ioucon.sh
readonly WORKON=/usr/binos/conf/workon.sh

readonly MCP_UPGRADE_ROMMON_HELPER=/usr/binos/conf/mcp_upgrade_rommon_helper.sh

FLASHUTIL_EXEC_PATH=/usr/binos/bin/flashutil

readonly ISSU_REMOTE_HELPER=/usr/binos/conf/issu_helper.sh

readonly AUTOUPGRADE_REMOTE_HELPER=/usr/binos/conf/auto_upgrade_helper.sh

readonly FAILOVER_EXEC_PATH=/usr/binos/conf/reload_fru.sh

readonly PROV_SCRIPT="/usr/binos/conf/provision.sh"

readonly EXPAND_SCRIPT="/usr/binos/conf/packtool.sh"

readonly ISSU_ONESHOT_SCRIPT="/usr/binos/conf/oneshot_issu.sh"

readonly ISSU_WRAPPER_FILE="/usr/binos/conf/issu_wrapper.sh"

readonly KEXEC_RPBOOT_PREVFY_SCRIPT="/usr/binos/conf/kexec_rpboot_prevfy.sh"
readonly KEXEC_RELOAD_SCRIPT="/usr/binos/conf/kexec_reload.sh"
readonly KEXEC_STK_RELOAD_SCRIPT="/usr/binos/conf/kexec_stk_reload.sh"
readonly KEXEC_SW_INSTALL_SCRIPT="/usr/binos/conf/kexec_sw_install.sh"
readonly KEXEC_STK_INSTALL_SCRIPT="/usr/binos/conf/kexec_stk_install.sh"
readonly ROMMON_RELOAD_SCRIPT="/usr/binos/conf/rommon_reload.sh"
readonly FPGA_PREUPGR_SCRIPT="/usr/binos/conf/fpga_preupgr.sh"
readonly KR_PREUPGR_SCRIPT="/usr/binos/conf/kr_preupgr.sh"
readonly BOOT_PREUPGR_SCRIPT="/usr/binos/conf/rommon_preupgr.sh"
readonly SW_PLOAD_SVC_SCRIPT="/usr/binos/conf/sw_pload_svc.sh"
readonly STK_PLOAD_SVC_SCRIPT="/usr/binos/conf/stk_pload_svc.sh"
readonly MCU_PLOAD_FAILURE_SIGNATURE="FAILED MCU check and upgrade"
readonly FPGA_FAST_RLD_PRECHECK_SCRIPT="/usr/binos/conf/fpga_fast_rld_precheck.sh"
readonly BOARD_FAST_RLD_PRECHECK_SCRIPT="/usr/binos/conf/board_fast_rld_precheck.sh"
readonly SW_FAST_RLD_PRECHK_SCRIPT="/usr/binos/conf/sw_fast_rld_prechk.sh"
readonly FAST_RLD_PRECHECK_SCRIPT="/usr/binos/conf/fast_rld_precheck.sh"
readonly FAST_RLD_IMAGECHK_SCRIPT="/usr/binos/conf/fast_rld_imagechk.sh"
readonly EXPR_BOOT_FW_CHK_SCRIPT="/usr/binos/conf/expr_boot_fw_chk.sh"
readonly FAST_RLD_UPGCHECK_SCRIPT="/usr/binos/conf/fast_rld_upgcheck.sh"
readonly FAST_RLD_START_GR_SCRIPT="/usr/binos/conf/fast_rld_start_gr.sh"
readonly FAST_RLD_PREVERIFY_SCRIPT="/usr/binos/conf/fast_rld_preverify.sh"
readonly FAST_RELOAD_SCRIPT="/usr/binos/conf/fast_reload.sh"
readonly STK_EFSU_PLOAD_SCRIPT="/usr/binos/conf/stk_efsu_pload.sh"

readonly INSTALL_ENGINE_SCRIPT="/usr/binos/conf/install_engine.sh"

# --------------------------------------------
# Paths to working directories used at runtime
# --------------------------------------------

# The rommon upgrade command handler on the active rp will
# mount the rommon package in the ROMMON_MOUNT directory, which
# is published via the rsync daemon (rsyncd).
readonly ROMMON_MOUNT=/tmp/rommon_upgrade_pub

# The rommon helper script on each fru will rsync the rommon upgrade file
# down into the ROMMON_UPGRADE_TEMP_DIR
readonly ROMMON_UPGRADE_TEMP_DIR=/tmp/rommon_upgrade

# The hwprg upgrade command handler on the active rp will
# mount the hwprg package in the _MOUNT directory,
# this will be copied over to the fru/slot in the stage directory
# and finally rsync'ed by the CC/stbyRP before it upgrades
readonly HWPRG_MOUNT=/tmp/hwprg_upgrade_pub

# stage directory on RP HWPRG_UPGRADE_STAGE_DIR
readonly HWPRG_UPGRADE_STAGE_DIR=/tmp/hwprg_upgrade_stage

# The hwprg helper script on each fru will rsync the hwprg upgrade file
# down into the HWPRG_UPGRADE_TEMP_DIR
readonly HWPRG_UPGRADE_LOCAL_DIR=/tmp/hwprg_upgrade

# The booted / mounted packages are all present in this directory
readonly BOOTED_PACKAGES_LIST=/tmp/sw/mount/

# Path to the actual packages.conf we booted from.
readonly BOOTED_PACKAGES_DIR=/tmp/sw/boot/booted_packages.conf.dir

# ------------------------------------------
# Constants for referencing the various frus
# ------------------------------------------

# Typical programmatic references use the two-character lower case
# Constants for displaying the fru abbreviations are provided
# as well as constants for displaying the fru by name
readonly BINOS_RP_LOWER="rp"
readonly BINOS_FP_LOWER="fp"
readonly BINOS_CC_LOWER="cc"
readonly BINOS_BP_LOWER="bp"

readonly BINOS_RP_UPPER="RP"
readonly BINOS_FP_UPPER="FP"
readonly BINOS_CC_UPPER="CC"
readonly BINOS_BP_UPPER="BP"

readonly BINOS_RP_ABBR="RP"
readonly BINOS_FP_ABBR="ESP"
readonly BINOS_CC_ABBR="SIP"
readonly BINOS_SPA_ABBR="SPA"
readonly BINOS_CLC_ABBR="CLC"
readonly BINOS_BP_ABBR="BP"

readonly BINOS_RP_NAME="Route-Processor"
readonly BINOS_FP_NAME="Embedded-Service-Processor"
readonly BINOS_CC_NAME="SPA-Inter-Processor"
readonly BINOS_BP_NAME="Bootstrap-Plane"

readonly BINOS_FRU_ROLE_ACTIVE="active"
readonly BINOS_FRU_ROLE_STANDBY="standby"

# Display name for the rommon
readonly ROMMON_NAME="rom-monitor"
readonly HWPRG_NAME="hw-programmable"

# The IOS image names
readonly BINOS_CC_IMAGE_NAME="ubrclc_k9lc_ms"
readonly BINOS_SPA_IMAGE_NAME="mcpcc_lc_ms"
readonly BINOS_RP_IMAGE_NAME="linux_iosd_image"
readonly BINOS_BP_IMAGE_NAME="linux_iosd_image"

# Some symbolic names for invalid values
readonly BINOS_SLOT_INVALID=-1
readonly BINOS_BAY_INVALID=-1

# ISSU one-shot required variables
readonly ISSU_CHASFS_DIR="/tmp/rp/chasfs/issu"
readonly ISSU_WRAPPER_PID_FILE="$ISSU_CHASFS_DIR/wrapper_pid"
readonly ISSU_WRAPPER_OUTPUT_FILE="/tmp/issu_wrapper.log"
readonly RESUME_ONESHOT_ISSU_SUPER="$ISSU_CHASFS_DIR/resume_oneshot_issu_super"
readonly AUTO_COMMITVERSION="$ISSU_CHASFS_DIR/auto_commitversion"
readonly AUTO_COMMITVERSION_RESULT="$ISSU_CHASFS_DIR/auto_commit_result"
readonly IOS_SAVE_MODIFIED_CFG="$ISSU_CHASFS_DIR/ios_save_modified_cfg"
readonly IOS_CFG_SAVE_DONE="$ISSU_CHASFS_DIR/ios_cfg_save_done"
readonly INSTALL_BOOT_PARAM_UPDATE="$ISSU_CHASFS_DIR/install_boot_param_update"
readonly INSTALL_BOOT_PARAM_UPDATE_DONE="$ISSU_CHASFS_DIR/install_boot_param_update_done"
readonly COMP_SW_TREE_DIR="comp_sw_tree_new"
readonly COMP_SW_TREE_DIR_LEGACY="comp_sw_tree"
readonly COMP_DECISION="compatibility_decision"
readonly COMP_ERR_FILE="compatibility_error.log"
readonly LOCAL_COMP_SW_TREE_DIR=$ISSU_CHASFS_DIR/local/$COMP_SW_TREE_DIR
readonly LOCAL_COMP_SW_TREE_DIR_LEGACY=$ISSU_CHASFS_DIR/local/$COMP_SW_TREE_DIR_LEGACY
readonly RSYNC_COMP_SW_TREE_DIR="chasfs/issu/local/$COMP_SW_TREE_DIR"

# CRFT collection specific variables
readonly CRFT_TMP_STORAGE_ROOT="/tmp/.CRFT"
readonly CRFT_PERSISTENT_STORAGE_ROOT="/harddisk/.CRFT"

# --------------------------------------------------------------
# Simple functions
#
# Functions added to this file must be completely self-contained
# (only depend on variable values provided to the function or
# constants contained in this file).
# --------------------------------------------------------------

# binos_fru_to_display_abbr
#
# Convert a binos FRU lower/upper to its full display abbreviation
function binos_fru_to_display_abbr () {
    local readonly fru_val="$1"

    case $fru_val in
        $BINOS_RP_LOWER | $BINOS_RP_UPPER) echo -n "$BINOS_RP_ABBR";;
        $BINOS_FP_LOWER | $BINOS_FP_UPPER) echo -n "$BINOS_FP_ABBR";;
        $BINOS_CC_LOWER | $BINOS_CC_UPPER) echo -n "$BINOS_CC_ABBR";;
        $BINOS_BP_LOWER | $BINOS_BP_UPPER) echo -n "$BINOS_BP_ABBR";;
        *) echo -n "$fru_val";;
    esac
}
readonly -f binos_fru_to_display_abbr;

# binos_fru_to_display_name
#
# Convert a binos FRU lower/upper to its full display name
function binos_fru_to_display_name () {
    local readonly fru_val="$1"

    case $fru_val in
        $BINOS_RP_LOWER | $BINOS_RP_UPPER) echo -n "$BINOS_RP_NAME";;
        $BINOS_FP_LOWER | $BINOS_FP_UPPER) echo -n "$BINOS_FP_NAME";;
        $BINOS_CC_LOWER | $BINOS_CC_UPPER) echo -n "$BINOS_CC_NAME";;
        $BINOS_BP_LOWER | $BINOS_BP_UPPER) echo -n "$BINOS_BP_NAME";;
        *) echo -n "UKNOWN";;
    esac
}
readonly -f binos_fru_to_display_name;

function notify_update () {
    local readonly msg_location="$1"
    shift;
    if [[ $msg_location == "remote" ]]; then
        if [[ "$4" != "" ]]; then
            vconfd_notifier "$@"
        fi
    elif [[ $msg_location == "console" ]]; then
        echo "$4"
    fi
}
readonly -f notify_update
