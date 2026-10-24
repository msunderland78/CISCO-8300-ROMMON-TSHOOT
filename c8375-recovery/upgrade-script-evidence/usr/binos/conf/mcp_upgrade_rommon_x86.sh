#!/bin/bash
#------------------------------------------------------------------
# mcp_upgrade_rommon_x86.sh - MCP upgrade functions for x86
#
# May 2013, Lin Luo
#
# Copyright (c) 2013-2014, 2016-2024 by Cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

if [[ $BOARD_SUBTYPE == "RP2" || $BOARD_SUBTYPE == "RP3" ]] ; then
    PCA8550_DIR="/sys/bus/i2c/devices/4-004e"
elif [[ $BOARD_SUBTYPE == "1GL" || $BOARD_SUBTYPE == "2DA" ]] ; then
    PCA8550_DIR="/sys/bus/i2c/devices/16-004e"
elif [[ $BOARD_SUBTYPE == "KATAR" ]] ; then 
    PCA8550_DIR=""
elif [[ $BOARD_SUBTYPE == "160G" || 
        $BOARD_SUBTYPE == "1GD" || 
        $BOARD_SUBTYPE == "1EN" ||
        $BOARD_SUBTYPE == "1AC" ||
        $BOARD_SUBTYPE == "ACE" || 
        $BOARD_SUBTYPE == "ACE_G2" ||
        $BOARD_SUBTYPE == "1RM" ||
        $BOARD_SUBTYPE == "1WSP" || 
        $BOARD_SUBTYPE == "1WKPH" ||
        $BOARD_SUBTYPE == "KAKUTE" ]] ; then
    PCA8550_DIR="/sys/bus/i2c/devices/10-004e"
else
    PCA8550_DIR="/sys/bus/i2c/devices/1-004e"
fi

if [[ "$BOARD_TYPE" == "RP" ]]; then 
    if [[ $BOARD_SUBTYPE == "KATAR" ]] ; then 
        ROMMON_DEVICE="/dev/mtdblock2"
    else
        ROMMON_DEVICE="/dev/mtdblock0"
    fi
else
    ROMMON_DEVICE="/dev/mtdblock0"
fi

DESC_ME_SIZE=2097152
DESC_ME_UPDATE="TRUE"
ROMVAR_PRIM_OFFSET=2097152
ROMVAR_BKUP_OFFSET=2228224
ROMVAR_PRIM_SIZE=65536
ROMVAR_BKUP_SIZE=65536
PUBKEY_SIZE=0

ROMMON_IMAGE_END_ADDR=4194304

if [ -d /tmp/chassis/cpld/chasfs ]; then
    CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
else
    CPLD_DIR="/sys/bus/platform/devices/cpld/"
fi

if chasfs_is_fru_jf_based $BINOS_FRU $BOARD_SUBTYPE; then
    ROMMON_IMAGE_SIZE=2097152
    # 2KP can support Code signing
    if rp_support_code_signing $BINOS_FRU $BOARD_SUBTYPE; then
        ROMMON_FIPS_IMAGE_SIZE=2097152
    fi

elif [[ $BINOS_FRU == "rp" && \
       ($BOARD_SUBTYPE == "1NG" || $BOARD_SUBTYPE == "2KH" ||
        $BOARD_SUBTYPE == "1SR") ]] ; then
    DESC_ME_SIZE=4259840
    DESC_ME_UPDATE="TRUE"
    ROMVAR_PRIM_OFFSET=4259840
    ROMVAR_BKUP_OFFSET=4390912
    ROMVAR_PRIM_SIZE=131072
    ROMVAR_BKUP_SIZE=131072
    PUBKEY_OFFSET=4521984
    PUBKEY_SIZE=655360
    ROMMON_IMAGE_END_ADDR=8388608
    ROMMON_IMAGE_SIZE=3211264
    ROMMON_FIPS_IMAGE_SIZE=3211264

