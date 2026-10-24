#!/bin/bash
#
# April 2007, Michael J. Albanese 
#             && Rajeev Kochhar
#
# Utility functions to read various chasfs values
#
# Any script which sources this file should also source . pglobals.sh
# as ceratin paths named there are required by routines here
#
# Note there is a use of the btrace_XXX universe in this file. This 
# can either be utilized by the sourcer, or the sourcer may define 
# an empty btrace_info routine if it does not itself bring in and 
# initialize the real btrace info world.
#
#
# Copyright (c) 2007-2025 by cisco Systems, Inc.
# All rights reserved

# Use an include guard to prevent multiple sourcing.
[[ ${CHASUTILS_SH_GUARD:-} ]] && return || CHASUTILS_SH_GUARD=1

source mcp_board_defs.sh


CPLD_DIR="${BINOS_CPLD_ROOT:=/tmp/chassis/cpld/chasfs/}"
# chasfs_init_complete
#
# Returns 0 if the initial run of chassis manager (aka cman -c)
# to create chasfs has completed.
#
# This is coordinated with the binos startup script which sets
# board_type and board_subtype immediate after cman -c completes.
chasfs_init_complete () {
    test -e ${BINOS_BASE_DIR}/chasfs/midplane/board_subtype
}

chasfs_is_bp_enabled_on_platform () {
    local bp_enabled

    bp_enabled=$(cyan_get_value $CHASSIS_ATTRS_BP_FRU)
    if [[ $? != 0 ]]; then
        bp_enabled="false"
    fi

    echo -n "$bp_enabled"
}

#
# chasfs_sb_rp_is_ready
#
# Is the Standby RP slot or bay ready
# Orig
# 
chasfs_sb_rp_is_ready () {
    local sb_ready

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/mastership/standby-rp-state" ]; then
	return 1
    fi

    sb_ready=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp-state)

    if [[ ${sb_ready} = "not-ready" ]]; then
	return 1
    fi

    return 0
}

#
# chasfs_is_sb_rp_hot
#
# Has the Standby RP reached sso-ready state
# 
chasfs_is_sb_rp_hot () {
    local sb_ready

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/mastership/standby-rp-state" ]; then
	return 1
    fi

    sb_ready=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp-state)

    if [[ ${sb_ready} = "sso-ready" ]]; then
	return 0
    fi

    return 1
}


#
# chasfs_sb_fp_is_ready
#
# Is the Standby FP slot or bay ready
# Orig
# 
chasfs_sb_fp_is_ready () {
    local sb_ready

    sb_ready=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-fp-state)

    if [[ ${sb_ready} = "sso-ready" ]]; then
	return 0
    fi

    return 1
}

#
# chasfs_rp_is_active
#
# Is the passed in slot the active RP slot?
#
chasfs_rp_is_active () {
    local inquire_slot=$1
    local active_rp

    active_rp=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-rp)
    active_rp=${active_rp:3:1}

    if [[ ${active_rp} = ${inquire_slot} ]]; then
        return 0
    fi
    
    return 1
}

#
# chasfs_fp_is_active
#
# Does the passed in slot contain the active FP ?
# Orig
#
chasfs_fp_is_active () {
    local active_fp
    local slot=$1

    active_fp=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-fp)
    active_fp=${active_fp:3:1}

    if [[ ${active_fp} = $slot ]]; then
        return 0
    fi
    
    return 1
}

#
# chasfs_is_active_fp_online
#
# Verifies that the active FP is online
#
chasfs_is_active_fp_online () {
    local active_fp

    active_fp=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-fp)
    active_fp=${active_fp:3:1}

    return $(chasfs_is_fp_online $active_fp)
}

#
# chasfs_is_active_fp_state_ready
#
# Verifies that the active FP's state is ready
#
chasfs_is_active_fp_state_ready () {
    local active_state

    active_state=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-fp-state)

    if [[ ${active_state} = "ready" ]]; then
        return 0
    fi

    return 1
}

#
# chasfs_is_fp_shutdown
#
# Verifies that the fp is shutdown
#
chasfs_is_fp_shutdown () {
    local fp_slot=$1
    local shutdown_state

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/fp/$fp_slot/cfg_shutdown" ] ; then
        return 1
    fi

    shutdown_state=$(cat ${BINOS_BASE_DIR}/chasfs/fp/$fp_slot/cfg_shutdown)

    if [[ ${shutdown_state} = "yes" ]]; then
        return 0
    fi
    return 1
}

#
# chasfs_rp_bay_is_active
#
# Is this the active RP bay?
# Orig
#
chasfs_rp_bay_is_active () {
    local active_rp_bay
    local fsb
    local bay

    fsb=$1
    bay=${fsb:5:1}

    active_rp_bay=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-rp)
    active_rp_bay=${active_rp_bay:5:1}

    btrace_info "Chasfs active bay: ${active_rp_bay}, input bay: ${bay}"
    if [[ ${active_rp_bay} = ${bay} ]]; then
        btrace_info "Chasfs this RP bay $fsb is active"
        return 0
    fi
    
    btrace_info "Chasfs this RP bay $fsb is NOT active"
    return 1
}

# chasfs_get_chassis_model
#
# Returns the chassis model string
chasfs_get_chassis_model () {
    # Chassis model is right padded with lots of space, so trim all spaces
    cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_model | tr -d " "
}

#
# chasfs_chas_type_present
#
# Is chassis_type object populated?
#
chasfs_chas_type_present () {
     test -e ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type
}

# chasfs_is_fru_present
#
# Returns 0 if the fru object is present.
# This should be valid on both active RP and standby.
chasfs_is_fru_present () {
    local fru_param=$1
    local slot_param=$2
    local bay_param=${3:-}

    if [ -z "$bay_param" ]; then
        if [ -d "$BINOS_BASE_DIR/chasfs/$fru_param/$slot_param" ]; then
            return 0
        fi
    else
        if [ -d "$BINOS_BASE_DIR/chasfs/$fru_param/$slot_param/$bay_param" ]; then
            return 0
        fi
    fi

    return 1
}

#
# chasfs_is_1ru
#
# Are we running on a 1ru chassis type.
# No Params taken
#
chasfs_is_1ru () {
    local chas_type
    local one=1RU

    # Extract the substring after the MCP portion and compare.
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    chas_type=${chas_type:3:3}

    if [[ ${chas_type} = ${one} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_1ng
#
# Are we running on a 1ng chassis type.
# No Params taken
#
chasfs_is_1ng () {
    local chas_type
    local nightster=1NG

    # Extract the substring after the MCP portion and compare.
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    chas_type=${chas_type:3:3}

    if [[ ${chas_type} = ${nightster} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_2ru
#
# Are we running on a 2ru chassis type.
# No Params taken
#
chasfs_is_2ru () {
    local chas_type
    local two=2RU

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    chas_type=${chas_type:3:3}

    if [[ ${chas_type} = ${two} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_4ru
#
# Are we running on a 4ru chassis type.
# No Params taken
#
chasfs_is_4ru () {
    local chas_type
    local four=4

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    chas_type=${chas_type:3:1}

    if [[ ${chas_type} = ${four} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_6ru
#
# Are we running on a 6ru chassis type.
# No Params taken
#
chasfs_is_6ru () {
    local chas_type
    local mcp6ru=MCP6RU

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp6ru} ]] ; then
        return 0
    fi

    return 1
}


#
# chasfs_is_dominica
#
# Are we running on a PEGASUS1M chassis type.
# No Params taken
#
chasfs_is_dominica () {
    local chas_type
    local board_subtype

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    board_subtype=$(cat $CPLD_DIR/board_subtype)
    if [[ ${chas_type} = "PEGASUS1M" ]] ; then 
    if [[ "$board_subtype" = "DOMINICA_4C" ||
          "$board_subtype" = "DOMINICA_4I" ||
          "$board_subtype" = "DOMINICA_20I" ||
          "$board_subtype" = "DOMINICA_20C" ]]; then
        return 0
    fi   
    fi

    return 1
}

#
# chasfs_is_hotsprings
#
# Are we running on a PEGASUS1M chassis type.
# No Params taken
#
chasfs_is_hotsprings () {
    local chas_type
    local board_subtype

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    board_subtype=$(cat $CPLD_DIR/board_subtype)
    if [[ ${chas_type} = "PEGASUS1M" ]] ; then 
    if [[ "$board_subtype" = "HOTSPRINGS" ]]; then
        return 0
    fi   
    fi

    return 1
}

#
# chasfs_is_6ru_x
#
# Are we running on a 6ru chassis type.
# No Params taken
#
chasfs_is_6ru_x () {
    local chas_type
    local mcp6rux=MCP6RX

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp6rux} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_9ru_x
#
# Are we running on a 9ru chassis type.
# No Params taken
#
chasfs_is_9ru_x () {
    local chas_type
    local mcp9rux=MCP9RUX

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp9rux} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_13ru
#
# Are we running on a 13ru chassis type.
# No Params taken
#
chasfs_is_13ru () {
    local chas_type
    local thirteen=13

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    chas_type=${chas_type:3:2}

    if [[ ${chas_type} = ${thirteen} ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_2kp
#
# Are we running on a 2KP/Kingpin chassis type.
# No Params taken
#
chasfs_is_2kp () {
    local chas_type
    local mcp2kp=MCP2KP

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp2kp} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_2kh
#
# Are we running on a 2KH/Kingpin chassis type.
# No Params taken
#
chasfs_is_2kh () {
    local chas_type
    local mcp2kh=MCP2KH

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp2kh} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1sr
#
# Are we running on a 1SR/Kingpin chassis type.
# No Params taken
#
chasfs_is_1sr () {
    local chas_type
    local mcp1sr=MCP1SR

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1sr} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1gl
#
# Are we running on a 1SR/Kingpin/1GL  chassis type.
# No Params taken
#
chasfs_is_1gl () {
    local chas_type
    local mcp1gl=MCP1GL

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1gl} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1gl_5g
#
# Are we running on a 1SR/Kingpin/1GL  chassis type.
# No Params taken
#
chasfs_is_1gl_5g () {
    local chas_type
    local mcp1gl5g=MCP1GL5G

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1gl5g} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_katar
#
# Are we running on a 1SR/Kingpin/1GL/KATAR  chassis type.
# No Params taken
#
chasfs_is_katar () {
    local chas_type
    local mcpkatar=MCPKATAR

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcpkatar} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_kakute
#
# Are we running on a KAKUTE  chassis type.
# No Params taken
#
chasfs_is_kakute () {
    local chas_type
    local mcpkakute=MCPKAKUTE

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcpkakute} ]] ; then
        return 0
    fi
    return 1
}


#
# chasfs_is_2da
#
# Are we running on a 1SR/1GL/2DA  chassis type.
# No Params taken
#
chasfs_is_2da () {
    local chas_type
    local mcp2da=MCP2DA

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp2da} ]] ; then
        return 0
    fi
    return 1
}

#

#
# chasfs_is_mach5
#
# Are we running on MACH5 a chassis type.
# No Params taken
#
chasfs_is_mach5 () {
    local chas_type
    local mcpmach5=MCPMACH5

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcpmach5} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1gd
#
# Are we running on Greenday a chassis type.
# No Params taken
#
chasfs_is_1gd () {
    local chas_type
    local mcp1gd=MCP1GD

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1gd} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1wsp
#
# Are we running on spatha chassis type.
# No Params taken
#
chasfs_is_1wsp () {
    local chas_type
    local mcp1wsp=MCP1WSP

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1wsp} ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_1en
#
# Are we running on Encore a chassis type.
# No Params taken
#
chasfs_is_1en () {
    local chas_type
    local mcp1en=MCP1EN

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1en} ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_1wkph
#
# Are we running on khopesh chassis type.
# No Params taken
#
chasfs_is_1wkph () {
    local chas_type
    local mcp1wkph=MCP1WKPH

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1wkph} ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_1ac
#
# Are we running on Accolade a chassis type.
# No Params taken
#
chasfs_is_1ac () {
    local chas_type
    local mcp1ac=MCP1AC

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1ac} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_ace
#
# Are we running on Ace a chassis type.
# No Params taken
#
chasfs_is_ace () {
    local chas_type
    local mcpace=MCPACE

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcpace} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_1rm
#
# Are we running on Ramones a chassis type.
# No Params taken
#
chasfs_is_1rm () {
    local chas_type
    local mcp1rm=MCP1RM

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${mcp1rm} ]] ; then
        return 0
    fi
    return 1
}

readonly BIOS_PROTECTION_BIT=0x4
# bios_protection_support
#
# Returns 0 if the BIOS protection is enabled on the local FRU
#
# Read the bios protection property from flash if it exists,
#  else consider it not enabled
bios_protection_support () {
    local rommon_capbits
    local capsule_support

    if get_capability_bits rommon_capbits; then
        capsule_support=$(($rommon_capbits & $BIOS_PROTECTION_BIT))
        if [[ $capsule_support -eq $BIOS_PROTECTION_BIT ]]; then
            return 0;
        fi
    fi
    return 1;
}

#
# chasfs_is_mcp_chassis
#
# Is this ASR1K chassis?
#
chasfs_is_mcp_chassis () {

    if  chasfs_is_1ru || chasfs_is_1ng || \
        chasfs_is_2ru || chasfs_is_2kp || \
        chasfs_is_4ru || chasfs_is_6ru || \
        chasfs_is_6ru_x || chasfs_is_9ru_x || \
        chasfs_is_13ru || chasfs_is_2kh ||
        chasfs_is_mach5 || chasfs_is_2da || chasfs_is_katar ||
        chasfs_is_1gd || chasfs_is_1rm || chasfs_is_fugazi ||
        chasfs_is_1en || chasfs_is_1ac ||
        chasfs_is_cbr || chasfs_is_1sr ||
        chasfs_is_1gl || chasfs_is_1gl_5g ||
        chasfs_is_ace || chasfs_is_bender || chasfs_is_fry ||
        chasfs_is_1wsp || chasfs_is_1wkph || chasfs_is_kakute; then
        return 0
    fi
    return 1
}

#
# chasfs_is_uea3ru
#
# Are we running on a uea 3RU chassis type.
# No Params taken
#
chasfs_is_uea3ru () {
    local chas_type
    local uea3ru=UEA3RU

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${uea3ru} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_uea2ru
#
# Are we running on a uea 2RU chassis type.
# No Params taken
#
chasfs_is_uea2ru () {
    local chas_type
    local uea2ru=UEA2RU

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${uea2ru} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_uea7ru
#
# Are we running on a uea 7RU chassis type.
# No Params taken
#
chasfs_is_uea7ru () {
    local chas_type
    local uea7ru=UEA7RU

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = ${uea7ru} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_pegasus
#
# Are we running on a uea chassis type.
# No Params taken
#
chasfs_is_pegasus () {
    local chas_type
    local peg1m=PEGASUS1M
    local pegcu=PEGASUSCU
    local pegf2=PEGASUSF2

    # parsing the return type: MCP4RU -o MCP6RU -o ???
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    #validating the dominica since the chas_type of pegasus and dominica 
    #are same 
    if chasfs_is_dominica; then
        return 1
    fi

    if [[ ${chas_type} = ${peg1m} ]] ; then
        return 0
    elif [[ ${chas_type} = ${pegcu} ]] ; then
        return 0
    elif [[ ${chas_type} = ${pegf2} ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_vxe
# Are we running on a vxe chassis type.
# No Params taken
#
chasfs_is_vxe () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "MCPVXE" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_ovld
#
# Are we running on a overlord chassis type.
# No Params taken
#
chasfs_is_ovld () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "OVLD" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_utah
#
# Are we running on a utah chassis type.
# No Params taken
#
chasfs_is_utah () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "UTAH" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_family_coral
#
# Are we running on a coral platform type.
# No Params taken
#
chasfs_is_family_coral () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CORAL" ]]; then
        return 0
    fi
    return 1
}

#
# chasfs_is_family_ngwc
#
# Are we running on a NGWC platform type.
# No Params taken
#
chasfs_is_family_ngwc () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "KATANA" ||
          ${chas_type} = "EDISON" ||
          ${chas_type} = "NYQUIST" ||
          ${chas_type} = "QUAKE1" ||
          ${chas_type} = "QUAKE2" ]] || chasfs_is_family_ie9k; then
        return 0
    fi
    return 1
}

#
# chasfs_is_ngwc_standalone
#
# Are we running on a NGWC Standalone platform type.
# No Params taken
#
chasfs_is_ngwc_standalone () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CONDOR" ||
          ${chas_type} = "CLARKE_LITE" || 
          ${chas_type} = "SONIC" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_family_ie9k
#
# Are we running on a IE9K platform type.
# No Params taken
#
chasfs_is_family_ie9k () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CONDOR" ||
          ${chas_type} = "CLARKE_ADV" ||
          ${chas_type} = "CLARKE_LITE" || 
          ${chas_type} = "SONIC" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_family_stacking
#
# all platforms which has  more than one max_stack_number or of NGWC family
# FIXME: This  function defination needs to be replaced with CYAN attribute
#        currently can't source cyan_api.sh in chasutils.sh
#
chasfs_is_family_stacking () {
    local max_chassis_number_path=${BINOS_CHASSIS_PATH}/max_chassis_number

    if chasfs_is_ngwc_standalone; then
        return 1
    fi

    if [ -f "$max_chassis_number_path" ]; then
        local max_chassis_number=$(cat $max_chassis_number_path)
        if chasfs_is_family_ngwc || chasfs_is_family_symphony || [[ $max_chassis_number -gt 1 ]]; then
            return 0
        fi
    fi
    return 1
}

#
# chasfs_is_edison
#
# Are we running on a cbr 8ru chassis type.
# No Params taken
#
chasfs_is_edison () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "EDISON" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_nyquist
#
# Are we running on a NYQUIST chassis type.
# No Params taken
#
chasfs_is_nyquist () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "NYQUIST" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_family_petra
#
# Are we running on a PETRA platform type.
# No Params taken
#
chasfs_is_family_petra () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "PETRA" ]] ; then
       return 0
    fi
    return 1
}

#
# chasfs_is_family_hellcat
#
# Are we running on a HELLCAT platform type.
# No Params taken
#
chasfs_is_family_hellcat () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "HELLCAT" ]] ; then
       return 0
    fi
    return 1
}

