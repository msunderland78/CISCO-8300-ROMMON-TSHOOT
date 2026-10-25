# C8375-G2 recovery context — October 23, 2026

This is the consolidated handoff for the device identifying as **C8375-E-G2**, chassis **FDO2742M0FK**. Read this file before acting on older notes. It records the working IOS state achieved earlier today, the subsequent ROMMON experiments, and the later failure to boot.

Workspace: `/Users/games/Documents/SOFTWARE`  
Actual session date: **2026-10-23**, America/New_York. Router timestamps such as May 29, 2025, and 1970/1979 file dates were incorrect clock values; they are not the actual dates of this work.

## 1. Current state — start here

**The router no longer boots normally after the recommended ROMMON experiment. Do not mistake the earlier successful IOS tests for its current condition.**

- Original development firmware was backed up with **two independent, identical 32 MiB SPI reads** before the native firmware write. Verified copies now exist on both the Mac and USB.
- The Cisco-recommended **17.18(3r).s2.cp** payload was programmed to the command's **primary** target.
- The old native updater also wrote beyond the firmware payload and failed verification there. Those extra regions were restored from the original backup under diagnostic Linux, while the new firmware payload and current environment were retained.
- A complete **32 MiB device readback then exactly matched the intended assembled image**. This proves the bytes matched that image; it does not establish compatibility with this board or successful secure boot.
- After a soft restart and a user-confirmed cold power cycle, there was **no normal SCP, ROMMON, or IOS startup output**. Only brief power-transition noise appeared on serial.
- The user reported **blinking red STATUS, other LEDs solid green, and fans at maximum**. Cisco describes blinking red STATUS as a hardware-integrity failure indication. The exact failing boot stage and cause remain unknown.
- The user was asked to turn the router off and move **CISCO FILES** back to the Mac. The user confirmed the USB was connected, and files were copied and verified. Reconfirm the router's actual power state before physical work; there has been no later successful boot observation.
- **Console capture is stopped and the serial port is released to the user.** Do not claim a capture is still running or reclaim the console without checking the user's use of it.
- The next prepared recovery step is an **external-programmer restoration of the exact original flash**, after identifying the physical chip/bank and verifying the programmer, package, voltage, and wiring. This restoration has **not** yet been attempted or proven.

No TPM provisioning, fuse, secure-boot key, lifecycle, or manufacturing-state changes were attempted. No eMMC erase or factory reset was performed. We never issued an explicit `2/g` golden-ROM write, but the physical bank mapping is unconfirmed: **do not claim the golden bank is independently verified or untouched solely from the command selector or “Boot ROM1” label.**

## 2. User intent and scope

The user initially asked us to:

1. Read `C8235-G2-RECOVERY-CONTEXT.txt`, which concerns a **separate router**.
2. Copy the original extracted Cisco 8300/SoC2 ROMMON to the USB drive **CISCO FILES**.
3. Troubleshoot this second device, which failed to boot IOS XE 26.2.1, and investigate whether it is early development hardware or an ordinary C8375-E-G2.
4. Assess its approximately 8 GiB RAM and empty DDR5 slot before buying memory.

The user explicitly required **INSTALL mode**, later authorized flashing the recommended ROMMON, and then requested a full current-ROMMON backup and another upgrade attempt. They were open to experimental recovery because the devices might otherwise be scrap.

The user believes ROMMON caused the rapid, loud fan cycling. That connection was **not established**. An unsupported/unknown PSU indication also remained unresolved before the flash experiment.

The user said equipment ordered for the C8235 is arriving in the next few days. The exact purchased programmer kit has **not been verified**. Later discussion identified the previously proposed CH341A setup; do not treat a reviewed listing as a confirmed order.

**Keep the routers separate:** this device uses **SoC2 / Crestone** firmware. The C8235 uses **SoC1 / Arata**. No C8235 SoC1 or experimental hybrid image was flashed to this C8375.

## 3. Hardware and original firmware identification

| Item | Observed value |
|---|---|
| Reported PID / VID | `C8375-E-G2` / `V01` |
| Chassis serial | `FDO2742M0FK` |
| PCA serial | `FDO27380KFQ` |
| EBF board | `mirabile-crestone`, revision `r3` |
| Board version | `5` |
| SoC / SKU | CN10616 B0 / `MV-CN10616-B0-AAP` |
| Physical CPU cores reported by SCP | 16 |
| Original ROMMON | `SDK112308-UEFI-ROMMON-SoC2-v9.2.1-Release` |
| ROMMON classification / build | **DEVELOPMENT SOFTWARE**, September 21, 2023 |
| Original boot stub / EBF | September 22, 2023 / `11.23.08` |
| Original BL2 / BL31 | Marvell `11.23.08`, built September 21, 2023 |
| CPLD | `2408272B`, also shown as `2.B`, dated August 27, 2024 |
| EBF board serial | `unknown`; chassis/PCA cookies were nevertheless readable |
| ROMMON running-image label | `Boot ROM1` |
| SCP boot-source label | `SPI0.CS0 (Primary image0)` |
| Boot security state in old SCP output | `provisioning`; secure, non-encrypted boot |
| Linux SPI flash identification | `spi0.0`: `mt25qu256a`, 32 MiB |

“Boot ROM1” and “Primary image0” are different software labels. They do not establish the physical golden-bank mapping.

Development firmware, early board revision, unusual memory arrangement, and topology discrepancies suggest an early development unit. They **do not conclusively prove** the unit's production/prototype classification.

### Memory findings

