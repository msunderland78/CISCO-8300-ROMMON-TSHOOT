#!/bin/bash
#------------------------------------------------------------------
# mcp_upgrade_rommon.sh - MTD based rommon upgrader for MSTP/RP/FP/CC
#
# April 2006, Derek Taubert
#
# Copyright (c) 2006-2015, 2018-2021 by Cisco Systems, Inc.
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
source $SCRIPTS_DIR/pglobals.sh
source $SCRIPTS_DIR/psimple.sh
source $SCRIPTS_DIR/iosxe_upgrade_rommon_em.sh
source $SCRIPTS_DIR/hwutil.sh
source $SCRIPTS_DIR/mcp_script_defs.sh
source $SCRIPTS_DIR/chasutils.sh
# use cyan funtions
source /usr/binos/conf/cyan_api.sh

hwutil_set_plat_board_fru_slot_bay
if [ -d /tmp/chassis/cpld/chasfs ]; then
    CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
else
    CPLD_DIR="/sys/bus/platform/devices/cpld/"
fi

UPGRADE_STATUS="0"
if [ ! -d "$CPLD_DIR" ]; then
    echo
    echo "FATAL: cannot find cpld /sys directory"
    exit -1
fi

if [[ "$BINOS_FRU" == "rp" ]]; then
    ROMMON_UPGRADE_DIP_PRESENT=$(cyan_get_value $CHASSIS_ATTRS_ROMMON_UPGRADE_DIP)
    capsule_guid=$(echo -n -e $(cyan_get_value $CHASSIS_ATTRS_CAPSULE_GUID))
else
    ROMMON_UPGRADE_DIP_PRESENT="true"
    capsule_guid=$(echo -n -e "\xee\x50\xb9\x57\xb9\x50\xdf\x41\xbb\x1c\xd0\xf7\x75\xb3\x3b\xcf")
fi
guid_size=${#capsule_guid}

fetch_cpld_status () {
    CP_VER=`cat "$CPLD_DIR/reg_cp_version" | sed 's/cp_version: ......\(..\)/0x\1/' | awk --non-decimal-data '{ printf "%d\n",$1 }'`

    CP_STAT=`cat "$CPLD_DIR/reg_cp_status" | sed 's/cp_status: 000000\(.\)\(.\)/0x\1 0x\2/'`
    CP_RESET=`cat "$CPLD_DIR/reg_cp_reset_reason" | sed 's/cp_reset_reason: 000000\(.\)\(.\)/0x\1 0x\2/'`
    if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "false" ]]; then
      DIP_SWITCH_STAT=`cat "$CPLD_DIR/reg_lpc_cfg_stat_cntrl" | sed 's/lpc_cfg_stat_cntrl: 000000\(.\)\(.\)/0x\1 0x\2/'`
    fi
}

# Read CPLD registers before loading pca8550 driver.
# The CPLD cp status register indicating currently booted rommon will
# need some time to settle down after pca8550 driver is loaded and 
# initialized.

fetch_cpld_status

if chasfs_is_fru_x86_based $BINOS_FRU $BOARD_SUBTYPE; then
    source $SCRIPTS_DIR/mcp_upgrade_rommon_x86.sh
else
    source $SCRIPTS_DIR/mcp_upgrade_rommon_ppc.sh
fi

if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "true" ]]; then
   # Find i2c bus based on $PCA8550_DIR
   i2cbus=`echo $PCA8550_DIR | sed 's/\(\/sys\/bus\/i2c\/devices\/\)//' | cut -d "-" -f 1`

   #
   #From Documentation/i2c/instantiating-devices:
   #"You can also instantiate the device before the driver is loaded or even
   #available, and you don't need to know what driver the device needs."
   #
   #Instantiating the device at i2c bus first before installing pca8550 module
   #inform kernel of the correct i2c bus for pca8550 device.
   #

   if [ ! -e "/sys/bus/i2c/devices/i2c-$i2cbus/$i2cbus-004e" ]; then
      echo pca8550 0x4e > /sys/bus/i2c/devices/i2c-$i2cbus/new_device
      /sbin/modprobe pca8550 no_probe=1
   fi


   if [ ! -d "$PCA8550_DIR" ]; then
      echo
      echo "FATAL: cannot find pca8550 /sys directory"
      exit -1
   fi
