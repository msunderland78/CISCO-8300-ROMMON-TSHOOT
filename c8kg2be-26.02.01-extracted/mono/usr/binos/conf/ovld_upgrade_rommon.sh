#!/bin/bash
#------------------------------------------------------------------
# ovld_upgrade_rommon.sh - MTD based rommon upgrader for ESG platforms.
#
# June 2012, Srinivas Kothapally
#
# Copyright (c) 2012-2014, 2016-2026 by Cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------
# This script needs to be run twice in order to complete a rommon upgrade:
# 1) With a single argument that is the upgrade .BIN filename.  After
#    checking the file and burning the flash, the script will force a
#    hardware reset.
# 2) With no arguments after the board has rebooted into linux.  This
#    invocation will cement the new rommon into place.

# get the common functions
readonly SCRIPTS_DIR=/usr/binos/conf
 
# set up globals needed by chasfs utils
source /common
source $SCRIPTS_DIR/mcp_script_defs.sh
source $SCRIPTS_DIR/psimple.sh
source $SCRIPTS_DIR/iosxe_upgrade_rommon_em.sh
source $SCRIPTS_DIR/hwutil.sh

# Set the BOARD_TYPE, BOARD_SUBTYPE, etc.
hwutil_set_plat_board_fru_slot_bay;
source $SCRIPTS_DIR/pglobals.sh
source $SCRIPTS_DIR/chasutils.sh
uuid=""
notification="console"
if [[ "$1" == "--remote" ]]; then
    uuid="$3"
    notification="remote"
    #now shift past the first 3
    shift
    shift
    shift
else
    #need to get past the first empty param 
    shift
fi

if [ -d /tmp/chassis/cpld/chasfs ]; then
    CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
else
    CPLD_DIR="/sys/bus/platform/devices/cpld/"
fi

readonly ROMMON_DEVICE="/dev/mtdblock0"

# The following vars are only used for debug purposes
TURNONDEBUG=0
GOODCATCHES=0
CHKSUMCATCHES=0
SYNCCATCHES=0
PRENVRAMSUMCATCHES=0
POSTNVRAMSUMCATCHES=0
PREPSKEYSUMCATCHES=0
POSTPSKEYSUMCATCHES=0
RC_SYNC=0
RC_PRENVRAMSUM=0
RC_POSTNVRAMSUM=0
PRENVRAMSUM=0
POSTNVRAMSUM=0
PREPSKEYSUM=0
POSTPSKEYSUM=0
PREIMAGESUM=0
POSTIMAGESUM=0
# End of vars used only for debug purposes

# CPLD registers
CPLD="/sys/devices/platform/cpld"

# Registers we use from dash fpgs.
# Notice that the base address is 0xFED40000 and the offsets are below.

REG_RSN=$CPLD/reg_cp_reset_reason         # 0x4
REG_CKE=$CPLD/reg_cp_magic_cookie         # 0x8
REG_STA=$CPLD/reg_cp_status               # 0xc
REG_RST_CTRL=$CPLD/reg_cp_reset_control   # 0x10
REG_RP_CTRL_0=$CPLD/reg_rp_control_0      # 0x58
REG_VER=$CPLD/reg_main_fpga_ver           # 0x88
REG_CNF=$CPLD/reg_main_conf_hdr_ctrl      # 0xB0

# Sizes of various lego blocks
# See: /vob/ios/sys/rommon/src-i86_x64-esg/esg_pcmap.h

# ROMMON NVRAM section offsed and size
NVRAM_OFFSET=4259840
PSKEY_OFFSET=4521984
NVRAM_SIZE=262144
PSKEY_SIZE=196608
FULL_UPGRADE=0
SKIP_ROMVAR_UPDATE=0
GOLDEN_AND_UPGRADE_BIOS_SCHEME=0
SET_UPGRADE_PENDING=0

# Expected size of the binary BIOS image and offset
if chasfs_is_family_tsn; then
    FLASH_SIZE=33554432
    ROMMON_SIZE=8388608
    IMAGE_SIZE=4194304
    FLASH_OFFSET=4194304
    NVRAM_SIZE=0
    PSKEY_SIZE=0
elif chasfs_is_family_usd; then
    FLASH_SIZE=8388608
    ROMMON_SIZE=4194304
    IMAGE_SIZE=4194304
    FLASH_OFFSET=4194304
    PSKEY_SIZE=0
elif chasfs_is_neptune || chasfs_is_radium || chasfs_is_thallium ||
     chasfs_is_nanook || chasfs_is_vg410; then
# Intel chipsets with BIOS SPI flash size 16M need to be
# separated from flash size 32M, example Skylake-D
    FLASH_SIZE=16777216
    ROMMON_SIZE=8388608
    IMAGE_SIZE=8388608
    FLASH_OFFSET=8388608
    NVRAM_OFFSET=8388608
    NVRAM_SIZE=131072
    PSKEY_SIZE=0
elif chasfs_is_uranium || chasfs_is_thorium || chasfs_is_fugazi; then
# Intel chipsets with BIOS SPI flash size 32MB
    FLASH_SIZE=33554432
    ROMMON_SIZE=16777216
    IMAGE_SIZE=16777216
    FLASH_OFFSET=16777216
    NVRAM_OFFSET=16777216
    NVRAM_SIZE=131072
    PSKEY_SIZE=0
elif chasfs_is_promethium || chasfs_is_sumatra; then
# Though promethium uses 16M SPI flash, denverton CPU on 
# this board has different ROMMON NVRAM offsets, so, 
# separately added here
    FLASH_SIZE=16777216
    ROMMON_SIZE=8388608
    IMAGE_SIZE=8388608
    FLASH_OFFSET=8454144
    NVRAM_OFFSET=8454144
    NVRAM_SIZE=131072
    PSKEY_SIZE=0
