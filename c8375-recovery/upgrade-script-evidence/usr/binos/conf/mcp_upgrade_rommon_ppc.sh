#!/bin/bash
#------------------------------------------------------------------
# mcp_upgrade_rommon_ppc.sh - MCP upgrade functions for PPC 
#
# May 2013, Lin Luo
#
# Copyright (c) 2013, 2018 by Cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

#Store ELC Data in the table: ROMMON size, FIPS image siz
# put_fru_data <fru_subtype> <rommon_image_size> <fips_image_size>
#                   <image_offset> <rommon_device> <code_sign_support>
put_fru_data ELC_40G 1966080 1966080 131072 "/dev/mtdblock2" 1
put_fru_data ELC_100G 1966080 1966080 131072 "/dev/mtdblock2" 1

PCA8550_DIR="/sys/bus/i2c/devices/0-004e"

if [[ $BOARD_SUBTYPE == "ELC_40G" ||
      $BOARD_SUBTYPE == "ELC_100G" ]] ; then
    get_fru_data $BOARD_SUBTYPE
else
    ROMMON_DEVICE="/dev/mtdblock3"
    ROMMON_IMAGE_OFFSET=0
    ROMMON_IMAGE_SIZE=1966080
fi

ROMMON_XN1_SUM="253f15daf89eea22b1db92d440d03608"
ROMMON_XN2_SUM="3c93c2dae50b93a30644b7df51065f9b"
ROMMON_XNB_SUM="3d682df0bb0db74d0ed6ba567d4fc824"
ROMMON_XNC_SUM="3d237999248811ea9a08705e29d2a6bf"
ROMMON_XN1_VER="12.2(33r)XN1,"
ROMMON_XN2_VER="12.2(33r)XN2,"
ROMMON_XNB_VER="12.2(33r)XNB,"
ROMMON_XNC_VER="12.2(33r)XNC,"
ROMMON_V0_EVARSIZ=768
ROMMON_V1_EVARSIZ=4096

#
# mcp_upgd_rom_downconvert
#
# Check to see if we are downgrading to a prior version ROMMON
# that would require a downconvert of the ROMMON env var table
#
function mcp_upgd_rom_downconvert()  {
   NVRAM_VERSION=`$FLASHUTIL_EXEC_PATH -c getversion`
   if [[ $NVRAM_VERSION == "0" ]] ; then
       # no downconversion needed
        return 0
    fi

    if ! check_downrev_rommon ; then
        return 0
    fi

    # The ROMMON being installed is downrev, and the env var table
    # is uprev.  Need to check to make sure that the env vars will
    # fit in the downrev structure.  Fail the upgrade if they won't fit.
    EVARTBL_FREE=`$FLASHUTIL_EXEC_PATH -c getevarsiz | awk '{print $1}'`
        EVARTBL_USED=`expr "$ROMMON_V1_EVARSIZ" - "$EVARTBL_FREE"`
        if [[ "$EVARTBL_USED" -gt "$ROMMON_V0_EVARSIZ" ]] ; then
	    echo
	    echo "FAILURE: ROMMON variables too large for new ROMMON version"
	    echo "       : Please return to the ROMMON prompt and delete any"
        echo "       : unused ROMMON variables to reclaim some space"
        return 1
    fi

    # Finally, we can downconvert the NVRAM.
    if ! `$FLASHUTIL_EXEC_PATH -c downconvert` ; then
        echo "FAILURE: ROMMON NVRAM could not be converted to new version "
        return 1
    fi
    return 0
}
readonly -f mcp_upgd_rom_downconvert

function copy_rommon_data () {
    return 0
}
readonly -f copy_rommon_data

function fips_rom_file_sz_check() {
    return 1
}
readonly -f fips_rom_file_sz_check

#
# enable_flash_write
#
# Remove enable flash write
#
function enable_flash_write() {
    local card_subtype=$1
    # Specific to ELC40 and ELC100 - enable flash write
    if [[ $card_subtype == "ELC_40G" ||
          $card_subtype == "ELC_100G" ]] ; then
        # Save the contents of register CP_RESET_CONTROL
        CP_RES_SAVE_ELC=`cat "$CPLD_DIR/reg_cp_reset_control" | sed 's/cp_reset_control: //'`
        # Clear bit-1 to enable flash writes
        echo "0x$CP_RES_SAVE_ELC" | awk --non-decimal-data '{ printf "%08x\n", and($1,0xFFFFFFFD) }' > "$CPLD_DIR/reg_cp_reset_control"
    fi
}

#
# disable_flash_write
#
# disable flash write
#
function disable_flash_write() {
    local card_subtype=$1
    # Specific to ELC40 and ELC100 - disable flash write
    if [[ $card_subtype == "ELC_40G" ||
          $card_subtype == "ELC_100G" ]] ; then
        if [ -z "$CP_RES_SAVE_ELC" ];
        then
            CP_RES_SAVE_ELC=`cat "$CPLD_DIR/reg_cp_reset_control" | sed 's/cp_reset_control: //'`
            # Set bit-1 to disable flash writes
            echo "0x$CP_RES_SAVE_ELC" | awk --non-decimal-data '{ printf "%08x\n", or($1,0x2) }' > "$CPLD_DIR/reg_cp_reset_control"
        else
            echo $CP_RES_SAVE_ELC > "$CPLD_DIR/reg_cp_reset_control"
        fi;
    fi
    CP_RES_SAVE_ELC=
}

function echo_image_type () {
    echo "ROMMON Image Type : PPC"
}

function check_header_magic () {
    MAGIC=`od -j 1966076 -N 4 -A n -t "x4" "$ROMMON_FILE"`
    if [ "foo_$MAGIC" != "foo_ 4bfff004" ]; then
        echo
        echo "File $1 does not have the right magic header!"
        return 1
    fi
    return 0
}

#
# compute_rom_img_offset
#
function compute_rom_img_offset () {
    # Has already set image offset for ELC in get_fru_data  
    if [[ $BOARD_SUBTYPE != "ELC_40G" &&
          $BOARD_SUBTYPE != "ELC_100G" ]] ; then
        ROMMON_IMAGE_OFFSET=0
    fi
}

function copy_rom_env () {
    local dummy=$1
}
readonly -f copy_rom_env

function clear_spi_sel_override () {
    local dummy=0
}

switch_spi_bank () {
    local dummy=0
}
readonly -f switch_spi_bank

#
# rom_nvram_expansion
#
function rom_nvram_expansion () {
    NVRAM_VERSION=`$FLASHUTIL_EXEC_PATH -c getversion`
    if [[ $NVRAM_VERSION != "0" ]] ; then
        # no expansion needed
        echo "ROMMON nvram expansion not needed"
        return 0
    fi

    # If we are loading an older downrev ROMMON, it's OK to have
    # the smaller ROMVAR table
    if  check_uprev_rommon ; then
        echo "downrev ROMMON installed, no expansion needed"
        return 0
    fi

    # The ROMMON being installed is not downrev, and the env var table
    # is downrev, so expand the NVRAM structure in flash
    if ! `$FLASHUTIL_EXEC_PATH -c upconvert` ; then
        echo "FAILURE: ROMMON NVRAM could not be converted to new version "
        return 1
    fi
    return 0
}
readonly -f rom_nvram_expansion

function get_capability_bits () {
    local rc=0
    local __resultvar=$1

    __resultvar=0
    return $rc
}
readonly -f get_capability_bits