- User explicitly answered that there is **only one DDR5 slot and it is empty**.
- Firmware initialized `DMC2: 8 GB/ch, 1Rx8, UDIMM, 32-bit data, 4-bit ECC`.
- Total detected DRAM: **8 GB DDR5 at 4800 MT/s**. IOS reported `8388608K` physical memory.
- Raw inventory described memory as `16GB,Cisco,Onboard Memory`. This descriptor conflicts with measured/detected capacity and is **not proof** that 16 GB is physically fitted or that half the memory failed.
- Production documentation lists a single 16 GB default DIMM and a 32 GB upgrade, but that does not establish the layout or generic UDIMM compatibility of this board.
- No RAM purchase, installation, or physical memory repair occurred. Hold off selecting a DIMM until the board layout and supported module are established.

### Other pre-flash observations

- `P0`: PSU `Unknown`, `incompatible`; PID/VID/serial were blank even in raw inventory.
- `P1`: empty.
- `P2`: `C8300-FAN-1R`, OK.
- User was asked for the installed PSU's visible label/part number; no answer is recorded.
- Temperatures and measured voltage rails were Normal. CPU approximately 34–36°C, inlet sensors 25–27°C, power 34–36 W, and chassis fan snapshots approximately 5,280–5,520 RPM.
- Filtered logs showed startup fan insertion and the missing PSU-bay alarm, without captured thermal/fan-failure alerts during the cycling investigation.
- Brief audible fan surges were not correlated with a large measured RPM change. Cisco documents approximately 60-second updates for the displayed environmental readings, so short changes could be missed.

## 4. Initial staging and preservation of existing files

The original SoC2 ROMMON set extracted from `c8kg2be-universalk9.26.02.01.SPA.bin` was copied to:

```text
/Volumes/CISCO FILES/C8375-E-G2-ROMMON-17.18-3r/
```

This folder contains the original `firmware_mirabile_soc2.pkg`, raw IOS-upgrade image, UEFI capsule, vendor MD5/SHA1 files, and supporting checksum/metadata files. Eight payload/metadata source files were verified against the extraction manifest. Finder also created `._` sidecar files; these are not firmware payloads.

Cisco's 26.2 compatibility table lists:

| Platform / IOS XE | Minimum ROMMON | Recommended ROMMON |
|---|---|---|
| C8375-E-G2 / 26.2.1 | `17.15(3.2r).s2.cp` | `17.18(3r).s2.cp` |

The image checks established extraction/copy integrity, not independent validation of every Cisco RSA signature or compatibility with this physical unit.

Existing internal files were preserved to `usb0:/C8375-ORIGINAL-BACKUPS/` before firmware programming:

| USB backup | Size | Verified source/USB MD5 |
|---|---:|---|
| `SDK112310-UEFI-SoC2-SB-v11.2.7_RSA4K.img` | 16,580,608 | `a8b9efb975c1213525fe33bd37dc871f` |
| `SDK112312-Prod-SoC2-v17.15.1_13d-cp-RSA2K.pkg` | 5,753,916 | `d947e04256c496a7d881c7baf1778ec8` |
| `original-development-ios.SSA.bin` | 1,000,259,196 | `e245f58d04438feb8bbbb08c9b7d409c` |

The development IOS source was `c8kg2be-universalk9.BLD_POLARIS_DEV_LATEST_20250204_002714.SSA.bin`. These preserved files were **pre-existing staged files, not dumps of the installed v9.2.1 ROMMON**. Neither staged ROMMON version was flashed today. They remain potential intermediate-version leads, not validated recovery choices.

## 5. Boot troubleshooting before firmware flashing

### 5.1 Original 26.2.1 failure: secondary CPU startup

Initial saved boot parameter:

```text
USER_BOOT_PARAM=maxcpus=24 failure_shell
```

The old ROMMON read the verified USB 26.2.1 image, printed integrity/signature-verification messages and `%ERROR% Booting an incompatible image for this platform`, but continued into Linux 6.6.95.

At secondary CPU startup it halted with `Unhandled Exception in EL3`, including `elr_el3=0xB5F08C`, `esr_el3=0xBE000011`, and `x19=x20=0x10`. No IOS prompt was reached. A historical October 22 capture of IOS 17.15.6 showed the same Crestone revision and EL3 failure with `maxcpus=24`; that capture was copied into this task for comparison.

### 5.2 Temporary single-CPU diagnostic

After a power cycle, a temporary, unsaved parameter was tested:

```text
maxcpus=1 failure_shell
```

It bypassed the EL3 startup fault and eventually reached IOS. The console was quiet for a significant interval after UART handoff. The assistant initially proposed another power cycle too soon; the user correctly pointed out slowed fans and green LEDs. We waited instead, and IOS output appeared. **A quiet console alone was not proof of a hang.**

However, the one-CPU boot did not provide a healthy forwarding plane: `qfp_ucode_mirabile` failed with `rc134`, and forwarding/module processes went offline.

At about 234 seconds, Linux panicked in `edac-poller` / `octeontx_edac_device_wq`:

```text
octeontx_edac_wq_handler+0xbc/0x2b0
__memcpy_fromio+0x50/0x98
```

The fault involved a firmware RAS-ring read beyond mapped memory, with uninitialized-looking `A5A5` fields. A driver/old-firmware record-layout incompatibility was suspected, not proven as the sole cause.

The crash dump completed in approximately 157 seconds, then the router automatically rebooted. The compressed core was about **1,749,903,412 bytes**, named `kernel.rp_RP-MIRABILE_0_19700101000010.core.gz`, with a corresponding text file. The unsaved single-CPU setting did not persist.

### 5.3 Sixteen CPUs and console-path diagnosis

Tested temporarily:

```text
maxcpus=16 failure_shell keep_bootcon
```