elif chasfs_is_nutella; then
# Though nutella uses 16M SPI flash, denverton CPU on 
# this board has different ROMMON NVRAM offsets, so, 
# separately added here
    FLASH_SIZE=16777216
    ROMMON_SIZE=8388608
    IMAGE_SIZE=8388608
    FLASH_OFFSET=8388608
    NVRAM_OFFSET=8388608
    NVRAM_SIZE=131072
    PSKEY_SIZE=0
# Upgrade pending status bit is handled by FPGA driver
# in Nutella (Offset 0x700)
    REG_CNF="/sys/bus/platform/devices/nutella_fpga/upgrade_pending"
# Skip ROMVAR update for Nutella, as the ROMMON variables
# are stored in eMMC instead of BIOS SPI Flash
    SKIP_ROMVAR_UPDATE=1
# Nutella uses Golden/Upgrade BIOS scheme, instead of
# ping-pong mechanism used by other platforms
    GOLDEN_AND_UPGRADE_BIOS_SCHEME=1
    SET_UPGRADE_PENDING=1
elif chasfs_is_family_14er || chasfs_is_bender || chasfs_is_fry; then
    FLASH_SIZE=33554432
    ROMMON_SIZE=19791872
    IMAGE_SIZE=19791872
    FLASH_OFFSET=0
    NVRAM_OFFSET=32702464
    NVRAM_SIZE=131072
    PSKEY_SIZE=0
    if chasfs_is_family_14er; then
       TAMPER_MARK_PRIM_OFFSET=32833536
       TAMPER_MARK_BKUP_OFFSET=32899072
       TAMPER_MARK_COUNT=65536
    fi
elif chasfs_is_charon_family || chasfs_is_calliope; then
# Charon and Calliope use capsule method to upgrade Rommon,
# no need to set below variables anymore.
    #FLASH_SIZE=33554432   #32M
    #ROMMON_SIZE=7340032   #7M
    #IMAGE_SIZE=7340032    #7M
    #FLASH_OFFSET=1048576  #ROM0 Offset 0x100000, ROM1 is 0x900000
# No need to copy NVRAM and PSKEY during upgrade
    NVRAM_SIZE=0
    PSKEY_SIZE=0
else
    FLASH_SIZE=8388608
    ROMMON_SIZE=3211264
    IMAGE_SIZE=3211264
    FLASH_OFFSET=5177344
fi

# File to store ROMMON NVRAM section and temp file for the upgrade procedure
ROMVAR_FILE="/tmp/.romvars"
PUBKEY_FILE="/tmp/.pubkeys"
TAMP_MARK_PRIM_FILE="/tmp/.tampprimfile"
TAMP_MARK_BKUP_FILE="/tmp/.tampbkupfile"

EFI_CAPSULE_DIR=/bootflash/EFI
UPDATE_CAPSULE_DIR="$EFI_CAPSULE_DIR/UpdateCapsule"
UPDATE_CAPSULE_FILE="$UPDATE_CAPSULE_DIR/UpdateCapsuleFile.bin"

cleanup_tmp_files () {
  if [ -f $ROMVAR_FILE ]; then
     rm -f $ROMVAR_FILE
  fi
  if [ -f $PUBKEY_FILE ]; then
     rm -f $PUBKEY_FILE
  fi
}

if [ ! -d "$CPLD" ]; then
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail ""
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FATAL: cannot find $CPLD directory"
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FATAL: upgrade via self updater from rommon"
    exit -1
fi

convert_ios_to_path () {
    fname=$(echo "/"$1 | sed 's/:/\//')
    echo -n "$fname"
}

#
# The ROMMON binary image provides the BIOS image.  Because the Descriptor and
# ME section are write protected, the sections cannot be updated by the binary
# image.
# The binary image contains the OS public keys and the BIOS image.
#
check_binary_file () {

    if [ ! -r "$1" ]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail ""
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FATAL: File $1 can not be read! Upgrade aborted"
        return 1
    fi

    # Verify that the upgrade file is of the proper size
    FILE_SIZE=`stat -c "%s" "$1"`

    if [ $FILE_SIZE -eq $ROMMON_SIZE ]; then
       FULL_UPGRADE=0
    elif [ $FILE_SIZE -eq $FLASH_SIZE ]; then
       FULL_UPGRADE=1
    else
       notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FATAL: $1 is not correct size"
       notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FATAL: rommon upgrade aborted"
       return 1
    fi

    return 0
}

perform_fips_test () {
    if [ ! -e /usr/binos/bin/csverify  ] ; then
        # If the file is not present, then the platform doesn't support
        # FIPS-140-3 verfication of the image (note however, the rommon
        # package itself is verified at higher layer), so no need to alarm
        # user with a message here.
        :
    elif chasfs_is_family_tsn; then
        # csverify cannot verify an LDWM signed image.
        # when csverify is updated to support LDWM verification
        # please remove the TSN family check
        :
    else
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "File $1 is a FIPS ROMMON image"
        # Let us do a load test.
        /usr/binos/bin/csverify  rom-bundle $1
        if [ $? -eq 0 ]; then
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "FIPS-140-3 Load Test on $1 has PASSED."
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Authenticity of the image has been verified."
        else
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "FAILURE: csverify failed.  return code is $?"
           return 1
           #
           # em_iosxe_upgrade_rommon_ROMMON_LOADTEST_FAIL "$1"
           #
           # Ideally, we should generate this message, however
           # Someone can build Unsigned IOS-XE package, and that
           # will still bring in the csverify. Now, they try to
           # Go back to a rommon pre-dating the Code signing
           # We don't want to scare the user with the error message
           # here. MCP_FIXME when we make code signing mandatory
        fi
     fi

     return 0
}

