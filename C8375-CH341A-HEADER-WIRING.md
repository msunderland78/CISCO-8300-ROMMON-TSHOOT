# C8375 recovery through the CH341A and board header

Updated October 24, 2026, America/New_York. **Active target: C8375-A / FDO2742M0FK. Active approach: CH341A + accepted 1.8 V adapter + Dupont wires + board header.** The user explicitly reaffirmed this approach after the assistant incorrectly switched to C8300 work. The SOIC-16 clip is expected tomorrow and is an alternate access method.

The programmer/adapter is accepted. Do not repeat standalone programmer checks or the completed broad supply/ground/header resistance matrices. No programmer has been attached to the router, and no external chip read or write has occurred.

## Wiring map: known connections and unresolved signals

This is a tracking map, **not a ready-to-power harness**. Power/ground net identity does not establish the signal route, mux power/control, or acceptable board loading. Leave the programmer disconnected while tracing.

| Function | Adapter active 8-pin output | Micron U1 flash 16-pin package | C8375 header | Evidence/status |
| --- | --- | --- | --- | --- |
| Flash VCC | 8 | 2 | P1 pin 1 | Header-to-flash continuity measured; actual in-circuit powering not tested |
| Ground | 4 | 10 | P1 pin 2 | Continuity established; P2 pins 1/3 also ground |
| Clock | 6 | 16 | **P1 pin 4, via U4 IA0/channel A** | P1-4→U4-2 **33 Ω**; U4-4→U1 CLK **22 Ω**. Passing this route still requires mux power/select/enable setup |
| Chip select | 1 | 7 | Unmapped | Previous direct-header scan found no low-resistance path |
| MOSI / data to flash | 5 | 15 | Unmapped | Pending |
| MISO / data from flash | 2 | 8 | Unmapped | Pending |
| WP#/DQ2 control | 3 | 9 | Unmapped | Board control handling unresolved |
| HOLD#/DQ3 control | 7 | 1 | Unmapped | Board control handling unresolved |
| RESET# | No dedicated adapter pin assigned | 3 | Unmapped | Establish existing board handling before attachment |

The adapter's input/output expected operation was confirmed by the user. The flash package assignments follow [Micron Figure 6](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). Do not equate adapter, header, and flash pin numbers.

## Clock trace result: U1 flash to U4 channel A

The requested unpowered trace produced **22 Ω from U1 flash pin 16 / CLK to U4 mux pin 4**. The user reports U4 pins 7/9/12 as really high; no individual values or units were supplied for those three. This points to U4 **channel A** as the flash-clock path. A series resistance along the path is consistent with the 22 Ω reading; no individual resistor has been identified.

The [PI3CH480 datasheet](https://www.mouser.com/datasheet/2/322/PI3CH480-348795.pdf) assigns common terminal YA to pin 4 and its two selectable terminals IA0/IA1 to pins **2 and 3**, respectively. The user subsequently confirmed **U4 pin 2 / IA0 to P1 pin 4 = 33 Ω**. This identifies P1 pin 4 as the header branch for the measured clock channel. Their first message said U1 pin 2; they explicitly corrected it to **U4**, so do not record a new flash-VCC-to-header reading. Actual selector state, mux power and end-to-end operation remain unresolved.

U4 pin numbering in that saved-photo orientation, with pin-1 marker at top-right:

```text
Top row:       8  7  6  5  4  3  2  1
                    U4_CSPI
Bottom row:    9 10 11 12 13 14 15 16
```

| Fixed endpoint | Moving endpoint | Resistance |
| --- | --- | --- |
| U1 flash pin 16 / CLK | U4 mux pin 4 | **22 Ω**, user-reported |
| U1 flash pin 16 / CLK | U4 mux pin 7 | High, qualitative user report; exact value/unit not supplied |
| U1 flash pin 16 / CLK | U4 mux pin 9 | High, qualitative user report; exact value/unit not supplied |
| U1 flash pin 16 / CLK | U4 mux pin 12 | High, qualitative user report; exact value/unit not supplied |

## Clock header branch: P1 pin 4 to U4 IA0

| Fixed endpoint | Header result | Status |
| --- | --- | --- |
| U4 mux pin 2 / IA0 | **P1 pin 4 = 33 Ω** | Confirmed by user, with chip-name correction from U1 to U4 |
| U4 mux pin 3 / IA1 | P1 pins 3–8: **no low readings; most OL** | User qualitative report; other high values not supplied |

The identified route is:

```text
P1 pin 4 -- measured 33 Ω path -- U4 pin 2 / IA0
                                 [channel-A switch]
                                 U4 pin 4 / YA -- measured 22 Ω path -- U1 CLK pin 16
```

The two path measurements do not establish a measured end-to-end header/flash resistance while the switch is unpowered. The datasheet selects IA0 with Select low and Enable low; the board's actual powered levels and supply remain unresolved. No selector jumper, injection, programmer attachment, or read has occurred.

## Alternate clock branch result

The user reports **no small resistance readings and most OL** from U4 pin 3 / IA1 to P1 posts 3–8. Do not convert this into all six being OL or invent the other values. No low-resistance header path was identified on IA1. The measured IA0 path to **P1 pin 4 at 33 Ω** remains the clock header branch; these scans are finished and should not be repeated.

## Next test: trace U1 chip select to a remaining U4 channel

Keep all router cords disconnected, CR2032 removed, programmer USB unplugged/unattached, and meter in ohms. Hold red on **large right-hand Micron U1 flash pin 7 / CS#**, the **second lead from the top on its right side** in the saved-photo orientation. Measure black to **small U4 mux pins 7, 9 and 12**, the remaining common terminals after channel A was traced for clock. Record all three actual resistances or high/OL.

| Fixed endpoint | Moving endpoint / photo position | Result |
| --- | --- | --- |
| Large U1 flash pin 7 / CS# | Small U4 mux pin 7 / top row, second from left | Pending |
| Large U1 flash pin 7 / CS# | Small U4 mux pin 9 / bottom-left corner | Pending |
| Large U1 flash pin 7 / CS# | Small U4 mux pin 12 / bottom row, fourth from left | Pending |

These CS#-to-mux pairs have not been measured; the older CS# test was to the header. A low path would identify the next channel to trace to its header-side terminal. A high-only result would leave this route unresolved rather than diagnose a failed chip. Other SPI signals, board-control handling and mux supply remain unresolved; no powered harness connection or selector jumper is selected.

## Acquisition and recovery sequence

After the physical target, wiring, route/control and in-circuit power setup are established, the first CH341A operation is read-only identification. Save two full 33,554,432-byte reads from each physical chip under distinct filenames, confirm matching plausible contents, then compare against the known original and nonbooting images. Only then select the physical chip and exact restoration image. See [R-01 and C8375-02/03](ROUTER-RECOVERY-TEST-PLAN.md).

The exact original restore image for this chassis is [the preserved 32 MiB original](c8375-recovery/restore-original-20261023/C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin), SHA-256:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

This file is not the known nonbooting post-write readback. Preserve current chip contents before any restoration.
