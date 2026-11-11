# C8375-A aligned controller reads and bounded fan probes

**November 11, 2026, America/New_York · C8375-05 · 17:44–17:59 EST**

**Neither temporary probe slowed the fans. Normal IOS and the voice NIM are restored, with no permanent fan change.** Aligned controller access now works. The controller overwrites the tested host-side curve and override fields; the command needed to apply a profile remains unidentified. This does not establish that software control is impossible.

## Verified access

Same owner-confirmed USB-to-RJ45 target **C8375-A / C8375-E-G2 / FDO2742M0FK**, P1 **PWR-CC1-400WAC / LIT2727C7NE**, NIM **NIM-2FXS/4FXOP / FOC23152BE1**. Both serial aliases were free before opening `/dev/cu.usbserial-AL00F7EQ`. The same-session assembled/cover/no-programmer confirmation applies; no new physical work was requested.

An authorized reload entered ROMMON. Original boot arguments and confreg `0x1822` were saved before an **unsaved** maintenance parameter. Plain `boot` initially selected the 26.2.1 bundle; Ctrl-C aborted that read before Linux. Explicit `boot bootflash:packages.conf` then loaded the installed 26.1.2 kernel/initramfs. The maintenance boot retained the EDAC blacklist and used `nosmp` only for diagnosis.

Native `dash_fpga` and matching `nios_v2` loaded successfully. Fresh partition inspection preceded mounting bootflash **read-only, without journal replay**; the exact installed mono package was mounted read-only at SquashFS offset 4096. Its Python 3.12.9 ran helpers in RAM. Transferred reader and executed probe SHA-256 values matched the Mac copies.

The reader verifies PCI `0003:03:00.0`, vendor/device `1137:01ec`, board `07000011`, BAR0 `0x882001000000..0x8820010fffff`, and three fan identity anchors `33-100267-01`. It maps BAR0+`0x34000` with **O_RDONLY/PROT_READ**, performing individual aligned 32-bit loads. RPM and temperature readings agree with native NIOS sysfs. There was **no unexpected reset in this maintenance session**.

## Bounded probes

These were explicit experimental writes to volatile shared memory, not merely read-only diagnostics. Each probe allowed at most 20 seconds, checked temperature/RPM bounds, restored in `finally`, and forked a separate 25-second restoration guard. Offline regular-file fixtures checked the exact changed bytes, guards and restoration. No unknown controller opcode was sent.

| Probe | Exact temporary change, relative to NIOS page | Observed result |
| --- | --- | --- |
| Idle curve only | Word `0xa64`: `0x322a0000` → `0x32220000`; only byte `0xa66`, 42 → 34 | Immediate readback matched; original 42 returned by the first two-second sample. Ten samples showed no fan/N2H change. |
| Idle curve plus labelled override | Same curve change, plus word `0xab4`: `0x5b000000` → `0x5b000100`; only byte `0xab5`, 0 → 1 | Both values remained at 0.5 seconds, then reverted by one second. Forty samples showed no fan/N2H change. Adjacent byte `0xab7=0x5b` stayed intact. |

An initial override helper correctly refused before writing because it expected the entire adjacent word to be zero. A separate revised helper preserved the live `0x5b` byte. The first RAM file transfer also failed because `/tmp` was absent; after creating it, hashes verified all executed helpers. These failures are retained in the capture.

During both probes, CPU was **28–29°C**, fans **12,240–12,300 RPM**, N2H table **0**, temperature level **0**, N2H override **0**. This is the **maintenance boot profile**, with IOS/voice services absent; normal IOS uses table 1 near 9,500 RPM. The complete 86-byte N2H and H2N control blocks matched their pretest values afterward. No lower profile or retained thermal response was demonstrated.

## Restored operating state

Read-only mounts were removed. The systemd reboot wrapper could not operate with a shell as PID1; explicit `busybox reboot -f` then performed the planned reset. Saved normal boot automatically restored **16 CPUs, the original EDAC blacklist, committed IOS 26.1.2, packages.conf and confreg 0x1822**.

At the 17:58 health checkpoint: all displayed sensors **Normal**, CPU **32°C**, chassis fans **9660/9480/9600 RPM**, PSU fan **6080 RPM**. NIM 0/1 is **ok**, DSP **UP / 66.1.0**, six signaling channels, six idle voice ports and **no DSP errors**. Management G0 and both Service-Engine interfaces are up/up; gateway and Mac pings each pass 3/3. SSH recovered after an initial connection closed during startup. NTP is synchronized, stratum 3/CTRL. No new core payload or filtered CGX/traceback/crash/panic/failure/timeout event was observed.

Running and startup configuration bodies both match the preceding 17:40 checkpoint. No configuration save, firmware update or security-state change was commanded. Agent SSH and serial sessions closed; both serial aliases and router TCP22 connection inventory are free. Calls, throughput and extended thermal qualification remain deferred by the owner.

**Next requirement:** identify the environmental controller's fan command or acceptance handshake and its restoration semantics. Direct shared-field edits alone are now tested negative. Do not repeat the defective mailbox display from the [earlier diagnostic checkpoint](../controller-protocol-20261111/README.md), or infer an opcode from the older 17.15.6 driver.

[Measurements, hashes and configuration comparison](results.json) · [readable console](../../sanitized-evidence/c8375-recovery/aligned-controller-tests-20261111/console.log) · [IOS health commands](../../sanitized-evidence/c8375-recovery/aligned-controller-tests-20261111/selected-session.log).

Original logs, packages, extracted vendor code and gated experimental helpers remain local under `.git/recovery-private/c8375-controller-protocol-20261111/`. Helpers are AI-assisted original Python standard-library code with explicit entry points and no hardware activity on import. Known-value and pattern scans cannot prove every unknown secret absent.
