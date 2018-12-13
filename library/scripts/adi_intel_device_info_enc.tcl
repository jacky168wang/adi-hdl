## ***************************************************************************
## ***************************************************************************
## Copyright 2014 - 2018 (c) Analog Devices, Inc. All rights reserved.
##
## In this HDL repository, there are many different and unique modules, consisting
## of various HDL (Verilog or VHDL) components. The individual modules are
## developed independently, and may be accompanied by separate and unique license
## terms.
##
## The user should read each of these license terms, and understand the
## freedoms and responsibilities that he or she has by using this source/core.
##
## This core is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
## A PARTICULAR PURPOSE.
##
## Redistribution and use of source or resulting binaries, with or without modification
## of this file, are permitted under one of the following two license terms:
##
##   1. The GNU General Public License version 2 as published by the
##      Free Software Foundation, which can be found in the top level directory
##      of this repository (LICENSE_GPL2), and also online at:
##      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
##
## OR
##
##   2. An ADI specific BSD license, which can be found in the top level directory
##      of this repository (LICENSE_ADIBSD), and also on-line at:
##      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
##      This will allow to generate bit files and not release the source code,
##      as long as it attaches to an ADI device.
##
## ***************************************************************************
## ***************************************************************************

# adi_intel_device_info_enc.tcl

# The main rule when adding a new parameter is to have the same names for the parameter
# and it's list (valid range type or supported entity and its encoded value type)

variable auto_set_param_list
variable fpga_technology_list
variable fpga_family_list
variable speed_grade_list
variable dev_package_list
variable xcvr_type_list
variable fpga_voltage_list

# Parameter list for automatic assignament(generation)
set auto_gen_param_list { \
          FPGA_TECHNOLOGY \
          FPGA_FAMILY \
          SPEED_GRADE \
          DEV_PACKAGE}

set auto_set_param_list { \
          FPGA_VOLTAGE \
          XCVR_TYPE}


# List for automatically assigned parameter values and encoded values
# The list name must be the parameter name (lowercase), appending "_list" to it
set fpga_technology_list { \
        { "Cyclone V"  0x10 } \
        { "Cyclone 10" 0x11 } \
        { "Arria 10"   0x12 } \
        { "Stratix 10" 0x13 }}

set fpga_family_list { \
        { SX        0x10 } \
        { GX        0x11 } \
        { GT        0x12 } \
        { GZ        0x13 }}

       #technology 5 generation
       # family Arria SX

set speed_grade_list { \
        { 1         0x1  } \
        { 2         0x2  } \
        { 3         0x3  } \
        { 4         0x4  } \
        { 5         0x5  } \
        { 6         0x6  } \
        { 7         0x7  } \
        { 8         0x8  }}

set dev_package_list { \
        { FBGA      1  } \
        { UBGA      16 } \
        { MBGA      17 }}

# FBGA - Fine Pitch Ball Grid Array
# FBGA - Fine Pitch Ball Grid Array


set xcvr_type_list { \
       { GX        0x0  } \
       { GT        0x1  } \
       { GXT       0x2  }}

set fpga_voltage_list { 0 20480 } ;# 4.12 format (min 0V max 5V)

## ***************************************************************************
## ***************************************************************************