#
# chasfs_is_family_rio
#
# Are we running on a RIO platform type.
# No Params taken
#
chasfs_is_family_rio () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "RIO" ]] ; then
       return 0
    fi
    return 1
}

#
# chasfs_is_family_trax_m
#
# Are we running on a TRAX-M platform type.
# No Params taken
#
chasfs_is_family_trax_m () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "TRAX_M" ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_family_sparrow
#
# Are we running on a SPARROW platform type.
# No Params taken
#
chasfs_is_family_sparrow () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "SPARROW" ]] ; then
       return 0
    fi
    return 1
}

# chasfs_is_blackheart
#
# Are we running on a BLACKHEART platform type.
# No Params taken
#
chasfs_is_blackheart () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "BLACKHEART" ]] ; then
       return 0
    fi
    return 1
}

# chasfs_is_cabo
#
# Are we running on a cabo platform type.
# No Params taken
#
chasfs_is_cabo () {
    local chas_type

    chas_type=$(<${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
    
    if [[ ${chas_type} == "CABO" ]] ; then
       return 0
    fi
    return 1
}

# chasfs_is_aventus
#
# Are we running on a AVENTUS platform type.
# No Params taken
#
chasfs_is_aventus () {
    local chas_type

    chas_type=$(<${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} == "AVENTUS" ]] ; then
       return 0
    fi
    return 1
}

chasfs_is_macallan_4slot () {
    local chas_type
    
    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
 
    if [[ ${chas_type} = "MACALLAN4SLOT" ]] ; then
	return 0
    fi
    return 1
}

chasfs_is_macallan_7slot () {
     local chas_type
 
     chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
 
     if [[ ${chas_type} = "MACALLAN7SLOT" ]] ; then
         return 0
     fi
     return 1
}
 
chasfs_is_macallan_10slot () {
     local chas_type
 
     chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)
 
     if [[ ${chas_type} = "MACALLAN10SLOT" ]] ; then
         return 0
     fi
     return 1
}
 
chasfs_is_family_macallan () {
    if chasfs_is_macallan_4slot; then
	return 0;
    elif chasfs_is_macallan_7slot; then
        return 0;
    elif chasfs_is_macallan_10slot; then
	return 0; 
    else
        return 1
    fi
}

#
# chasfs_is_sword
#
# Are we running on a sword chassis type.
# No Params taken
#
chasfs_is_sword () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "SWORD" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_cbr_8ru
#
# Are we running on a cbr 8ru chassis type.
# No Params taken
#
chasfs_is_cbr_8ru () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CBR8RU" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_cbr_13ru
#
# Are we running on a cbr 13ru chassis type.
# No Params taken
#
chasfs_is_cbr_13ru () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CBR13RU" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_cbr
#
# Are we running on a cbr 8ru chassis type.
# No Params taken
#
chasfs_is_cbr () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CBR8RU" || ${chas_type} = "CBR13RU" ]] ; then
        return 0
    fi

    return 1
}


#
# chasfs_is_cylons
#
# Are we running on a cylons linecard in cbr.
# No Params taken
#
chasfs_is_cylons () {
    local board_type

    board_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [[ ${board_type} = "CYLONS"  || ${board_type} = "KOBOL" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_kobol
#
# Are we running on a cylons linecard in cbr.
# No Params taken
#
chasfs_is_kobol () {
    local board_type

    board_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [ ${board_type} = "KOBOL" ] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_cbr_patch_file
#
# Are we running on a cbr 8ru chassis type.
# No Params taken
#
chasfs_is_cbr_patch_file () {
    local subpkg_file=$1
    local subpkg_suffix_start=${#subpkg_file}-4

    if chasfs_is_cbr; then
        if [[ "${subpkg_file:$subpkg_suffix_start:4}" = ".tar" ]]; then
            return 0
        fi
    fi

    return 1
}

#
# chasfs_is_dagger
#
# Are we running on a dagger chassis type.
# No Params taken
#
chasfs_is_dagger () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "DAGGER" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_goldbeach
#
# Are we running on a goldbeach chassis type.
# No Params taken
#
chasfs_is_goldbeach () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "GOLDBEACH" ]] ; then
        return 0
    fi
    return 1
}

#
# chasfs_is_tsn
#
# Are we running on a TSN chassis type.
# No Params taken
#
chasfs_is_tsn () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "TSN" || ${chas_type} = "STARESG"  || ${chas_type} = "BETELGEUSE" || ${chas_type} = "SUPERNOVA" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_wilson
#
# Are we running on a WILSON chassis type.
# No Params taken
#
chasfs_is_wilson () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "WILSON" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_crestone
#
# Are we running on a CRESTONE chassis type.
# No Params taken
#
chasfs_is_crestone () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CRESTONE" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_shasta
#
# Are we running on a SHASTA chassis type.
# No Params taken
#
chasfs_is_shasta() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "SHASTA" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_arata
#
# Are we running on a ARATA chassis type.
# No Params taken
#
chasfs_is_arata() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "ARATA" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_arata_e
#
# Are we running on a ARATA_E chassis type.
# No Params taken
#
chasfs_is_arata_e() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "ARATA_E" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_styx
#
# Are we running on a STYX chassis type.
# No Params taken
#
chasfs_is_styx() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "STYX_L" ||
          ${chas_type} = "STYX_M" ||
          ${chas_type} = "STYX_M_CU" ||
          ${chas_type} = "STYX_H" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_avatar
#
# Are we running on a AVATAR chassis type.
# No Params taken
#
chasfs_is_avatar() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "AVATAR" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_whitney
#
# Are we running on a WHITNEY chassis type.
# No Params taken
#
chasfs_is_whitney() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "WHITNEY" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_neptune
#
# Are we running on a NEPTUNE chassis type.
# No Params taken
#
chasfs_is_neptune () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "NEPTUNE" ]] ; then
        return 0
    fi

    return 1
}


#
# chasfs_is_radium
#
# Are we running on a RADIUM chassis type.
# No Params taken
#
chasfs_is_radium () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "RADIUM" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_thallium
#
# Are we running on a THALLIUM chassis type.
# No Params taken
#
chasfs_is_thallium () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "THALLIUM" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_uranium
#
# Are we running on a URANIUM chassis type.
# No Params taken
#
chasfs_is_uranium () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "URANIUM" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_thorium
#
# Are we running on a THORIUM chassis type.
# No Params taken
#
chasfs_is_thorium () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "THORIUM" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_promethium
#
# Are we running on a PROMETHIUM chassis type.
# No Params taken
#
chasfs_is_promethium () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "PROMETHIUM" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_vg4x0
#
# Are we running on a VG410 chassis type.
# No Params taken
#
chasfs_is_vg410 () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "VG410" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_charon_family
#
# Are we running on a CHARON_FAMILY chassis type.
# No Params taken
#
chasfs_is_charon_family () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CHARON_FAMILY" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_calliope
#
# Are we running on a CALLIOPE chassis type.
# No Params taken
#
chasfs_is_calliope () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "CALLIOPE" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_sumatra
#
# Are we running on a SUMATRA chassis type.
# No Params taken
#
chasfs_is_sumatra() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "SUMATRA" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_rufous
#
# Are we running on a RUFOUS chassis type.
# No Params taken
#
chasfs_is_rufous() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "RUFOUS" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_fugazi
#
# Are we running on a FUGAZI chassis type.
# No Params taken
#
chasfs_is_fugazi () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "FUGAZI" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_bender
#
# Are we running on a BENDER chassis type.
# No Params taken
#
chasfs_is_bender () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "BENDER" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_fry
#
# Are we running on a FRY chassis type.
# No Params taken
#
chasfs_is_fry () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "FRY" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_nanook
#
# Are we running on a NANOOK chassis type.
# No Params taken
#
chasfs_is_nanook () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "NANOOK" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_nutella
#
# Are we running on a NUTELLA chassis type.
# No Params taken
#
chasfs_is_nutella () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "NUTELLA" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_family_usd
#
# Are we running on an USD platform type.
# No Params taken
#
chasfs_is_family_usd () {
  if chasfs_is_utah; then
        return 0;
  elif chasfs_is_sword; then
       return 0;
  elif chasfs_is_dagger; then
       return 0;
  elif chasfs_is_goldbeach; then
       return 0;
  else
       return 1
  fi
}

#
# chasfs_is_family_tsn
#
# Are we running on an TSN platform type.
# No Params taken
#
chasfs_is_family_tsn () {
  if chasfs_is_tsn; then
       return 0;
  else
       return 1
  fi
}

#
# chasfs_is_family_mirabile
#
# Are we running on a MIRABILE family type.
# No Params taken
#
chasfs_is_family_mirabile () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "WILSON" ||
          ${chas_type} = "CRESTONE" ||
          ${chas_type} = "SHASTA" ||
          ${chas_type} = "ARATA" ||
          ${chas_type} = "ARATA_E" ||
          ${chas_type} = "WHITNEY" ||
          ${chas_type} = "AVATAR" ||
          ${chas_type} = "STYX_L" ||
          ${chas_type} = "STYX_M" ||
          ${chas_type} = "STYX_M_CU" ||
          ${chas_type} = "STYX_H" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_family_14er
#
# Are we running on a 14er family type.
# No Params taken
#
chasfs_is_family_14er() {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "WILSON" ||
          ${chas_type} = "CRESTONE" ||
          ${chas_type} = "SHASTA" ||
          ${chas_type} = "ARATA" ||
          ${chas_type} = "ARATA_E" ||
          ${chas_type} = "WHITNEY" ||
          ${chas_type} = "AVATAR" ||
          ${chas_type} = "STYX_L" ||
          ${chas_type} = "STYX_M" ||
          ${chas_type} = "STYX_M_CU" ||
          ${chas_type} = "STYX_H" ]] ; then
        return 0
    fi

    return 1
}