cleanup_capsule() {

    if [ -f $UPDATE_CAPSULE_FILE ]; then
        rm -f $UPDATE_CAPSULE_FILE
        if [[ $? -ne 0 ]]; then
            RESULTSSTRING="FAILURE: Removing $UPDATE_CAPSULE_FILE ($?)"
            print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        fi
    fi
    if [ -d $UPDATE_CAPSULE_DIR ]; then
        rmdir $UPDATE_CAPSULE_DIR
        if [[ $? -ne 0 ]]; then
            RESULTSSTRING="FAILURE: Removing $UPDATE_CAPSULE_DIR ($?)"
            print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        fi
    fi
    if [ -d $EFI_CAPSULE_DIR ]; then
        rmdir $EFI_CAPSULE_DIR
        if [[ $? -ne 0 ]]; then
            RESULTSSTRING="FAILURE: Removing $EFI_CAPSULE_DIR ($?)"
            print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        fi
    fi

    return 0
}

print_results() {
    local PRINTRESULTSSTRING=$1
    local NVRAM_FILE=$2
    local MTD_DEVICE=$3
    local PSKEY_FILE=$4
    local ROMMON_FILE=$5

    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status ""
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "$PRINTRESULTSSTRING"
    if [ $TURNONDEBUG -eq 1 ]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "GOODCATCHES $GOODCATCHES    CHKSUMCATCHES $CHKSUMCATCHES    SYNCCATCHES $SYNCCATCHES"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PRENVRAMSUMCATCHES $PRENVRAMSUMCATCHES    POSTNVRAMSUMCATCHES $POSTNVRAMSUMCATCHES"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PREPSKEYSUMCATCHES $PREPSKEYSUMCATCHES    POSTPSKEYSUMCATCHES $POSTPSKEYSUMCATCHES"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "RC_SYNC             $RC_SYNC"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "RC_PRENVRAMSUM      $RC_PRENVRAMSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "RC_POSTNVRAMSUM     $RC_POSTNVRAMSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PRENVRAMSUM         $PRENVRAMSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "POSTNVRAMSUM        $POSTNVRAMSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PREPSKEYSUM         $PREPSKEYSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "POSTPSKEYSUM        $POSTPSKEYSUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PREIMAGESUM         $PREIMAGESUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "POSTIMAGESUM        $POSTIMAGESUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "NVRAM_OFFSET        $NVRAM_OFFSET"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "NVRAM_SIZE          $NVRAM_SIZE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PSKEY_SIZE          $PSKEY_SIZE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PSKEY_OFFSET        $PSKEY_OFFSET"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "ROMMON_DEVICE       $ROMMON_DEVICE"

        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "NVRAM_FILE            $NVRAM_FILE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "MTD_DEVICE            $MTD_DEVICE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "PSKEY_FILE            $PSKEY_FILE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "ROMMON_FILE           $ROMMON_FILE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "CAPSULE_FILE          $CAPSULE_FILE"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "UPDATE_CAPSULE_FILE   $UPDATE_CAPSULE_FILE"

        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "rommon_capbits         $rommon_capbits"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "capsule_support        $capsule_support"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "update_capsule_support $update_capsule_support"
    fi

    return 0
}
readonly -f print_results

#
# Copy the NVRAM, OS Key section and tamper mark data to a local file.
#
copy_romenv() {
    local rc_nvram=0
    local rc_pskey=0
    local NVRAM_FILE=$1
    local PSKEY_FILE=$2
    local MTD_DEVICE=$3
    local COPYRESULTSSTR="NA"

    # In certain platforms, ROMMON Variables for both BIOS SPI Flash are maintained
    # in a common storage area. Thereby, copy of ROMMON variables are not required,
    # as both BIOS SPI Flash access the same ROMMON variables storage
    if [[ $NVRAM_SIZE -eq 0 && $PSKEY_SIZE -eq 0 || $SKIP_ROMVAR_UPDATE -eq 1 ]]; then
        return 0
    fi

    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Copying ROMMON environment..."

    if [[ $NVRAM_SIZE -gt 0 ]]; then
        # Copy NVRAM section from the SPI device to a file
        dd if=$MTD_DEVICE of=$NVRAM_FILE count=$NVRAM_SIZE bs=1 skip=$NVRAM_OFFSET
        rc_nvram=$?
    fi

    if [[ $PSKEY_SIZE -gt 0 ]]; then
        # Copy Primary/Secondary key section from the SPI device to a file
        dd if=$MTD_DEVICE of=$PSKEY_FILE count=$PSKEY_SIZE bs=1 skip=$PSKEY_OFFSET
        rc_pskey=$?
    fi

    if [[ $rc_nvram -ne 0 ]]; then
        COPYRESULTSSTR="FAILURE: Copying NVRAM section from the SPI device to a file. ($rc_nvram)"
        print_results "$COPYRESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
        return 1
    fi

    if [[ $rc_pskey -ne 0 ]]; then
        COPYRESULTSSTR="FAILURE: Copying Primary/Secondary key section from the SPI device to a file. ($rc_pskey)"
        print_results "$COPYRESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
        return 1
    fi
    
    if chasfs_is_family_14er; then
        # Copy tamper detection marker data on to backup ROMMON SPI flash, to ensure the data
        # integrity after ROMMON upgrade. Note that ROMMON upgrade performs ROMMON update
        # on backup ROMMON SPI and force it to be active after successful ROMMON upgrade
        dd if=$MTD_DEVICE of=$TAMP_MARK_PRIM_FILE skip=$TAMPER_MARK_PRIM_OFFSET count=$TAMPER_MARK_COUNT bs=1
        dd if=$MTD_DEVICE of=$TAMP_MARK_BKUP_FILE skip=$TAMPER_MARK_BKUP_OFFSET count=$TAMPER_MARK_COUNT bs=1
    fi

    # return the results
    return 0
}
readonly -f copy_romenv

