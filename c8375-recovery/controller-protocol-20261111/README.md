# C8375-A fan curves and temporary diagnostic boot

**November 11, 2026, America/New_York · C8375-05 · 17:40 EST checkpoint**

**No quieter setting has been applied. Normal IOS and the voice NIM are restored.** Further analysis found candidate fan curves in the saved controller data, and temporary maintenance access identified the live FPGA. Two diagnostic boots ended in unexpected resets; a mailbox display contains a concrete alignment defect. The next reader must use the aligned access pattern used by the native NIOS driver.

## Candidate curves

Across 18 saved frames from the [NIM comparison](../fan-nim-comparison-20261111/README.md) and [exact-driver investigation](../fan-profile-research-20261111/README.md), the 86-byte N2H fan block at `0x2b0` has only two variants, differing solely at the table selector `0x2b2`. The H2N block at `0xa60` is identical throughout.

Both blocks contain the same 75 bytes, starting at `0x2b6` and `0xa66`. Interpreted as three groups of 25 values, groups 1 and 2 differ only at their first value: **34 versus 26**. The selector changes 1→2→1 when the NIM is removed and reinserted. All remaining values in those two candidate groups are identical. This is a promising lower-idle-profile lead; **PWM units, array dimensions, controller acceptance and retained thermal escalation remain unverified**. No bytes were changed. Exact arrays and source hashes are in [results.json](results.json).

A byte-pattern search of the 5,085 extracted host files and 18 selected SoC2 artifacts found no matching curve constants. This limited search does not exclude compressed data, constructed tables or code outside the selected files. The incoming native event handler processes type-1 interrupt messages; it does not establish an outbound fan command.

## Access and preserved failures

Owner confirmation identifies the connected **USB-to-RJ45 console** as C8375-A/FDO2742M0FK. Both serial aliases were free before opening. Fresh SSH and serial identity checks match committed IOS 26.1.2, P1 PWR-CC1-400WAC/LIT2727C7NE and the installed NIM-2FXS/4FXOP/FOC23152BE1. The same-session cover/no-programmer confirmation applies; battery/telephone state was not separately reported.

The installed **68,479,592-byte rpboot package** was copied during a temporary SCP window and its SHA-512 independently matched the router. SHA-256: `414a0c5e33a6884b88d505af201ca461a101ca893d69cd38c01f8c3e3c588d2b`. Offline extraction identifies kernel 5.15.199 and the matching initramfs. Vendor programs were not executed on the Mac.

The owner had authorized shutdown tests. A normal reload used temporary confreg `0x1820`, with configuration save declined. At ROMMON, **original normal boot arguments and confreg `0x1822` were saved before any unsaved diagnostic parameter**. The following outcomes are retained:

- The previous one-CPU maintenance command reached a shell. Initial proc/sys mounts failed because their mountpoints were absent; the router subsequently reset. The exact cause was not captured. The console helper's buffered-input issue was corrected; the original helper/log remain preserved.
- A shorter quoted-space command passed ROMMON readback but the EFI loader rejected `/x` as an invalid flag. That attempt did not enter Linux.
- A 127-byte command using `nosmp`, the original EDAC blacklist, `rdinit=bin/sh` and a temporary RAM console node reached a usable shell. The kernel explicitly logged the blacklist. The [Linux PL011 driver](https://raw.githubusercontent.com/torvalds/linux/v5.15/drivers/tty/serial/amba-pl011.c) supplies the 204:64 tty numbering; it was also verified by working live console I/O. Temporary single-CPU operation was diagnostic only.
- Native `dash_fpga` loaded. PCI `0003:03:00.0` identifies `1137:01ec`; BAR0 is `0x882001000000..0x8820010fffff`, board register `07000011`, NIOS version `3f`, fan status `701`. A read-only `/dev/mem` attempt at BAR0+`0x34000` returned **Bad address / zero bytes**.
- Reading `cpu_nios_mlbx_msg_512b_blk2` was followed immediately by a soft reset. Exact callback code at `0xeba0` performs a 32-bit load, while `0xebe8` advances the pointer by two bytes. Every other load is unaligned. This is a leading explanation for the reset, **not a captured exception trace proving causation**. Do not repeat this diagnostic. The native `nios_n2h_memcpy` instead aligns to four bytes and advances four bytes per 32-bit load.

No fan, MCU mode, firmware, TPM, key, provisioning or raw register write occurred. Loading the native driver and normal boot itself initialize hardware; these are not described as completely passive operations.

## Restoration checkpoint

Normal saved boot automatically restored the 16-CPU limit, EDAC blacklist, committed **26.1.2 / packages.conf / confreg 0x1822**. SSH initially timed out during startup, then recovered; management pings succeeded. NTP synchronized at 17:38:36 EST. NIM DSP is **UP / 66.1.0**, with six signaling channels and no DSP errors. Final CPU **33°C**, chassis fans **9600/9600/9540 RPM**, all displayed sensors Normal. No new core payload or filtered CGX/panic/traceback event was observed after normal boot; the earlier two CGX events remain historical evidence.

All three startup-config bodies match. Running configuration differs only by omission of explicit `no ip address` and `ip proxy-arp` lines under the automatically created Service-Engine0/1/0 interface after reboot; that interface is up/up. No network/credential settings were changed or saved. Temporary SCP was removed before reboot. Agent SSH and serial access closed; both aliases and TCP22 inventory are free at this checkpoint.

[Structured results and hashes](results.json) · [SSH selection](../../sanitized-evidence/c8375-recovery/controller-protocol-20261111/selected-session.log) · [first console](../../sanitized-evidence/c8375-recovery/controller-protocol-20261111/20261111-172307-console.log) · [subsequent console](../../sanitized-evidence/c8375-recovery/controller-protocol-20261111/20261111-173045-console.log).

Raw captures, packages, configs and extracted vendor code stay private under `.git/recovery-private/c8375-controller-protocol-20261111/`. Readable console derivatives remove CR/ANSI formatting and replace undecodable bytes; originals are unchanged. Authored Python helpers perform explicit capture/copy or offline collation, with no hardware action on import. No calls, throughput or extended thermal qualification is claimed. Known-value and pattern scans cannot prove every unknown secret absent.