elif [[ $BINOS_FRU == "rp" && \
        ($BOARD_SUBTYPE == "RP3" || $BOARD_SUBTYPE == "MACH5" ||
         $BOARD_SUBTYPE == "1GL" || $BOARD_SUBTYPE == "KATAR" ||
         $BOARD_SUBTYPE == "1GD" || $BOARD_SUBTYPE == "1RM" ||
         $BOARD_SUBTYPE == "ACE_G2" ||
         $BOARD_SUBTYPE == "ACE") ]] ; then
    DESC_ME_SIZE=8388608
    DESC_ME_UPDATE="FALSE"
    ROMVAR_PRIM_OFFSET=8388608         # 0x80_0000
    ROMVAR_BKUP_OFFSET=8519680         # 0x82_0000
    ROMVAR_PRIM_SIZE=131072            # 0x02_0000
    ROMVAR_BKUP_SIZE=131072            # 0x02_0000
    PUBKEY_OFFSET=8650752              # 0x84_0000
    PUBKEY_SIZE=131072                 # 0x01_0000primary+0x01_0000backup
    ROMMON_IMAGE_END_ADDR=16777216     # 0x100_0000
    ROMMON_IMAGE_SIZE=7995392          # 0x7A_0000
    ROMMON_FIPS_IMAGE_SIZE=7995392     # 0x7A_0000

elif [[ $BINOS_FRU == "fp" && \
        ($BOARD_SUBTYPE == "100X" || $BOARD_SUBTYPE == "200X") ]] ; then
    DESC_ME_SIZE=8388608
    DESC_ME_UPDATE="FALSE"
    ROMVAR_PRIM_OFFSET=8388608         # 0x80_0000
    ROMVAR_BKUP_OFFSET=8519680         # 0x82_0000
    ROMVAR_PRIM_SIZE=131072            # 0x02_0000
    ROMVAR_BKUP_SIZE=131072            # 0x02_0000
    PUBKEY_OFFSET=8650752              # 0x84_0000
    PUBKEY_SIZE=131072                 # 0x01_0000primary+0x01_0000backup
    ROMMON_IMAGE_END_ADDR=16777216     # 0x100_0000
    ROMMON_IMAGE_SIZE=7995392          # 0x7A_0000
    ROMMON_FIPS_IMAGE_SIZE=7995392     # 0x7A_0000
   
elif [[ $BINOS_FRU == "rp" && ($BOARD_SUBTYPE == "1EN" || \
    $BOARD_SUBTYPE == "1AC")  ||
    ($BOARD_SUBTYPE == "1WSP" ||
     $BOARD_SUBTYPE == "1WKPH" ||
     $BOARD_SUBTYPE == "KAKUTE")]] ; then

    DESC_ME_SIZE=50397184              # 48Mb + 64Kb
    DESC_ME_UPDATE="FALSE"
    ROMVAR_PRIM_OFFSET=50397184        # 0x301_0000
    ROMVAR_BKUP_OFFSET=50528256        # 0x303_0000
    ROMVAR_PRIM_SIZE=131072            # 0x02_0000
    ROMVAR_BKUP_SIZE=131072            # 0x02_0000
    PUBKEY_OFFSET=50659328             # 0x305_0000
    PUBKEY_SIZE=131072                 # 0x01_0000primary+0x01_0000backup
    ROMMON_IMAGE_END_ADDR=67108864     # 0x400_0000
    ROMMON_IMAGE_SIZE=16318464         # 0xF9_0000
    ROMMON_FIPS_IMAGE_SIZE=16318464    # 0xF9_0000

elif [[ $BINOS_FRU == "rp" && ($BOARD_SUBTYPE == "2DA") ]] ; then
    DESC_ME_SIZE=16842752
    DESC_ME_UPDATE="FALSE"
    ROMVAR_PRIM_OFFSET=16842752     # 0x101_0000
    ROMVAR_BKUP_OFFSET=16973824     # 0x103_0000
    ROMVAR_PRIM_SIZE=131072         # 0x02_0000
    ROMVAR_BKUP_SIZE=131072         # 0x02_0000
    PUBKEY_OFFSET=17104896          # 0x105_0000
    PUBKEY_SIZE=131072              # 0x01_0000primary+0x01_0000backup
    ROMMON_IMAGE_END_ADDR=33554432  # 0x200_0000
    ROMMON_IMAGE_SIZE=16318464      # 0xF9_0000
    ROMMON_FIPS_IMAGE_SIZE=16318464 # 0xF9_0000 

else
    ROMMON_IMAGE_SIZE=1048576
    ROMMON_FIPS_IMAGE_SIZE=1114112
fi