#
# Write the ROMMON variable
#
function set_rommon_var () {
    local rc=
    local romvar=$1
    local value=$2

    rc=$($FLASHUTIL_EXEC_PATH --command setvar --name $romvar --value $value 2>&1)

    return $rc
}
readonly -f set_rommon_var


# The copy the BIOS image to the SPI FLASH
upgrade_spi_flash() {
    local ROMMON_FILE=$1
    local MTD_DEVICE=$2
    local UPGRADERESULTSSTR="NA"

    switch_spi_bank
    
    # Write to the flash.
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Upgrading ROMMON image..."
    dd if=$ROMMON_FILE of=$MTD_DEVICE skip=$FLASH_SKIP seek=$FLASH_SEEK count=$IMAGE_SIZE bs=1
    if [[ $? -ne 0 ]]; then
        UPGRADERESULTSSTR="FAILURE: Writing to the flash. ($?)"
        print_results "$UPGRADERESULTSSTR" "NA" $MTD_DEVICE "NA" $ROMMON_FILE
        return 1
    fi

    # Force the write-back of the file.
    sync
    if [[ $? -ne 0 ]]; then
        UPGRADERESULTSSTR="FAILURE: Writing back to the file. ($?)"
        print_results "$UPGRADERESULTSSTR" "NA" $MTD_DEVICE "NA" $ROMMON_FILE
        return 1
    fi

    # Get the md5sum for the upgrade image.
    PREIMAGESUM=`dd if=$ROMMON_FILE skip=$FLASH_SKIP count=$IMAGE_SIZE bs=1 | md5sum | awk '{print $1}'`
    if [[ $? -ne 0 ]]; then
        UPGRADERESULTSSTR="FAILURE: Getting the chksum for the upgrade image. ($?)"
        print_results "$UPGRADERESULTSSTR" "NA" $MTD_DEVICE "NA" $ROMMON_FILE
        return 1
    fi

    # Get the md5sum from the FLASH.
    # Need to use $FLASH_SEEK for skip.
    # $FLASH_SEEK is the offset ROMMON image in the flash.
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Verifying ROMMON image..."
    POSTIMAGESUM=`dd if=$MTD_DEVICE skip=$FLASH_SEEK count=$IMAGE_SIZE bs=1 | md5sum | awk '{print $1}'`
    if [[ $? -ne 0 ]]; then
        UPGRADERESULTSSTR="FAILURE: Getting the chksum for the flash. ($?)"
        print_results "$UPGRADERESULTSSTR" "NA" $MTD_DEVICE "NA" $ROMMON_FILE
        return 1
    fi

    restore_spi_bank

    if [ "foo_$PREIMAGESUM" != "foo_$POSTIMAGESUM" ]; then
        UPGRADERESULTSSTR="FAILURE: Upgraded ROMMON image failed verification check."
        print_results "$UPGRADERESULTSSTR" "NA" $MTD_DEVICE "NA" $ROMMON_FILE
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "Upgrade image MD5 signature is $PREIMAGESUM"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-fail "Upgraded ROMMON image MD5 signature is $POSTIMAGESUM"
        return 1
    fi

    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "ROMMON upgrade was successful..."
    return 0
}
readonly -f upgrade_spi_flash

