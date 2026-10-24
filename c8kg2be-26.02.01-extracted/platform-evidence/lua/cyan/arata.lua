--[[
  *  Chassis attribute table for Arata
  *
  *  July 2023, Sathish Teganahalli
  *
  *  based off:
  *  wilson.lua
  *
  *  Copyright (c) 2023-2026 by Cisco Systems, Inc.
  *  All Rights Reserved
--]]

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
--                              support modules                           --
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
local CHASSIS_NAME = "ARATA"

local log = require("log")
log.trace("Defining chassis attributes for " .. CHASSIS_NAME)

local cyanTable = require("cyanTable")
local globals = require("globals")

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- THIS (current) module defined here                                     --
--  All exported functions and variables will be prefixed with THIS       --
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
local THIS = cyanTable.new(CHASSIS_NAME)

-- Chassis Attributes
THIS.MAX_BAYS_PER_CC = 6
THIS.NUM_SLOTS_PFU = 4
THIS.NUM_SLOTS_POE_EXT = 1
THIS.NUM_SLOTS_POE_INT = 1
THIS.POE_PSU_SLOT_MIN = 3
THIS.POE_EXT_EEPROM = false
THIS.POWER_MGMT = true

THIS.MIN_THROUGHPUT = 3000
THIS.MAX_THROUGHPUT = 6000

-- Chassis Capabilities
THIS.TELEMETRY = true
THIS.GNMI = true
THIS.BOOST_LICENSE = true
THIS.CHASSIS_SERIAL_NUM_FOR_SUDI = true

-- Platform supports NGFW
THIS.NGFW_CAPABLE = true

-- virtual DSP
THIS.UC_VDSP = true
THIS.VDSP_BAY = 4

-- Platform punt-policer capability factors
THIS.CPU_CAPABILITY_DIVIDER = 2

--- Platform supports interrupt based OIR for PSUs in the system
THIS.INTR_BASED_PSU_OIR = false

--- Platform supports interrupt based failure detection for PSUs in the system
THIS.INTR_BASED_PSU_FAILURE = false

-- This specifies the SPA OIR Insert/Remove CLIs
THIS.OIR_INS_REM_CLI = true

-- Platform runs Licensing Manager daemon
THIS.LMAN = true
THIS.BINOS_DYN_AUTHOR_SVR = true

-- Platform supports IPSEC Anti Replay Multiple sequence numbers
THIS.IPSEC_MULTI_SNS = true

-- Platform IPSec MCAM Max entries
THIS.IPSEC_MCAM_MAX = 750

-- Enable tamper detection feature
THIS.TAMPER_DETECTION_FEAT = true

-- Enable consent token generation for tamper feature
THIS.CTLIB_TAMPER_DETECTION_FEAT = true

-- Using EAE data as tamper detection mark
THIS.TAMPER_DETECTION_EAE_MARK = true

-- Polling interval time in sec
THIS.ENV_POLLING_INTERVAL = 20

-- Platform supports interrupt based Modules OIR
THIS.INTR_BASED_MODULE_OIR = true

-- default 32/32
THIS.BIPC_FED_BUFS_M_START = 12
THIS.BIPC_FED_BUFS_M_MAX = 16

-- default 16/16
THIS.BIPC_FED_BUFS_S_START = 9
THIS.BIPC_FED_BUFS_S_MAX = 12

-- default 128
THIS.BIPC_FED_TMS_BUFS_MAX = 48

-- default 32
THIS.BIPC_BUFS_MAX = 16

-- default 256
THIS.BIPC_TMS_BUFS_MAX = 64

-- default 256
THIS.BIPCMGR_MAX_WRITE_BUFS = 64

-- default 256
THIS.IOSXE_CLIENT_BIPCMGR_MAX_WRITE_BUFS = 64

-- default 128
THIS.NMHA_BIPCMGR_MAX_WRITE_BUFS = 48

-- default 64
THIS.NILE_BIPCMGR_MAX_WRITE_BUFS = 32