All CPU0–15 activated. F0 and the built-in network module became operational. This strongly implicated attempted activation of nonexistent/unsupported core16+ entries under the old 24-entry topology in the earlier EL3 fault, although the exact firmware defect was not independently established.

The native USB console later stopped responding while Linux heartbeats continued and fans/LEDs suggested operation. Reconnecting native USB and sending XON did not restore the prompt. The user swapped to the FTDI USB-to-RJ45 cable and unplugged native USB; the RJ45 prompt responded immediately without a router reboot. At that point the silence was a console-path problem, not a total system hang.

### 5.4 Sixteen CPUs alone did not fix EDAC

After saving `maxcpus=16 failure_shell` without `keep_bootcon`, an internal 26.2.1 boot panicked at approximately **53.3 seconds** in the same EDAC read path, this time on CPU10. Therefore the CPU limit did not solve the EDAC problem.

A second compressed core, approximately **2,325,885,277 bytes**, was saved in about 166 seconds as `kernel.rp_RP-MIRABILE_0_19700101000007.core.gz`. Both large dumps remained on internal storage; no cleanup was performed.

With automatic boot enabled before a BOOT target had been set, ROMMON fell back to the existing February 2025 development IOS. That image reached IOS with 16 CPUs and F0 online; its version was `17.18.20250204:011211`. We then returned to controlled manual ROMMON boot. A serial BREAK sent during image verification did not abort that load.

### 5.5 EDAC initialization workaround

The original 26.2.1 kernel was inspected offline. It contains `octeontx_edac_init` and supports Linux `initcall_blacklist`. A Marvell-authored driver patch corroborated the initialization/workqueue names.

Tested and later persisted:

```text
maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init
```

The kernel explicitly logged `blacklisting initcall octeontx_edac_init`. IOS and the forwarding/module processes started without the previous early EDAC panic.

**This disabled an OS error-reporting driver. It did not repair memory or prove hardware fault-free.** Early firmware separately reported MDC double-bit ECC rows `0x33e` and `0xe64`, and a later single-bit row `0xee9`, all Chain1/Hub8/Node0. The physical component has not been mapped; these reports cannot automatically be assigned to the empty DIMM slot.

ChipGuard CPU UUID validation also continued to fail in the development ROMMON, but the old firmware proceeded to boot. Its keys/state were not modified.

## 6. IOS XE 26.2.1 installation and successful tests

The 26.2.1 installer image was copied from USB to internal bootflash and verified:

```text
Size:   1,048,008,916 bytes
SHA256: 0842a7210a2a0933f0a823bbe71c5ba2109f276ee49635a59ba0a26f17f0f456
MD5:    f25a1154427adbbad4a1993e0969d08c
```

At the user's direction, the final configuration was converted to **INSTALL mode**:

```text
install add file bootflash:c8kg2be-universalk9.26.02.01.SPA.bin activate commit
```

Add, Activate, postcheck, and Commit passed. The installer saved configuration and reloaded. The original startup configuration had already been backed up. `packages.conf` was 8,405 bytes, with 14 expanded package files observed.

After saving the tested boot workaround and automatic boot register, an unattended reset loaded `bootflash:packages.conf` without a manual boot command. Verification showed:

```text
System image file is "bootflash:packages.conf"
IMG C 26.02.01.0.263
Auto abort timer: inactive
```

The install summary alone was not treated as proof of install mode; the system-image path and automatic boot were also checked.

### Physical two-port test

The user connected a spare patch cable between **data ports 0/0/0 and 0/0/1**. Temporary separate VRFs forced traffic through the physical ports:

- `RECOVERY-A`, `TwoGigabitEthernet0/0/0`, `198.18.83.1/30`.
- `RECOVERY-B`, `TwoGigabitEthernet0/0/1`, `198.18.83.2/30`.
- Both negotiated **2500 Mbps full duplex**.
- ARP resolved the opposite physical MACs, `e80a.b995.77a0` and `.77a1`.
- Initial short ping: 4/5, likely initial ARP resolution; this explanation was an inference.
- Longer test: **1000/1000 successful 1500-byte pings in each direction**, RTT min/average/max **1/1/4 ms**.
- After counters refreshed: each port had 2015 RX and 2015 TX packets, 3,031,756 bytes each direction, zero CRC/input/output errors and zero drops.

This proved physical two-port packet exchange, **not rated transit throughput**. All test IPs, VRF associations, and RECOVERY-A/B VRFs were removed. Both ports were verified back to their original `no ip address` / `negotiation auto` configuration. Test configuration was not saved. The user was told the loop cable could be removed.

The control processor reported Healthy, all 16 CPUs were present, RAM use approximately 57–58% of 7,904,544 KB, and temperatures/rails were Normal. No long burn-in, full DRAM test, all-port/module test, or rated forwarding benchmark was completed.

## 7. Fan cycling, reboot checks, and console handoff

When the user asked whether the router had rebooted, console checks showed uptime increasing from approximately 6 to 10 and then 14 minutes, with last reload reason still `Image Install`. There was no new reboot evidence at those checks. Fan noise alone was not counted as a reset.

The user later reported repeated loud fan ramps. Environmental readings, logs, and platform status were checked; readings were Normal, while the PSU remained unidentified/incompatible. The source of the audible noise—main chassis versus PSU fan—and its exact cycle period were not resolved.

The user requested console access. The bridge was closed and capture stopped. The user configured SSH and returned the console. The actual resulting hostname was **`CAT3875-G2`**; preserve that spelling rather than silently “correcting” it in evidence.

The assistant did not create a username, login password, or enable password. Existing credentials were not printed. Before further maintenance:

| Backup | Size | Meaning |
|---|---:|---|
| `original-startup-config.txt` | 2,436 bytes | Original startup before installer changes |
| `pre-rommon-current-running-20261023.txt` | 6,984 bytes | Running configuration after the user's SSH setup |
| `pre-rommon-startup-20261023.txt` | 3,209 bytes | Startup before saving that current running configuration |

The current running configuration was then successfully copied to startup to preserve the user's changes. These config files may contain credentials. **Do not print or publish their contents.**

## 8. First ROMMON upgrade attempt — packaged secure update failed

`show rom-monitor R0` confirmed the original v9.2.1 development ROMMON. The user's reference to “16.2.1” was interpreted as **26.2.1**, the image actually installed.

The raw SoC2 image was copied to `bootflash:rommon-17.18-3r-soc2.bin`; MD5 matched the vendor/local value `82c750449cd0ed8609296f2e89ef6ddf`. IOS rejected this raw form:

```text
File bootflash:rommon-17.18-3r-soc2.bin is corrupt or is not a valid package.
```

The exact embedded package was then copied as `bootflash:rommon-17.18-3r-soc2.pkg`, MD5 `a0856bd81efaa8f2f08e8cec2f2e8b55`, and accepted by:

```text
upgrade rom-monitor filename bootflash:rommon-17.18-3r-soc2.pkg all
```

IOS reported a single ROMMON, Booted/Selected1, and that secure upgrading would occur after reload. It copied ROMMON environment/key-area data, switched to ROM0 while updating/verifying environment data, switched back to ROM1, and printed “ROMMON upgrade complete.” **That message represented staging, not a successfully installed new ROMMON.**

After reload, the old firmware detected the secure upgrade request and identified target `v17.18(3r).s2.cp`, then failed:

```text
%ERROR: Locate BIOS protection protocol failed
StartImage returned 8
Unable to start package Status = 8
%ERROR% Failed to launch upgrade
Continuing with current ROMMON version ...
```

IOS returned in install mode, F0 and the network module became online, and `show rom-monitor R0` still showed the original development firmware. `bootflash:EFI/UpdateCapsule/` did not exist when checked afterward. No manual capsule cleanup was performed.

The missing BIOS-protection interface suggested an incompatibility with the old development firmware. No exact public Cisco fix was found; this was not established as the only issue with the board.

## 9. Full current-ROMMON backup through temporary diagnostic Linux

The user specifically requested a true current-ROMMON backup before another attempt. A normal IOS system-shell request returned:

```text
% Please secure authentication via request consent-token
```

No consent token, development key, fuse, or security-state change was made. Instead, we used a temporary boot of the original installed IOS initramfs into its Linux shell.

### Console lessons and temporary boot parameters

The first diagnostic boot used `rdinit=/bin/sh` with the existing parameters, but its shell was inaccessible on the RJ45 console. Default kernel console was `ttyAMA1`, the disconnected native USB path. A user power cycle returned normal IOS because the diagnostic parameter was unsaved.

For the corrected boot, we entered manual ROMMON through IOS `config-register 0x1820` and reload. A late `B` keystroke once buffered into the ROMMON command line and produced an invalid `Bset`; it did not enter an EBF menu or modify firmware.

ROMMON rejected a 160-byte command line as too large; a 122-byte command was accepted. The successful **temporary, unsaved** diagnostic command was:

```text
set USER_BOOT_PARAM "maxcpus=1 rdinit=/bin/sh -c mount${IFS}-tdevtmpfs${IFS}none${IFS}/dev;sh</dev/ttyAMA0&>/dev/ttyAMA0"
boot bootflash:packages.conf
```

Do not append `failure_shell` to this diagnostic form: bare unrecognized kernel arguments can become shell arguments. The normal EDAC blacklist was not present in this shortened diagnostic form; polling was later deferred through RAM-only sysfs settings before extended repair work.

Opening `ttyAMA0` reset the RJ45 UART to **9600 baud**, producing NULs at the Mac's 115200 setting. The bridge was enhanced to accept an initial baud argument and a JSON baud-change action. Opening at 9600 produced `sh-5.0#`; `stty 115200` on the router followed by changing the bridge back to 115200 restored readable interaction. This avoided another unnecessary physical power cycle.

The original initrd was inspected offline from gzip offset `38665384` in the original 26.2.1 image. It contained bash, BusyBox, `dd`, `mount`, and the needed libraries. Kernel configuration showed built-in MTD SPI NOR, Cadence XSPI, USB storage/XHCI, and VFAT support.

### Read-only device identification and backup

After mounting devtmpfs, `/proc`, and `/sys`, the layout was:

```text
dev:    size      erasesize  name
mtd0:   02000000  00001000   "spi0.0"
mtd1:   00400000  00001000   "spi0.1"
```

`mtd0` was **33,554,432 bytes**, erase size 4096. `mtd1` was **not read or programmed**; it was not established as a golden-ROM bank and may represent another device. Prior C8235 mapping must not be assumed to apply here.

`blkid` identified USB `/dev/sda1`, VFAT, label `CISCO FILES`, UUID `4480-1609`. It was mounted at `/mnt/usb`. Two independent reads were made:

```sh
dd if=/dev/mtd0 of=/mnt/usb/C8375-SPI-BACKUP-20261023/current-spi0-cs0-32MiB-read1.bin bs=65536
dd if=/dev/mtd0 of=/mnt/usb/C8375-SPI-BACKUP-20261023/current-spi0-cs0-32MiB-read2.bin bs=65536
```

Each read returned 512 complete records / 33,554,432 bytes in about 11.46 seconds. Both SHA-256 hashes matched:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