#
# chasfs_is_family_poseidon
#
# Are we running on an neptune family type.
# No Params taken
#
chasfs_is_family_poseidon () {
  if chasfs_is_neptune; then
       return 0;
  elif chasfs_is_family_curie; then
       return 0;
  else
       return 1
  fi
}

#
# chasfs_is_family_curie
#
# Are we running on an isr6k platform type.
# No Params taken
#
chasfs_is_family_curie () {
  if chasfs_is_radium; then
        return 0;
  elif chasfs_is_thallium; then
       return 0;
  elif chasfs_is_uranium; then
       return 0;
  elif chasfs_is_thorium; then
       return 0;
  elif chasfs_is_promethium; then
       return 0;
  else
       return 1
  fi
}

#
# chasfs_is_family_vg4x0
#
# Are we running on an vg4x0 platform type.
# No Params taken
#
chasfs_is_family_vg4x0 () {
  if chasfs_is_vg410; then
       return 0;
  else
       return 1
  fi
}

#
# chasfs_is_family_esg
#
# Are we running on an ESG platform type.
# No Params taken
#
chasfs_is_family_esg () {
  if chasfs_is_ovld; then
        return 0;
  elif chasfs_is_family_usd; then
        return 0;
  elif chasfs_is_family_tsn; then
       return 0;
  elif chasfs_is_family_mirabile; then
       return 0;
  elif chasfs_is_family_poseidon; then
       return 0;
  elif chasfs_is_family_curie; then
       return 0;
  elif chasfs_is_family_vg4x0; then
       return 0;
  elif chasfs_is_nanook; then
       return 0;
  elif chasfs_is_nutella; then
       return 0;
  elif chasfs_is_sumatra; then
       return 0;
  elif chasfs_is_rufous; then
       return 0;
  elif chasfs_is_charon_family; then
       return 0;
  elif chasfs_is_calliope; then
       return 0;
  else
       return 1
  fi
}

# chasfs_is_distr_stack_enabled
#
# Are we running in distributed stack mode 
# No Params taken
#
chasfs_is_distr_stack_enabled () {
    if [ ! -e "/tmp/chassis/local/stack_mgr/distr_stack/fss_mode" ]; then
        return 1
    fi
    
    sv_mode=$(cat /tmp/chassis/local/stack_mgr/distr_stack/fss_mode)
    case $sv_mode in
        access|aggregation)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# chasfs_is_macallan
#
# Are we running on a macallan platform type.
# No Params taken
#
chasfs_is_macallan () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "MACALLAN" ]] ; then
        return 0
    fi
    return 1
}

chasfs_is_family_starfleet_chassis_type () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "STARFLEET_GRYPHON" ||
          ${chas_type} = "STARFLEET_GRYPHON_LITE" ||
          ${chas_type} = "STARFLEET_PROMETHEUS" || 
          ${chas_type} = "STARFLEET_SKYFOX" ]] ; then
         return 0
     fi
     return 1
}

# chasfs_is_family_starfleet
#
# Are we running on a Starfleet platform type.
# No Params taken
#
chasfs_is_family_starfleet () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "STARFLEET" ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_family_starfleet_modular
#
# Are we running on a Starfleet modular platform type.
# No Params taken
#
chasfs_is_family_starfleet_modular () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "STARFLEET6SLOT" ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_vulcan
#
# Vulcan is Sup1 of 9600 which is STARFLEET6SLOT type
# No Params taken
#
function chasfs_is_vulcan () {
    local board_subtype
    board_subtype=$(<${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [[ "$board_subtype" = "VULCAN" ]]; then
        return 0
    fi
    return 1
}

# chasfs_is_intrepid
#
# Intrepid is Sup2 of 9600 which is LEABA asic based
# No Params taken
#
function chasfs_is_intrepid () {
    local board_subtype
    board_subtype=$(<${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [[ "$board_subtype" = "INTREPID" ]]; then
        return 0
    fi
    return 1
}

# chasfs_is_discovery
#
# Discovery is Sup3 of 9600 which is krypton asic based
# No Params taken
#
function chasfs_is_discovery () {
    local board_subtype
    board_subtype=$(<${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [[ "$board_subtype" == "DISCOVERY" ]]; then
        return 0
    fi
    return 1
}


function chasfs_is_jura () {
    local board_subtype
    board_subtype=$(<${BINOS_BASE_DIR}/chasfs/midplane/board_subtype)

    if [[ "$board_subtype" = "JURA" ]]; then
        return 0
    fi
    return 1
}

# chasfs_is_family_bigbang_modular
#
# Are we running on a Bigbang modular platform type.
# No Params taken
#
chasfs_is_family_bigbang_modular () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "BIGBANG-STARGAZER"  || \
          ${chas_type} = "BIGBANG-C9610"      || \
          ${chas_type} = "MACALLANBB4SLOT"    || \
          ${chas_type} = "MACALLANBB7SLOT"    || \
          ${chas_type} = "MACALLANBB10SLOT" ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_family_startrek
#
# Are we Big Bang/Startrek?
# No Params taken
#
chasfs_is_family_startrek () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "SCORPION" || \
          ${chas_type} = "MARTIAN"  || \
          ${chas_type} = "FARSCAPE" || \
          ${chas_type} = "MAGIC_CARPET" || \
          ${chas_type} = "BIG_THUNDER" || \
          ${chas_type} = "BARNSTORMER" || \
          ${chas_type} = "SMALLWORLD" || \
          ${chas_type} = "SPACE_MOUNTAIN" || \
          ${chas_type} = "BORG" ]] ; then
        return 0
    fi
    return 1
}

# chasfs_is_family_stratocaster
#
# Are we Symphony/Stratocaster?
# No Params taken
#
chasfs_is_family_stratocaster () {
    local chas_type

    chas_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_type)

    if [[ ${chas_type} = "GH" || ${chas_type} = "RAITT48U" ||
          ${chas_type} = "RAITT48P" || ${chas_type} = "RAITT48T" ||
          ${chas_type} = "RAITT24U" || ${chas_type} = "RAITT24P" ||
          ${chas_type} = "RAITT24T" || ${chas_type} = "HENDRIX48HX" ||
          ${chas_type} = "HENDRIX24HX" || ${chas_type} = "HARRISON48Y" || 
          ${chas_type} = "HARRISON24Y" || ${chas_type} = "HARRISON12Y" || 
          ${chas_type} = "HOLLY48S" || ${chas_type} = "HOLLY24S" ||
          ${chas_type} = "VALENS48HM" || ${chas_type} = "VALENS24HM" || 
          ${chas_type} = "GILMOUR48HXN" ||
          ${chas_type} = "TOWNSHEND48HXG" || ${chas_type} = "HENDRIX48TX" ||
          ${chas_type} = "BUCKETHEAD48HXN4L" ||
          ${chas_type} = "BUCKETHEAD48HXM4L" || ${chas_type} = "BUCKETHEAD24HXM4L" ||
          ${chas_type} = "BUCKETHEAD24HXN4L" || ${chas_type} = "FRAMPTON48UM4L" ||
          ${chas_type} = "FRAMPTON24UM4L" || ${chas_type} = "IOMMI48P4L" ||
          ${chas_type} = "IOMMI24P4L" ||
          ${chas_type} = "IOMMI48T4L" ||
          ${chas_type} = "IOMMI24T4L" ]]; then
        return 0
    fi
    return 1
}

# chasfs_is_family_bigbang
#
# Are we Big Bang/Pangea?
# No Params taken
#
chasfs_is_family_bigbang () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "BIGBANG" ]] ; then

        return 0
    fi
    return 1
}

# chasfs_is_family_vegas
#
# Are we Vegas?
# No Params taken
#
chasfs_is_family_vegas () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "VEGAS" ]] ; then

        return 0
    fi
    return 1
}

chasfs_is_family_symphony () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "SYMPHONY" ]] || chasfs_is_family_vegas; then

        return 0
    fi
    return 1
}

# chasfs_is_family_galaxy
#
# Are we Galaxy?
# No Params taken
#
chasfs_is_family_galaxy () {
    local plat_type

    [ -r ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type ] || return 1

    plat_type=$(cat ${BINOS_BASE_DIR}/chasfs/midplane/platform_fam_type)

    if [[ ${plat_type} = "GALAXY" ]] ; then

        return 0
    fi
    return 1
}

#
# chasfs_is_consolidated
#
# Are we running on a 1ru chassis type.
# No Params taken
#
chasfs_is_consolidated () {
    if chasfs_is_1ru; then
        return 0;
    elif chasfs_is_1ng; then
        return 0;
    elif chasfs_is_2kp; then
        return 0;
    elif chasfs_is_2kh; then
        return 0;
    elif chasfs_is_mach5; then
        return 0;
    elif chasfs_is_1gd; then
        return 0;
    elif chasfs_is_1en; then
        return 0;
    elif chasfs_is_1ac; then
        return 0;
    elif chasfs_is_ace; then
        return 0;
    elif chasfs_is_1rm; then
        return 0;
    elif chasfs_is_1sr; then
        return 0;
    elif chasfs_is_1gl; then
        return 0;
    elif chasfs_is_1gl_5g; then
        return 0;
    elif chasfs_is_2da; then
        return 0;
    elif chasfs_is_katar; then
        return 0;
    elif chasfs_is_fugazi; then
        return 0;
    elif chasfs_is_family_esg; then
        return 0;
    elif chasfs_is_bender; then
        return 0;
    elif chasfs_is_fry; then
        return 0;
    elif chasfs_is_cbr; then
        if chasfs_is_cylons; then
            return 1;
        else
            return 0;
        fi
    elif chasfs_is_family_ngwc; then
        return 0;
    elif chasfs_is_family_coral; then
        return 0;
    elif chasfs_is_family_macallan; then
	return 0;
    elif chasfs_is_family_petra; then
    return 0;
    elif chasfs_is_family_hellcat; then
    return 0;
    elif chasfs_is_family_rio; then
    return 0;
    elif chasfs_is_family_starfleet; then
    return 0;
    elif chasfs_is_family_starfleet_chassis_type; then
    return 0;
    elif chasfs_is_family_starfleet_modular; then
    return 0;
    elif chasfs_is_family_bigbang_modular ; then
    return 0;    
    elif chasfs_is_family_bigbang ; then
    return 0;
    elif chasfs_is_family_symphony ; then
    return 0;
    elif chasfs_is_family_startrek ; then
    return 0;
    elif chasfs_is_family_sparrow; then
    return 0;
    elif chasfs_is_aventus; then
         return 0;
    elif chasfs_is_cabo; then
         return 0;
    elif chasfs_is_blackheart; then
         return 0;
    elif chasfs_is_vxe; then
        return 0;
    elif chasfs_is_1wsp; then
        return 0;
    elif chasfs_is_1wkph; then
        return 0;
    elif chasfs_is_kakute; then
        return 0;
    else
        return 1
    fi
}

#
# chasfs_chassis_has_2_rp_slots
#
# Returns 0 if the chassis has two slots for RPs
# (independent of whether the the slots are both populated)
chasfs_chassis_has_2_rp_slots () {
    if chasfs_is_6ru ; then
        return 0;
    fi
    if chasfs_is_6ru_x ; then
        return 0;
    fi
    if chasfs_is_9ru_x ; then
        return 0;
    fi
    if chasfs_is_13ru ; then
        return 0;
    fi
    if chasfs_is_uea3ru ; then
        return 0;
    fi
    if chasfs_is_family_macallan ; then
	return 0;
    fi
    if chasfs_is_family_starfleet_modular ; then
    return 0;
    fi
    if chasfs_is_family_bigbang_modular ; then
    return 0;
    fi
    if chasfs_is_cbr; then
        return 0;
    fi
    if chasfs_is_uea7ru ; then
        return 0;
    fi
    if chasfs_is_family_symphony; then
        return 0;
    fi   
    if chasfs_is_distr_stack_enabled; then
    	if chasfs_is_family_starfleet; then
    		return 0;
    	fi
    	if chasfs_is_family_bigbang; then
            return 0;
        fi

    fi
    
    return 1;
}

#
# chasfs_has_capsule_support
#
# Return 0 if the chassis and/or card supports
# update capsule secure SPI FLASH upgrades.
#
chasfs_has_capsule_support () {
    if chasfs_is_family_usd; then
        return 0;
    elif chasfs_is_ovld; then
        return 0;
    elif chasfs_is_family_poseidon; then
        return 0;
    elif chasfs_is_nutella; then
       return 0;
    elif chasfs_is_nanook; then
       return 0;
    elif bios_protection_support; then
        return 0;
    fi

    return 1;
}

# chasutil_chassis_max_slot
#
# Returns the maximum slot number for the specified fru type
# for this chassis (for example "rp" on a 6RU returns 1).
#
# Note to callers- until the next ISSU break, there is a chance
# that this function will return a value larger than the true
# chassis value.  In the case of a rp_base >= RLS5 and an rp_daemons
# <= RLS4 install, cman would not have populated the chassis_max_*
# values in chasfs.
chasutil_chassis_max_slot () {
    local fru=$1

    if [ -e "${BINOS_BASE_DIR}/chasfs/midplane/chassis_slot_max_${fru}" ]; then
        cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_slot_max_${fru}
    else
        # return the 13ru values
        case $fru in
            rp) echo -n "$CHASSIS_RP_SLOT_MAX";;
            fp) echo -n "$CHASSIS_FP_SLOT_MAX";;
            cc) echo -n "$CHASSIS_CC_SLOT_MAX";;
        esac
    fi
}

# chasutil_chassis_max_spa
#
# Returns the maximum spa number for this chassis.
# (for example on a 6RU returns 3).
#
chasutil_chassis_max_spa () {
    if [ -e "${BINOS_BASE_DIR}/chasfs/midplane/chassis_spa_max" ]; then
        cat ${BINOS_BASE_DIR}/chasfs/midplane/chassis_spa_max
    else
        # return the 13ru value
        echo -n "$CHASSIS_CC_BAY_MAX"
    fi
}

