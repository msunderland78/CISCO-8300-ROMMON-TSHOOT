# C8375 recovery through the CH341A and board header

Updated October 24, 2026, America/New_York. **Active target: C8375-A / FDO2742M0FK. Active approach: CH341A + accepted 1.8 V adapter + Dupont wires + board header.** The user explicitly reaffirmed this approach after the assistant incorrectly switched to C8300 work. The SOIC-16 clip is expected tomorrow and is an alternate access method.

The programmer/adapter is accepted. Do not repeat standalone programmer checks or the completed broad supply/ground/header resistance matrices. No programmer has been attached to the router, and no external chip read or write has occurred.

## Wiring map: known connections and unresolved signals

This is a tracking map, **not a ready-to-power harness**. Power/ground net identity does not establish the signal route, mux power/control, or acceptable board loading. Leave the programmer disconnected while tracing.

| Function | Adapter active 8-pin output | Micron U1 flash 16-pin package | C8375 header | Evidence/status |
| --- | --- | --- | --- | --- |
| Flash VCC | 8 | 2 | P1 pin 1 | Header-to-flash continuity measured; actual in-circuit powering not tested |
| Ground | 4 | 10 | P1 pin 2 | Continuity established; P2 pins 1/3 also ground |
| Clock | 6 | 16 | Unmapped | Next focused trace below |
| Chip select | 1 | 7 | Unmapped | Previous direct-header scan found no low-resistance path |
| MOSI / data to flash | 5 | 15 | Unmapped | Pending |
| MISO / data from flash | 2 | 8 | Unmapped | Pending |
| WP#/DQ2 control | 3 | 9 | Unmapped | Board control handling unresolved |
| HOLD#/DQ3 control | 7 | 1 | Unmapped | Board control handling unresolved |
| RESET# | No dedicated adapter pin assigned | 3 | Unmapped | Establish existing board handling before attachment |

The adapter's input/output expected operation was confirmed by the user. The flash package assignments follow [Micron Figure 6](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). Do not equate adapter, header, and flash pin numbers.

## Next test: trace the flash clock to U4 common terminals

**This test has not been performed.** Earlier clock scans were from the flash to the header; supply scans were from U4 VCC to the header. Here we are looking for a direct PCB path between the flash clock and a mux terminal, rather than continuity through a powered switch.

Keep all router cords disconnected, CR2032 removed, programmer USB unplugged and programmer unattached to the router. Use resistance mode, contacting one IC lead at a time.

- Fixed red probe: **large right-hand Micron U1_CSPI flash, pin 16 / clock**, bottom-left lead in [the saved photo](c8375-recovery/board-photos/IMG_1260-spi-pair-inspection.jpg).
- Move black probe across **small U4_CSPI mux pins 4, 7, 9 and 12**. U4 is the lower small mux beside P1. These four common terminals are identified in the [PI3CH480 datasheet](https://www.mouser.com/datasheet/2/322/PI3CH480-348795.pdf).

U4 pin numbering in that saved-photo orientation, with pin-1 marker at top-right:

```text
Top row:       8  7  6  5  4  3  2  1
                    U4_CSPI
Bottom row:    9 10 11 12 13 14 15 16
```

| Fixed endpoint | Moving endpoint | Resistance |
| --- | --- | --- |
| U1 flash pin 16 / CLK | U4 mux pin 4 | Pending |
| U1 flash pin 16 / CLK | U4 mux pin 7 | Pending |
| U1 flash pin 16 / CLK | U4 mux pin 9 | Pending |
| U1 flash pin 16 / CLK | U4 mux pin 12 | Pending |

A low resistance would identify one candidate clock trace and its mux channel. We would then trace that channel's paired terminals to the header. This is a hypothesis about the flash/common-side arrangement, not an established board route: if no direct path appears, record that result; do not diagnose a failed mux or assign a header pin. Single-lead access must be practical before attempting this check.

Mux power/control and the other SPI signals will still need a justified setup before a header read. No selector jumper or supply injection has been selected.

## Acquisition and recovery sequence

After the physical target, wiring, route/control and in-circuit power setup are established, the first CH341A operation is read-only identification. Save two full 33,554,432-byte reads from each physical chip under distinct filenames, confirm matching plausible contents, then compare against the known original and nonbooting images. Only then select the physical chip and exact restoration image. See [R-01 and C8375-02/03](ROUTER-RECOVERY-TEST-PLAN.md).

The exact original restore image for this chassis is [the preserved 32 MiB original](c8375-recovery/restore-original-20261023/C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin), SHA-256:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

This file is not the known nonbooting post-write readback. Preserve current chip contents before any restoration.