-- default 64
THIS.SMAN_BIPCMGR_MAX_WRITE_BUFS = 32

-- default 256
THIS.BIPC_LMRP_BUFS_MAX = 64

-- default 128
THIS.BIPC_PLOG_BUFS_MAX = 48

-- default 256
THIS.BIPC_BUFS_L_MAX = 64

-- This platform supports PLATFORM BASED LICENSING
THIS.PLATFORM_BASED_LICENSING = true

-- This platform supports SD-Routing config mode
THIS.SD_ROUTING_CONFIG = true

-- This platform supports Unified Licensing
THIS.SL_LICENSE_UNIFIED = true

-- This platform supports Day-0 enforcement
THIS.SLP_STD_DAY_0_ENFORCEMENT = true

-- This platform does not support pak license
THIS.IGNORE_PAK_LICENSES = true

--This platform default boot level --
THIS.DEFAULT_BOOT_LEVEL = "ipbasek9"

-- Skip clearing boot level rommon before write
THIS.SKIP_EMPTY_BOOT_LEVEL_ROMVAR_WRITE = true

-- Supports platform for show power related clis handling
THIS.SHOW_PWR_USAGE = true

-- Collection of temperature monitoring stats
THIS.COLLECT_TEMP_MON_STATS = true

-- Support onboard PSU
THIS.PSU_SENSOR_ONBOARD = false

-- Platform supports Anti-counterfeit chip TPM device
THIS.TPM = true
THIS.ACT2 = false

-- Platform uses TAM X509 keys/certs
THIS.X509_KEYS = true

-- Platform uses RAM based X509 keys/certs
THIS.X509_RAM_KEYS = true

-- Platform supports chipguard chip on TPM platforms
THIS.CHIPGUARD = true

-- Platform does not support WDC
THIS.WDC = false

--Platform supports newer SL crypto license model
THIS.CRYPTO_THPUT_LEVELS = true
THIS.CRYPTO_THPUT_LEVELS_LIST = "10M,15M,25M,50M,100M,250M,500M,1G,2.5G"
THIS.CRYPTO_THPUT_LEVELS_DEFAULT = "10M"
THIS.CRYPTO_THPUT_LEVELS_DP_MINIMUM = "250M"

--Platform supports Tier based license
THIS.TIER_BASED_LICENSE = true
THIS.CRYPTO_THPUT_LEVELS_TIER_LIST = "T0,T1,T2,T3"
THIS.CRYPTO_THPUT_lEVELS_TIER_HELPER = "T3(up to 5 gbps) aggregate thput"

--Platform support for crypto CLI
THIS.CRYPTO_DEDICATED_SHOW_COMMAND = true

-- TAN statistics supported
THIS.TAN_STATS = true

-- Native Docker is supported
THIS.DOCKER = true

-- Family name
THIS.PLATFORM_IMAGE_GROUP = "c8kg2be"

-- Support for configuring controller-managed/autonomous mode
THIS.DEVICE_CONTROLLER_MODE = true

-- Major page fault threshold
THIS.HMAN_PG_FLT_THRESHOLD = 80

-- This is for per platfrom limit FTM flow rate
THIS.FTM_FLOW_RATE_LIMIT = 8500

-- This is for per platfrom FNF cache size
THIS.FNF_CACHE_SIZE = "512000"

-- This is for per platfrom FNF Ager params
THIS.FNF_AGER_SHORT_INTERVAL= 1280
THIS.FNF_AGER_INSPECTED_FLOWS = 16000
THIS.FNF_AGER_CONTINUE_INSPECTED = true
THIS.FNF_AGER_PARAMS = true

-- This sets ARP learn max limit for platform
THIS.ARP_PF_LEARN_LIMIT = true

-- Platform supports New Install Infra
THIS.INSTALL_MGR_CHK = true

-- Platform supports SMU from vManage
if (THIS.INSTALL_MGR_CHK == true) then
    THIS.SDWAN_SMU = true
end

