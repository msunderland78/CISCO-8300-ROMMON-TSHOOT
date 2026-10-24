#!/bin/bash
#
# Hardware Abstraction Layer
# Herein lies Crankshaft platform dependent functions
#
# March 2014, Conan Huang
#
# Hardware utility shell functions that require information about and
# access to the chassis hardware
#
# Copyright (c) 2007-2014, 2017-2020 by cisco Systems, Inc.
# All rights reserved

PATH=${PATH}:/sbin:/bin:/usr/bin:/usr/sbin:/usr/binos/conf

source hwutil-combined.sh

function hwutil_fru_present_16bits () {
    echo $(cpld_fru_present_16bits)
}
readonly -f hwutil_fru_present_16bits

function hwutil_is_rem_rp_present () {
    return $(cpld_is_rem_rp_present)
}
readonly -f hwutil_is_rem_rp_present

function hwutil_num_fp_present () {
    echo $(cpld_num_fp_present)
}
readonly -f hwutil_num_fp_present

function hwutil_num_cc_present () {
    echo $(cpld_num_cc_present)
}
readonly -f hwutil_num_cc_present

function hwutil_is_rp_fru_present () {
    return $(cpld_is_rp_fru_present $1)
}
readonly -f hwutil_is_rp_fru_present

function hwutil_is_cc_fp_fru_present () {
    return $(cpld_is_cc_fp_fru_present $1 $2)
}
readonly -f hwutil_is_cc_fp_fru_present

function hwutil_clear_pca9548_0 () {
    i2c_clear_pca9548_0
}
readonly -f hwutil_clear_pca9548_0

function hwutil_clear_pca9548_1 () {
    i2c_clear_pca9548_1
}
readonly -f hwutil_clear_pca9548_1

function hwutil_get_i2c_reset_mask_for_fp () {
    echo $(i2c_get_i2c_reset_mask_for_fp)
}
readonly -f hwutil_get_i2c_reset_mask_for_fp

function hwutil_get_i2c_reset_mask_for_cc () {
    echo $(i2c_get_i2c_reset_mask_for_cc)
}
readonly -f hwutil_get_i2c_reset_mask_for_cc

function hwutil_get_i2c_reset_mask_for_fp_cc () {
    echo $(i2c_get_i2c_reset_mask_for_fp_cc)
}
readonly -f hwutil_get_i2c_reset_mask_for_fp_cc

function hwutil_pwrcycle_given_reset_mask () {
    return $(i2c_pwrcycle_given_reset_mask $1)
}
readonly -f hwutil_pwrcycle_given_reset_mask

function hwutil_get_cc_fp_reset_mask_given_fru () {
    echo $(i2c_get_cc_fp_reset_mask_given_fru $1 $2)
}
readonly -f hwutil_get_cc_fp_reset_mask_given_fru

function hwutil_pwrcycle_cc_fp_fru () {
    return $(i2c_pwrcycle_cc_fp_fru $1 $2)
}
readonly -f hwutil_pwrcycle_cc_fp_fru

function hwutil_pwrcycle_im () {
    return $(i2c_pwrcycle_im $1 $2)
}
readonly -f hwutil_pwrcycle_im

function hwutil_set_plat_board_fru_slot_bay () {
    cpld_set_plat_board_fru_slot_bay
}
readonly -f hwutil_set_plat_board_fru_slot_bay

function hwutil_get_active_rp_slot () {
    echo $(cpld_get_active_rp_slot)
}
readonly -f hwutil_get_active_rp_slot

function hwutil_get_slot () {
    echo ${BINOS_SLOT_LOCAL:-$(cpld_get_slot)}
}
readonly -f hwutil_get_slot

function hwutil_get_physical_slot () {
    echo $(cpld_get_physical_slot)
}
readonly -f hwutil_get_physical_slot