# chasutil_chassis_has_slot
#
# Returns 0 if this chassis type has the specified slot number for
# the specified fru type.  This is not dependent on whether a board
# is inserted into the slot or not.
#
# See chasutil_chassis_max_slot "Note to callers" for caveat.
chasutil_chassis_has_slot () {
    local fru=$1
    local slot=$2

    local max_slot=$(chasutil_chassis_max_slot $fru)
    if [[ $slot -le $max_slot ]]; then
        return 0
    fi

    return 1
}

# chasutil_get_frutypes
#
# Returns a string: "rp fp cc bp" allowing for iteration over fru types
chasutil_get_frutypes () {
    if [[ $(chasfs_is_bp_enabled_on_platform) = "true" ]]; then
        echo -n "rp fp cc bp"
    else
        echo -n "rp fp cc"
    fi
}

# chasutil_get_all_fruslots
#
# Returns a list of all slots for this chassis in the form fru/slot
# For example a 6RU returns:
#
#  "rp/0 rp/1 fp/0 fp/1 cc/0 cc/1 cc/2"
chasutil_get_all_fruslots () {
    local frutypes=$(chasutil_get_frutypes)

    local fs_list=""
    local fru
    for fru in $frutypes; do
        local max=$(chasutil_chassis_max_slot $fru)
        local curr=$(eval echo $fru/{0..$max})
        fs_list="$fs_list $curr"
    done
    echo -n "$fs_list"
}

#
# chasfs_get_active_rp
#
# Returns the contents of the active-rp mastership chasfs entry.
# The value is of the form "rp/<slot>/<bay>"
chasfs_get_active_rp () {
    cat ${BINOS_BASE_DIR}/chasfs/mastership/active-rp
}

#
# chasfs_get_standby_rp
#
# Returns the contents of the standby-rp mastership chasfs entry.
# The value is of the form "rp/<slot>/<bay>"
chasfs_get_standby_rp () {
    cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp
}

#
# chasfs_get_active_rp_bay
#
chasfs_get_active_rp_bay () {
    local active_rp_bay

    active_rp_bay=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-rp)
    active_rp_bay=${active_rp_bay:5:1}

    echo -n "$active_rp_bay"
}

#
# chasfs_get_active_rp_slot
#
chasfs_get_active_rp_slot () {
    local active_rp_slot

    active_rp_slot=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/active-rp)
    active_rp_slot=${active_rp_slot:3:1}

    echo -n "$active_rp_slot"
}

#
# chasfs_get_global_active_rp_slot
#
chasfs_get_global_active_rp_slot () {
    local glb_active_rp_slot

    if [[ -e ${BINOS_BASE_DIR}/chasfs/mastership/global-active-rp ]]; then
        glb_active_rp_slot=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-active-rp)
        glb_active_rp_slot=$(echo $glb_active_rp_slot | cut -d '/' -f3)

        echo -n "$glb_active_rp_slot"
    fi
}

#
# chasfs_get_global_standby_rp_slot
#
chasfs_get_global_standby_rp_slot () {
    local glb_standby_rp_slot

    if [[ -e ${BINOS_BASE_DIR}/chasfs/mastership/global-standby-rp ]]; then
        glb_standby_rp_slot=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-standby-rp)
        glb_standby_rp_slot=$(echo $glb_standby_rp_slot | cut -d '/' -f3)

        echo -n "$glb_standby_rp_slot"
    fi
}

#
# chasfs_get_local_rp_slot
#
chasfs_get_local_rp_slot () {
    local local_rp_slot

    local_rp_slot=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/local-rp-slot)

    echo -n "$local_rp_slot"
}

#
# chasfs_get_standby_rp_bay
#
chasfs_get_standby_rp_bay () {
    local sb_rp_bay

    sb_rp_bay=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp)
    sb_rp_bay=${sb_rp_bay:5:1}

    echo -n "${sb_rp_bay}"
}

#
# chasfs_get_standby_rp_slot
#
chasfs_get_standby_rp_slot () {
    local standby_rp_slot

    standby_rp_slot=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp)
    standby_rp_slot=${standby_rp_slot:3:1}

    echo -n "$standby_rp_slot"
}

#
# chasfs_get_active_bp
#
# Returns the contents of the active-bp mastership chasfs entry.
# The value is of the form "bp/<slot>/<bay>"
chasfs_get_active_bp () {
    cat ${BINOS_BASE_DIR}/chasfs/mastership/active-bp
}

#
# chasfs_get_active_bp_slot
#
chasfs_get_active_bp_slot () {
    local active_bp_slot

    active_bp_slot=$(chasfs_get_active_bp)
    active_bp_slot=${active_bp_slot:3:1}

    echo -n "$active_bp_slot"
}

#
# chasfs_is_bp_online
#
chasfs_is_bp_online () {
    local bp_slot=$1
    local state_guts="off"

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/bp/$bp_slot/state" ]; then
        return 1
    fi

    state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/bp/$bp_slot/state)

    if [[ "$state_guts" = "online" ]]; then
       return 0
    fi

    return 1
}

#
# chasfs_active_bp_hostname
#
chasfs_active_bp_hostname () {
    local active_bp_slot
    local slot_based_host

    active_bp_slot=$(chasfs_get_active_bp_slot)
    slot_based_host="bp$active_bp_slot-$active_bp_slot"

    echo -n "$slot_based_host"
}

#
# chasfs_is_cc_online
#
chasfs_is_cc_online () {
    local cc_slot=$1
    local state_guts="off"

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/state" ] ; then
        return 1
    fi

    state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/state)

    if [[ "$state_guts" = "online" ]]; then
	return 0
    fi
    return 1
}

#
# chasfs_is_cc_performing_mdr
#
chasfs_is_cc_performing_mdr () {
    local cc_slot=$1
    local state_guts="offline"

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/oper_state" ] ; then
        return 1
    fi

    # Test if cc's state contains 'mdr' string
    state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/oper_state)
    if [[ "$state_guts" =~ "mdr" ]]; then
        return 0
    fi

    return 1
}

#
# chasfs_is_fp_online
#
chasfs_is_fp_online () {
    local fp_slot=$1
    local state_guts="off"

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/fp/$fp_slot/state" ] ; then
        return 1
    fi

    state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/fp/$fp_slot/state)

    if [[ "$state_guts" = "online" ]]; then
	return 0
    fi
    return 1
}

# chasfs_is_cc_present
#
# Returns 0 if the cc object is present.
# This should be valid on both active RP and standby.
chasfs_is_cc_present () {
    local cc_slot=$1

    if [ -d "$BINOS_BASE_DIR/chasfs/cc/$cc_slot" ]; then
        return 0
    fi

    return 1
}