if not (globals.is_controller_mode()) then
    -- Enabling install add via install_mgr
    -- Also enables usage of /bootflash/.images/<ver> for booting
    THIS.INSTALL_MGR_TXN_CHK = true

    -- Feature check install rearch ph 2
    THIS.INSTALL_MGR_TXN_2_CHK = true

    -- install rearch ph 2: redirect install RPC to install_mgr
    -- This needs installer-api-client service to be enabled in platform tdl
    THIS.INSTALL_MGR_TXN_RPC_CHK = true
end

-- This is for Platform supports "platform resource" in the system
THIS.PLATFORM_RESOURCE = true
THIS.PLATFORM_RESOURCE_DEFAULT = "service_plane_heavy"

-- Platform supports "platform resource" with dynamic core allocation
THIS.PLATFORM_RESOURCE_DCA = true

--Platform supports SDWAN Integrated Service Node, service controller, HYBRID
THIS.APPQOE_SERVICE_CONTROLLER = true
THIS.APPQOE_INTEGRATED_SERVICE_NODE = true
THIS.APPQOE_HYBRID = true

-- Platform supports SSLPROXY
THIS.SDWAN_SSLPROXY = true

-- Platform requires services throughput infra
THIS.REQUIRES_SRVCS_THRPUT_INFRA = true

-- To check if specific IDB need to bypass bad IP addr check
THIS.IDB_BYPASS_BAD_IP_ADDR_CHECK = true

-- Platform supports Kgv
THIS.SYSTEM_INTEGRITY_BTL_SHALEN = 32

-- Platform per core services BW in Kbps
THIS.SERVICE_CORE_BW = 100000000

-- Platform requires specific package for GuestShell (GS) IOSP client
THIS.GS_IOSP_CLIENT_PACKAGE = "arm64marvell"

-- Platform supports Firmware upgrade via vManage
THIS.FIRMWARE_UPGRADE_OVER_NETCONF = true

-- Platform supports eSIM
THIS.ESIM_CELLULAR = true

-- Platform supports cellular modem Firmware  action via vmanage
THIS.IOSXE_CWANFWUPG_CAPABLE = true

-- Platform supports Factory Reset via Vmanage
THIS.FACTORY_RESET_OVER_NETCONF = true

-- Platform displays actual Config-register value getting configured
THIS.DISPLAY_ACTUAL_CONFIG_REG_VAL_TO_SET = true

-- Attribute to always set console line speed permanently
THIS.SET_CONS_LINE_SPEED_ALWYS_PERMNTLY = true

--[[
  * Virtual Addresses of various TDL databases.
  *
  * - DB_ADDR_PASSWD_KEY:
  *   The value used needs to be same as that of PASSWD_KEY_DB_BASE_PTR_KATANA
  *   for 64 bit platforms.  PASSWD_KEY_DB_BASE_PTR_KATANA is defined as
  *   PASSWD_KEY_DB_BASE_PTR_EDISON, which in turn is defined as
  *   "((void *)0x780000000L)" in
  *   "binos/infra/mcp_common/include/mcp_shm_static_defs.h".
--]]
THIS.DB_ADDR_PASSWD_KEY = 0x780000000

-- For LTE PIM, following params are kept in sync with TSN/STAR
THIS.UNIX_INTR_INFO_MSEC = 20
THIS.UNIX_INTR_TRACE_MSEC = 64
THIS.UNIX_INTR_TRACE_MSEC_IOMD = 20

-- Platform supporting CSL storage for BAY0 only
THIS.CSL_STORAGE_BAY0_ONLY = true

-- Platform modifies bootflash CSL partition FS type to be ext4 instead of ext2
THIS.BOOTFLASH_CSL_PARTITION_FS_TYPE = "ext4"

-- Platform supporting NIST erase(Data Wipe, factory-reset all secure)
THIS.NIST_ERASE = true

-- GE switch external device reset
THIS.FPGA_GE_SWITCH_RESET = true

-- Delay "hold reset" of the GE switch external device reset
THIS.FPGA_GE_SWITCH_RESET_DELAY_HOLD = true