fi

fetch_rom_status () {

    export BOOTED_ROM=`echo $CP_STAT | awk --non-decimal-data '{ print rshift(and($1,2), 1) }'`
    export SEL_ROM=`echo $CP_STAT | awk --non-decimal-data '{ print and($1,1) }'`
    export RESET_REASON=`echo $CP_RESET | awk --non-decimal-data '{ print and($1,1) }'`
    if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "true" ]]; then
      export BOOT_IMAGE=`cat "$PCA8550_DIR/reg_non_volatile" |sed 's/\(.\)\(.\)/\1/'` 
      export MUX_OUT=`cat "$PCA8550_DIR/reg_non_volatile" | sed 's/\(.\)\(.\)/\2/'`
    else
      DIP_SWITCH_STAT=`cat "$CPLD_DIR/reg_lpc_cfg_stat_cntrl" | sed 's/lpc_cfg_stat_cntrl: 000000\(.\)\(.\)/0x\1 0x\2/'`
      export BOOT_IMAGE=`echo $DIP_SWITCH_STAT | awk --non-decimal-data '{ print and($1,1) }'`
    fi
}

print_rom_status () {
    if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "true" ]]; then
      echo "PCA8550_DIR is $PCA8550_DIR"
      echo "EEPROM DIP BOOT_IMAGE $BOOT_IMAGE (PCA8550)"
      echo "EEPROM DIP MUX_OUT  $MUX_OUT (PCA8550)"
    else
      echo "CPLD DIP BOOT_IMAGE $BOOT_IMAGE (CPLD)"
    fi
    echo "CP_STAT Reigster $CP_STAT (CPLD)"
    echo "Current ROM booted from partition $BOOTED_ROM (CPLD)"
    echo "Initial ROM selection is partition $SEL_ROM (CPLD)"
}

convert_ios_to_path () {
    fname=$(echo "/"$1 | sed 's/:/\//')
    echo -n "$fname"
}

check_uprev_rommon() {

    ROMMON_VER=`grep XN /proc/rmonbifo/bootver | awk '{print $4}'`

    if [ "foo_$ROMMON_VER" == "foo_$ROMMON_XN1_VER" ]; then
        return 0
    fi
    if [ "foo_$ROMMON_VER" == "foo_$ROMMON_XN2_VER" ]; then
        return 0
    fi
    if [ "foo_$ROMMON_VER" == "foo_$ROMMON_XNB_VER" ]; then
        return 0
    fi
    if [ "foo_$ROMMON_VER" == "foo_$ROMMON_XNC_VER" ]; then
        return 0
    fi
    return 1
    
}

check_downrev_rommon() {

    MD5SUM=`dd if="$ROMMON_DEVICE" bs=1 | md5sum | awk '{print $1}'`

    if [ "foo_$MD5SUM" == "foo_$ROMMON_XN1_SUM" ]; then
        return 0
    fi
    if [ "foo_$MD5SUM" == "foo_$ROMMON_XN2_SUM" ]; then
        return 0
    fi
    if [ "foo_$MD5SUM" == "foo_$ROMMON_XNB_SUM" ]; then
        return 0
    fi
    if [ "foo_$MD5SUM" == "foo_$ROMMON_XNC_SUM" ]; then
        return 0
    fi
    return 1
    
}