# chasfs_is_elc_present
#
# Returns 0 if elc is present.
chasfs_is_elc_present () {
    local cslot_param=${1:-}
    local ccfru="cc"
    local ccslotmax=$(chasutil_chassis_max_slot $ccfru)
    local cslot
    local cc_type
    local retval=1

    if [ -z "$cslot_param" ]; then
        for ((cslot=0; cslot <= $ccslotmax; cslot++)); do
            if ! chasfs_is_cc_present $cslot; then
                continue
            fi
            cc_type=$(chasfs_get_card_type $ccfru $cslot)
            if [[ ("$cc_type" = "$MCP_ELC40G_CONTROLLER_ID") || \
                  ("$cc_type" = "$MCP_ELC100G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        done
    else
        if chasfs_is_cc_present $cslot_param; then
            cc_type=$(chasfs_get_card_type $ccfru $cslot_param)
            if [[ ("$cc_type" = "$MCP_ELC40G_CONTROLLER_ID") || \
                  ("$cc_type" = "$MCP_ELC100G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        fi
    fi

    echo -n "$retval"
}

# chasfs_is_mdr_compat_elc_present
#
# Returns 0 if elc is present.
chasfs_is_mdr_compat_elc_present () {
    local cslot_param=${1:-}
    local ccfru="cc"
    local ccslotmax=$(chasutil_chassis_max_slot $ccfru)
    local cslot
    local cc_type
    local retval=1

    if [ -z "$cslot_param" ]; then
        for ((cslot=0; cslot <= $ccslotmax; cslot++)); do
            if ! chasfs_is_cc_present $cslot; then
                continue
            fi
            cc_type=$(chasfs_get_card_type $ccfru $cslot)
            if [[ ("$cc_type" = "$MCP_ELC40G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        done
    else
        if chasfs_is_cc_present $cslot_param; then
            cc_type=$(chasfs_get_card_type $ccfru $cslot_param)
            if [[ ("$cc_type" = "$MCP_ELC40G_CONTROLLER_ID") ]]; then 
                retval=0
            fi
        fi
    fi

    echo -n "$retval"
}

# chasfs_is_sip_present
#
# Returns 0 if any type of SIP is present.
chasfs_is_sip_present () {
    local cslot_param=${1:-}
    local ccfru="cc"
    local ccslotmax=$(chasutil_chassis_max_slot $ccfru)
    local cslot
    local cc_type
    local retval=1

    if [ -z "$cslot_param" ]; then
        for ((cslot=0; cslot <= $ccslotmax; cslot++)); do
            if ! chasfs_is_cc_present $cslot; then
                continue
            fi
            cc_type=$(chasfs_get_card_type $ccfru $cslot)
            if [[ ("$cc_type" = "$MCP_CC10G_CONTROLLER_ID") || \
                  ("$cc_type" = "$MCP_CC40G_CONTROLLER_ID") ]]; then
                retval=0
                break
            fi
        done
    else
        if chasfs_is_cc_present $cslot_param; then
            cc_type=$(chasfs_get_card_type $ccfru $cslot_param)
            if [[ ("$cc_type" = "$MCP_CC10G_CONTROLLER_ID") || \
                  ("$cc_type" = "$MCP_CC40G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        fi
    fi

    echo -n "$retval"
}

# chasfs_is_mdr_compat_sip_present
#
# Returns 0 if MDR compatible SIP is present.
chasfs_is_mdr_compat_sip_present () {
    local cslot_param=${1:-}
    local ccfru="cc"
    local ccslotmax=$(chasutil_chassis_max_slot $ccfru)
    local cslot
    local cc_type
    local retval=1

    if [ -z "$cslot_param" ]; then
        for ((cslot=0; cslot <= $ccslotmax; cslot++)); do
            if ! chasfs_is_cc_present $cslot; then
                continue
            fi
            cc_type=$(chasfs_get_card_type $ccfru $cslot)
            if [[ ("$cc_type" = "$MCP_CC40G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        done
    else
        if chasfs_is_cc_present $cslot_param; then
            cc_type=$(chasfs_get_card_type $ccfru $cslot_param)
            if [[ ("$cc_type" = "$MCP_CC40G_CONTROLLER_ID") ]]; then
                retval=0
            fi
        fi
    fi

    echo -n "$retval"
}

# chasfs_is_spa_present
#
# Returns 0 if the spa object is present.
# This should be valid on both active RP and standby.
chasfs_is_spa_present () {
    local cc_slot=$1
    local cc_bay=$2

    if [ -d "$BINOS_BASE_DIR/chasfs/cc/$cc_slot/$cc_bay" ]; then
        return 0
    fi

    return 1
}

# chasfs_is_spa_online
#
# Returns 0 if the spa object is online.
# This should be valid on both active RP and standby.
chasfs_is_spa_online () {
    local cc_slot=$1
    local cc_bay=$2
    local state_guts="offline"

    # MCP_FIXME: Need to have a better way of detecting for SPA being 
    # online. Right now this indicates that IOSD has been kicked off on the 
    # SPA. We should have a very similar chasfs property that not just
    # only tells whether IOSD was kicked off, but also makes sure that it
    # is successfully loaded and is in ready state to start routing traffic.
    if [ -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/state" ]; then
        state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/state)
        if [[ "$state_guts" = "online-rspios" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# chasfs_is_spa_ok
#
# Returns 0 if the spa object is in the "ok" FRU state.
#
chasfs_is_spa_ok () {
    local cc_slot=$1
    local cc_bay=$2
    local state_guts="not-ok"

    if [ -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/fru_state" ]; then
        state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/fru_state)
        if [[ "$state_guts" = "ok" ]]; then
            return 0
        fi
    fi

    return 1
}

#
# chasfs_is_spa_shutdown
#
# Return 0 if SPA is shutdown
#
chasfs_is_spa_shutdown () {
    local cc_slot=$1
    local cc_bay=$2

    if [ -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/shutdown" ]; then
        return 0
    fi

    return 1
}

#
# chasfs_is_spa_performing_mdr
#
# Return 0 if mdr_status is present/SPA is performing MDR
#
chasfs_is_spa_performing_mdr () {
    local cc_slot=$1
    local cc_bay=$2

    if [ -e "${BINOS_BASE_DIR}/chasfs/cc/$cc_slot/$cc_bay/mdr_status" ]; then
        return 0
    fi

    return 1
}

# chasfs_is_im_present
#
# Returns 0 if the im object is present.
# This should be valid on both active RP and standby.
#
chasfs_is_im_present () {
    local cc_slot=$1
    local cc_bay=$2
    #
    # An IM on UEA looks like a SPA in slot 0 on MCP to
    # the chassfs. 
    # 
    #
    return $(chasfs_is_spa_present ${cc_slot} ${cc_bay})
}

# chasfs_is_im_online
#
# Returns 0 if the im object is online.
# This should be valid on both active RP and standby.
#
chasfs_is_im_online () {
    local cc_slot=$1
    local cc_bay=$2

    return $(chasfs_is_spa_online ${cc_slot} ${cc_bay})
}

#
# chasfs_is_rp_online
#
chasfs_is_rp_online () {
    local rp_slot=$1
    local state_guts="off"

    if [ ! -e "${BINOS_BASE_DIR}/chasfs/rp/$rp_slot/state" ]; then
        return 1
    fi

    state_guts=$(cat ${BINOS_BASE_DIR}/chasfs/rp/$rp_slot/state)

    if [[ "$state_guts" = "online" ]]; then
	return 0
    fi
    return 1
}

#
# chasfs_is_fru_online
#
chasfs_is_fru_online () {
    local l_fru=$1
    local l_slot=$2

    return $(chasfs_is_${l_fru}_online $l_slot)
}

#
# chasfs_rp_has_two_bays
#
# This should only be true on single RP chassis's (today)
# which are running dual iosd's
#
chasfs_rp_has_two_bays () {
    local rp_slot=$1
    local bay_zero=0
    local bay_one=1

    if [ -d "${BINOS_BASE_DIR}/chasfs/rp/$rp_slot/$bay_zero" ]; then
        if [ -d "${BINOS_BASE_DIR}/chasfs/rp/$rp_slot/$bay_one" ]; then
            return 0
        fi
    fi

    return 1
}

#
# chasfs_is_dual_ios
#
# verify dual iosd is actually configured
#
chasfs_is_dual_ios () {
    local rp_slot=$1

    if [ -e "$(chasfs_get_chasfs_dir)/rp/$rp_slot/ios-dual-requested" ]; then
        return 0
    fi

    return 1
}

#
# chasfs_is_red_mode_sso
#
# Detect how iosd is configured to run. It will have conveyed this
# setting to the local cman who persists into chasfs.
#
# Note: This is not neccessarily reflecitve of the current running
#       state of the system, just the intended configuration.
#
# strongly tied to the tdl definitions in the redundancy.tdl file.
# enum_def mcp_redundancy_mode {
#     MCP_RED_MODE_UNDEFINED,
#     MCP_RED_MODE_NONE,
#     MCP_RED_MODE_RPR,
#     MCP_RED_MODE_RPR_PLUS,
#     MCP_RED_MODE_SSO,
#     MCP_RED_MODE_LAST,
# };
#
chasfs_is_red_mode_sso () {
    red_mode_val=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/red-mode)

    if [[ "$red_mode_val" = "$MCP_RED_MODE_SSO" ]]; then
	return 0
    fi
    return 1
}

#
# chasfs_is_red_mode_rpr
#
# Detect how iosd is configured to run. It will have conveyed this
# setting to the local cman who persists into chasfs.
#
# Note: This is not neccessarily reflective of the current running
#       state of the system, just the intended configuration.
#
# strongly tied to the tdl definitions in the redundancy.tdl file.
#
chasfs_is_red_mode_rpr () {
    red_mode_val=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/red-mode)

    if [[ "$red_mode_val" = "$MCP_RED_MODE_RPR" ]]; then
	return 0
    fi
    return 1
}

#
# chasfs_is_red_mode_none
#
chasfs_is_red_mode_none () {
    red_mode_val=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/red-mode)

    if [[ "$red_mode_val" = "$MCP_RED_MODE_NONE" ]]; then
	return 0
    fi
    return 1
}

#
# chasfs_is_sb_rp_cold
#
# Has the Standby RP reached rpr-ready state
# 
chasfs_is_sb_rp_cold () {
    local sb_rpr_ready

    sb_rpr_ready=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/standby-rp-state)

    if [[ ${sb_rpr_ready} = "rpr-ready" ]]; then
	return 0
    fi

    return 1
}

#
# chasfs_is_sb_rp_in_terminal_state
#
# Returns 0 if the standby rp state is the terminal state for
# the currently configured redundancy mode.
#
chasfs_is_sb_rp_in_terminal_state () {
    local red_mode_val=$(tr -d '\0' <${BINOS_BASE_DIR}/chasfs/mastership/red-mode)

    if [ -z "$red_mode_val" ]; then
        return 1
    fi

    case $red_mode_val in
        $MCP_RED_MODE_RPR)
            return $(chasfs_is_sb_rp_cold)
            ;;
        $MCP_RED_MODE_SSO)
            return $(chasfs_is_sb_rp_hot)
            ;;
    esac

    return 1;
}

# Check if ICS are in RPR ready state
chasfs_are_ics_in_rpr_ready_state () {
    l_location=$1
    l_state=""
    # l_location is space separated list of ICS locations
    for l_loc in ${l_location}; do
        l_chassis=$(chasfs_convert_location_to_chassis $l_loc)
        l_slot=$(echo "$l_loc" | cut -d'/' -f3)
        l_state_file="/tmp/chassis/$l_chassis/rp/chasfs/rp/$l_slot/state"
        l_state=$(head -n 1 $l_state_file)
        if [[ "$l_state" != "online" ]]; then
            return 1
        fi
    done
    return 0
}

chasfs_convert_chassis_all_ics_to_loc () {
   local l_chassis_num=$1
   local l_fru=$2
   local l_skip_location=$3
   local l_bay=0
   local l_resolved_locs=""
   local l_loc=""
   local state=""
   local maxslot=$(chasutil_chassis_max_slot $l_fru)

   btrace_notice "Request Recieved for chassis=$l_chassis_num, FRU=$l_fru and skip location=$l_skip_location"
   if [[ $l_fru = "rp" ]]; then
      for ((rpslot=0; rpslot <= $maxslot; rpslot++)); do
         if [ -s "/tmp/chassis/${l_chassis_num}/rp/chasfs/rp/$rpslot/rpr/state" ]; then
            state=$(head -n 1 /tmp/chassis/${l_chassis_num}/rp/chasfs/rp/${rpslot}/rpr/state)
            if [[ $state = "Ready" ]]; then
               l_loc=${l_chassis_num}/${l_fru}/$rpslot/${l_bay}
               if [[ "${l_loc}" != "${l_skip_location}" ]] && [ ! -z "${l_loc}" ]; then
                  l_resolved_locs="${l_resolved_locs} ${l_loc}"
               else
                  btrace_notice "skipping the location $l_loc"
               fi
            fi
          fi
      done
   fi
   btrace_notice "The Resolved locations is $l_resolved_locs"
   echo -n "$l_resolved_locs"
}

# Function to get resolved location for all ICSes
chasfs_get_all_ics_locations () {
    local l_compare_fn=$1
    local l_skip_location=$2
    local l_min_chassis_num
    local l_max_chassis_num
    local l_chassis_num
    local l_resolved_locs=""
    local l_loc

    if [ ! -s "${BINOS_CHASSIS_PATH}/${CHASFS_MIN_CHASSIS_NUMBER}" ]; then
        echo -n "${l_resolved_locs}"
        return
    fi

    if [ ! -s "${BINOS_CHASSIS_PATH}/${CHASFS_MAX_CHASSIS_NUMBER}" ]; then
        echo -n "${l_resolved_locs}"
        return
    fi

    l_min_chassis_num=$(cat ${BINOS_CHASSIS_PATH}/${CHASFS_MIN_CHASSIS_NUMBER})
    l_max_chassis_num=$(cat ${BINOS_CHASSIS_PATH}/${CHASFS_MAX_CHASSIS_NUMBER})

    for ((l_chassis_num = l_min_chassis_num;
          l_chassis_num <= l_max_chassis_num;
          l_chassis_num++)); do
        l_state_str="$BINOS_CHASSIS_PATH/$l_chassis_num/$CHASFS_CHASSIS_STATE"

        if [ -s "${l_state_str}" ]; then
            local l_state_val=$(cat ${l_state_str})
            if eval $l_compare_fn ${l_state_val}; then
                l_loc=$(chasfs_convert_chassis_all_ics_to_loc \
                        $l_chassis_num "rp" "$l_skip_location")
                if [ ! -z "${l_loc}" ]; then
                    l_resolved_locs="${l_resolved_locs} ${l_loc}"
                fi
            fi
        fi
    done
    echo -n "${l_resolved_locs}"
}

#
# chasfs_configured_red_mode_get_str
#
# Return a user-display string for the configured redundancy mode
#
chasfs_configured_red_mode_get_str () {
    local red_mode_val=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/red-mode)

    case "$red_mode_val" in
        $MCP_RED_MODE_NONE)     echo -n "none";;
        $MCP_RED_MODE_RPR)      echo -n "rpr";;
        $MCP_RED_MODE_RPR_PLUS) echo -n "rpr-plus";;
        $MCP_RED_MODE_SSO)      echo -n "sso";;
        *)                      echo -n "unknown";;
    esac
}

#
# chasfs_is_bay_stopped
#
# Checks for the existence of the "shutdown" property in
# the rp bay.  If it exists, 0 is returned, else 1.
chasfs_is_bay_stopped ()
{
    local bay=$1

    if [ -e "$BINOS_BASE_DIR/chasfs/rp/$bay/shutdown" ]; then
        return 0;
    fi

    return 1;
}

#
# chasfs_active_rp_hostname
#
# Returns the processed contents of the active-rp mastership 
# chasfs entry. The value is of the form "rp<slot>-<slot>".
# Typically used when role-based address of "rp-active" may
# be delayed in becoming effective. See /etc/hosts for mapping
chasfs_active_rp_hostname () {
    local active_rp_slot
    local slot_based_host

    active_rp_slot=$(chasfs_get_active_rp_slot)
    slot_based_host="rp$active_rp_slot-$active_rp_slot"
    # VWLC_HA : the following 'if' is temporary
    if [ -e $CPLD_DIR/board_vtype ]; then
        board_vtype=$(cat $CPLD_DIR/board_vtype)
        if [ "$board_vtype" = "VWLC" ]; then
            slot_based_host="rp$active_rp_slot-0"
        fi
    fi
    echo -n "$slot_based_host"
}

#
# chasfs_standby_rp_hostname
#
# Returns slot based hostname for standby RP.
# For hardware redundant chassis, the value is of the
# form "rp<slot>-<slot>".
# For non-redundant chassis, it will be "rp-standby".
# When used with rsync, caller should ensure function is
# invoked on hardware redundant chassis as rsync to
# "rp-standby" hostname is not supported.
chasfs_standby_rp_hostname () {
    local active_rp=0
    local standby_rp=1
    local slot_based_host="rp-standby"

    if chasfs_chassis_has_2_rp_slots; then
        active_rp=$(chasfs_get_active_rp_slot)
        if [[ $active_rp -eq 1 ]]; then
           standby_rp=0
        fi
        slot_based_host="rp$standby_rp-$active_rp"
    fi

    echo -n "$slot_based_host"
}

#
# chasfs_get_card_type
#
# Returns the (hex) card type value for the specified fru/slot
# or fru/slot/bay.
chasfs_get_card_type () {
    local fru_param=$1
    local slot_param=$2
    local bay_param=${3:-}

    local type_file
    local card_type=""

    if [ -z "$bay_param" ]; then
        type_file=${BINOS_BASE_DIR}/chasfs/${fru_param}/${slot_param}/type
    else
        type_file=${BINOS_BASE_DIR}/chasfs/${fru_param}/${slot_param}/${bay_param}/type
    fi

    if [ -e "$type_file" ]; then
        card_type=$(cat $type_file)
    fi

    echo -n "$card_type"
}

#
# chasfs_get_fpd_versions
#
# Returns the versions for the FPD bundles present in this card type.
#
chasfs_get_fpd_versions () {
    local slot_param=$1
    local bay_param=$2

    local versions_file
    local fpd_versions

    versions_file=${BINOS_BASE_DIR}/chasfs/cc/${slot_param}/${bay_param}/fpd_version

    if [ -e "$versions_file" ]; then
        fpd_versions=$(tr '\n' ';' < $versions_file)
    fi

    echo -n "$fpd_versions"
}

chasfs_get_mastership_dir () {
    echo -n "${BINOS_BASE_DIR}/chasfs/mastership"
}

chasfs_get_rp_mastership_file () {
    echo -n "active-rp"
}

chasfs_get_chasfs_dir () {
    echo -n "${BINOS_BASE_DIR}/chasfs"
}

#
# push_meta_files
#
# Push the meta files from this FRU over to the other fru.
#
# Prior to each rsync call make sure the 'eobc' vrf is set, to resolve
# proper tcpip addresses.
#
# Since its possible to run on the standby RP (in 6ru chassis) cannot rely
# on the chasfs library/scripts for detecting a fru's ability to rsync.
#
# Params:
#   $1 - the symlink of the source epoch to xfer out to the fru's
#   $2 - on_active = 1 then on active, = 0 then on standby
#
push_meta_files () {
    local meta_slot=$1
    local on_active_rp=$2
    local rphost=$(chasfs_standby_rp_hostname)
    local dest_fru_module="tdlresolve_dst/$meta_slot/"

    # on standby ? then push to active 
    if [[ "$on_active_rp" = "0" ]]; then
        rphost=$(chasfs_active_rp_hostname)
    fi

    # push only if other rp present and online 
    if platform_is_other_fru_ready "rp" ; then
        btrace_notice "Sync meta files directory to: $rphost/$dest_fru_module"

        rsync_out=$($MY_EOBC rsync -rptDlqOH /tmp/tdlresolve/$meta_slot/ \
                    rsync://$rphost/$dest_fru_module 2>&1)
        rc=$?
	if [[ $rc -ne 0 ]]; then
	    btrace_notice "When sync'ing to revisions lower than rls4 the following error is expected."
	    btrace_err $rsync_out
        fi
    fi
}

# chasfs_chassis_uses_psvp
#
# Utility routine that returns 0 (TRUE) if this chassis type uses
# the Process Senior VP (PSVP).
#
# This is useful for code that calls workon.sh as workon takes an
# extra FRU argument in that case.
chasfs_chassis_uses_psvp () {
    if chasfs_is_consolidated; then
        return 0;
    else
        return 1
    fi
}

# chasfs_chassis_supports_licensing
#
# Utility routine that returns 0 (TRUE) if this chassis type supports
# licensing.
chasfs_chassis_supports_licensing () {
    if chasfs_is_1ru; then
        return 0;
    else
        return 1
    fi
}

# chasfs_active_fp_hostname
#
# Returns slot based hostname for active FP.
chasfs_active_fp_hostname () {
    local active_rp
    local active_fp
    local slot_based_host="fp-active"

    active_rp=$(chasfs_get_active_rp_slot)
    if chasfs_fp_is_active 0 ; then
        slot_based_host=fp0-$active_rp
    elif chasfs_fp_is_active 1 ; then
        slot_based_host=fp1-$active_rp
    fi

    echo -n "$slot_based_host"
}

# chasfs_standby_fp_hostname
#
# Returns hostname for standby FP. For hardware redundant
# chassis, the value is of the form "fp<slot>-<active_eobc>".
chasfs_standby_fp_hostname () {
    local active_rp=0
    local active_fp
    local slot_based_host="fp-standby"

    if chasfs_chassis_has_2_rp_slots; then
        active_rp=$(chasfs_get_active_rp_slot)
        if chasfs_fp_is_active 0 ; then
            slot_based_host=fp1-$active_rp
        elif chasfs_fp_is_active 1 ; then
            slot_based_host=fp0-$active_rp
        fi
    fi
    echo -n "$slot_based_host"
}

#
# chasfs_active_cc_hostname
#
# Returns the processed contents of the active-rp mastership 
# chasfs entry. The value is of the form "cc<slot>-<slot>".
chasfs_active_cc_hostname () {
    local active_rp_slot
    local slot_based_host

    active_rp_slot=$(chasfs_get_active_rp_slot)
    slot_based_host="cc$active_rp_slot-$active_rp_slot"

    echo -n "$slot_based_host"
}

#
# chasfs_standby_cc_hostname
#
# Returns slot based hostname for standby CC.
# For hardware redundant chassis, the value is of the
# form "cc<slot>-<slot>".
# When used with rsync, caller should ensure function is
# invoked on hardware redundant chassis  that supports
# a notion of standby CC.
chasfs_standby_cc_hostname () {
    local active_rp=0
    local standby_rp=1
    local slot_based_host="cc-standby"

    #MCP_FIXME: revisit when chasfs is aware of UEA chassis
    if chasfs_chassis_has_2_rp_slots; then
        active_rp=$(chasfs_get_active_rp_slot)
        if [[ $active_rp -eq 1 ]]; then
           standby_rp=0
        fi
        slot_based_host="cc$standby_rp-$active_rp"
    fi

    echo -n "$slot_based_host"
}

# chasfs_cc_hostname
#
# Returns hostname for ASR1K CC.  The value is of the
# form "cc<slot>-<active_eobc>".
chasfs_cc_hostname () {
    local active_rp=0
    local slot_based_host

    active_rp=$(chasfs_get_active_rp_slot)
    slot_based_host=$1-$active_rp
    echo -n "$slot_based_host"
}

# chasfs_resolve_role_based_hostname
#
# Resolve a role based fru host name to a slot based host name
# caller should ensure notion of "<fru>-standby" is valid
# for the chassis
chasfs_resolve_role_based_hostname () {
    local fru_name=$1
    local host=$fru_name
    local active_rp=0
    local standby_rp=1

    case $fru_name in
        rp-active) host=$(chasfs_active_rp_hostname);;
        rp-standby) host=$(chasfs_standby_rp_hostname);;
        fp-active) host=$(chasfs_active_fp_hostname);;
        fp-standby) host=$(chasfs_standby_fp_hostname);;
        cc-active) host=$(chasfs_active_cc_hostname);;
        cc-standby) host=$(chasfs_standby_cc_hostname);;
        cc*) host=$(chasfs_cc_hostname $fru_name);;
    esac
    echo -n $host
}

#
# chassis_is_mcp_single_cpu
#
# Are we running on a mcp single cpu chassis type.
# No Params taken
#
chassis_is_mcp_single_cpu () {
    if chasfs_is_1ru; then
        return 0;
    elif chasfs_is_1ng; then
        return 0;
    elif chasfs_is_2kp; then
        return 0;
    elif chasfs_is_2kh; then
        return 0;
    elif chasfs_is_mach5; then
        return 0;
    elif chasfs_is_1gd; then
        return 0;
    elif chasfs_is_1en; then
        return 0;
    elif chasfs_is_1ac; then
        return 0;
    elif chasfs_is_ace; then
        return 0;
    elif chasfs_is_1rm; then
        return 0;
    elif chasfs_is_1sr; then
        return 0;
    elif chasfs_is_1gl; then
        return 0;
    elif chasfs_is_1gl_5g; then
        return 0;
    elif chasfs_is_2da; then
        return 0;
    elif chasfs_is_katar; then
        return 0;
    elif chasfs_is_fugazi; then
        return 0;
    elif chasfs_is_bender; then
        return 0;
    elif chasfs_is_fry; then
        return 0;
    elif chasfs_is_family_esg; then
        return 0;
    elif chasfs_is_family_ngwc; then
        return 0;
    elif chasfs_is_1wsp; then
        return 0;
    elif chasfs_is_1wkph; then
        return 0;
    elif chasfs_is_kakute; then
        return 0;
    else
        return 1
    fi
}

#
# Function to get the type of card residing in a slot.
#
chasfs_get_slot_type_string () {
    local l_slot=$1

    local l_ctype=$(cat /tmp/rp/chasfs/cc/$l_slot/type)
    #
    #  These values need to be updated whenever a new CC/ELC type is added.
    #
    case $l_ctype in
        7*) echo -n "elc";;
        *) echo -n "cc";;
    esac
}