Additional metadata saved to USB included `/proc/mtd`, diagnostic command line, `dmesg`, and the 98,073-byte runtime DTB from `/sys/firmware/fdt`. The USB was synced and cleanly unmounted before rebooting to ROMMON. These were the first actual complete flash backups of this router, distinct from earlier copies of staged firmware files.

## 10. Native primary ROMMON programming — CRC failure

Before programming, normal boot settings were restored and synced:

```text
set USER_BOOT_PARAM "maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init"
confreg 0x1822
sync
```

The raw SoC2 file on USB was reverified:

```text
File:   mirabile_soc2_uefi64_rel_ios_upgrade_SPA.bin
Size:   16,580,608 bytes = 0xFD0000
SHA256: cfcf1ae38c2886e9d28138d3428636c2c8345b903bbef522f8e9ebfb363ff985
```

ROMMON help documented `1/p` for primary and `2/g` for golden. The user-authorized native write was:

```text
flashmon usb0:/C8375-E-G2-ROMMON-17.18-3r/mirabile_soc2_uefi64_rel_ios_upgrade_SPA.bin 1
```

The warning was confirmed with `y`. No interrupt/reset was sent during programming. The updater printed protection claims for:

```text
monitor environment: 0x01F30000 - 0x01F4FFFF
manufacturing data:  0x00FD0000 - 0x0002FFFF
uncovered area:      0x00FD0000 - 0x01FFEFFF
```

The manufacturing endpoint above is nonsensical/backward **as printed**. Do not silently turn that printout into a verified physical map.

Actual reported programming ranges were:

| Range, inclusive | Observation |
|---|---|
| `0x00000000–0x00FCFFFF` | Programmed, then verified OK; exactly the payload span |
| `0x01001000–0x01F2FFFF` | Programmed beyond payload, then verification failed |
| `0x01F50000–0x01FFFFFF` | Programmed beyond payload; final state assessed by readback later |

The operation ended with:

```text
spi: failed to program BIOS firmware (CRC Error)
monitor: failed to burn BIOS!
```

**We did not reset at this point.** The original ROMMON was still running from RAM, so we booted diagnostic Linux directly through that running firmware to inspect and repair the result.

## 11. Readback, repair of extra writes, and complete verification

The same temporary one-CPU shell was used, again recovering UART9600 →115200 without a reset. A complete post-write flash dump was saved as `after-native-flash-crc-failure.bin`.

Comparisons established:

1. The first **253 ×65536 bytes** exactly matched the original Cisco SoC2 payload hash `cfcf…f985`.
2. The observed preserved span **`0xFD0000–0x1000FFF`** matched the original backup.
3. The two upper ranges programmed beyond payload end differed from the original backup.

For longer diagnostic work, polling was deferred in this Linux session only:

```sh
for f in /sys/devices/system/edac/cpu/poll_msec /sys/devices/system/edac/mdc/poll_msec /sys/devices/system/edac/llc/poll_msec; do
    echo 600000 > "$f"
    cat "$f"
done
```

All three read back `600000`. We did not unbind the EDAC drivers because the remove-handler safety was not established. This polling change was in RAM and did not provision or alter firmware security state.

Internal eMMC `/dev/mmcblk0p1` was mounted **read-only, `noload`**, at `/mnt/bootflash`. The installed mono package was mounted **read-only squashfs, loop, offset4096**, at `/mnt/mono` to use its native ARM `flash_erase` utility. No internal eMMC files were erased or modified in this diagnostic repair.

An expected full image was assembled in `/tmp/expected-spi.bin`:

1. Start with the exact original 32 MiB backup.
2. Overlay the exact new Cisco payload at offset0, length `0xFD0000`.
3. Retain the **current** post-write environment at `0x1F30000–0x1F4FFFF` (128 KiB), because known boot settings had legitimately changed after the original capture.

That assembled image was also saved to USB as `candidate-17.18-3r-with-preserved-data.bin`.

The following are **historical repair commands, not instructions to run against an unidentified chip or the currently nonbooting device**. They restored only the extra upper areas from the expected RAM image:

```sh
/mnt/mono/usr/sbin/flash_erase -q /dev/mtd0 0x1001000 3887 && dd if=/tmp/expected-spi.bin of=/dev/mtd0 bs=4096 skip=4097 seek=4097 count=3887 conv=notrunc
/mnt/mono/usr/sbin/flash_erase -q /dev/mtd0 0x1f50000 176 && dd if=/tmp/expected-spi.bin of=/dev/mtd0 bs=4096 skip=8016 seek=8016 count=176 conv=notrunc
```

The first wrote 15,921,152 bytes; the second wrote 720,896 bytes, without reported errors. These repair commands did not write the new payload, manufacturing gap, or environment span.

A complete new **device readback**, `verified-17.18-3r-readback.bin`, then matched the expected full image exactly:

```text
68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b
```

All filesystems were synced and unmounted cleanly before `busybox reboot -f`.

## 12. Boot failure after the verified programming

The soft reset produced no normal startup output. A cold power cycle was requested to reset the flash hardware state as well as the processor; the user confirmed it was back on. No normal startup banner appeared after that either.

At the later cold boot the user reported blinking red status and maximum fans. A brief check at 9600 baud with Enter gave no prompt; 115200 was restored. There was no confirmed post-flash SSH reachability or new IOS uptime. The SSH IP was requested but not provided. A targeted Mac ARP lookup for the known MAC prefix found no entry; that alone is not proof of a network failure.

We therefore recorded **a failed boot after the firmware experiment**, not a successful upgrade. Repeated power cycles without new evidence were not prescribed. The router was to remain off pending recovery preparation.

### Offline checks after USB returned to Mac

All captured `.bin` files were copied to the Mac and source/destination SHA-256 hashes matched. The original two dumps still matched each other. Offline comparison confirmed:

- The programmed payload exactly equals the original extracted Cisco raw image.
- Outside the payload, only the specifically retained environment differs from the original backup.
- The first **64 KiB is all `FF` in both original and programmed images**; that is not evidence that an original populated header was accidentally erased.
- Old and new TIM/header structures differ. At `0x10000` and `0x20000`, the old total-minus-length-field difference was `0x114`; the new difference was `0x214`, and header word9 changed from0 to`0x402`.

These header/signing differences are a lead for compatibility investigation, **not proof of an RSA-key/fuse mismatch or a specific secure-boot failure**. No fuse values or required provisioning state were determined. A full readback matching our expected image does not establish that every firmware component is compatible with this early board.

## 13. Exact restore artifacts and hashes

### Original restore image — use this set for planning restoration

Mac directory:

```text
/Users/games/Documents/SOFTWARE/c8375-recovery/restore-original-20261023/
```

USB directory, last confirmed mounted on the Mac:

```text
/Volumes/CISCO FILES/C8375-RESTORE-ORIGINAL-20261023/
```

Contents:

```text
C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin
SHA256SUMS.txt
RESTORE-NOTES.txt
```

The `.bin` is an **unmodified exact original full-chip read**, 33,554,432 bytes:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

It is not a ROMMON upgrade package and must not be passed blindly to `flashmon`. It may contain unique device data and must remain private. External restoration is not yet tested. The captured original environment selected manual boot (`0x1820`), so restored firmware may stop at ROMMON and need the known working automatic settings re-established.

### Raw capture and comparison directory

Mac: `c8375-recovery/spi-backups-20261023/`  
USB: `C8375-SPI-BACKUP-20261023/`

| File | Bytes | SHA-256 |
|---|---:|---|
| `current-spi0-cs0-32MiB-read1.bin` | 33,554,432 | `72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107` |
| `current-spi0-cs0-32MiB-read2.bin` | 33,554,432 | `72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107` |
| `after-native-flash-crc-failure.bin` | 33,554,432 | `117ac567acd7dd08826d5af717dea9afdf2965099e03fb5119fa851beb73c2ca` |
| `candidate-17.18-3r-with-preserved-data.bin` | 33,554,432 | `68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b` |
| `verified-17.18-3r-readback.bin` | 33,554,432 | `68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b` |

The candidate/readback images are the **new, nonbooting firmware state**, not the originals to restore next.

Supporting files include:

- `SHA256SUMS.txt`, `verified-17.18-3r-SHA256SUMS.txt`.
- `README.txt`, `programming-and-repair-notes.txt`.
- `mtd-layout.txt`, `diagnostic-boot-command-line.txt`, `diagnostic-dmesg.txt`, `original-runtime.dtb`.
- `offline-comparison.json` and `tim-header-comparison.txt`, generated on the Mac after the copy.

The local staged-firmware and config copies are in `c8375-recovery/original-staged-firmware/`. The 1 GB development IOS backup remains on USB/internal storage; this session did not copy that entire file into this local directory.

Local raw backup directories and binary/config copies were given restrictive permissions. A `shutil.copy2` attempt to the FAT USB failed while copying unsupported file flags after data copying; the restore set was recopied using `copyfile`, then its USB hash was verified. Do not interpret that resolved metadata-copy error as a corrupt restore image.

## 14. Known working boot settings for after original restoration

These were proven with the **original development ROMMON** earlier today. They do not mean the current flashed firmware can execute:

```text
USER_BOOT_PARAM=maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init
BOOT=bootflash:packages.conf,12;
Configuration register: 0x1822
Console: 115200, 8N1, no flow control
```

ROMMON command syntax, if a working ROMMON prompt is regained:

```text
set USER_BOOT_PARAM "maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init"
confreg 0x1822
sync
```

Verify the BOOT target and environment before reset. `0x1820` selects manual ROMMON boot; `0x1822` selected automatic boot while preserving the verified 115200 console setting. Do not substitute `0x2102` without checking baud and other register bits.

## 15. External programmer discussion and outstanding hardware checks

The previously discussed C8235 setup was a **CH341A USB SPI programmer**, a genuine **1.8 V power and signal-level adapter**, and a **SOIC-16 clip/breakout**. Reviewed examples were an ACEIRMC CH341A kit (`B07V2M5MVH`) and the separate `SOP16 Clip+Cable+Adapter Board` option (`B07WCB2PZ2`). These were earlier proposals; exact ordered/delivered hardware remains unconfirmed.

The **C8235** board photos identified Micron `RW170` / `MT25QU256ABA8ESF-0SIT`, 1.8 V, SOIC-16. Subsequent C8375 photo inspection on October 23 identified two matching Micron `RW170` SOIC-16 chips: **U2_CSPI (left) and U1_CSPI (right), as oriented in IMG_1260**. They are above the large Microsemi SmartFusion2 device and beside headers P1_CSPI/P2_CSPI. The retained official Micron decoder maps `RW170` to `MT25QU256ABA8ESF-0SIT` (256 Mbit / 32 MiB, 1.8 V). This matches the previously detected `mt25qu256a` family. **Physical primary/golden bank mapping is still unconfirmed. Do not apply the C8235's U2900/U2901 labels or assume the adjacent headers' pinout.**

The C8375 source photo, an inspection crop of this pair, and a copy of the previously retained official Micron decoder response are saved in `c8375-recovery/board-photos/`. Earlier photo candidates were ruled out: the part beside the large processor heatsink was a TI TMP400 temperature sensor; the apparent “HIC” device was a PI7C9X2G304SV PCIe switch with a small EEPROM beside it. Exact ordered programmer hardware remains unconfirmed. No programmer connection, flash read/write, or header probing occurred during this photo identification.