check_upgrade_file () {

    export ROMMON_FILE=$(convert_ios_to_path $1)
    if [ ! -r "$ROMMON_FILE" ]; then
	echo
	echo "File $1 can not be read!"
	return 1
    fi

    # Verify that the upgrade file is of the proper size
    export ROMMON_FILE_SIZE=`stat -c "%s" "$ROMMON_FILE"`
    if rp_support_code_signing $BINOS_FRU $BOARD_SUBTYPE; then
        echo "File size : $ROMMON_FILE"
        echo "File size is : $ROMMON_FILE_SIZE"
        echo "FIPS File size is : $ROMMON_FIPS_IMAGE_SIZE"
        echo_image_type
    fi
    # FRUs supporting code signing Would skip this check
    if [ "$ROMMON_FILE_SIZE" -ne "$ROMMON_IMAGE_SIZE" ]; then
        # Check for a FIPS image
        if fips_rom_file_sz_check $1; then
            echo "File $1 is a FIPS ROMMON image"
            return 0
        fi
	echo
	echo "File $1 is not the right size!"
	return 1
    fi

    # Verify that the magic header of the upgrade file is correct
    if ! check_header_magic $1; then
        return 1;
    fi

    # FRUs supporting code signing would pass this test
    if rp_support_code_signing $BINOS_FRU $BOARD_SUBTYPE; then
        if [ "$ROMMON_FILE_SIZE" -eq "$ROMMON_FIPS_IMAGE_SIZE" ]; then
            if [ ! -e /usr/binos/bin/csverify  ] ; then
                echo "/usr/binos/bin/csverify Not found; skipping Load test"
            else
                echo "File $1 is a FIPS ROMMON image"
                # Individual binary signatures are different for asr1k platforms.
                # some of the platforms use capsule image.
                # ignoring csverify for asr1k based platforms.
                if [ ! chasfs_is_mcp_chassis ]; then 
                    # Let us do a load test.
                    /usr/binos/bin/csverify  rom-bundle $1
                    if [ $? == 0 ]; then
                       echo "FIPS-140-3 Load Test on $1 has PASSED."
                       echo "Authenticity of the image has been verified."
                    else
                       :
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
            fi
        else
            echo "File $1 is not the right size!"
            echo "Can't to FIPS test "
            return 1
        fi
    fi

    if mcp_upgd_rom_downconvert ; then
        return 0
    fi

    return 1
}

upgrade_flash () {
    echo "Checking upgrade image..."
    PRE_SUM=`dd if="$1" ibs=1 | md5sum | awk '{print $1}'`
    echo "Upgrade image MD5 signature is $PRE_SUM"
    
    if [ ! -b "$2" ]; then
	echo
	echo "FAILURE: $2 is not a block device"
        echo "Possible downrev ROM"
	return 1
    fi

    if [ ! -w "$2" ]; then
	echo
	echo "FAILURE: Flash device $2 is not writable"
	return 1
    fi
    
    switch_spi_bank

    enable_flash_write $BOARD_SUBTYPE

    compute_rom_img_offset

    echo "Burning upgrade partition..."
    dd if="$1" of="$2" bs=1 seek="$ROMMON_IMAGE_OFFSET" count="$ROMMON_FILE_SIZE"

    echo "Checking upgrade partition..."
    POST_SUM=`dd if="$2" bs=1 skip="$ROMMON_IMAGE_OFFSET"| md5sum | awk '{print $1}'`

    # Force the write-back of the file.
    sync

    disable_flash_write $BOARD_SUBTYPE

    clear_spi_sel_override

    echo "Upgrade flash partition MD5 signature is $POST_SUM"

    if [ "foo_$PRE_SUM" != "foo_$POST_SUM" ]; then
	echo
	echo "FAILURE: MD5 signature does not match!"
	return 1
    fi

    return 0
}

