# C8375 recovery: CH341A wiring and access history

Updated October 25, 2026, America/New_York. **Active target: C8375-A / FDO2742M0FK. Active approach: accepted CH341A + 1.8 V adapter + Dupont wires + newly arrived full SOIC-16 clip on U1_CSPI.** Arrival is now user-confirmed, superseding the earlier delivery expectation and partial-clip/hook proposal retained below.

The programmer/adapter is accepted. Do not repeat standalone programmer checks or completed broad header scans. The user confirms the chassis, all external power/cables removed, CR2032 removed and CH341A USB unplugged. They can identify the clip connection for each U1 leg and now report **all eight harness wires connected according to the map below**. Assembly is user-reported; the first assembled-harness supply check is recorded below, with other electrical checks still pending. No powered target connection or external chip read/write is reported.

## Current SOIC-16 wiring map — C8375-01-SOIC16

User-reported measurements through the newly fitted clip: **U1 pin 10 to P1 pin 2 = 0.3 Ω**; **U1 pin 8 to P1 pin 8 = 9.35 kΩ**. Ground contact is supported. The second is a resistive-path observation, not direct continuity or verification of all contacts. Earlier **9.33 kΩ** readings were bare **U1 pin 7 / CS#** and partial-clip contact 3 to P1-8. Preserve the different endpoints; do not relabel today's pin 8 / MISO result as pin 7 or assign P1-8 a signal function. Present meter mode, lead baseline, polarity and a fresh residual-voltage reading were not separately supplied.

With USB unplugged, route each Dupont wire from the **active 1.8 V adapter output** to the full-clip terminal reaching the specified **physical U1 pin**. Breakout terminal numbers/colors are not assumed to equal package numbers. The user confirms they can map all 16 clip contacts; numerical point-to-point readings for all contacts have not been supplied.

| Active 1.8 V adapter output | Signal | Full-clip contact reaching physical U1 pin |
| --- | --- | --- |
| 1 | CS# / chip select | 7 |
| 2 | MISO / DQ1, flash to programmer | 8 |
| 3 | WP# / DQ2 | 9 |
| 4 | GND / VSS | 10 |
| 5 | MOSI / DQ0, programmer to flash | 15 |
| 6 | CLK | 16 |
| 7 | HOLD# / DQ3 | 1 |
| 8 | VCC, 1.8 V | 2 |

Reference: [Micron MT25QU256ABA datasheet, Figure 6 and Table 1, pages 12–14](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). U1 pins **4/5/6/11/12/13/14 are DNU**: leave their clip terminals electrically disconnected. U1 **pin 3 is RESET#**: no additional programmer wire or hard VCC tie is assigned; Micron specifies an internal pull-up, but the board could still affect the level.

This is an **unpowered assembly map**, not a completed/powered test. Check each used clip terminal and assembled wire against its intended leg, and check for unintended bridges before USB power. WP#/HOLD# must have defined inactive levels for ordinary SPI use; adapter outputs 3/7 provide their usual high levels, but any board-held-low condition or contention must be resolved before powering. Direct clip access avoids needing a working header/mux route; it does not isolate U1 electrically from the board. Loaded VCC, control levels, back-powering and bus contention remain untested. First powered work, after harness checks, is controlled identification and stable reads under R-01; no erase/write is selected.

**Assembled-harness check, October 25, 2026, America/New_York — C8375-01-SOIC16-HARNESS-VCC:** after access clarification, the user measured accessible **P1 pin 1 to P1 pin 2 = 0 V DC and 288 Ω**, with all eight harness wires connected and programmer USB still unplugged under the current setup. The prior mapping makes this the U1 VCC/GND rail pair. This records no residual voltage displayed on that pair and a resistance above the lead baseline; it does not establish powered current, absence of every bridge, or safe in-circuit operation. Keep the earlier board-only **925 Ω** P1-1→P2-1/GND observation separately: the attached, unpowered adapter adds circuit paths, and the measurements are not identical configurations. Fresh lead baseline and polarity were not restated. No powered test/read/write.