Prepared next steps, not completed actions:

1. Confirm the physical flash chip, package, pin1 orientation, and bank mapping.
2. Confirm programmer/software support for the full 32 MiB chip and correct power **and signal** voltage. Do not connect a generic 3.3/5 V clip setup to a 1.8 V part.
3. With router power, console, and USB disconnected, establish the correct wiring and attempt reads. In-circuit access may work; board interference may require isolation or chip removal.
4. Preserve two matching reads from the programmer before writing, and compare them with the captured images to establish the correct target.
5. Restore the exact original image, verify a full readback, disconnect the programmer, and test booting.
6. If original boot is recovered, reassess the pre-existing intermediate firmware files and fan/PSU issue before any new release-ROMMON experiment.

No programmer attachment, voltage test, new harness mapping, chip removal, soldering, or external flash operation was performed today on this C8375. Hardware restoration is a prepared path, not a guaranteed result.

The original IOS install and saved SSH configuration are on internal eMMC. The prepared restore targets SPI boot firmware; it is not an eMMC wipe or factory reset.

## 16. Console tooling and current ownership

Current known cable/port:

```text
/dev/cu.usbserial-AL00F7EQ
115200 baud, 8 data bits, no parity, 1 stop bit, no flow control
```

Original native USB console port was `/dev/cu.usbmodem4101`. The active path was changed to RJ45 during troubleshooting. Present macOS device names must be rechecked after unplug/replug.

Bridge: `c8375-recovery/rj45_serial_console.py`. It now accepts an optional initial baud argument and newline-delimited JSON actions:

```json
{"send":"show platform\r"}
{"baud":9600}
{"baud":115200}
{"break":true}
{"close":true}
{"expect_send":{"pattern":"rommon 1 > ","send":"set\r"}}
```

There is no break-on-pattern feature. Wait for a prompt before issuing the next dependent command, especially slow ROMMON directory listings. Do not open the same port simultaneously in SecureCRT and the bridge.

Session IDs are historical, not reusable promises: initial native18135, reconnect96722, RJ4573906, reconnect34548, resumed62070, baud-adjustable27665. **The last bridge session27665 was closed cleanly. Capture is stopped and the user has console access.** The final user question about console access was answered with the port/settings and this released state.

## 17. Evidence and previous notes

Important console captures under `c8375-recovery/console-logs/`:

| Capture | Main coverage |
|---|---|
| `20261023-100652-console.log` | Initial native USB boot, identity, CPU/EDAC failures |
| `20261023-102849-console.log` | Native USB reconnect during silence |
| `20261023-103319-console.log` | Working RJ45 session, backups, install and packet tests |
| `20261023-111440-console.log` | Fan checks and first packaged ROMMON attempt |
| `20261023-151731-console.log` | Return from user SSH configuration, early diagnostic attempts |
| `20261023-153046-console.log` | Accessible diagnostic shell, complete SPI backup, native write, repair, verified readback, later silence |

`20261023-111437-console.log` is a short open/close artifact. Readable derivatives of some earlier captures are present. Use raw logs as primary console evidence; readable copies may predate the last appended raw output.

Other useful evidence:

- `c8375-recovery/rommon-upgrade-failure-20261023.txt`: secure-updater BIOS-protection error.
- `c8375-recovery/native-flash-failure-20261023.txt`: native programming/verification failure, with exact printed ranges.
- `c8375-recovery/kernel-edac-symbols.txt` and `mdc-register-header-excerpt.txt`.
- `c8375-recovery/historical-17.15.6-boot-2026-10-22.log`: prior-day comparison, not a new test today.
- `c8375-recovery/usb-staging-notes.txt`, `usb-staging-SHA256SUMS.txt`, `usb-backup-MD5SUMS.txt`.
- `c8375-recovery/initrd-evidence/` and `upgrade-script-evidence/`: extracted original kernel/initrd/script evidence.
- `C8375-E-G2-RECOVERY-CONTEXT.txt`: preceding condensed handoff.
- `c8375-recovery/context-history-through-20261023-rommon-attempt.txt`: longer accumulated chronology, including intermediate states.
- `c8375-recovery/RECOVERY-CONTEXT.txt`: earlier chronological notes; statements such as “no flash performed” apply to their historical point, not the end of today.

## 18. Sources consulted during today's work