# After copying the new ROMMON in bootflash partition
# IOS-XE needs to set the upgrade pending bit in EEPROM DIP
# to inform ROMMON the upgrade is pending
do_upgrade_notify () {

    if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "false" ]]; then
       # Write a 1 to bit 0 to indicate ROMMON upgrade pending
       # Clear upgrade counter of bits 3 and 2
       upgrade_pending=1
       echo "$[BOOTED_ROM]$[0x$upgrade_pending]" > "$CPLD_DIR/reg_lpc_cfg_stat_cntrl"
    else
       # unprotect PCA8550
       CP_RES_SAVE=`cat "$CPLD_DIR/reg_cp_reset_control" | sed 's/cp_reset_control: //'`

       # explicitly clear bit 2 to unprotect
       echo "0x$CP_RES_SAVE" | awk --non-decimal-data '{ printf "%08x\n", and($1,0xFFFFFFFB) }' > "$CPLD_DIR/reg_cp_reset_control"

       # get FPGA select
       fpga_sel=$[0x$MUX_OUT & 0x2]

       # Write a 1 to PCA8550 bit 0 to indicate ROMMON upgrade pending
       # Keep FPGA select and clear upgrade counter of bits 3 and 2
       echo "$[BOOTED_ROM]$[0x$fpga_sel | 0x1]" > "$PCA8550_DIR/reg_non_volatile"

    fi
    sleep 1

    # protect PCA8550
    echo $CP_RES_SAVE > "$CPLD_DIR/reg_cp_reset_control"

    echo "ROMMON upgrade complete."

    if [[ "$BINOS_FRU" == "rp" ]]; then
       echo "To make the new ROMMON permanent, you must restart the RP."
    else
       echo "To make the new ROMMON permanent, you must restart the linecard."
    fi
}

check_upgrade_pending () {
    if [ "$RESET_REASON" = "0" ]; then
	return 1
    fi
    echo
    echo "ROMMON upgrade detected, accepting new image"
    return 0
}

# IOS-XE checks if the router
# booted using the upgrade ROMMON
# After verified the upgrade ROMMON
# IOS-XE will accept the new ROMMON
# by programming EEPROM DIP to select
# upgrade ROMMON partition and
# clearing ROMMON upgrade pending bit
check_upgrade_complete () {

    print_rom_status

    # SEL_ROM pointed to initial boot ROMMON partition.
    # The ROMMON will load the upgrade ROMMON pointed by 
    # BOOTED_ROM.
    if [ "foo_$BOOTED_ROM" = "foo_$SEL_ROM" ]; then
	echo
	echo "ABORTED: The upgrade partition is not currently running"
	em_iosxe_upgrade_rommon_ROMMON_UPGRADE_FAIL "$BOOTED_ROM"
        #Update upgrade status as fail
        UPGRADE_STATUS="0x2"
	return 1
    fi

    echo "Making the new ROM permanent..."
    if [[ "$ROMMON_UPGRADE_DIP_PRESENT" == "false" ]]; then
      # Write a 0 to bit 0 to indicate ROMMON upgrade done
      # Clear upgrade counter of bits 3 and 2
      upgrade_pending=0
      echo "$[BOOTED_ROM]$[0x$upgrade_pending]" > "$CPLD_DIR/reg_lpc_cfg_stat_cntrl"
    else
      # unprotect PCA8550
      CP_RES_SAVE=`cat "$CPLD_DIR/reg_cp_reset_control" | sed 's/cp_reset_control: //'`
      # explicitly clear bit 2 to unprotect
      echo "0x$CP_RES_SAVE" | awk --non-decimal-data '{ printf "%08x\n", and($1,0xFFFFFFFB) }' > "$CPLD_DIR/reg_cp_reset_control"

      # Clear PCA8550 bit 0 upgrade pending flag
      # Clear PCA8550 bits 2 & 3 rommon upgrade counter
      # Keep bit 1 for FPGA patition
      # Save BOOTED_ROM or Bit 4 pointing to upgraded ROMMON partition 
      echo "$[BOOTED_ROM]$[0x$MUX_OUT & 0x2]" > "$PCA8550_DIR/reg_non_volatile"

      # Allow write to complete
      sleep 1

      # protect PCA8550
      echo $CP_RES_SAVE > "$CPLD_DIR/reg_cp_reset_control"
    fi
    sleep 1

    fetch_rom_status
    print_rom_status

    if [ "foo_$BOOTED_ROM" != "foo_$BOOT_IMAGE" ]; then
	echo
	echo "FAILURE: The non-volatile BOOT_IMAGE bit was not updated"
        #Update upgrade status as fail
        UPGRADE_STATUS="0x2"
	return 1
    fi

    if rom_nvram_expansion ; then
        return 0
    fi
    return 1
}