update_romenv() {
    local rc=0
    local NVRAM_FILE=$1
    local PSKEY_FILE=$2
    local MTD_DEVICE=$3
    local LOOPLIMIT=3
    local loopctr=0
    local UPDATERESULTSSTR="NA"

    # In certain platforms, ROMMON Variables for both BIOS SPI Flash are maintained
    # in a common storage area. Thereby, update of ROMMON variables are not required,
    # as both BIOS SPI Flash access the same ROMMON variables storage
    if [[ $NVRAM_SIZE -eq 0 && $PSKEY_SIZE -eq 0 || $SKIP_ROMVAR_UPDATE -eq 1 ]]; then
        return 0
    fi

    switch_spi_bank

    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Updating ROMMON environment..."
    # loop a few times to write back the data if needed
    while [ $loopctr -lt "$LOOPLIMIT" ]
        do

        let "loopctr += 1"
        if [[ $NVRAM_SIZE -gt 0 ]]; then
            # Copy the ROMMON Variables file to the Backup SPI FLASH
            dd if=$NVRAM_FILE of=$MTD_DEVICE seek=$NVRAM_OFFSET count=$NVRAM_SIZE bs=1
            if [[ $? -ne 0 ]]; then
                UPDATERESULTSSTR="Problem ($loopctr): Copying ROMMON Variables. ($?)"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi
        fi

        if [[ $PSKEY_SIZE -gt 0 ]]; then
            # Copy the ROMMON Public Keys file to the Backup SPI FLASH
            dd if=$PSKEY_FILE of=$MTD_DEVICE seek=$PSKEY_OFFSET count=$PSKEY_SIZE bs=1
            if [[ $? -ne 0 ]]; then
                UPDATERESULTSSTR="Problem ($loopctr): Copying ROMMON Public Keys. ($?)"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi
        fi

        # Force the write-back of the data
        sync
        RC_SYNC=$?
        if [[ $RC_SYNC -ne 0 ]]; then
            let "SYNCCATCHES += 1"
            UPDATERESULTSSTR="Problem ($loopctr): Syncing the data ($RC_SYNC)."
            print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
            continue
        fi

        if [[ $NVRAM_SIZE -gt 0 ]]; then
            # Calculate the md5sum for the NVRAM File
            PRENVRAMSUM=`md5sum $NVRAM_FILE | awk '{print $1}'`
            RC_PRENVRAMSUM=$?
            if [[ $RC_PRENVRAMSUM -ne 0 ]]; then
                let "PRENVRAMSUMCATCHES += 1"
                UPDATERESULTSSTR="Problem ($loopctr): Calculating pre chksum for the NVRAM"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi

            # Calculate the md5sum for the NVRAM on the Backup SPI FLASH
            POSTNVRAMSUM=`dd if=$MTD_DEVICE skip=$NVRAM_OFFSET count=$NVRAM_SIZE bs=1 | md5sum | awk '{print $1}'`
            RC_POSTNVRAMSUM=$?
            if [[ $RC_POSTNVRAMSUM -ne 0 ]]; then
                let "POSTNVRAMSUMCATCHES += 1"
                UPDATERESULTSSTR="Problem ($loopctr): Calculating post chksum for the NVRAM"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi
        fi

        if [[ $PSKEY_SIZE -gt 0 ]]; then
            # Calculate the md5sum for the Public Keys file
            PREPSKEYSUM=`md5sum $PSKEY_FILE | awk '{print $1}'`
            if [[ $? -ne 0 ]]; then
                let "PREPSKEYSUMCATCHES += 1"
                UPDATERESULTSSTR="Problem ($loopctr): Calculating pre chksum for the Public Keys file. ($?)"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi

            # Calculate the md5sum for the Public Keys on the Backup SPI FLASH
            POSTPSKEYSUM=`dd if=$MTD_DEVICE skip=$PSKEY_OFFSET count=$PSKEY_SIZE bs=1 | md5sum | awk '{print $1}'`
            if [[ $? -ne 0 ]]; then
                let "POSTPSKEYSUMCATCHES += 1"
                UPDATERESULTSSTR="Problem ($loopctr): Calculating post chksum for the Public Keys file. ($?)"
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                continue
            fi
        fi

        # This is the good case, everything is working fine!
        if [[ $NVRAM_SIZE -eq 0 ]] || [ $PRENVRAMSUM == $POSTNVRAMSUM ]; then
            if [[ $PSKEY_SIZE -eq 0 ]] || [ $PREPSKEYSUM == $POSTPSKEYSUM ]; then
                let "GOODCATCHES += 1"
                UPDATERESULTSSTR="ROMMON Variable data passed verification check ($loopctr)."
                print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
                break;
            fi
        fi

        # If we get here then something did not work correctly.
        # Let's try it again!
        let "CHKSUMCATCHES += 1"
        UPDATERESULTSSTR="Problem ($loopctr): ROMMON Variable CHKSUM Mismatch"
        print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"

    done

    #
    # Check the ROMMON Variable and Public Keys
    # Do not allow upgrade process to continue
    #
    if [[ $NVRAM_SIZE -gt 0 ]]; then
        if [ "foo_$PRENVRAMSUM" != "foo_$POSTNVRAMSUM" ]; then
            UPDATERESULTSSTR="FAILURE: ROMMON Variable data failed verification check."
            print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
            rc=1
        fi
    fi

    if [[ $PSKEY_SIZE -gt 0 ]]; then
        if [ "foo_$PREPSKEYSUM" != "foo_$POSTPSKEYSUM" ]; then
            UPDATERESULTSSTR="FAILURE: ROMMON public keys failed verification check."
            print_results "$UPDATERESULTSSTR" $NVRAM_FILE $MTD_DEVICE $PSKEY_FILE "NA"
            rc=1
        fi
    fi
    
    sync
    if chasfs_is_family_14er; then
        # Update Tamper marked data, both for primary and backup to the SPI flash.
        dd if=$TAMP_MARK_PRIM_FILE of=$MTD_DEVICE seek=$TAMPER_MARK_PRIM_OFFSET count=$TAMPER_MARK_COUNT bs=1
        dd if=$TAMP_MARK_BKUP_FILE of=$MTD_DEVICE seek=$TAMPER_MARK_BKUP_OFFSET count=$TAMPER_MARK_COUNT bs=1
    fi
    sync

    restore_spi_bank

    return $rc
}
readonly -f update_romenv

# Fetch ROM Status:
# Get what is our Booted SPI device was, and what is our Selected SPI device is.
#
# There is a bug in the Overlord and Utah FPGA code. Therefore, fetch_rom_status
# can only be called once at the start of the Upgrade process.  The Boot SPI
# Select Override (Bit-31, 0x58) changes Booted SPI PROM Image (bit-5, 0x0C)
# instead of Selected SPI PROM Image (Bit-4, 0x0C) as it should.
#

fetch_rom_status () {
    CP_RESET=`cat "$REG_RSN" | sed 's/cp_reset_reason: 000000\(.\)\(.\)/0x\1 0x\2/'`
    export RESET_REASON=`echo $CP_RESET|awk --non-decimal-data '{ print and($1,1)  }'` 
    # Booted ROM : Bit 5 : 0 ==> ROM0, 1 ==> ROM1
    # selcted ROM : Bit 4 : 0 ==> ROM0, 1 ==> ROM1
    export SELECTED_ROM=`cat $REG_STA |sed 's/cp_status: ......\(.\)/0x\1/' | awk --non-decimal-data '{ printf "%x\n", rshift(and($1,0x10),4) }'`
    export BOOTED_ROM=`cat $REG_STA |sed 's/cp_status: ......\(.\)/0x\1/' | awk --non-decimal-data '{ printf "%x\n", rshift(and($1,0x20),5) }'`

    # Calculate the ROMMON image skip and seek offset
    set_rommon_skip_seek
}