**Remaining requested measurements, C8375-01-SOIC16-HARNESS (planned, no remaining readings yet):** keep all external power/console/cables and CR2032 removed, CH341A USB unplugged. Use accessible clip breakout terminals identified by the **U1 physical pins they reach**, without moving the fitted clip or probing hidden chip legs. First check DC volts, black at U1-10/GND and red at U1-2/VCC; establish no residual voltage before resistance mode. Then record settled resistance for **U1-2↔10 (VCC/GND)**, **U1-7↔8 (CS#/MISO)**, **U1-15↔16 (MOSI/CLK)** and **U1-3↔10 (RESET#/GND)**. These check the newly assembled harness and reset path, not the completed header-routing scans. The VCC/GND check has now been performed through P1 as recorded above; do not request it again without a setup change. For the next two pairs use accessible metal/solder points of the **active 1.8 V adapter output terminals 1↔2 (CS#/MISO) and 5↔6 (MOSI/CLK)**, with all wires in place and USB unplugged. This avoids probing the chip legs hidden by the clip. RESET# requires the separately mapped clip breakout contact reaching U1-3, since it has no programmer wire; that check remains pending. Retain changing values/ranges and units; a continuity beep is insufficient. The adapter remains attached but unpowered, so readings include adapter and board paths. No all-pairs-OL expectation or powered-test clearance follows from these checks alone.

## Historical header wiring map: known connections and unresolved signals

This is a tracking map, **not a ready-to-power harness**. Power/ground net identity does not establish the signal route, mux power/control, or acceptable board loading. Leave the programmer disconnected while tracing.

| Function | Adapter active 8-pin output | Micron U1 flash 16-pin package | C8375 header | Evidence/status |
| --- | --- | --- | --- | --- |
| Flash VCC | 8 | 2 | P1 pin 1 | Header-to-flash continuity measured; actual in-circuit powering not tested |
| Ground | 4 | 10 | P1 pin 2 | Continuity established; P2 pins 1/3 also ground |
| Clock | 6 | 16 | **P1 pin 4, via U4 IA0/channel A** | P1-4→U4-2 **33 Ω**; U4-4→U1 CLK **22 Ω**. Passing this route still requires mux power/select/enable setup |
| Chip select | 1 | 7 | Header unmapped; **clip contact 3 supported by reference match** | Clip-3→P1-8 **9.33 kΩ**, matching earlier bare U1-7→P1-8. Indirect evidence; not a powered test |
| MOSI / data to flash | 5 | 15 | Unmapped | Attempted U4 trace was MΩ/OL with difficult fine-pin contact; inconclusive. Assess secure direct flash-leg access |
| MISO / data from flash | 2 | 8 | Header unmapped; proposed direct clip contact 4 | Direct pad hidden; U4 trace MΩ/OL with unreliable access, so contact/routing remains unresolved |
| WP#/DQ2 control | 3 | 9 | Unmapped | Board control handling unresolved |
| HOLD#/DQ3 control | 7 | 1 | Unmapped | Board control handling unresolved |
| RESET# | No dedicated adapter pin assigned | 3 | Unmapped | Establish existing board handling before attachment |

The adapter's input/output expected operation was confirmed by the user. The flash package assignments follow [Micron Figure 6](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). Do not equate adapter, header, and flash pin numbers.

## Earlier proposal: partial SOIC-8 clip plus mapped header connections

The user proposes using the eight-pin clip on part of U1 and supplying the remaining connections through P1/P2. **This is mechanically/electrically possible in principle, not a verified fit or a ready harness.** The actual jaws/cable and placement are now photographed in [IMG_1269](Photos/IMG_1269.jpeg), [IMG_1270](Photos/IMG_1270.jpeg), [IMG_1271](Photos/IMG_1271.jpeg) and [IMG_1273](Photos/IMG_1273.jpeg). The clip appears positioned over the intended CS# end of U1; its electrical contacts remain unverified. Its contact pitch, jaw span for the wide SOIC-16 package, alignment, grip and one-to-one contact continuity must be established unpowered. Do not force the clip or rely on a precarious fit.

The most useful candidate position is the **CS# end, away from the pin-1 dot**, toward the top of the saved U1 photo. A correctly aligned four-contacts-per-jaw clip there would touch **flash pins 5–8 on one side and 9–12 opposite**, including CS# 7, MISO 8, WP# 9 and GND 10. The other touched pins **5, 6, 11 and 12 are DNU** and must have no electrical connection to programmer outputs or supply. This is a proposed contact window, not a confirmed pinout of the actual clip cable.

**Do not plug the ordinary eight-pin clip cable straight into the adapter for this offset position.** Its normal eight-pin pin mapping would be wrong. Every used cable contact must be traced to its actual U1 leg and routed individually through a suitable breakout/Dupont connection; unused contacts remain electrically disconnected. Check that each used contact touches only its intended leg, with no adjacent bridge, before any powered operation.

| Function | U1 pin | Proposed access | Status |
| --- | --- | --- | --- |
| CS# | 7 | Partial clip contact 3 | **9.33 kΩ** reference match supports connection; no powered functional test |
| MISO | 8 | Partial clip, individually mapped | Clip fit/contact map pending |
| WP#/DQ2 | 9 | Partial clip if needed; establish inactive control handling | Pending |
| Ground | 10 | Known P1 pin 2 or **clip contact 6** | User corrected and validated chip/clip ground; low reading **0.3 Ω** |
| 1.8 V VCC | 2 | Known P1 pin 1 | Net mapped; in-circuit powering not tested |
| Clock | 16 | P1 pin 4 through U4 IA0/channel A | Two trace segments mapped; **mux power/select/enable not established** |
| MOSI | 15 | Header/board route still to be identified | Unmapped |
| HOLD#/DQ3 | 1 | Existing board handling or verified connection | Must establish appropriate inactive level |
| RESET# | 3 | Existing board handling; part has internal pull-up | No new hard tie assigned |

Thus the proposal could solve direct access to CS#/MISO, but it does not by itself complete MOSI, clock switching, or board-control/power handling. All clip work in this phase is unpowered.

## Using CH341A as a diagnostic tool

After a known, compatible circuit connection is established, chip-ID probing and repeatable full reads are useful diagnostics. **An ID/read-only command does not make guessed wiring electrically safe.** A USB-powered programmer applies voltage and drives signals even with the router's own power cords removed. Wrong voltage, a supply-to-ground short, driving an existing output, or back-powering other circuitry can damage the flash, programmer/adapter or board.

Use only the accepted **1.8 V adapter output**, not the bare programmer pads (the bare signal levels measured approximately 5.18 V). Disconnect programmer USB and normal router power before every wiring change. Guessing unknown P1/P2 posts or moving wires while powered is not the next diagnostic step. Controlled testing follows identification of compatible signal nodes and acceptable loading; it does not replace that identification.

**Photo observations:** IMG_1269 shows a separate small green clip breakout with eight male legs, allowing individual cable contacts to be reached; this is not the green 1.8 V adapter with the blue socket. IMG_1270/1271/1273 show the clip on U1's end away from the pin-1 dot, consistent with the proposed CS-end window. The jaw contacts are partly hidden, so photos do not prove all four contacts per side are aligned, stable, or isolated. No contact numbering is inferred from ribbon color or breakout position.

## October 25: corrected ground contact and partial-clip map

The user explicitly corrected the earlier numbering error after checking the bare chip and reseating/checking the clip: **U1 pin 10 is ground, reached by clip/breakout contact 6**. The earlier low reading, **0.3 Ω to known ground**, belongs to this corrected ground connection, not U1 pin 9 / clip contact 5. Other checked contacts were reported OL to ground. Preserve the prior statement as a corrected report, not evidence of a WP# ground tie or a clip bridge. The requested clip-removed WP# investigation is superseded; no further ground scan is needed for this correction.

These are ground-reference checks. They do not by themselves establish point-to-point continuity of the non-ground contacts.

| Clip/breakout contact, user's numbering | U1 physical pin in proposed window | Signal | Status |
| --- | --- | --- | --- |
| 1 | 5 | DNU | User-described alignment; leave electrically disconnected |
| 2 | 6 | DNU | Inferred position within window, not separately measured; leave disconnected |
| 3 | 7 | CS# | Indirect **9.33 kΩ** reference match supports intended contact |
| 4 | 8 | MISO | Direct pad hidden; next trace clip contact to remaining U4 commons |
| 5 | 9 | WP#/DQ2 | Earlier ground assignment explicitly withdrawn; control handling unresolved |
| **6** | **10** | **GND** | **User validated bare chip and reseated clip; corrected low ground reading 0.3 Ω** |
| 7 | 11 | DNU | Inferred position within window, not separately measured; leave disconnected |
| 8 | 12 | DNU | User-described alignment; leave disconnected |

## Clip access limitation and contact-3/contact-4 result

The user reports that the fitted clip **blocks access to the actual U1 legs/pads**, so the direct clip-3→U1-7 and clip-4→U1-8 checks could not be performed. Do not record them as OL or as verified contacts. Their broad statement that all clip contacts read OL to other clip contacts was explicitly withdrawn. A specific follow-up confirms **clip contact 3→clip contact 4 = OL**. This is only that pair's result; it does not establish every inter-contact reading or prove both jaws are making chip contact.

| Pair | Actual result / status |
| --- | --- |
| Clip contact 3 → actual U1 chip lead/pad 7 | Not performed: jaw blocks access |
| Clip contact 4 → actual U1 chip lead/pad 8 | Not performed: jaw blocks access |
| Clip contact 3 → clip contact 4 | **OL**, user explicitly confirmed |

## CS# contact reference result

The earlier bare-chip scan recorded **red U1 pin 7 / CS#, black P1 pin 8 = 9.33 kΩ**. With the clip seated, the user now measures **red clip contact 3, black P1 pin 8 = 9.33 kΩ**, exactly matching the recorded value. This supports the intended clip CS# connection without accessing a hidden leg. It is indirect resistance evidence, not unique proof of physical landing, an identified direct header signal, or a powered functional test. **P1 pin 8 remains only a resistance reference; it is not assigned as CS#.** No repeat is needed.

## Data-trace attempt: high readings with difficult U4 access

The user reports the requested six data-to-common-terminal pairs **all in MΩ or OL**, while explicitly saying U4 is extremely small and difficult to contact reliably. No individual values or allocation of OL versus MΩ were supplied. Preserve this as a group report with a contact-access limitation, not proof of disconnected signals or a faulty mux. **Stop further U4 fine-pin probing with this setup.** Earlier positive clock-path measurements remain recorded, but they do not make the uncertain data-path negatives definitive.

| Red endpoint | Black endpoints attempted | User result |
| --- | --- | --- |
| Large U1 flash pin 15 / MOSI | Small U4 pins 7, 9, 12 | MΩ or OL, group report; exact per-pair values not supplied, difficult contact |
| Clip contact 4 / expected MISO | Small U4 pins 7, 9, 12 | MΩ or OL, group report; exact per-pair values not supplied, difficult contact |

## Next access decision: bypass the mux rather than repeat tiny-pin scans

The proper wide SOIC-16 clip, once received and checked for fit/contact mapping, would provide direct access to both **U1 pin 15 / MOSI** and **pin 16 / CLK**, as well as the other required flash pins. The user says it remains approximately 16 hours away, expected October 25 around 4:30 PM local time.

A conditional alternative using existing tools is the partial CS-end clip plus **two secure individual hook connections** directly to U1's uncovered pins **15 / MOSI** and **16 / clock**. In the saved-photo orientation these are the left-side bottom two leads: pin 15 second from bottom, pin 16 bottom-left. They are adjacent, so ordinary hooks may be too large to attach independently without bridging or stressing the legs. The actual hook tips have not been photographed or assessed. A 4 mm meter connector specification does not establish hook-tip clearance.

| Required connection | Conditional direct-access proposal | Status |
| --- | --- | --- |
| MOSI | Accepted adapter output 5 to U1 pin 15 through a suitably isolated, stable hook | **Not connected; hook fit unverified** |
| CLK | Accepted adapter output 6 to U1 pin 16 through another suitably isolated, stable hook | **Not connected; hook fit unverified** |
| CS#/MISO/GND | Existing partial clip contacts 3/4/6, individually routed as established | Ground confirmed, CS# supported indirectly, MISO contact unresolved |
| VCC | Known P1 pin 1, 1.8 V only | Net mapped; loaded powering not tested |
| HOLD#/RESET#/WP# | Board/control handling still to be established | Pending |

Using direct flash-side MOSI/CLK connections would avoid requiring the unpowered U4 path to pass those signals. This is an access proposal, not a ready harness or authorization to energize uncertain contacts. Safe loading, remaining control levels and contact isolation still need a justified setup. Do not use hand-held needle pressure or an improvised unstable connection for a firmware write.

**Immediate next step while awaiting the full clip:** put a clear photograph of the **two actual hook tips beside U1's exposed pins 15/16** in Photos, with the clip/programmer cables and all normal router power disconnected. Leave the hooks unattached for this first size/fit view; do not force them onto IC legs. We will decide whether direct isolated contacts are practical from the actual tools. No further U4 sweep, powered connection, jumper or flash operation is requested. If the hooks cannot provide secure single-leg contact, use the proper wide SOIC-16 clip when it arrives rather than guessing/forcing contacts.

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

## Chip-select result: no low path to U4 or either header

The user expanded the requested CS# scan: **large U1 flash pin 7 to every pin on small U4 and every post on P1 and P2**. They report no reading below approximately **5,000 Ω / 5 kΩ**. Per-endpoint values were not supplied. This includes the requested U4 common terminals 7/9/12; do not ask for those measurements again or assign exactly 5 kΩ to each endpoint.

No low-resistance chip-select connection has been established to these tested endpoints. The assumption that CS# would share U4 with clock remains unconfirmed; possible alternate mux/buffer/logic routing has not been traced. These measurements do not diagnose a failed flash, mux, or broken PCB trace. The [Micron pin reference](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf), Figure 6, still identifies SOIC-16 pin 7 as S#/chip select.

## Prior U3 chip-select trace request: superseded by partial-clip assessment

Keep all router cords disconnected, CR2032 removed, programmer USB unplugged/unattached, meter in ohms. Fixed red remains on **large right-hand U1 flash pin 7 / CS#**, second lead from the top on its right side in the saved photo. Move black to **small U3_CSPI mux pins 4, 7, 9 and 12**. U3 is the **upper small mux beside P2**, above U4. No individual results for these CS#-to-U3 pairs have been supplied. They are no longer the immediate requested action.

U3 is the same PI3CH480 family. Identify its pin-1 marker before counting; in the saved-photo orientation the marker is at top-right, with the same row numbering as U4:

```text
Top row:       8  7  6  5  4  3  2  1
                    U3_CSPI
Bottom row:    9 10 11 12 13 14 15 16
```

| Fixed endpoint | Moving endpoint / photo position | Result |
| --- | --- | --- |
| Large U1 flash pin 7 / CS# | Small U3 pin 4 / top row, fourth from right | Pending |
| Large U1 flash pin 7 / CS# | Small U3 pin 7 / top row, second from left | Pending |
| Large U1 flash pin 7 / CS# | Small U3 pin 9 / bottom-left corner | Pending |
| Large U1 flash pin 7 / CS# | Small U3 pin 12 / bottom row, fourth from left | Pending |

This earlier targeted request is retained as history, not a new instruction to resume CS# hunting. These were candidate alternate-route tests, not a claimed U3 assignment. Keep the accepted programmer unattached; mux power/control and the rest of the signal map remain unresolved. No jumper, supply injection or flash operation is selected.

## Acquisition and recovery sequence

After the physical target, wiring, route/control and in-circuit power setup are established, the first CH341A operation is read-only identification. Save two full 33,554,432-byte reads from each physical chip under distinct filenames, confirm matching plausible contents, then compare against the known original and nonbooting images. Only then select the physical chip and exact restoration image. See [R-01 and C8375-02/03](ROUTER-RECOVERY-TEST-PLAN.md).

The exact original restore image for this chassis is [the preserved 32 MiB original](c8375-recovery/restore-original-20261023/C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin), SHA-256:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

This file is not the known nonbooting post-write readback. Preserve current chip contents before any restoration.
