# C8300 1N1S ROMMON 26.1(1r), extracted from IOS XE 26.2.1

**Observed November 2, 2026, America/New_York (C8300-03):** the supplied `c8000be-universalk9.26.02.01.SPA.bin` contains `firmware_curie1ru.pkg`. Its CE9331 upgrade payload contains the UTF-16LE banner **System Bootstrap, Version 26.1(1r), RELEASE SOFTWARE** inside a successfully decompressed LZMA stream.

The IOS source remains unchanged on `/Volumes/CISCO FILES`; 1,080,756,706 bytes, SHA-256 `6d0b610b1f8f1dc426268000f6a04a7ddcf01cc0a621de0be6cd0fda7e3b4717`.

| Exact artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `firmware_curie1ru.pkg` | 7,875,640 | `cf6050063e5fec0502096c452866e8b3a5445ce2d2d0c91e7e69f984d9ed4ca4` |
| `ce9331_uefi64_rel_ios_upgrade_SPA.bin` | 8,388,608 | `fa10209f76a14608155f3af73dfa07d814f1673b2a1f48fb11caae6dda4fa343` |
| `ce9331_uefi64_rel_update_capsule_image_SPA.bin` | 17,780,692 | `c8562ff7ffdd96a067712f19cd5da889ab4ea354cec416d0049ce1bb8aa0d8af` |

## Platform selection

The extracted [Cisco selector](../../../../research-evidence/c8300-iosxe-2621-20261102/vendor-firmware_autoupgrade.sh) explicitly associates C8300_1N1S with RADIUM/THALLIUM and selects `firmware_curie1ru.pkg` (lines 104–108 and 282–283). Its upgrade target is 26.1(1r). URANIUM/THORIUM are the 2RU/2N2S branch and select `firmware_curie2ru.pkg` (lines 116–121 and 284–285).

The 1RU archive also contains URANIUM/THORIUM aliases alongside RADIUM/THALLIUM/POLONIUM. Their presence does **not** override the selector. All five paths resolve to the same two CE9331 payloads. This shows why path names or equal package sizes alone cannot select a restore image. The previously supplied standalone C8000-2N2S-17-18-1r package belongs to the separate CE9351 family and is not selected for this 1N1S by this IOS release's logic.

The selector skips its automatic upgrade for DEVELOPMENT ROMMON in the relevant branch. The installed firmware on C8300-A remains unknown while its console is silent. No extracted vendor script was executed and no automatic upgrade was attempted.

## Reproducible extraction and verification

Python 3 SHA-256 and magic inspection identified the outer SquashFS at byte **46,041,570**. Homebrew `unsquashfs -no-xattrs -no-progress -o 46041570 -d <temporary-packages> <IOS-image> c8000be-mono-universalk9.26.02.01.SPA.pkg .pkginfo packages.conf` extracts selected files. The mono package is 901,611,520 bytes, with SquashFS at byte **4096**. The same extraction command with that offset and paths `firmware/host usr/binos/conf/firmware_autoupgrade.sh` recovers the packages and selector.

The initial outer extraction returned status 2 because macOS could not store Linux `security.selinux` extended attributes. Repeating with `-no-xattrs` succeeded; this changes extracted filesystem metadata handling, not firmware file bytes. Full IOS/mono images, intermediate ISOs and redundant trees remain outside this repository in `/tmp/c8300-ios-2621-review-20261102` and on the source USB. They are not split/compressed for publication.

For the 1RU package, copy bytes beginning at **1080** into a temporary ISO and use macOS `bsdtar -tvf` / `-xf`. The [archive listing](archive-listing.txt) records hard-link aliases. One canonical copy of each payload, its embedded checksum files, and [package metadata](package-info.txt) are retained here. The 2RU comparison used ISO offset **1084**, with hashes and sizes retained in [payload analysis](../../../../research-evidence/c8300-iosxe-2621-20261102/payload-analysis.json), rather than duplicating its firmware here.

**All 20 embedded MD5/SHA-1 checks for the five 1RU paths pass; all eight checks for the two 2RU paths pass.** These demonstrate extraction consistency; independent Cisco download checksums and cryptographic signature authentication were not performed.

For internal version identification, Python `lzma.LZMADecompressor(format=lzma.FORMAT_ALONE, memlimit=64*1024*1024)` successfully decodes the stream at upgrade-file byte **458920**, limiting output to 32 MiB. It reaches EOF with **14,381,184 bytes**; the banner begins at decompressed byte **10,901,728**, UTF-16LE. [Version inspection record](../../../../research-evidence/c8300-iosxe-2621-20261102/curie1ru-version-streams.json); [complete provenance](../../../../research-evidence/c8300-iosxe-2621-20261102/results.json). Only inspection output was decoded; original package/payload bytes were preserved.

## Limits for recovery

This resolves the firmware-reference question for the 1N1S family. It does **not** prove that C8300-A has corrupt ROMMON or that this release will repair it. The **8 MiB upgrade payload** is not an established full image of either photographed **32 MiB** Micron chip; the capsule is an updater input with a different layout. Do not pad, truncate or write either as a whole-chip replacement. First preserve independent full reads, identify actual chip roles and map expected changed/preserved regions, including identity/security data. No chip read or write was performed during extraction.

Known-value/pattern publication checks cannot prove absence of every unknown secret in binary data. Canonical binaries remain byte-exact.