fetch_selected_rom_status () {
    # selcted ROM : Bit 4 : 0 ==> ROM0, 1 ==> ROM1
    export SELECTED_ROM=`cat $REG_STA |sed 's/cp_status: ......\(.\)/0x\1/' | awk --non-decimal-data '{ printf "%x\n", rshift(and($1,0x10),4) }'`

    # Calculate the ROMMON image skip and seek offset
    set_rommon_skip_seek
}


# Assumes fetch_rom_status is called, and it set the correct values.
print_rom_status () {
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Booted : $BOOTED_ROM"
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Selected : $SELECTED_ROM"
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Reset Reason: $RESET_REASON"
}

#
# Calculate the Skip and Seek offset
#
function set_rommon_skip_seek () {

    if chasfs_is_family_tsn; then
        # TSN has one SPI FLASH, so we must simulate two ROMMON images.
        # ROM0 starts at 0x000_0000 and ROM1 starts at 0x040_0000.
        # The TSN upgrade image has matching offset for the ROM image.
        # Because of the nature of the LDWM signing, the ROM upgrade image
        # must be copied to the same ROM image in the SPI FLASH (i.e. the
        # skip and seek offset must match).
        if [ "$SELECTED_ROM" = "0" ]; then
            FLASH_SKIP=0
            FLASH_SEEK=0
        else
            FLASH_SKIP=$FLASH_OFFSET
            FLASH_SEEK=$FLASH_OFFSET
        fi
    else
        # All other platforms have two SPI FLASH chips, so just SPI FLASH
        # offest (seek) is needed.
        # For the ISR4K platforms, the older pkg files were created with the
        # wrong upgrade file (DediProg vs IOS Upgrade).  The Descriptor and
        # ME sections are write-protected, and should be skipped.
        # Otherwise, there could be upgrade failure because those sections
        # are not upgradable.
        if [ "$FULL_UPGRADE" = "0" ]; then
            FLASH_SKIP=0
        else
            FLASH_SKIP=$FLASH_OFFSET
        fi
        FLASH_SEEK=$FLASH_OFFSET
    fi
}
readonly -f set_rommon_skip_seek

# Toggle the SPI banks
switch_spi_bank () {
    # switch SPI flash chips to access the upgrade partition
    #
    # Bit 31 is the chip select override
    # Bit 30 is the SPI chip select
    # notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "BOOTED_ROM is $BOOTED_ROM"
    if [ "$BOOTED_ROM" = "0" ]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Switching to ROM 1"
        echo "C0000000" > $REG_RP_CTRL_0
    else
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Switching to ROM 0"
        echo "80000000" > $REG_RP_CTRL_0
    fi
    # Give the hardware a little time before we access the flash
    sleep 3

    if chasfs_is_uranium || chasfs_is_thorium || chasfs_is_promethium || chasfs_is_sumatra; then
        # Restart SPI driver
        modprobe -r spi-intel-pci
        modprobe -r spi-intel
        modprobe -r spi-nor

        modprobe tiny-intel-spi-pci
        modprobe -r tiny-intel-spi-pci

        if chasfs_is_sumatra || chasfs_is_family_curie; then
            sleep 1
        fi
        modprobe spi-nor
        modprobe spi-intel writeable=1
        modprobe spi-intel-pci
    fi

    # Update the $SELECTED_ROM status
    fetch_selected_rom_status
}

# Restore the SPI banks
restore_spi_bank () {
    # remove the cs override 
    #
    # Bit 31 is the chip select override
    # Bit 30 is the SPI chip select
    # notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "BOOTED_ROM is $BOOTED_ROM"
    if [ "$BOOTED_ROM" = "0" ]; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Switching back to ROM 0"
        echo "00000000" > $REG_RP_CTRL_0
    else
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Switching back to ROM 1"
        echo "00000000" > $REG_RP_CTRL_0
    fi
    # Give the hardware a little time before we access the flash
    sleep 3

    # Update the $SELECTED_ROM status
    fetch_selected_rom_status
}

do_upgrade_notify () {
    # We are about to do final step of Upgrade.

    # Calliope uses the UEFI capsule mechanism and does not have the
    # ESG ping-pong CPLD register. Skip the REG_CNF write and just notify
    # the user; the capsule is applied by firmware on the next reload.
    if chasfs_is_calliope; then
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "ROMMON upgrade complete."
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "To make the new ROMMON permanent, you must restart the RP."
        return 0
    fi

    # Refer : EDCS # 999274, Section 3.3
    # bits 15:31 <Key Value>: 
    # and set CPLD_OVLD_NEXT_UPG_AVAILABLE bit in reg_dash_conf_hdr_ctrl
    # If BIOS is using a Golden-Upgrade scheme, instead of a 
    # Ping-Pong mechanism, set the correspnding 'Upgrade Pending'
    # bit to 1
    if [[ "$GOLDEN_AND_UPGRADE_BIOS_SCHEME" = 1 ]]; then
        echo "$SET_UPGRADE_PENDING" > "$REG_CNF"
    else
        if [ "$BOOTED_ROM" = "0" ]; then
           echo "6A2F0040" > $REG_CNF
        else
           echo "6A2F00C0" > $REG_CNF
        fi
    fi

    # Testing: Now issue a Cookie reset, which is same as "reload".
    # This would take care of syncing the disks etc., and perform a
    # staged reload.
    # echo "94cb2f01" > $REG_CKE
    # In real script, we ask user to type "reload"
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "ROMMON upgrade complete."
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "To make the new ROMMON permanent, you must restart the RP."
}