# udev_harddisk_info
#
# update/sync harddisk info.
udev_harddisk_info () {
    local active_rp=$(chasfs_get_active_rp_slot)
    local active_rp_host="rp$active_rp-$active_rp"
    local rsync_output
    local rsync_res

    if [ "$ACTION" = "add" ]; then
        if [[ $BINOS_SLOT -ne $active_rp ]]; then
            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                rsync://$active_rp_host/$RSYNC_UDEVDIR/ $ACT_UDEVDIR \
                2>&1)
            rsync_res=$?
           
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync active udev from Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync active udev from $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi

            /bin/rm -r -f $ACT_UDEVDIR/stby-harddisk
            /bin/touch $ACT_UDEVDIR/exist_file_list
            ls $ACT_UDEVDIR/ >> $ACT_UDEVDIR/exist_file_list
            /bin/cp -rf $UDEVDIR/harddisk $ACT_UDEVDIR/stby-harddisk 

            rsync_output=$(rsync -r -p --timeout 5 -m \
                --exclude-from "$ACT_UDEVDIR/exist_file_list" \
                $ACT_UDEVDIR/ rsync://$active_rp_host/$RSYNC_UDEVDIR  \
                2>&1)
            /bin/rm -r -f $ACT_UDEVDIR/exist_file_list
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync standby harddisk to Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync standby harddisk to $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi
        fi              
     elif [ "$ACTION" = "remove" ]; then
        if [[ $BINOS_SLOT -ne $active_rp ]]; then
            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                rsync://$active_rp_host/$RSYNC_UDEVDIR/ $ACT_UDEVDIR \
                2>&1)
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync active udev from Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync active udev from $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi

            /bin/rm -r -f $ACT_UDEVDIR/stby-harddisk 

            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                '--include=stby-harddisk**' '--exclude=*' \
                $ACT_UDEVDIR/ rsync://$active_rp_host/$RSYNC_UDEVDIR  \
                2>&1)
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync standby harddisk to Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync standby harddisk to $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi
        fi              
    fi
}

#
# chasfs_global_location_to_hostname
#
# convert a location of the form <chassis>/<fru>/<slot/<bay> to
# "<fru>-<chassis>-<slot>-<slot>".
# Caller needs to provide a valid string.
chasfs_global_location_to_hostname () {
    local l_location_str=$1
    local l_chassis
    local l_fru
    local l_slot
    local l_hostname=""

    l_chassis=$(echo $l_location_str | cut -d / -f 1)
    l_fru=$(echo $l_location_str | cut -d / -f 2)
    l_slot=$(echo $l_location_str | cut -d / -f 3)

    if [[ -n "$l_chassis" && -n "$l_fru" && -n "$l_slot" ]]; then
        if [[ "$l_chassis" = "local" ]]; then
            #POLARIS_FIXME, if this is ever enabled for mcp, then
            #eobc of hostname must be adjusted for the active rp.
            l_hostname=$l_fru-$l_slot-$l_slot
        else 
            l_hostname=$l_fru-$l_chassis-$l_slot-$l_slot
        fi
    fi

    echo -n "$l_hostname"
}

#
# chasfs_global_mastership_to_chassisnum
#
# Returns the chassis number from the global mastership
# chasfs entry. Caller needs to provide a valid string.
chasfs_global_mastership_to_chassisnum () {
    local mastership_str=$1
    local l_chassis

    l_chassis=$(echo $mastership_str | cut -d / -f 1)
    echo -n "$l_chassis"
}

#
# chasfs_global_mastership_get_slot
#
# Returns the slot number from the global mastership
# chasfs entry. Caller needs to provide a valid string.
chasfs_global_mastership_get_slot () {
    local mastership_str=$1
    local l_slot

    l_slot=$(echo $mastership_str | cut -d / -f 3)
    echo -n "$l_slot"
}


#
# chasfs_get_target_name
#
# This function changes fs_target name from "stby-<fs>" to 
# "<fs>-<chassis_no>-<rp_num>" format for Macallan/Starfleet platform.
# For all other platforms fs_target is unchanged.
#
chasfs_get_target_name () {
    local PLATFORM_TYPE=$1
    local fs_target=$2
    local fs_command=$3
    local sv_mode
    local board_subtype

    board_subtype=$(cat $CPLD_DIR/board_subtype)
    board_vtype=$(cat $CPLD_DIR/board_vtype)
    if [[ $PLATFORM_TYPE = "starfleet" && $fs_target = "flash" ]]; then
        fs_target="bootflash"
    fi

    if [[ $PLATFORM_TYPE == "petra" || $PLATFORM_TYPE == "hellcat" || $PLATFORM_TYPE == "rio" ||
          $board_subtype = "CONDOR" ||
          $board_subtype = "CLARKE_ADV" ||
          $board_subtype = "CLARKE_LITE" ||
          $board_subtype = "SONIC" ]]; then
        if [[ $fs_target == "bootflash" ]]; then
            fs_target="flash"
        fi
    fi

    if [[ $board_subtype = "CLARKE_ADV" ]]; then

        if [[ $fs_target = stby* ]]; then
            local g_standby_rp=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-standby-rp)

            if [[ -n "$g_standby_rp" ]]; then
                local standby_chassid=$(chasfs_global_mastership_to_chassisnum "$g_standby_rp")

                fs_target=${fs_target:5}
                fs_target="$fs_target-$standby_chassid"
            fi
        else
            local g_active_rp=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-active-rp)

            if [[ -n "$g_active_rp" ]]; then
                local active_chasid=$(chasfs_global_mastership_to_chassisnum "$g_active_rp")

                #if target comes with active chassis ID, then remove -chassisId from the target name
                if [[ $fs_target = *-$active_chasid ]]; then
                    fs_target=${fs_target%-$active_chasid}
                fi
            fi
        fi
    fi

    if [[ $fs_target = stby* ]]; then
        if [[ $board_subtype = "QUAKE1" ||
              $board_subtype = "QUAKE2" ||
              ($fs_command = "show" && $PLATFORM_TYPE = "mcp"  &&
               (($BOARD_SUBTYPE = "VXE" && "$BOARD_VTYPE" = "VWLC") || # for vWLC
                ($BOARD_SUBTYPE = "1GL" || # for qWLC/Gladius
                 $BOARD_SUBTYPE = "2DA" || # for Dao
                 $BOARD_SUBTYPE = "KATAR" || # for KATAR
                 $BOARD_SUBTYPE = "KAKUTE" || # for KAKUTE
                 $BOARD_SUBTYPE = "1WSP" || # for 1WSP
                 $BOARD_SUBTYPE = "1WKPH"))) ]]; then # for 1WKPH
            local chassid=$(chasfs_get_rp_standby_chassisnum)
            fs_target=${fs_target:5}
            fs_target="$fs_target-$chassid"
        fi
    fi

    #File system mapping for VPCGW variant
    if [[ $BOARD_SUBTYPE = "VXE" && "$BOARD_VTYPE" = "VPCGW" ]]; then
        if [[ $fs_target = "flash" || $fs_target = "crashinfo" ]]; then
            fs_target="bootflash"
        fi
    fi

    if [[ $PLATFORM_TYPE = "ngmod" || $PLATFORM_TYPE = "starfleet" ||
         $PLATFORM_TYPE = "bigbang" ]]; then
        sv_mode=$(cyan_get_value $CHASSIS_ATTRS_STACKWISE_VIRTUAL_MODE) 
        if [[ $? != 0 ]]; then    
            sv_mode="false"
        fi
        if [[ $fs_target = stby* ]]; then
            # Removing "stby-" from fs_target
            fs_target=${fs_target:5}
            if [[ $sv_mode = "true" ]]; then
               stby_rp_str=$(cat $CHASFS_MASTERSHIP_PATH/$CHASFS_GLOBAL_STANDBY_RP)
               local chassid=$(chasfs_get_rp_standby_chassisnum)
               [ -z "$chassid" ] && { echo -n ""; return 1; }
               global_stby_rp=$(chasfs_global_mastership_get_slot $stby_rp_str)
                  if [[ $BOARD_SUBTYPE = "PROMETHEUS" ||
                        $BOARD_SUBTYPE = "GRYPHON" ||
                        $BOARD_SUBTYPE = "GRYPHON_LITE" ||
                        $BOARD_SUBTYPE = "SKYFOX" ]]; then 
                  fs_target="$fs_target-$chassid"
               else
                  fs_target="$fs_target-$chassid-$global_stby_rp"
               fi
            else 
                stby_rp=$(chasfs_get_standby_rp_slot)
                fs_target="$fs_target-1-$stby_rp"
            fi
        elif [[ $fs_target = "flash" ]]; then
            fs_target="bootflash"
        fi
    fi
    if [[ $PLATFORM_TYPE = "symphony" ||  $board_subtype = "NYQUIST" ]]; then
        if [ $fs_target = "bootflash" ]; then
             fs_target="flash"
        fi
    fi
    echo -n "$fs_target"
}

