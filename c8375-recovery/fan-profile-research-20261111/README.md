# C8375-A quieter fan profile: exact 26.1.2 investigation

**November 11, 2026, America/New_York · C8375-05**  
Live commands: **16:55–17:11 EST**; offline analysis follows.

**No quieter profile has been applied with the NIM installed. It has not been shown impossible.** The exact installed 26.1.2 driver exposes a generic outbound controller-message interface that the previously examined 17.15.6 handler did not expose in the same form. The remaining gap is the fan-specific command or shared-memory handshake, its rollback and retained temperature response.

The [preceding NIM comparison](../fan-nim-comparison-20261111/README.md) remains the operational evidence: table 1 and roughly 9,500 RPM with the NIM physically present, including software power-off; table 2 and 5,220–5,460 RPM when removed with a blank. The owner accepts a slower profile for a lightly loaded home lab. Undocumented reversible methods remain within the investigation's scope.

## Exact software and controller path

Fresh SSH identity checks matched **C8375-A / C8375-E-G2 / FDO2742M0FK**, committed IOS **26.1.2**, P1 **PWR-CC1-400WAC / LIT2727C7NE**, NIM **NIM-2FXS/4FXOP / FOC23152BE1**. The assembled/covered/no-programmer confirmation remains from this session. No physical work or serial access occurred here; battery and telephone-line state were not individually supplied.

Copied the installed **943,767,552-byte** mono package and independently matched the router's SHA-512. SHA-256: `998f672401d91f855c12f3456842b3cd1eeb757ac5df670a9ba9c39986260cc0`. Extracted host software and kernel modules offline; vendor code was never executed. The live kernel log identifies `nios_v2` and the matching build date. This matches the installed package, not an independently hashed image of loaded module memory.

| Path examined | Verified static evidence | Consequence |
| --- | --- | --- |
| NIOS fan sysfs attributes | Twelve named fan-control attributes in each of the base and I/O-component drivers are mode 0444 with no store callback | These diagnostic nodes cannot themselves apply a profile |
| Current NIOS ioctl handler | `nios_ioctl.isra.0` at `0x4b34`; request `0x40124e02` copies an 18-byte user message and forwards its header and length-selected payload | A generic outbound control path exists; no fan command has been identified |
| Native caller | `mcu_img_upgrade` opens `/dev/nios` and sends type 0, length 1, mode byte at ioctl call `0x46c8` | This controls ENV operating mode during firmware updates; it is not a demonstrated speed setting and was not run |
| Generic PWM wrappers | Setters operate through platform data and configured sensor paths; current 1RU fan data identifies RPM/power paths | A shared function name does not establish a Crestone PWM output |
| `nios_set_fan_level` | Calls register index 82; Crestone selects the Neptune map, whose index 82 is `n2h_psu0_env_out_12v_pwr` | This legacy-looking function is not a validated Crestone fan actuator |
| DASH mapping | A bounded device-memory mapping exists; a separate NIOS memory-block API reads data | Raw access still requires an understood register transaction; no mapping or write attempted |

**Correction to the October 31 inference:** the selected 17.15.6 ioctl handler forced an outbound type-6, zero-length message. The installed 26.1.2 handler instead copies a caller-supplied message. Do not generalize the earlier limitation to current software. The new message layout is inferred from disassembly as a type byte, length byte and up to 16 payload bytes; this is not a validated fan-control protocol or permission to guess opcodes.

A static scan of **5,085 regular host files** under `usr/binos/bin` and `usr/binos/lib64` found only the MCU updater constructing this ioctl constant with the inspected ARM64 MOVZ/MOVK sequence. It does not exclude computed constants, indirect calls or other paths. The complete current **139,264-byte MCU package** also matches router SHA-512; its only firmware payload is **SEQ_MCU_STYX**, version `0x0010`, with matching vendor MD5. It contains no Crestone ENVMCU image/profile to decode. SHA-256: `84cb94ff2a6526f948511c3c0535946e216ac2ebd7d9c4ba5c5cd7ead0e7139c`.

