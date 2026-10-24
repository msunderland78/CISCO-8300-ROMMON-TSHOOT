#!/bin/bash
#------------------------------------------------------------------
# cyan_api.sh: interact with CYAN through bash 
#
# Copyright (c) 2017-2020, 2025 by Cisco Systems, Inc.
# All rights reserved
#------------------------------------------------------------------
if [ -z "${CYAN_API_SH:-}" ]; then
CYAN_API_SH=1

source ${BINOS_ROOT_FS:-}/usr/binos/conf/cyan_api_helper.sh
source ${BINOS_ROOT_FS:-}/usr/binos/conf/required_modules.sh

# cyan_get_value
#
# Retrieve a value from a CDB file
# $1 (required) - CDB key
# $2 (optional) - CDB package name (eg. rp_daemons)
# 
# Value is echoed, so caller must catch this.
# Return code must also be checked. If it is non-zero,
# any echoed value is an error message
cyan_get_value () {
    local fallback_pkgs="rp_core mono rp_base fpx86 elc cc clcmips"
    local db_name=${2:-}
    local cyan_prefix=${BINOS_ROOT_FS:=/tmp}
    local pkg

    # Require 1 or 2 args
    if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
        echo -n "Invalid args"
        return 1
    fi

    for pkg in $db_name $fallback_pkgs; do
        [ -e "$cyan_prefix/cyan/$pkg.cdb" ] && break
    done

    if [[ ! -e "$cyan_prefix/cyan/$pkg.cdb" ]]; then
        return 1
    fi

    # Query CDB file for supplied key
    # Value is echoed to stdout, so caller must catch it in a var
    # Redirect stderr to stdout, so errors can be retrieved
    cdb -q "$cyan_prefix/cyan/$pkg.cdb" "$1" | tr -d '\0' 2>&1
    return $?
}

# End source guard CYAN_API_SH
fi