cleanup_tmp_files () {

    if [ -f "$X86_SPI_FILE" ]; then
        rm "$X86_SPI_FILE"
    fi

    if [ -f "$X86_ROMVAR_FILE" ]; then
        rm "$X86_ROMVAR_FILE"
    fi

    if [ -f "$X86_PUBKEY_FILE" ]; then
        rm "$X86_PUBKEY_FILE"
    fi
}

set_upgrade_status () {

    # Set the Upgrade status for asr1k platform only
    if chasfs_is_mcp_chassis; then

        # If ROMMON upgrade fails, set the reload reason as 'BootRomUpgradeFail'
        if [ "$1" == "0x2"  ]; then
            echo "Update Reload reason as 'BootRomUpgradeFail'"
            rm -rf /bootflash/.prst_sync/reload_info
            echo "ReloadReason=BootRomUpgradeFail">>/bootflash/.prst_sync/reload_info
        # If ROMMON upgrade is successful, set the reload reason as 'BootRomUpgrade'
        elif [ "$1" == "0x1" ]; then
            echo "Update Reload reason as 'BootRomUpgrade'"
            rm -rf /bootflash/.prst_sync/reload_info
            echo "ReloadReason=BootRomUpgrade">>/bootflash/.prst_sync/reload_info
        fi
    fi
}

fetch_rom_status
mkdir -p /tmp/trace

# We don't need the diag bit enabled, so removing it if it's found being set.
if [[ $BINOS_FRU == "cc" || $BINOS_FRU == "fp" ]]; then
        confreg=`/usr/binos/bin/flashutil -c getconfreg`
        if (($confreg & 0x8000)); then
           echo "config register debug bit is enabled, disabling it"
           confreg_without_debug=$(printf '0x%04x' $((confreg & 0x7fff)))
           /usr/binos/bin/flashutil -c setconfreg -V $confreg_without_debug
        fi
fi

if [ -z "$1" ]; then

    UPGRADE_STATUS=`echo $CP_RESET | awk --non-decimal-data '{ print $1 }'`
    echo "UPGRADE STATUS is $UPGRADE_STATUS"

    if !  check_upgrade_pending; then
        set_upgrade_status $UPGRADE_STATUS
	exit 0
    fi
    if !  check_upgrade_complete; then
        set_upgrade_status $UPGRADE_STATUS
	exit 1
    fi

    set_upgrade_status $UPGRADE_STATUS

    echo
    echo "Success!  Upgrade is complete."
    exit 0
fi

# Use to decode the ROMMON capability bits for BIOS Protection support
#
readonly CAPSULE_SUPPORT_BIT=0x4
readonly WRTPROT_SUPPORT_BIT=0x8
declare -i rommon_capbits=0
 
#
# Perform the Backup SPI FLASH Upgrade
#
#
# Step 1 : Get the ROMMON capability_bits on the Active SPI FLASH.
#
if ! get_capability_bits rommon_capbits; then
    cleanup_tmp_files
    exit 1
fi

