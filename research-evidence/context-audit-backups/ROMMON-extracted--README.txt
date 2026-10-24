ROMMON found inside c8kg2be-universalk9.26.02.01.SPA.bin

The IOS XE image contains TWO ROMMON packages under the main (mono) package's /firmware/host directory. The original embedded package files are copied here without modification, along with their extracted ROMMON binaries and update capsules.

soc1/
  firmware_mirabile_soc1.pkg (5,684,280 bytes)
  ROMMON version from capsule header: 17.18(4.1r).s1.cp
  mirabile_soc1_uefi64_rel_ios_upgrade_SPA.bin (13,697,024 bytes)
  mirabile_soc1_uefi64_rel_update_capsule_image_SPA.bin (13,722,320 bytes)
  Package build date: 2026-03-31_20.37
  Internal board directories: ARATA, ARATA_E, SHASTA, WHITNEY
  Automatic upgrade script selects this package for ARATA, ARATA_E, WHITNEY.

soc2/
  firmware_mirabile_soc2.pkg (5,813,308 bytes)
  ROMMON version from capsule header: 17.18(3r).s2.cp
  mirabile_soc2_uefi64_rel_ios_upgrade_SPA.bin (16,580,608 bytes)
  mirabile_soc2_uefi64_rel_update_capsule_image_SPA.bin (16,605,904 bytes)
  Package build date: 2026-01-18_20.59
  Internal board directories: CRESTONE, WILSON, plus mcp/RP/BENDER and FRY
  Automatic upgrade script selects this package for CRESTONE, WILSON.

Each package stores multiple board paths as hard links to the same two payloads. This folder contains one copy of each payload under its original descriptive filename. The full directory structure is preserved separately under ../c8kg2be-26.02.01-extracted/rommon/.

Verification
All eight included MD5/SHA-1 checksum files match the extracted binaries (four checks per SoC). SHA256SUMS.txt records newly calculated SHA-256 hashes for the delivered files. This verifies extraction consistency; Cisco signatures have not been cryptographically authenticated here.

Platform relationship
Cisco's IOS XE 26.2.x release notes recommend 17.18(4.1r).s1.cp for C8231-G2, C8235-G2, C8231-E-G2 and C8235-E-G2, and 17.18(3r).s2.cp for C8355-G2 and C8375-E-G2. Those versions match the capsule headers recovered here. The 8200-G2/SoC1 and 8300-G2/SoC2 association follows from that version match plus the image's board-selection script; exact marketing PID-to-codename mapping was not independently established.
Source:
https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/cisco-8000-series-secure-routers-release-26-2-x.html

Upgrade context
The internal usr/binos/conf/firmware_autoupgrade.sh script mounts the selected package, verifies its package type is "rommon", and locates rommon/<platform_type>/<board_type>/<board_subtype>/latest.bin and, when capsule support is present, capsule.bin.

Cisco documents the manual upgrade command using a ROMMON package downloaded from Cisco:
  upgrade rom-monitor filename bootflash:<ROMMON-package-name> all
It also documents checking the installed version with show rom-monitor r0 and reloading to complete an upgrade.

This investigation established the embedded contents and integrity of extraction. It did not test whether the recovered internal .pkg files can be supplied directly to the public upgrade command, and it did not flash a router. The raw ROMMON image and capsule have distinct roles and are not interchangeable.

Extraction layout
Original .bin -> SquashFS at byte 74,021,076 -> c8kg2be-mono-universalk9.26.02.01.SPA.pkg -> SquashFS at byte 4,096 -> firmware/host/firmware_mirabile_soc[12].pkg -> ISO9660 at byte 1,080 (SoC1) or 1,084 (SoC2) -> ROMMON binaries.

Tools: unsquashfs, Python 3, bsdtar (including ISO9660/Rock Ridge/zisofs decoding).
The original IOS XE .bin was not modified. Intermediate packages, file listing, scripts and full ROMMON directory trees are retained in ../c8kg2be-26.02.01-extracted/.