check_upgrade_pending () {
    local CHECKPENDINGSTRING="NA"

    if [ "$RESET_REASON" = "0" ]; then
        CHECKPENDINGSTRING="FAILURE: RESET_REASON $RESET_REASON"
        print_results "$CHECKPENDINGSTRING" "NA" "NA" "NA" "NA"
        return 1
    fi
    CHECKPENDINGSTRING="ROMMON upgrade detected, accepting new image"
    print_results "$CHECKPENDINGSTRING" "NA" "NA" "NA" "NA"
    return 0
}

check_upgrade_complete () {
    local CHECKCOMPLETESTRING="NA"

    if [ $SELECTED_ROM  -eq 0 ]; then
        if [ $BOOTED_ROM -eq 0 ]; then
           CHECKCOMPLETESTRING="FATAL: With Selected and Booted ROM 0, check_upgrade called"
           print_results "$CHECKCOMPLETESTRING" "NA" "NA" "NA" "NA"
        else
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Will make ROM1 permanent"
           echo "6A2F0080" > $REG_CNF
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Upgrade complete"
        fi
    else
        if [ $BOOTED_ROM -eq 0 ]; then
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Will make ROM0 permanent"
           echo "6A2F0000" > $REG_CNF
           notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Upgrade complete"
        else
           CHECKCOMPLETESTRING="FATAL: With Selected and Booted ROM 1, check_upgrade called"
           print_results "$CHECKCOMPLETESTRING" "NA" "NA" "NA" "NA"
        fi
    fi

  return 0
}

#
# Start the upgrade process
#
RESULTSSTRING="NA"

fetch_rom_status
print_rom_status
mkdir -p /tmp/trace

# RESULTSSTRING="Upgrade Starting $0 $1 $2"
# print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
if [ -z "${1:-}" ]; then
    # Remove previous update files and directories
    cleanup_capsule

    # If device uses Golden-Upgrade scheme, instead of ping-pong
    # mechanism, the Upgrade partition has already been updated and
    # booted from. Also, in a Golden-Upgrade scheme, the Upgrade 
    # partition is always upgraded, and doesn't have provision to 
    # upgrade Golden partition. Thereby, skip checks during 
    # bootup post upgrade, to determine upgrade status
    if [[ "$GOLDEN_AND_UPGRADE_BIOS_SCHEME" = 1 ]]; then
        exit 0
    fi

    # After all Upgrade is done and when we booted the IOS image...
    if ! check_upgrade_pending; then
	exit 0
    fi
    if ! check_upgrade_complete; then
	exit 1
    fi

    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success ""
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "Success! Upgrade is complete."

    if chasfs_is_charon_family; then
       notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-success "Reload system to save boot preference configuration"
       source /usr/binos/conf/errmsg.sh
       errmsg notice $LOG_NOTICE $(msgsym ROMMON_UPGRADE_NEED_RELOAD SYS $LOG_NOTICE "Notice: Reload system after Rommon Upgrade complete")
       # clear last time reload info first
       rm -f /bootflash/.prst_sync/reload_info
       echo "ReloadReason=Rommon Upgrade" >> /bootflash/.prst_sync/reload_info
       sleep 1
       /usr/lib/systemd/system-shutdown/reset_local_rp.sh
    fi
    exit 0
fi

#
# Use to decode the ROMMON capability bits for BIOS Protection support
#
readonly CAPSULE_SUPPORT_BIT=0x4
declare -i rommon_capbits=0

#
# Perform the Backup SPI FLASH Upgrade
#
#
# Step 1. Get the ROMMON capability_bits on the Active SPI FLASH.
#
if ! get_capability_bits rommon_capbits; then
    RESULTSSTRING="FAILURE: Could not get capabilities."
    print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
    cleanup_tmp_files
    exit 1
fi

#
# Step 2. Verify the capsule file is accessible.
#         BIOS will verify the capsule file and its contents (i.e. BIOS image).
#
    CAPSULE_FILE=$(convert_ios_to_path $2)
    capsule_file_status=1
    if [ ! -e "$CAPSULE_FILE" ]; then
        capsule_file_status=0
        CAPSULE_FILE_ERROR="does not exist!"
    elif [ ! -s "$CAPSULE_FILE" ]; then
        capsule_file_status=0
        CAPSULE_FILE_ERROR="has an invalid length!"
    elif [ ! -r "$CAPSULE_FILE" ]; then
        capsule_file_status=0
        CAPSULE_FILE_ERROR="is not readable!"
    fi

#
# Step 3. Use both sets of capability_bits to decide which upgrade method to use
#
capsule_support=$(($rommon_capbits & $CAPSULE_SUPPORT_BIT))
update_capsule_support=$(($capsule_support && $capsule_file_status))
#notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status ""
#notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "rommon_capbits  is $rommon_capbits."
#notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "capsule_support is $capsule_support."
#notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "update_capsule_support is $update_capsule_support."
#notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status ""