-- CMAN_MIRABILE_FIXME
-- Function to check if a file/dir exists
local function cia_dir_exists(name)
  if type(name)~="string" then return false end
  return os.rename(name,name) and true or false
end

--- Check if cia directory exists
if cia_dir_exists("/tmp/cia") then
THIS.HW_INFO_CPA = true
end

-- Disable NGIO Reliable Protocol mechanism for NGIOLite
THIS.NGIO_RP = false

-- Platform is cellular capable
THIS.CELLULAR_CAPABLE = true

-- Platform supporting CTRL_MNG
THIS.CTRL_MNG = true

-- Move all tasks from root group to control plane group so that
-- they do not run on dataplane cores
THIS.MOVE_TASKS_TO_CP = 2

THIS.BOOTFLASH_SUP = true

-- As this platform uses switchroot during boot, To avoid the error message of
-- "/dev/loop1: Can't open blockdev" on boot up
-- we want to disable verification of
-- installed packages on boot as well as verification of pkg as soon
-- as they are copied on the device
THIS.INSTALL_MGR_PRE_INSTALL_PKG_VERIFY_DIS = true

-- Platform preferred location for tech-support bundle/archive
THIS.TECH_ARCHIVE_LOCATION = "bootflash"

--This is for IOS-XE CPU SoC Monitoring enhancement
THIS.CPU_MON_SOC = true

-- Beacon LED Check
THIS.HWMOD_BEACON = true

-- Delay EMD sensor register to let CMAN initialize PFU and populate chasfs
THIS.EMD_SENSOR_REGISTER_DELAY = 0

-- Skip HW IDPROM read for EMD
THIS.EMD_WAIT_ON_INVENTORY = true

-- Enable/Disable LED in Ecomode
THIS.LED_ECOMODE = true

-- PLATFORM supports setting HWCLOCK
THIS.SET_HWCLOCK = true

-- Platform support PAE, with log level setting enabled
if not (globals.is_controller_mode()) then
    THIS.PAE = true
    THIS.PAE_BT = true
end

-- Platform supports disabling of telnet access
THIS.REMOVE_TELNET_ACCESS = true

-- Platform requires dp core isolation
THIS.ISOLATE_DP_CORES = 1

-- Support for LLDP on Management interface
THIS.LLDP_ON_MGMT_INTF = true

-- Use the AUX thread to perform IFS write to bootflash to avoid watchdog timeout
THIS.AUX_THREAD_FOR_IFS_BOOTFLASH_WRITE = true

-- Platform specific vendor for mgmt interface
THIS.MGMT_INTF_VENDOR = "MARVELL"

-- Platform support MACsec
THIS.MACSEC = true

-- Platform doesn't support "request platform software package ..." for upgrade
THIS.RPSP_INSTALL = false

-- forensic dump : bootflash location
THIS.BOOTFLASH_PARTITION_LOCATION = "/dev/bootflash1"

-- forensic dump : bootloader location
THIS.BOOTLOADER_PARTITION_LOCATION = "/dev/mtdblock0"

-- forensic dump : bootflash dump offset, bootloader dump offset
-- If dump_offset is 0, no blocks are skipped
-- If dump_offset is 1, it skips 1 block, corresponding to 4MB offset
THIS.BOOTFLASH_DUMP_OFFSET = "0"
THIS.BOOTLOADER_DUMP_OFFSET = "0"

-- Primary interface for onboarding as a meraki device
THIS.CLOUD_MGMT_PRIMARY_UPLINK_INT = "TenGigabitEthernet0/0/9"

-- Secondary interface for onboarding as a meraki device
THIS.CLOUD_MGMT_SECONDARY_UPLINK_INT = "TenGigabitEthernet0/0/8"

-- MCU upgrade check
THIS.MCU_FWUP = true
THIS.PSEQ_MCU_FWUP = true

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
-- All modules return THIS by convention at the bottom of the module file --
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

return THIS