X86_SPI_FILE="/tmp/.spidescriptors"
X86_ROMVAR_FILE="/tmp/.romvars"
X86_PUBKEY_FILE="/tmp/.pubkeys"
UPDATE_CAPSULE_DIR=/bootflash/EFI/UpdateCapsule
UPDATE_CAPSULE_FILE=UpdateCapsuleFile.bin

function mcp_upgd_rom_downconvert ()  {
    return 0
}
readonly -f mcp_upgd_rom_downconvert

#
# copy_rommon_data
#
# Extract descriptor, ME, and ROMMON Var from flash in use
#
function copy_rommon_data () {
    # Save off the SPI descriptors and ROMVAR data on X86
    if [[ $DESC_ME_SIZE -gt 0 && $DESC_ME_UPDATE == "TRUE" ]]; then
        dd of="$X86_SPI_FILE" if="$ROMMON_DEVICE" bs=1 count="$DESC_ME_SIZE"
    fi
    dd of="$X86_ROMVAR_FILE" if="$ROMMON_DEVICE" bs=1 count="$ROMVAR_PRIM_SIZE" skip="$ROMVAR_PRIM_OFFSET"
    if [[ $PUBKEY_SIZE > 0 ]]; then
        dd of="$X86_PUBKEY_FILE" if="$ROMMON_DEVICE" bs=1 count="$PUBKEY_SIZE" skip="$PUBKEY_OFFSET"
    fi

    return 0
}
readonly -f copy_rommon_data

function fips_rom_file_sz_check() {
    if [ "$ROMMON_FILE_SIZE" -eq "$ROMMON_FIPS_IMAGE_SIZE" ]; then
        echo "File $1 is a FIPS ROMMON image"
        return 0
   fi
   return 1
}
readonly -f fips_rom_file_sz_check

function enable_flash_write () {
    local dummy=$1
}

function disable_flash_write () {
    local dummy=$1
}

function echo_image_type () {
    echo "ROMMON Image Type : X86"
}

function check_header_magic () {
    return 0
}

function compute_rom_img_offset () {
    ROMMON_IMAGE_OFFSET=`expr "$ROMMON_IMAGE_END_ADDR" - "$ROMMON_FILE_SIZE"`
}

function copy_rom_env () {
    echo "Copying ROMMON environment"
    switch_spi_bank
    enable_flash_write $BOARD_SUBTYPE
    if [[ $DESC_ME_SIZE -gt 0 && $DESC_ME_UPDATE == "TRUE" ]]; then
        dd if="$X86_SPI_FILE" of="$1" bs=1 count="$DESC_ME_SIZE"
    fi
    dd if="$X86_ROMVAR_FILE" of="$1" bs=1 count="$ROMVAR_PRIM_SIZE" seek="$ROMVAR_PRIM_OFFSET"
    dd if="$X86_ROMVAR_FILE" of="$1" bs=1 count="$ROMVAR_BKUP_SIZE" seek="$ROMVAR_BKUP_OFFSET"
   if [[ $PUBKEY_SIZE > 0 ]]; then
        dd if="$X86_PUBKEY_FILE" of="$1" bs=1 count="$PUBKEY_SIZE" seek="$PUBKEY_OFFSET"
    fi

    # Force a write-back of the SPI FLASH
    sync
    sync
    sync

    disable_flash_write $BOARD_SUBTYPE
    clear_spi_sel_override
}
readonly -f copy_rom_env

#
# clear_spi_sel_override
#
# If SPI_OVERRIDE bit 30 of rp_control_0 is cleared,
# the SPI chip is selected by bit 4 of PCA8550 and
# cooke controler. If the bit 30 is set,
# the bit 31 SPI_SEL selects one of flash chips. 
#
function clear_spi_sel_override () {
    echo "00000000" > $CPLD_DIR/reg_rp_control_0
    sleep 1
}

readonly -f clear_spi_sel_override

# Toggle the SPI banks
switch_spi_bank () {
    # switch SPI flash chips to access the upgrade partition
    # 
    # Bit 31 is the chip select override 
    # Bit 30 is the SPI chip select

    if [ "$BOOTED_ROM" = "0" ]; then
        echo "C0000000" > $CPLD_DIR/reg_rp_control_0
    else
        echo "80000000" > $CPLD_DIR/reg_rp_control_0
    fi
}
readonly -f switch_spi_bank

function rom_nvram_expansion () {
    return 0
}
readonly -f rom_nvram_expansion

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