#
# Step 2. Verify the capsule file is accessable.
#         BIOS will verify the capsule file and its contents (i.e. BIOS image).
#
CAPSULE_FILE=$(convert_ios_to_path $2)
capsule_file_status=1
if [ ! -e "$CAPSULE_FILE" ]; then
    capsule_file_status=0
    CAPSULE_FILE_ERROR='echo "FATAL: File $CAPSULE_FILE does not exist!        \
Upgrade aborted"'
elif [ ! -s "$CAPSULE_FILE" ]; then
    capsule_file_status=0
    CAPSULE_FILE_ERROR='echo "FATAL: File $CAPSULE_FILE has an invalid         \
length! Upgrade aborted"'
elif [ ! -r "$CAPSULE_FILE" ]; then
    capsule_file_status=0
    CAPSULE_FILE_ERROR='echo "FATAL: File $CAPSULE_FILE is not readable!       \
Upgrade aborted"'
fi
if [ ! -z "$2" ]; then
    file_guid=$(head -c $guid_size $CAPSULE_FILE)
    if [ "$file_guid" != "$capsule_guid" ]; then
        capsule_file_status=0
        CAPSULE_FILE_ERROR='echo "FATAL: File $CAPSULE_FILE is not valid capsule!  \
Upgrade aborted"'
    fi
fi

#
# Step 3. Use both sets of capability_bits to decide which upgrade method to use
#
capsule_support=$(($rommon_capbits & $CAPSULE_SUPPORT_BIT))
wrtprot_support=$(($rommon_capbits & $WRTPROT_SUPPORT_BIT))
bios_protection_support=$(($capsule_support && $wrtprot_support))
update_capsule_support=$(($capsule_support && $capsule_file_status))

# Step 4. Update Capsule Method supported:
if [[ $bios_protection_support -eq 1 || $update_capsule_support -eq 1 ]]; then
#   a. Verify the capsule file (.capsule.bin) exist.
    if [ $capsule_file_status -eq 0 ]; then
        echo
        echo $CAPSULE_FILE_ERROR
        cleanup_tmp_files
        exit 1
    fi

    #   b. Remove previous update files and directories
    rm -fr $UPDATE_CAPSULE_DIR

    #   c. Make update capsule directory
    mkdir -p $UPDATE_CAPSULE_DIR

    #   d. Copy capsule file (.capsule.bin) to /bootflash/EFI/UpdateCapsule/.
    cp -p $CAPSULE_FILE $UPDATE_CAPSULE_DIR/$UPDATE_CAPSULE_FILE

    #   e. Verify the capsule file copy via md5sum.
    MD5SUMA=`md5sum $CAPSULE_FILE | awk '{print $1}'`
    MD5SUMB=`md5sum $UPDATE_CAPSULE_DIR/$UPDATE_CAPSULE_FILE | awk '{print $1}'`
    if [ "foo_$MD5SUMA" != "foo_$MD5SUMB" ]; then
        echo ""
        echo "FAILURE: Unable to copy signed update file."
        echo "The ROMMON update file MD5 signature is $MD5SUMA"
        echo "The copied ROMMON update file MD5 signature is $MD5SUMB"
        cleanup_tmp_files
        exit 1
    fi

    #   f. A secure update will occur during BIOS start.
    echo ""
    echo "Secure update of the ROMMON image will occur after a reload."
    echo ""

    #   g. The secure update part of BIOS Protection will update the Public
    #      Keys, so the Public Key copy and update can be skipped.
    PUBKEY_SIZE=0
else
#
# Step 5. Direct SPI FLASH writes:
#   a. Verify that the upgrade ROMMON image size and authentication
    if ! check_upgrade_file $1; then
        cleanup_tmp_files
        exit 1
    fi

        #   b. Copy over the upgrade ROMMON image to the backup SPI FLASH.
    if ! upgrade_flash $ROMMON_FILE $ROMMON_DEVICE; then
        cleanup_tmp_files
        exit 1
    fi
fi

#
# Step 6 : Copy the ROMMON NVRAM and OS Keys on the Active SPI FLASH.
#
copy_rommon_data

#
# Step 7. Update the ROMMON NVRAM and OS Keys on the Backup SPI FLASH.
#
copy_rom_env $ROMMON_DEVICE

#
# Step 8. Clean up temporary files.
#
cleanup_tmp_files

#
# Step 10. Notify the customer to reload the platform to complete the upgrade.
#
do_upgrade_notify

exit 0