#
# chasfs_global_active_rp_hostname
#
# Returns the processed contents of the fru hosting the active rp
# control plane. The value is of the form "rp<slot>-<eobc>" for platforms
# that do not support multi-chassis/stacking. For such platforms
# the value is of the form "rp-<chassis>-<slot>-<eobc>".
# for all the supported platforms yet, eobc maps to slot#.
chasfs_global_active_rp_hostname () {
    local active_rp_str
    local hostname=""
    
    if ! chasfs_is_family_stacking; then
	hostname=$(chasfs_active_rp_hostname)
	echo -n $hostname
	return
    fi

    active_rp_str=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-active-rp)

    if [ -z "${active_rp_str}" ]; then
	echo -n $hostname
        return
    fi

    hostname=$(chasfs_global_location_to_hostname $active_rp_str)
    echo -n "$hostname"
}

#
# chasfs_global_standby_rp_hostname
#
# Returns the processed contents of the fru hosting the standby rp
# control plane. The value is of the form "rp<slot>-<eobc>" for platforms
# that do not support multi-chassis/stacking. For such platforms
# the value is of the form "rp-<chassis>-<slot>-<eobc>".
# for all the supported platforms yet, eobc maps to slot#.
chasfs_global_standby_rp_hostname () {
    local standby_rp_str
    local hostname=""
    
    if ! chasfs_is_family_stacking; then
        # no chassis based, return in-chassis hostname
        hostname=$(chasfs_standby_rp_hostname)
        echo -n $hostname
        return
    fi

    # for platforms that dont have this property?
    if [ ! -e "${BINOS_BASE_DIR}/chasfs/mastership/global-standby-rp" ]; then
        echo -n ""
        return
    fi

    standby_rp_str=$(cat ${BINOS_BASE_DIR}/chasfs/mastership/global-standby-rp)

    if [ -z "${standby_rp_str}" ]; then
        echo -n $hostname
        return
    fi

    hostname=$(chasfs_global_location_to_hostname $standby_rp_str)
    echo -n "$hostname"
}
#
# chasfs_location_resolved
#
# basic sanity
#  - chassis number known
#  - global active role resolved
#
chasfs_location_resolved () {
    local chassis_num_str=${BINOS_CHASSIS_PATH}/${CHASFS_LOCAL_CHASSIS_NUMBER}
    local g_active_rp_str=${CHASFS_MASTERSHIP_PATH}/${CHASFS_GLOBAL_ACTIVE_RP}

    if [[ -s ${chassis_num_str} &&
          -s ${g_active_rp_str} ]]; then
        return 0
    fi
    return 1
}

#
# chasfs_rp_is_global_active
#
# Is the local rp global active
#
chasfs_rp_is_global_active () {
    local g_active_rp
    local chassis_num
    local chassis_num_str=${BINOS_CHASSIS_PATH}/${CHASFS_LOCAL_CHASSIS_NUMBER}
    local g_active_rp_str=${CHASFS_MASTERSHIP_PATH}/${CHASFS_GLOBAL_ACTIVE_RP}
    local chassis_fru_str

    if chasfs_location_resolved ; then
        chassis_num=$(cat ${chassis_num_str})
        chassis_fru_str=${chassis_num}/rp/$SLOT/$BAY
        g_active_rp=$(cat ${g_active_rp_str})
        if [[ ${chassis_fru_str} = ${g_active_rp} ]] ; then
            return 0
        fi
    fi
    
    return 1
}

#
# get standby rp chassis num
#
chasfs_get_rp_standby_chassisnum () {
    local g_standby_rp_str=${CHASFS_MASTERSHIP_PATH}/${CHASFS_GLOBAL_STANDBY_RP}
    local g_standby_rp
    local standby_chassis_id=-1

    if [ -e "$g_standby_rp_str" ]; then
        g_standby_rp=$(cat ${g_standby_rp_str})
        standby_chassis_id=$(chasfs_global_mastership_to_chassisnum "$g_standby_rp")
        echo -n ${standby_chassis_id}
        return 0
    fi

    return 1
}

#
# get active rp chassis num
#
chasfs_get_rp_active_chassisnum () {
    local g_active_rp_str=${CHASFS_MASTERSHIP_PATH}/${CHASFS_GLOBAL_ACTIVE_RP}

    if [ -e "$g_active_rp_str" ]; then
        local g_active_rp=$(cat ${g_active_rp_str})
        local active_chassis_id=$(chasfs_global_mastership_to_chassisnum "$g_active_rp")

        echo -n ${active_chassis_id}
        return 0
    fi

    return 1
}

# chasfs_global_location
#
# returns a fully qualified location. if chassis is not resolved fully
# for stacked platforms, then chassis number part is -1.
#
chasfs_global_location () {
    local l_chassis_num="local"
    local l_chassis_num_str=${BINOS_CHASSIS_PATH}/${CHASFS_LOCAL_CHASSIS_NUMBER}
    local l_fru=$FRU
    local l_slot=$SLOT
    local l_bay=$BAY
    local l_resolved_loc=""

    if chasfs_is_family_stacking || chasfs_is_family_coral; then
        if chasfs_location_resolved ; then
            l_chassis_num=$(cat ${l_chassis_num_str})
        else
            return 1
        fi
    fi
    l_resolved_loc=${l_chassis_num}/${l_fru}/${l_slot}/${l_bay}

    echo -n "$l_resolved_loc"
    return 0
}

#
# chasfs_convert_chassis_to_location
#
# helper function to convert a chassis id to location. 
chasfs_convert_chassis_to_location () {
    local l_chassis_num=$1
    local l_fru=$2
    local l_slot=$3
    local l_bay=$4
    local l_resolved_loc

    if [[ $l_fru = "rp" ]] && [ -s "/tmp/chassis/${l_chassis_num}/rp_slot" ]; then
        if [ -s "/tmp/chassis/$l_chassis_num/rp/chasfs/rp/$l_slot/state" ]; then
            # Check if passed chassis-slot is online and if so then only use it
            local l_slot_state=$(cat /tmp/chassis/$l_chassis_num/rp/chasfs/rp/$l_slot/state)
            if [[ $l_slot_state != "online" ]]; then
                l_slot=$(cat /tmp/chassis/${l_chassis_num}/rp_slot)
            fi
        else
            l_slot=$(cat /tmp/chassis/${l_chassis_num}/rp_slot)
        fi
    fi
    l_resolved_loc=${l_chassis_num}/${l_fru}/${l_slot}/${l_bay}

    echo -n "$l_resolved_loc"
}

#Given a chassis number this function provides the location
#address for all FRUs in a system. If there is a skip request
#is provided particular FRU will be skipped. 
chasfs_convert_chassis_all_frus_to_loc () {
   local l_chassis_num=$1
   local l_fru=$2
   local l_skip_location=$3
   local l_bay=0
   local l_resolved_locs=""
   local l_loc=""
   local state
   local state_file
   local ics_state
   local maxslot=$(chasutil_chassis_max_slot $l_fru)
   
   btrace_notice "Request Recieved for chassis=$l_chassis_num, FRU=$l_fru and skip location=$l_skip_location" 
   if [[ $l_fru = "rp" ]]; then
      for ((rpslot=0; rpslot <= $maxslot; rpslot++)); do
         if [ -s "/tmp/chassis/${l_chassis_num}/rp/chasfs/rp/$rpslot/state" ]; then
            state=$(cat /tmp/chassis/${l_chassis_num}/rp/chasfs/rp/$rpslot/state)
            if [[ $state = "online" ]]; then
               l_loc=${l_chassis_num}/${l_fru}/$rpslot/${l_bay}
               if [[ "${l_loc}" != "${l_skip_location}" ]]; then
                  l_resolved_locs="${l_resolved_locs} ${l_loc}"
               else
                  btrace_notice "skipping the location $l_loc"
               fi 
            fi
        elif [ -s "/tmp/chassis/${l_chassis_num}/state" ] && chasfs_is_family_stacking; then
            # This is for non SVL stacking platforms which doesn't have 'rp/chasfs/rp/$rpslot/state'
            #Consider only the inserted slot
            btrace_notice "generating resolved location for regular stacking platformi chassis"
            if [ ! -s "/tmp/chassis/${l_chassis_num}/rp/chasfs/rp/$rpslot" ]; then
                continue
            fi

            if [[ $(cyan_get_value $CHASSIS_ATTRS_QUAD_SUP_SVL_MODE) == "true" ]]; then
                #CSCvq47936 creates the /tmp/chassis/${l_chassis_num}/rp/chasfs/rp/$rpslot path
                # even if ICS is not present due to auto upgrade requirements.
                # Blocking if ICS is not present here as it may result into CSCwe69412
                state_file="/tmp/chassis/$l_chassis/rp/chasfs/rp/$rpslot/state"
                if [ ! -f $state_file ]; then
                    #If state file doesnt exist , skip adding as ICS is not present
                    continue
                else
                    ics_state=$(head -n 1 $state_file)
                    if [[ "$ics_state" != "online" ]]; then
                        #Skip if ICS is not in ready state
                        continue
                   fi 
               fi
            fi

            state=$(cat /tmp/chassis/${l_chassis_num}/state)
            if [[ $state = "compatible" || $state = "incompatible" ]]; then
                l_loc=${l_chassis_num}/${l_fru}/$rpslot/${l_bay}
                if [[ "${l_loc}" != "${l_skip_location}" ]]; then
                    l_resolved_locs="${l_resolved_locs} ${l_loc}"
                else
                    btrace_notice "skipping the location $l_loc"
                fi
            fi
        elif chasfs_is_mcp_chassis && ! chasfs_is_family_stacking; then
                # This is for asr1k type platforms
                # Need to exclude the stacking family for platforms such as QWLC which
                #  are both considered mcp_chassis and family_stacking.
                if [ -s "/tmp/chassis/local/rp/chasfs/rp/$rpslot/$l_bay/state" ]; then
                    state=$(cat /tmp/chassis/local/rp/chasfs/rp/$rpslot/$l_bay/state)
                    if [[ $state = "online" ]]; then
                        l_loc=${l_chassis_num}/${l_fru}/$rpslot/${l_bay}
                        if [[ "${l_loc}" != "${l_skip_location}" ]]; then
                            l_resolved_locs="${l_resolved_locs} ${l_loc}"
                        else
                            btrace_notice "skipping the location l_loc"
                        fi
                    fi
                fi
        fi
      done
   fi
   btrace_notice "The Resolved locations are $l_resolved_locs" 
   echo -n "$l_resolved_locs" 
}

chasfs_convert_location_to_chassis () {
    local l_location=$1
    local l_chassis=$(echo $l_location | cut -d "/" -f 1)

    echo -n "${l_chassis}"

    return 0
}

#
# chasfs_convert_location_to_brelay_addr
#
chasfs_convert_location_to_brelay_addr () {
    local l_location=$1
    local l_chassis
    local l_fru
    local l_slot
    local l_brelay_addr=""

    l_chassis=$(echo $l_location | cut -d / -f 1)
    l_fru=$(echo $l_location | cut -d / -f 2)
    l_slot=$(echo $l_location | cut -d / -f 3)

    if [[ -n "$l_chassis" && -n "$l_fru" && -n "$l_slot" ]]; then
        if [[ "$l_fru" = "rp" ]]; then
           l_brelay_addr="route-processor $l_slot"
        elif [[ "$l_fru" = "fp" ]]; then
            l_brelay_addr="forwarding-processor $l_slot"
        elif [[ "$l_fru" = "cc" ]]; then
            l_brelay_addr="sip-processor $l_slot"
        elif [[ "$l_fru" = "bp" ]]; then
            l_brelay_addr="bootstrap-plane $l_slot"
        else
            return
        fi

        if [[ $l_chassis != "local" ]]; then
           l_brelay_addr="chassis ${l_chassis} ${l_brelay_addr}"
        fi
    fi

    echo -n "$l_brelay_addr"
}

# display location string. platforms can customize here whatever
# location to display they need.
chasfs_location_to_display_str () {
    local location=$1
    local l_chassis
    local l_fru
    local l_slot
    local display_str=""

    l_chassis=$(echo $location | cut -d / -f 1)
    l_fru=$(echo $location | cut -d / -f 2)
    l_slot=$(echo $location | cut -d / -f 3)

    if [[ -n "$l_chassis" && -n "$l_fru" && -n "$l_slot" ]]; then
        if chasfs_is_family_ngwc; then
            display_str="switch ${l_chassis}"
        elif chasfs_is_family_coral; then
            display_str="CORAL ${l_chassis}"
        elif [[ $(cyan_get_value $CHASSIS_ATTRS_REMOTE_CHASSIS_HA) = "true" ]]; then
            display_str="chassis ${l_chassis}/R$l_slot" 
        else 
           if [[ "$l_fru" = "rp" ]]; then
              display_str="R$l_slot"
           elif [[ "$l_fru" = "fp" ]]; then
               display_str="F$l_slot"
           elif [[ "$l_fru" = "cc" ]]; then
               display_str="SIP$l_slot"
           fi
        fi
    fi

    echo -n "$display_str"
}

# Display location string. 
# R0/R1 on Modular platforms
# 1/2/3 on switching platforms
chasfs_location_to_display_short_str () {
    local location=$1
    local l_chassis
    local l_fru
    local l_slot
    local display_str=""

    l_chassis=$(echo $location | cut -d / -f 1)
    l_fru=$(echo $location | cut -d / -f 2)
    l_slot=$(echo $location | cut -d / -f 3)

    if [[ -n "$l_chassis" && -n "$l_fru" && -n "$l_slot" ]]; then
        if [[ $(cyan_get_value $CHASSIS_ATTRS_REMOTE_CHASSIS_HA) = "true" ]]; then
            display_str="${l_chassis}/R$l_slot"
        elif chasfs_is_family_stacking || chasfs_is_family_coral; then
            display_str="${l_chassis}"
        else
            if [[ "$l_fru" = "rp" ]]; then
                display_str="R$l_slot"
            elif [[ "$l_fru" = "fp" ]]; then
                display_str="F$l_slot"
            elif [[ "$l_fru" = "cc" ]]; then
                display_str="SIP$l_slot"
            fi
        fi
    fi
    btrace_notice "Converting location [$location] to str [$display_str]"
    echo -n "$display_str"
}