- [Cisco 8000 Secure Routers, IOS XE 26.2.x release notes](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/cisco-8000-series-secure-routers-release-26-2-x.html): ROMMON matrix and packaged-upgrade procedure.
- [Cisco 8300 hardware overview](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/hardware_installation-guide/secure-8300-series-hig/m-overview.pdf): hardware and LED meanings.
- [Cisco environmental monitoring guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_01100.html): sensor reports and update intervals.
- [Marvell-authored OcteonTX2/CN10K EDAC driver patch](https://lists.openwall.net/linux-kernel/2024/07/31/710): driver initialization, workqueue, and removal behavior.
- [Linux 6.6 kernel parameters](https://www.kernel.org/doc/html/v6.6/admin-guide/kernel-parameters.html), [serial-console behavior](https://www.kernel.org/doc/html/v6.6/admin-guide/serial-console.html), and `init/main.c` from Linuxv6.6: diagnostic boot and init-argument behavior.
- [Cisco console/reset-button guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_0110.html): the documented `golden.bin` recovery is IOS/config recovery, **not proof of a method to select a golden SPI firmware bank**.
- [Micron MT25QU256ABA8ESF-0SIT part specifications](https://www.micron.com/products/storage/nor-flash/serial-nor/part-catalog/part-detail/mt25qu256aba8esf-0sit): 1.8 V part family; the C8375's exact physical part still needs confirmation.

## 19. Resume rules

- Start from **nonbooting device with original backup available**, not the earlier healthy IOS state.
- Do not reconnect to the console merely because an old session ID appears in notes; it is released to the user.
- Do not repeat the recommended-image flash or claim its successful verification means it booted.
- Keep exact original restore images distinct from the new nonbooting images and from staged intermediate firmware.
- Do not infer golden-bank selection, TPM state, fuse configuration, a RAM defect, or a PSU/fan root cause beyond the evidence above.
- Preserve unique board data and credentials. No full dump or configuration contents should be published.
- Reconfirm physical power/cable/USB state and actual programmer hardware before continuing.


## 20. October 24 bench handoff: programmer accepted, header route unresolved

The detailed current measurements are in [the tracking plan](ROUTER-RECOVERY-TEST-PLAN.md), especially C8375-01-HDR. The user has accepted the CH341A plus 1.8 V adapter and ended further standalone programmer validation. Adapter input measured 3.318 V and regulator tab 1.803 V. The active blue socket is printed 1–8, pin 4 ground; expected output levels were confirmed qualitatively, without separate per-pin numerical readings.

P1_CSPI pin 1 maps to U1 flash VCC and P1 pin 2 to ground. P2_CSPI is a four-post header: pins 1/3 each measured 0.2 Ω to P1 ground, while pins 2/4 were approximately 5 kΩ to ground. U4 Select→P2-2 measured 329 Ω, Select→P2-4 >9 kΩ, and Enable→known ground 331 Ω. No selector setting or supply injection was tried. The mux supply search has not found a direct header feed; latest remaining P1 readings were reported collectively in MΩ, with pin 8 at 5.6 kΩ. Do not conflate these endpoints with the earlier flash-clock scan or invent per-pin values.

The assistant ended repetitive broad scans after the user noted repetition. A complete SPI header access route remains unresolved; no programmer was attached to the router, and no external flash acquisition or write has occurred. The preferred next step is direct access with the SOIC-16 clip expected October 25, then two complete matching reads per physical chip, U1_CSPI and U2_CSPI. Compare with the exact original backup before selecting a restore target. Do not restart programmer validation or the same header matrices without new evidence. C8300 external-console diagnosis is a separate available task today, not work already performed.


## 21. Active priority clarification: continue the CH341A/Dupont/header route

After the preceding recommendation to wait for the clip and the assistant's switch to C8300, the user explicitly asked to return to recovering this router through the CH341A and pin header. Keep this as the immediate task. C8300 notes and the confirmed absence of its USB-console cable during RJ45 testing are retained for later.

Use [C8375-CH341A-HEADER-WIRING.md](C8375-CH341A-HEADER-WIRING.md) as the focused harness/status sheet. Programmer/adapter is accepted; broad supply/ground scans are complete and should not be repeated. Adapter output 8 to P1-1 and output 4 to P1-2 are known net correspondences, not a ready-to-power harness. SPI signals, mux power/control and board loading are unresolved.

The focused unpowered test found **22 Ω from large U1 flash CLK pin 16 to small U4 mux common pin 4 / YA**. The other tested common pins 7/9/12 were reported high, with no individual values/units. This points to channel A as the clock path; a discrete series resistor has not been identified. The user then explicitly corrected an initial U1/U4 wording error: **small U4 pin 2 / IA0 to P1 pin 4 = 33 Ω**. This identifies P1-4 as the header-side clock branch; do not record it as flash VCC or as a powered end-to-end test. The U4 pin 3 / IA1 scan against P1 posts 3–8 then returned **no small readings, most OL**, with other individual values not supplied. Clock branch scans are complete. The user then expanded the CS# scan from large U1 pin 7 to **every U4 pin and every P1/P2 post**, with no reading below approximately **5 kΩ**; individual values were not supplied. The U4 CS# tests are complete and should not be repeated. Next investigate **upper U3 mux common pins 4/7/9/12** from U1 CS# pin 7; these four new pairs are pending. Alternate buffer/logic routing remains possible, and no component fault is established. Mux power/control and other header signals remain unresolved. No programmer-to-router attachment, selector jumper, new chip read or write has occurred.


## 22. User proposes partial SOIC-8 clip plus header access

The user reports difficulty locating U1 CS# despite many searches and proposes using today's eight-contact clip on part of U1, with Dupont/header wires for the remaining connections. They also ask whether guessed powered CH341A wiring can cause permanent damage. This is the immediate assessment; set aside earlier U3/244A-device search questions rather than requesting more random scans.

See [the wiring sheet's hybrid proposal](C8375-CH341A-HEADER-WIRING.md). A naturally fitting clip on the end away from the pin-1 dot could cover U1 pins 5–8 and 9–12, including CS# 7/MISO 8/WP# 9/GND 10. Fit/contact identity is not verified; the wide SOIC-16 body may not suit this clip. The ordinary eight-pin cable mapping would be wrong in this position. Use only individually mapped contacts and leave touched DNU pins 5/6/11/12 electrically disconnected. Do not force the clip.

P1 supply/ground are mapped and its clock branch reaches U4 IA0, but MOSI, powered mux configuration and loading remain unresolved. This is not a ready harness. Next obtain clip-jaw/cable/placement photos with every power source disconnected, then map contacts unpowered. No clip fit, programmer-to-router attachment, chip read, write or powered trial has occurred. A USB-powered CH341A can damage wrongly wired parts even with router power removed; read-only software does not establish electrical safety. Use only the accepted 1.8 V adapter output and disconnect USB before wiring changes.
