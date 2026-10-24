#!/bin/bash
#
# Copyright (c) 2018-2020 by cisco Systems, Inc.
# All rights reserved
# 
if [ -z "${HWUTIL_COMBINED:-}" ]; then
HWUTIL_COMBINED=1
source hwutil-i2c.sh
source hwutil-cpld.sh
source hwutil-common.sh
# End source guard HWUTIL_COMBINED
fi