#
# Step 4. Update Capsule Method supported:
#
if [[ $capsule_support -ne 0 ]]; then
    # a. Verify the capsule file (.capsule.bin) exist.
    if [ $capsule_file_status -eq 0 ]; then
        RESULTSSTRING="ERROR: File $CAPSULE_FILE $CAPSULE_FILE_ERROR Upgrade aborted"
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        cleanup_tmp_files
        exit 1
    fi

    # b. Remove previous update files and directories
    cleanup_capsule

    # c. Make update capsule directory
    mkdir -p $EFI_CAPSULE_DIR
    if [[ $? -ne 0 ]]; then
        RESULTSSTRING="FAILURE: Making $EFI_CAPSULE_DIR ($?)"
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        cleanup_tmp_files
        exit 1
    fi
    mkdir -p $UPDATE_CAPSULE_DIR
    if [[ $? -ne 0 ]]; then
        RESULTSSTRING="FAILURE: Making $UPDATE_CAPSULE_DIR ($?)"
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        cleanup_tmp_files
        exit 1
    fi

    CAPSULE_FILESIZE=`stat -c%s "$CAPSULE_FILE"`
    FREESPACE=`df --block-size=1 /bootflash/ | sed -n 2p | awk '{print $4}'`
    if [ $CAPSULE_FILESIZE -gt $FREESPACE ]; then
        RESULTSSTRING="FAILURE: Not enough memory ( $FREESPACE ) in bootflash: to perform upgrade."
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        cleanup_tmp_files
        exit 1
    fi

    # d. Copy capsule file (.capsule.bin) to /bootflash/EFI/UpdateCapsule/.
    cp -p $CAPSULE_FILE $UPDATE_CAPSULE_FILE
    sync
    if [[ $? -ne 0 ]]; then
        RESULTSSTRING="FAILURE: Copying capsule ($?)"
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        cleanup_tmp_files
        exit 1
    fi

    # e. Verify the capsule file copy via md5sum.
    MD5SUMA=`md5sum $CAPSULE_FILE | awk '{print $1}'`
    MD5SUMB=`md5sum $UPDATE_CAPSULE_FILE | awk '{print $1}'`
    if [ "foo_$MD5SUMA" != "foo_$MD5SUMB" ]; then
        RESULTSSTRING="FAILURE: Unable to copy signed update file."
        print_results "$RESULTSSTRING" "NA" "NA" "NA" "NA"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "The ROMMON update file MD5 signature is $MD5SUMA"
        notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "The copied ROMMON update file MD5 signature is $MD5SUMB"
        cleanup_tmp_files
        exit 1
    fi

    # f. A secure upgrade will occur during BIOS start.
    notify_update $notification rommon-upgrade-status "$uuid" upgrade-rommon-status "Secure upgrade of the ROMMON image will occur after a reload."

    # g. The secure upgrade part of BIOS Protection will update the Public
    #    Keys, so the Public Key copy and update can be skipped.
    PSKEY_SIZE=0

#
# Step 5. Direct SPI FLASH writes:
#
else
    # a. Verify that the upgrade ROMMON image is the correct size.
    ROMMON_FILE=$(convert_ios_to_path $1)
    if ! check_binary_file $ROMMON_FILE; then
        RESULTSSTRING="FAILURE: Checking the upgrade ROMMON."
        print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE 
        cleanup_tmp_files
        exit 1
    fi

    # b. Verify the upgrade ROMMON image codesign verification.
    if ! perform_fips_test $ROMMON_FILE; then
        RESULTSSTRING="FAILURE: Verifying the upgrade ROMMON."
        print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE 
        cleanup_tmp_files
        exit 1
    fi

    # c. Copy over the upgrade ROMMON image to the backup SPI FLASH.
    if ! upgrade_spi_flash $ROMMON_FILE $ROMMON_DEVICE; then
        RESULTSSTRING="FAILURE: Copying the upgrade ROMMON."
        print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE 
        cleanup_tmp_files
        exit 1
    fi
fi

#
# Step 6. Copy the ROMMON NVRAM, OS Keys and tamper data on the Active SPI FLASH.
#
if ! copy_romenv $ROMVAR_FILE $PUBKEY_FILE $ROMMON_DEVICE; then
    RESULTSSTRING="FAILURE: Copying the ROMMON NVRAM."
    print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE 
    cleanup_tmp_files
    exit 1
fi

#
# Step 7. Update the ROMMON NVRAM, OS Keys and tamper data on the Backup SPI FLASH.
#
if ! update_romenv $ROMVAR_FILE $PUBKEY_FILE $ROMMON_DEVICE; then
    RESULTSSTRING="FAILURE: Updating the ROMMON NVRAM."
    print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE 
    cleanup_tmp_files
    exit 1
fi

#
# Step 8. Clean up temporary files.
#
cleanup_tmp_files

#
# Step 9. If update capsule method, set update request either ROMMON
#         (or BIOS) variable.

if [ $update_capsule_support -eq 1 ]; then
    if chasfs_is_calliope; then
        # Calliope rommon consumes FIRMWARE_UPGRADE / FIRMWARE_UPGRADE_COUNTER
        # to apply the staged capsule on next boot, and clears them itself
        # after a successful apply.
        if ! set_rommon_var FIRMWARE_UPGRADE "1"; then
            RESULTSSTRING="FAILURE: Setting FIRMWARE_UPGRADE."
            print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE
            exit 1
        fi
        if ! set_rommon_var FIRMWARE_UPGRADE_COUNTER "3"; then
            RESULTSSTRING="FAILURE: Setting FIRMWARE_UPGRADE_COUNTER."
            print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE
            exit 1
        fi
    else
        if ! set_rommon_var UPDATE_CAPSULE "1"; then
            RESULTSSTRING="FAILURE: Setting upgrade status."
            print_results "$RESULTSSTRING" "NA" "NA" "NA" $ROMMON_FILE
            exit 1
        fi
    fi
fi

sync

#
# Step 10. Notify the customer to reload the platform to complete the upgrade.
#
do_upgrade_notify

exit 0