#
# chasfs_local_chassisnum
#
# returns a fully qualified location. if chassis is not resolved fully
# for stacked platforms, then chassis number part is -1.
#
chasfs_local_chassisnum () {
    local chassis_num=""
    local chassis_num_str=${BINOS_CHASSIS_PATH}/${CHASFS_LOCAL_CHASSIS_NUMBER}
    local resolved_loc=""

    if chasfs_is_family_stacking; then
        if chasfs_location_resolved ; then
            chassis_num=$(cat ${chassis_num_str})
        else
            return 1
        fi
    fi
    echo -n "$chassis_num"
    return 0
}

#
# chasfs_global_active_rp_location
#
# determine the location of global active rp
chasfs_global_active_rp_location () {
    local l_active_rp_str=""

    if chasfs_is_family_stacking || chasfs_is_family_coral; then
        if chasfs_location_resolved ; then
            if [ -e "$CHASFS_MASTERSHIP_PATH/$CHASFS_GLOBAL_ACTIVE_RP" ]; then
                l_active_rp_str=$(cat $CHASFS_MASTERSHIP_PATH/$CHASFS_GLOBAL_ACTIVE_RP)
            else
                return 1
            fi
        else
            return 1
        fi
    else
        if [ -e "$CHASFS_MASTERSHIP_PATH/active-rp" ]; then
            l_active_rp_str=local/$(cat $CHASFS_MASTERSHIP_PATH/active-rp)
        else
             return 1
        fi
    fi

    echo -n "$l_active_rp_str"
    return 0
}

#
# chasfs_global_standby_rp_location
#
# determine the location of global standby rp
chasfs_global_standby_rp_location () {
    local l_standby_rp_str=""

    if chasfs_is_family_stacking || chasfs_is_family_coral; then
        if chasfs_location_resolved ; then
            if [ -e "$CHASFS_MASTERSHIP_PATH/$CHASFS_GLOBAL_STANDBY_RP" ]; then
                l_standby_rp_str=$(cat $CHASFS_MASTERSHIP_PATH/$CHASFS_GLOBAL_STANDBY_RP)
            else
                return 1
            fi
        else
            return 1
        fi
    else
        if [ -e "$CHASFS_MASTERSHIP_PATH/standby-rp" ]; then
            l_standby_rp_str=local/$(cat $CHASFS_MASTERSHIP_PATH/standby-rp)
        else
             return 1
        fi
    fi

    if [ -n "$l_standby_rp_str" ]; then
         echo -n "$l_standby_rp_str"
         return 0
    else
         return 1
    fi
}

# checks if the state is not compatible, may not be a terminal state
# Created is a state at provision. This is a state where the member is down
# It is not compatible nor non compatible. Dont consider it in the not comp list.
chasfs_not_compatible_compare_fn () {
    local l_arg1=$1

    if [[ "${l_arg1}" != "compatible" ]] &&
       [[ "${l_arg1}" != "created" ]]; then
       return 0
    fi

    return 1
}

# checks if the state is compatible (a terminal state)
chasfs_compatible_compare_fn () {
    local l_arg1=$1

    if [[ "${l_arg1}" = "compatible" ]]; then
       return 0
    fi

    return 1
}

chasfs_comm_up_compare_fn () {
    local l_arg1=$1

    if [[ "${l_arg1}" = "compatible" ||
          "${l_arg1}" = "comm_up" ]]; then
       return 0
    fi

    return 1
}

# chasfs_get_all_rp_locations
#
# determine the location of all rps
# $1: chassis state
# $2: skip location
chasfs_get_all_rp_locations () {
    local l_compare_fn=$1
    local l_skip_location=$2
    local l_min_chassis_num
    local l_max_chassis_num
    local l_chassis_num
    local l_resolved_locs=""
    local l_loc
    local skip_compatible_check=false
    if [ ! -z "${3:-}" ]; then
        skip_compatible_check=$3
    fi

    if [ ! -s "${BINOS_CHASSIS_PATH}/${CHASFS_MIN_CHASSIS_NUMBER}" ]; then
        if chasfs_is_mcp_chassis; then
            l_resolved_locs=$(chasfs_convert_chassis_all_frus_to_loc "1" "rp" "$l_skip_location")
        fi
        echo -n "${l_resolved_locs}"
        return
    fi

    if [ ! -s "${BINOS_CHASSIS_PATH}/${CHASFS_MAX_CHASSIS_NUMBER}" ]; then
        echo -n "${l_resolved_locs}"
        return
    fi

    l_min_chassis_num=$(cat ${BINOS_CHASSIS_PATH}/${CHASFS_MIN_CHASSIS_NUMBER})
    l_max_chassis_num=$(cat ${BINOS_CHASSIS_PATH}/${CHASFS_MAX_CHASSIS_NUMBER})

    for ((l_chassis_num = l_min_chassis_num;
          l_chassis_num <= l_max_chassis_num;
          l_chassis_num++)); do
        l_state_str="$BINOS_CHASSIS_PATH/$l_chassis_num/$CHASFS_CHASSIS_STATE"

        if [ -s "${l_state_str}" ]; then
            local l_state_val=$(cat ${l_state_str})
            if eval $l_compare_fn ${l_state_val} || [[ "$skip_compatible_check" = true ]]; then
               if [[ $(cyan_get_value $CHASSIS_ATTRS_QUAD_SUP_SVL_MODE ) = "true" ]] || [[ "$skip_compatible_check" = true ]]; then
                  l_loc=$(chasfs_convert_chassis_all_frus_to_loc \
                        $l_chassis_num "rp" "$l_skip_location")
                  l_resolved_locs="${l_resolved_locs} ${l_loc}"
               else
                  l_loc=$(chasfs_convert_chassis_to_location \
                               $l_chassis_num rp 0 0)
                  if [[ "${l_loc}" != "${l_skip_location}" ]]; then
                    l_resolved_locs="${l_resolved_locs} ${l_loc}"
                  fi
               fi 
            fi
        fi
    done
    echo -n "${l_resolved_locs}"
}

# chasfs_get_all_compatible_rp_locations
# $1: skip location
chasfs_get_all_compatible_rp_locations () {
    local l_skip_location=$1
    local l_resolved_locs
    l_resolved_locs=$(chasfs_get_all_rp_locations \
                      chasfs_compatible_compare_fn "${l_skip_location}")
    echo -n "${l_resolved_locs}"
}

# chasfs_get_all_comm_up_rp_locations
# $1: skip location
chasfs_get_all_comm_up_rp_locations () {
    local l_skip_location=$1
    local l_resolved_locs
    l_resolved_locs=$(chasfs_get_all_rp_locations \
                      chasfs_comm_up_compare_fn "${l_skip_location}")
    echo -n "${l_resolved_locs}"
}

# chasfs_get_all_not_compatible_rp_locations
# $1: skip location
chasfs_get_all_not_compatible_rp_locations () {
    local l_state_val=$1
    local l_resolved_locs
    l_resolved_locs=$(chasfs_get_all_rp_locations \
                      chasfs_not_compatible_compare_fn "${l_state_val}")
    echo -n "${l_resolved_locs}"
}

# udev_usb_info
#
# update/sync usb info.
udev_usb_info () {
    local active_rp=$(chasfs_get_active_rp_slot)
    local active_rp_host="rp$active_rp-$active_rp"
    local rsync_output
    local rsync_res
    local usb_id=$1
    
    if [ "$usb_id" != "usb0" ] && [ "$usb_id" != "usb1" ]; then
        return
    fi

    if [ "$ACTION" = "add" ]; then
        if [[ $BINOS_SLOT -ne $active_rp ]]; then
            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                rsync://$active_rp_host/$RSYNC_UDEVDIR/ $ACT_UDEVDIR \
                2>&1)
            rsync_res=$?
           
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync active udev from Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync active udev from $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi

            /bin/rm -r -f $ACT_UDEVDIR/stby-$usb_id
            /bin/touch $ACT_UDEVDIR/exist_file_list
            ls $ACT_UDEVDIR/ >> $ACT_UDEVDIR/exist_file_list
            /bin/cp -rf $UDEVDIR/$usb_id $ACT_UDEVDIR/stby-$usb_id 

            rsync_output=$(rsync -r -p --timeout 5 -m \
                --exclude-from "$ACT_UDEVDIR/exist_file_list" \
                $ACT_UDEVDIR/ rsync://$active_rp_host/$RSYNC_UDEVDIR  \
                2>&1)
            /bin/rm -r -f $ACT_UDEVDIR/exist_file_list
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync standby $usb_id to Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync standby $usb_id to $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi
        fi              
     elif [ "$ACTION" = "remove" ]; then
        if [[ $BINOS_SLOT -ne $active_rp ]]; then
            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                rsync://$active_rp_host/$RSYNC_UDEVDIR/ $ACT_UDEVDIR \
                2>&1)
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync active udev from Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync active udev from $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi

            /bin/rm -r -f $ACT_UDEVDIR/stby-$usb_id

            rsync_output=$(rsync -r -p --timeout 5 -m --delete \
                --include=stby-"$usb_id"** '--exclude=*' \
                $ACT_UDEVDIR/ rsync://$active_rp_host/$RSYNC_UDEVDIR  \
                2>&1)
            rsync_res=$?
            if [[ $rsync_res -ne 0 ]]; then
                echo "rsync standby $usb_id to Active RP failed:" \
                     " $rsync_res, $rsync_output"    
                btrace_err "rsync standby $usb_id to $active_rp_host failed:"
                btrace_err "rc=$rsync_res, $rsync_output"
            fi
        fi              
    fi
}

# Read LCHA related chasfs properties

readonly LCHA_UNKNOWN_CARD=-1
readonly LCHA_UNKNOWN_GROUP=-1

chasfs_get_lcha_property () {
    local l_path=${BINOS_BASE_DIR}/chasfs/mastership/cc/$1/$2

    if [ -e "$l_path" ]; then
        cat $l_path
    else
        echo ""
    fi
}


chasfs_get_card_role () {
    local l_role=$(chasfs_get_lcha_property $1 "role")
    if [[ $l_role = "" ]]; then
        l_role="undefined"
    fi
    echo $l_role
}


chasfs_get_card_mode () {
    local l_mode=$(chasfs_get_lcha_property $1 "mode")
    if [[ $l_mode = "" ]]; then
        l_mode="undefined"
    fi
    echo $l_mode
}


chasfs_get_card_ready () {
    local l_ready=$(chasfs_get_lcha_property $1 "ready")
    if [[ $l_ready = "" ]]; then
        l_ready="false"
    fi
    echo $l_ready
}


chasfs_get_card_protected () {
    local l_protected=$(chasfs_get_lcha_property $1 "protected")
    if [[ $l_protected = "" ]]; then
        l_protected="false"
    fi
    echo $l_protected
}


chasfs_get_card_switchover () {
    local l_switchover=$(chasfs_get_lcha_property $1 "switchover")
    if [[ $l_switchover = "" ]]; then
        l_switchover="not-in-progress"
    fi
    echo $l_switchover
}


chasfs_get_card_reconciliation () {
    local l_reconciliation=$(chasfs_get_lcha_property $1 "reconciliation")
    if [[ $l_reconciliation = "" ]]; then
        l_reconciliation="not-in-progress"
    fi
    echo $l_reconciliation
}


chasfs_get_card_peer () {
    local l_peer=$(chasfs_get_lcha_property $1 "peer")
    if [[ $l_peer = "" ]]; then
        l_peer="none"
    fi
    echo $l_peer
}


chasfs_get_card_group () {
    local l_group=$(chasfs_get_lcha_property $1 "group")
    if [[ $l_group = "" ]]; then
        l_group="none"
    fi
    echo $l_group
}

chasfs_is_tan_log_coll_present () {
    test -e ${BINOS_BASE_DIR}/chasfs/tan/log-collector
}

#
# Read the ROMMON Capability bits
#
get_capability_bits () {
    local rc=
    local __resultvar=$1

    get_capability_bits=$($FLASHUTIL_EXEC_PATH --command getcapbits 2>&1)
    rc=$?

    if [[ $rc -eq 0 ]]; then
        eval $__resultvar="'$get_capability_bits'"
    fi

    return $rc
}

chasfs_get_physical_active_slot () {
    local active_rp_slot=$(chasfs_get_active_rp_slot)
    local physical_rp_slot
    if chasfs_is_macallan_4slot; then
       if [[ $active_rp_slot -eq 0 ]]; then
           physical_rp_slot=2
       else
           physical_rp_slot=3
       fi
    elif chasfs_is_macallan_7slot; then
       if [[ $active_rp_slot -eq 0 ]]; then
           physical_rp_slot=3
       else
           physical_rp_slot=4
       fi
    elif chasfs_is_macallan_10slot; then
       if [[ $active_rp_slot -eq 0 ]]; then
           physical_rp_slot=5
       else
           physical_rp_slot=6
       fi
    elif chasfs_is_discovery; then
       if [[ $active_rp_slot -eq 0 ]]; then
           physical_rp_slot=5
       else
           physical_rp_slot=6
       fi
    fi
    echo -n "$physical_rp_slot"
}

# Get the Platform's support for SPI Prom Upgrade.
# Returns 0 if supported, 1 otherwise.
chasfs_supports_spiprom_upgrade() {
    local supports=1
    local spiprom_upgrade

    # Get the THIS.SPIPROM_UPGRADE value set in the .lua file.
    spiprom_upgrade="$(cyan_get_value "${CHASSIS_ATTRS_SPIPROM_UPGRADE}")"

    # If the value is explicitly "true", then set the "supported" state (zero)
    if [[ "${spiprom_upgrade}" == "true" ]]; then
        supports=0
    fi

    return $supports
}