An existing exploratory SoC2 expanded UEFI artifact identifies production **v17.18(3r).s2.cp**, not this chassis's restored development ROMMON. Its ASCII/UTF-16 strings expose inventory/RPM display and generic CPLD access, without an identified profile command. This limited reference search did not establish original derivation provenance, compatibility or a reason to flash it.

## Live diagnostics, restoration and a dump-format correction

`service internal` was temporarily enabled for help inspection. Fan tests still offered fault generation; sensor overrides simulate reported readings, and PFU tests simulate module events. None was invoked. `request platform software system shell R0` returned a requirement for consent-token authentication. Cisco documents that [consent-token authorization mechanism](https://www.cisco.com/c/en/us/td/docs/routers/ios/config/17-x/syst-mgmt/b-system-management/m-consent-token.html). No shell/token/provisioning change occurred.

SCP service was temporarily enabled for two read-only package-copy windows, then disabled. Internal help mode was removed after each of two inspection windows. **All five running-config captures match in configuration content, as do all five startup-config captures.** Timestamp headers are excluded from this comparison. No save, reboot, firmware, fan-register/PWM or thermal-policy change occurred.

The raw FPGA display generates kernel **“returned bad count”** warnings for `sm_env_dump_0/1`. The exact callbacks each return 4,096 bytes, while the captured concatenation contains 8,190. This is consistent with the Linux 5.15 [attribute warning](https://github.com/torvalds/linux/blob/v5.15/drivers/base/core.c#L1959) and [sysfs truncation to PAGE_SIZE−1](https://github.com/torvalds/linux/blob/v5.15/fs/sysfs/file.c#L37). Therefore, do not treat these dumps as contiguous 8 KiB: the final byte of each 4 KiB block is omitted. **All fan fields used in the NIM comparison and their independent identity anchors precede the first boundary**, and the exact current driver confirms those offsets. That interpretation remains intact. This diagnostic defect is not evidence of failed fan control. Further raw polling stopped; normal environmental CLI was used.

Final 17:11 check: CPU **34°C**, inlets **23/24°C**, all displayed sensors Normal; chassis fans **9,660/9,540/9,480 RPM**, PSU fan **6,112 RPM**. NIM DSP **UP**, firmware **66.1.0**, six signaling channels, no DSP errors. The filtered log still contains only the two previously recorded CGX timeouts. All three agent SSH sessions exited normally; socket inventory retained only owner SecureCRT. The router remains powered with the NIM installed.

## Evidence, reproducibility and next step

[Structured results, offsets and hashes](results.json) · [sanitized command selection](../../sanitized-evidence/c8375-recovery/fan-profile-research-20261111/selected-session.log) · [diagnostic warning selection](../../sanitized-evidence/c8375-recovery/fan-profile-research-20261111/diagnostic-warnings.log)

Private originals, configurations, package copies, extracted tree, disassembly and AI-assisted capture/copy/collation helpers remain in `.git/recovery-private/c8375-fan-profile-20261111/`. The result records their hashes and the exact package members. Reproduction uses `unsquashfs -o 4096 -cat PACKAGE MEMBER`, ELF symbols/relocations and `xcrun llvm-objdump -dr --disassemble-symbols=SYMBOL FILE`; no vendor program needs execution. Publication uses the existing sanitizer.

Preserved failures: the first SCP path lacked the slash and was rejected by filename checking; the corrected `bootflash:/` path succeeded without bypassing checks. The mono transfer then hit a Python 3.9 `hashlib.file_digest` postprocessing error; streaming hashes recovered the completed copy. The MCU helper uses the corrected implementation. Broad extraction returned an error for Linux SELinux attributes unavailable on macOS; all 5,085 regular members were checked present with expected sizes. An initial disassembly used an obsolete symbol name and was repeated with the actual symbol.

**Next technical requirement:** decode the Crestone environmental-controller protocol or obtain its matching firmware/native control implementation, then establish the profile transaction, acknowledgement and rollback. A lower-profile trial would retain the NIM, watch temperatures/RPM and verify that automatic thermal escalation still operates. No further NIM removal is needed to establish the already demonstrated presence effect. Actual calls/performance remain owner-deferred; no extended thermal qualification is claimed. Known-value and pattern scanning cannot prove every unknown secret absent.
