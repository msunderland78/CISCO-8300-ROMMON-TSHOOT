# Cisco router recovery: test plan and tracking log

Created: **2026-10-24** · Time zone: **America/New_York**  
Last updated: **2026-10-24**  
Workspace: `/Users/games/Documents/SOFTWARE`

This is the active tracking document for the five routers below. It expands the discussion and [initial bench worksheet](recovery-prep-20261024/TODAY-BENCH-PLAN.txt). Use this Markdown file for subsequent measurements, results, decisions, and next steps. The earlier recovery-context files remain the detailed history.

**Immediate priority:** map the C8375 flash headers with the board unpowered. If a header provides verified electrical access, attempt read-only backups before the SOIC-16 clip arrives. Otherwise, prepare the harness and wait for the clip. While awaiting tools, perform the C8300 external console checks.

**Execution status:** offline software preparation is verified. User measurements establish **P1 header pin 2 to U1 flash pin 10 (ground), settled 0.6 Ω**, and **P1 header pin 1 to U1 flash pin 2 (VCC), 0.3 Ω**. Actual U1 VCC relative to mapped ground measured **0.000–0.002 V DC** with cords disconnected and CR2032 removed. Earlier unstable values are preserved in the log. Remaining SPI signals, mux/bank routing, and U2 mapping remain to be checked. No programmer connections, flash reads/writes, or new router console tests have been reported in this session. Checkboxes distinguish completed preparation from planned bench work.

## 1. Fleet and current evidence

Tracking IDs are names for this document; they are not confirmed labels on the physical chassis. Match each chassis to its serial before starting work.

| Tracking ID | Router | Confirmed identification | Last known condition | Recovery approach |
| --- | --- | --- | --- | --- |
| C8235-A | Worked-on C8235-G2 | Console ID `FGL2835L42B`; PCB barcode `FOC28292GX9`; Arata r2 | Release firmware reaches TPM manufacturing-status halt before Cisco ROMMON | Read both flash chips; identify surviving development firmware; preserve unique board data |
| C8235-B | Second C8235-G2 | PID, serial, board revision pending | User reports nonworking; individual boot symptoms and write history pending | Establish separate baseline and obtain original backups |
| C8235-C | Third C8235-G2 | PID, serial, board revision pending | User reports nonworking; individual boot symptoms and write history pending | Establish separate baseline and obtain original backups |
| C8375-A | C8375-G2, identifies as C8375-E-G2 | Chassis `FDO2742M0FK`; Crestone r3 | No normal startup output after ROMMON experiment; previously reported blinking red STATUS and maximum fans | Identify physical target, back up both chips, restore this chassis's exact original SPI image |
| C8300-A | C8300-1N1S | Full PID suffix and serial pending | User reports steady red STATUS, green power/fan indications, no console through either connection type | Validate console paths, then inspect hardware and identify boot storage |

Do not assume that the other C8235s share C8235-A's board revision, flash parts, firmware, TPM state, or failure cause. Current power state, disassembly, battery state, and cable connections must be recorded at each bench session.

### Preparation already completed

- [x] Read [C8235 recovery context](C8235-G2-RECOVERY-CONTEXT.txt).
- [x] Read [C8375 condensed context](C8375-E-G2-RECOVERY-CONTEXT.txt).
- [x] Read [C8375 consolidated history](C8375-G2-RECOVERY-CONTEXT.md).
- [x] Inventory all 300 pre-existing workspace files, including subfolders: [inventory](recovery-prep-20261024/WORKSPACE-INVENTORY.txt).
- [x] Rehash the C8375 original restore image and both original full-chip source reads; all match the recorded original SHA-256.
- [x] Record the user's clarification: three C8235-G2s, one C8375-G2, one C8300-1N1S.
- [x] Check local software availability: Homebrew present; `flashrom` was absent at the initial inspection and was subsequently installed and verified under P-02 below.
- [ ] Tie tracking IDs to physical labels and chassis serials.

## 2. Equipment and connection rules

The user confirmed receipt on October 24, 2026 of the CH341A, 1.8 V adapter, Dupont wires, SOIC-8 clip, fine probe points, and hook clips. Receipt does not establish electrical compatibility or wiring. The SOIC-16 clip remains expected October 25; no arrival confirmation is recorded for it.

| Equipment | Reported availability | Intended use | Verification still needed |
| --- | --- | --- | --- |
| CH341A programmer | Received October 24, user-confirmed | SPI identification, reads, eventual recovery writes | Actual board revision, operating mode, pinout, logic levels |
| 1.8 V adapter | Received October 24, user-confirmed | Target power and signal-level translation | Input/output orientation, circuit/component identification, output measurements |
| SOIC-8 clip | Received October 24, user-confirmed | Only independently identified compatible 8-pin devices | Cable continuity, orientation, fit, target voltage |
| 40 × 20 cm Dupont wires | Received October 24, user-confirmed | Mapped headers and SOIC-16 breakout wiring | Connector genders, continuity, secure fit |
| Needle meter probe tips | Received October 24, user-confirmed | Fine unpowered connection mapping | Meter compatibility, safe exposed tip length, and refreshed lead baseline after fitting |
| Meter hook clips | Received October 24, user-confirmed | Secure connections on adequately spaced test points/headers | Actual hook jaw size and insulation; 4 mm connector size does not establish IC-leg clearance |
| SOIC-16 clip and breakout | Expected October 25 | Access to the identified G2 flash packages | Wide-body fit, pin numbering, every cable contact |
| Fluke 111 | Previously documented | DC voltage, resistance, continuity | Leads in COM and V/ohm, correct mode, lead resistance baseline |

### Rules that apply to every bench session

1. Identify the chassis and physical chip before attaching anything.
2. For resistance/continuity measurements, disconnect all external power inputs and cables. Record/remove the coin-cell where needed for an unpowered board; photograph its orientation first. Confirm no residual DC voltage on the nodes before changing to resistance mode.
3. Wait for stored charge to discharge. Do not short rails or capacitors to discharge them.
4. Use the V/ohm meter input, not a current input. Record actual resistance values rather than only a beep.
5. Do not bridge unknown headers, ground unknown control pins, or assume a header's function from its label.
6. The identified G2 flashes require **1.8 V power and compatible logic signals**. A supply regulator alone is not proof of signal-level translation.
7. Keep router power, console, and USB disconnected during external-programmer work. Do not address bus contention by powering the router and programmer together or increasing voltage.
8. Do not use the SOIC-8 clip on half of a SOIC-16 package. Do not use oversized meter hooks on fine IC legs.
9. For any later powered board measurement, restore mounting and cooling, secure insulated measurement leads while power is off, and select DC volts before power. Keep measurements on the low-voltage logic board; do not probe inside a mains PSU.
10. Preserve original dumps, board identity data, configurations, and credentials privately. A full main-array flash backup does not necessarily include OTP or separate security/configuration registers.

## 3. Work order and decision points

| Order / ID | Task | When | Completion evidence | If it does not pass |
| --- | --- | --- | --- | --- |
| 1 / F-01 | Identify and label all five chassis | Before board work | PID/serial and photo recorded for each | Resolve identity before using any chassis-specific file |
| 2 / C8300-01 | Validate C8300 external console paths | Can start before delivery | Logged startup, settings, active-console LEDs, received-byte observations | Continue to controlled physical inspection |
| 3 / C8375-01 | Map C8375 P1_CSPI/P2_CSPI unpowered | First task with fine probes | Separate connection tables for each flash | Trace mux/series paths or wait for SOIC-16 clip |
| 4 / P-01 | Validate programmer and adapter separately | Before any target attachment | Circuit identification, orientation, voltage record | Correct the setup before connecting a router |
| 5 / R-01 | Obtain two stable full reads per physical chip | After electrical checks | Size, hash, byte comparison, credible data | Diagnose wiring, loading, mux access or isolation; no write |
| 6 / C8375-02 | Identify the C8375 active target | After stable reads | Comparison against original and known nonbooting references | Inspect differences; do not force a bank assignment |
| 7 / C8375-03 | Restore exact C8375 original image | After target identification and preserved backups | Full readback equals original, then logged boot test | Separate programming mismatch from persistent boot failure |
| 8 / C8235-01 | Baseline and back up each C8235 independently | In parallel with preparation only where practical | Per-chassis observations and both-chip backups | Continue acquisition and mapping before firmware experiments |
| 9 / C8300-02 | Inspect C8300 logic board and identify storage | If console checks remain silent | Photos, memory/connector inspection, identified flash parts | Choose the next hardware test from observed evidence |

Each task remains **planned** until a dated result is entered. A failed test is useful evidence; record it before changing the setup.

## 4. C8375: first board task today

### C8375-01 — Identify and map the headers

Reference: [saved flash/header photo](c8375-recovery/board-photos/IMG_1260-spi-pair-inspection.jpg).

In that photo, **U2_CSPI is the left flash and U1_CSPI the right flash**. P1_CSPI, P2_CSPI, and nearby muxes are visible. Header pinouts, mux routing, and primary/golden chip assignments remain unknown.

- [ ] Confirm chassis `FDO2742M0FK` and take a current photo in a documented orientation.
- [x] Disconnect all external cables/power and record battery state: user confirms all cords disconnected and CR2032 removed.
- [x] Check the unpowered flash supply relative to ground before further continuity mapping: P1 header pin 2 (ground) to U1 flash pin 2 (VCC) measured 0.000–0.002 V DC. This is a check of that rail, not every board rail.
- [x] Record probe-to-probe resistance: **0.2 Ω with the original probes**, then **about 0.6 Ω with the new fine tips**, user-reported. Original separated probes showed OL. Compare each measurement with the baseline for its actual lead configuration.
- [ ] Identify each flash's pin-1 marker and number the headers from clear photos. Do not equate a header's numbering with flash numbering.
- [ ] Map ground first, then the required power/data/control signals.
- [x] Verify P1_CSPI header pin 2 to U1_CSPI flash pin 10 (VSS): user obtained a settled 0.6 Ω, matching the fine-tip baseline, after initially unstable contact.
- [x] Verify P1_CSPI header pin 1 to U1_CSPI flash pin 2 (VCC): user reported 0.3 Ω. The pair's requested DC reading was not separately supplied; do not invent one.
- [ ] Record the path to **both** flash chips, including higher resistance or open readings.
- [ ] Determine whether muxes or other circuitry interrupt header-to-flash access.
- [ ] Decide whether there is enough evidence for a header-based read or whether to wait for the clip.

Values near the meter lead baseline support a direct connection. Higher resistance may indicate a series resistor or another circuit path. A kΩ reading does not establish a direct trace. An unpowered mux may leave a valid route disconnected; an open reading alone does not prove a failed trace or component.

**Initial preparation reported October 24:** user measured 0.2 Ω with tips touching and OL with tips separated, and removed the CR2032. Reported installed orientation: the positive face pointed toward the router's center and the negative face toward the outside. This records the user's description, not independently confirmed holder polarity. The removed battery subsequently measured **3.03 V DC**, user-reported, consistent with its nominal unloaded voltage; no load test or battery-health conclusion follows. The user then explicitly confirmed that all cords are disconnected. Existing IMG_1260 and its inspection crop are sufficiently clear for accessible-header checks; another photograph is not required unless the actual layout differs or orientation becomes unclear. Physical chassis serial is not independently reconfirmed. P1_CSPI pin 1 subsequently measured **0 V DC and 980 Ω to the USB connector shell**; other endpoints and rail voltages remain unverified.

**Preliminary scan completed:** P1_CSPI pins 1–8 have user-reported readings to the USB connector shell, listed below. These endpoint checks do not establish SPI pin functions, USB-shield-to-flash-ground identity, or discharge of every board rail. Next is verification against a known flash ground, if a single IC leg can be contacted reliably with the current probes. Do not force fine-leg probing with an oversized tip.

### P1_CSPI preliminary header scan

Reference endpoint: USB connector metal outer shell. The user explicitly clarified that “chassis ground” in subsequent reports means this same measurement point. U1_CSPI pin 10 to this reference was reported as 0 V DC / 0.3 Ω and later as **0.6 Ω with the fine tips**, equal to the newly reported fine-tip baseline. This supports a direct ground connection. User reports all external cords disconnected and CR2032 removed. Original lead baseline: 0.2 Ω; fine-tip baseline: about 0.6 Ω. Do not subtract one configuration's baseline from another configuration's measurements. P1 pin 2's earlier conflicting results remain in the record, with a new fine-tip repeat of approximately 1.1 Ω to the shell that varies with contact.

| Header pin | DC voltage to USB shell | Resistance to USB shell | Assessment |
| --- | --- | --- | --- |
| 1 | 0 V, user-reported in initial scan | 980 Ω to shell in initial scan | Subsequently mapped to U1 flash pin 2 (VCC) by a separate 0.3 Ω direct measurement; this does not establish a valid powered supply |
| 2 | 0 V, earlier user report | Originally 0.2 Ω to shell; fine-tip shell repeat approximately 1.1 Ω with variation; subsequent direct U1-pin-10 check settled at 0.6 Ω | P1 pin 2 mapped to U1 flash VSS/ground by the settled 0.6 Ω direct result, equal to fine-tip baseline. Earlier 11.8 Ω and contact variation retained as historical observations |
| 3 | 0.015 V (15 mV), user-reported | OL, user-reported | User corrected the initially reported pin number from 2 to 3; function unknown |
| 4 | 0.006 V (6 mV), user-reported | OL, user-reported | Function unknown; nonzero DC reading recorded, no fault or discharge conclusion |
| 5 | 0.003 V (3 mV), user-reported | OL, user-reported | Function unknown; stability over time not reported; no fault or discharge conclusion |
| 6 | Fluctuating 0.000–0.001 V (0–1 mV), user-reported | OL, user-reported | Near-zero displayed voltage; function unknown |
| 7 | 0.021 V (21 mV), user-reported | OL, user-reported | Function unknown; stability over time not reported; no fault or discharge conclusion |
| 8 | 0 V, user-reported | 5.625 kΩ (5,625 Ω), user-reported | Resistive path; no direct shell connection demonstrated; function unknown |

**Header orientation correction:** the assistant's earlier description of pin 2 as beside pin 1 identified the wrong post. The user clarified that actual pin 2 is above pin 1 in their working orientation, and that the 0.015 V / OL measurements belong to **pin 3**. The user then measured actual pin 2 at **0 V DC and 0.2 Ω to the USB shell**, matching the lead baseline. This supports a direct shell connection; flash/circuit-ground continuity remains to be established before programmer wiring. Use the board's printed numbers and the user's confirmed orientation; do not assume a conventional drawn arrangement. The pin-3 DC reading is nonzero, and the user also reported an ohms reading; do not treat this as verification that all endpoints are discharged or that OL identifies a faulty/open board trace. Voltage should be checked first on subsequent endpoints.

**Current checkpoint assessment:** C8375 P1 power/ground continuity to U1 is established, but no direct clock/CS# path has been found. U4 mux ground is mapped; its VCC-to-flash-VCC reading is 1.22 kΩ, so no shared supply is assumed and fine mux probing is paused. Actual programmer/adapter photos are retained. Bare CH341A USB initialization and empty-bus SPI probing work without sudo despite a nonfatal detach warning (revision reported as 3.0.4; all-FF empty ID). A subsequent user sudo probe removed the access warning while retaining the informational entitlement line and expected no-chip result. User measured the bare programmer's labeled 3.3 V pad at 3.322 V and its 5 V pad at 5.195 V relative to labeled GND. Bare idle signal readings are now CS 5.19 V, MOSI 5.182 V, and CLK 5.182 V relative to GND. Direct connection to the 1.8 V flash is unsuitable; adapter power and signal translation remain unverified. User now reports continuity from both labeled programmer GND reference points to socket position B1 in the temporary upright-BIOS diagram; exact resistance and refreshed baseline were not supplied. Next map socket connections to the labeled 3.3 V pad with USB unplugged. Adapter placement remains pending. Keep adapter, clips, and all routers detached; adapter orientation, output voltage/logic levels, socket mapping, and target access remain pending.

**Initial flash-ground check (historical; resolved by settled repeat below):** U1_CSPI is the right Micron chip in the saved inspection crop, with its pin-1 dot at bottom-right and VSS pin 10 second from the top on the image's left side. The user measured the requested P1_CSPI pin 2 to U1 pin 10 pair at 0 V DC / 11.8 Ω, and U1 pin 10 to the USB-shell reference at 0 V DC / 0.3 Ω. These are measured observations, but they do not validate P1 pin 2 as a common programmer ground. Repeat the original P1 pin 2 to USB-shell pair with the fine probes and reliable contact before continuing net assignments.

**Equipment/numbering clarification:** after the user confirmed today's tool delivery, clarified the SOIC-16 numbering in IMG_1260 orientation: right side bottom-to-top 1–8; left side top-to-bottom 9–16. The bottom-right dot identifies pin 1. Thus U1_CSPI VSS pin 10 is second from the top on the image's left side. This is flash-package numbering, distinct from the header's printed numbers. The requested DC check is an unpowered pre-resistance check, not a request to power the board or expect 1.8 V. Refresh the tips-together resistance baseline after fitting the new needle points; the old 0.2 Ω baseline was obtained before this delivery.

**Initial ambiguous report (historical; resolved below):** flash pin 10 to “chassis ground” was reported at **0 V DC and 0.3 Ω**, and “pin 2” to flash pin 10 at **0 V DC and 11.8 Ω**. The assistant initially asked whether pin 2 meant the header or flash and whether the USB-shell/chassis references were separate. The user subsequently resolved both wording questions; use the confirmed endpoints below. No rail-short conclusion follows from the initial wording.

**Endpoint clarification (historical, before the settled repeat):** the user explicitly confirmed that **P1_CSPI header pin 2 to U1_CSPI chip pin 10** is the pair measuring **0 V DC and 11.8 Ω**. This is not a chip-VCC-to-ground measurement. U1 chip pin 10 to “chassis ground” is reported at **0 V DC and 0.3 Ω**, and the user further clarified that this is the **same USB-shell reference used earlier**. Keep the earlier header-pin-2-to-USB-shell result of **0 V DC and 0.2 Ω** as historical evidence rather than overwriting it. These readings do not agree; contact quality or endpoint identification may be involved, but no cause is established. Do not request a comparison of supposedly separate USB/chassis reference points. Next repeat **P1_CSPI pin 2 to that same USB shell with the fine probes**, recording the settled resistance and a second contact attempt; new-tip lead baseline also remains unreported. Header pin 2 is not a verified direct flash ground and must not be wired as programmer ground on the current evidence.

**Fine-tip baseline and first repeat (historical, before the settled direct result):** the user reports **about 0.6 Ω with the fine tips touching**, **0.6 Ω from USB shell to U1_CSPI pin 10 with those tips**, and a varying USB-shell-to-P1-header-pin-2 reading whose most consistent value is **about 1.1 Ω**. U1 pin 10 to shell therefore matches the current lead baseline. P1 pin 2 to shell is approximately 0.5 Ω above baseline, with limited precision because of contact variation. This makes contact resistance a plausible explanation for the earlier discrepancy, not a proven cause or evidence of a failed board connection. Next repeat **P1_CSPI header pin 2 to U1_CSPI chip pin 10** once using the same fine-tip configuration, record the settled value/range, and compare against 0.6 Ω before accepting the header ground mapping. No new powered measurement or programmer connection is requested.

**Ground check resolved by direct repeat:** the user held the **P1_CSPI header pin 2 to U1_CSPI flash pin 10** measurement for an extended period. It initially varied substantially and then **settled at 0.6 Ω**, matching the new fine-tip shorted-lead baseline. Accept **P1 header pin 2 → U1 flash VSS/ground** as the established measured connection. Earlier 11.8 Ω and approximately 1.1 Ω readings remain in the historical record; contact variation is a plausible explanation, not a demonstrated damaged component. No further repetition of this same pair is requested. This does not validate other header pins or programmer wiring. Next test **P1 header pin 1 to U1 flash pin 2 (VCC)**, DC voltage first; the proposed supply connection is not yet established.

### Micron package reference

The previously identified part is **MT25QU256ABA8ESF-0SIT / RW170**, 256 Mbit / 32 MiB, 1.7–2.0 V operating supply, SOIC-16 wide body. Confirm the marking on the unit being measured.

The following is the **IC pin reference, top view, pin-configuration option 8** from the [Micron datasheet, Figure 6](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). It is **not** a verified header or programmer-adapter pinout.

| Flash pin | Signal | Role in ordinary single-data-line SPI |
| --- | --- | --- |
| 1 | DQ3/HOLD# | Hold control; establish suitable inactive level |
| 2 | VCC | 1.8 V supply |
| 3 | RESET# | Reset control; establish suitable inactive level |
| 7 | S# | Chip select |
| 8 | DQ1 | MISO, data from flash |
| 9 | W#/DQ2 | Write-protect/control input |
| 10 | VSS | Ground |
| 15 | DQ0 | MOSI, data to flash |
| 16 | C | SPI clock |

Pins **4, 5, 6, 11, 12, 13, 14** are DNU: do not connect them. Check board pull-ups and other drivers before deciding how HOLD#, RESET#, and W# will be handled. Do not hard-short an unknown board-driven control.

### U1_CSPI mapping record

| Signal / flash pin | P1_CSPI pin and resistance | P2_CSPI pin and resistance | Other path / notes |
| --- | --- | --- | --- |
| GND / 10 | **P1 header pin 2: settled 0.6 Ω to U1 flash pin 10; connection verified by user measurement** | Pending | Fine-tip baseline 0.6 Ω; U1 pin 10 to shell 0.6 Ω. Initially unstable / 11.8 Ω result retained in history |
| VCC / 2 | **P1 header pin 1: 0.3 Ω to U1 flash pin 2; direct connection supported** | Pending | Mapping-pair voltage was not separately reported; subsequent actual U1 VCC-to-ground check was 0.000–0.002 V DC with all sources disconnected |
| CS# / 7 | P1 pins 3–7 reported approximately the same high/OL pattern as the clock scan; P1 pin 8 **9.33 kΩ** | Pending | Individual values for pins 3–7 not restated; do not copy clock values as exact CS measurements. No direct CS# connection identified |
| CLK / 16 | Tested P1 pins 3–8: none showed a low-resistance connection; values below | Pending | No P1 clock assignment established. Check another signal / mux routing; supply and ground continuity do not establish which header serves which flash |
| MOSI / 15 | Pending | Pending | |
| MISO / 8 | Pending | Pending | |
| HOLD# / 1 | Pending | Pending | |
| RESET# / 3 | Pending | Pending | |
| W# / 9 | Pending | Pending | |

### U1 clock-to-P1 scan — user-reported, unpowered

Red probe held on U1_CSPI flash pin 16 (clock); black moved across P1_CSPI header pins 3–8. All cords disconnected and CR2032 removed. Fine-tip baseline previously approximately 0.6 Ω.

| P1 header pin | Resistance to U1 flash pin 16 | Assessment |
| --- | --- | --- |
| 3 | 2.95 MΩ | No direct connection demonstrated |
| 4 | 2.88 MΩ | No direct connection demonstrated |
| 5 | 3.11 MΩ | No direct connection demonstrated |
| 6 | 3.08–3.11 MΩ | No direct connection demonstrated; range reported |
| 7 | OL | No direct connection demonstrated |
| 8 | 6.64 kΩ | Resistive path, not a demonstrated SPI clock wire |

None is a demonstrated low-resistance clock path. Do not designate P1 pin 8 as clock merely because it is lower than the MΩ values. Possible explanations include unpowered mux isolation, different routing/header-to-flash association, or contact effects; no cause is proven. Hold insulated probe handles, since finger contact with exposed metal can affect high-resistance readings. Next perform a second signal scan using U1 pin 7 (CS#) before choosing a mux investigation; do not power or bridge unknown controls.

### U1 chip-select-to-P1 scan — user-reported, unpowered

User held red on U1_CSPI pin 7 (CS#) and scanned P1 header pins 3–8 as requested. Report: “basically the same readings as pin 16” except **P1 pin 8 = 9.33 kΩ**. Treat P1 pins 3–7 as an approximate high-resistance/OL pattern; exact individual CS# measurements were not supplied. Do not duplicate the clock scan's exact numbers into this test.

No low-resistance CS# connection has been identified. Together with the clock results, this warrants checking the nearby mux/routing rather than scanning the remaining SPI signals blindly. Shared supply/ground do not identify which header serves which physical flash. This is not evidence that a flash or trace has failed.

### Mux investigation — next unpowered checks

In the saved inspection crop, U3_CSPI and U4_CSPI are the smaller parts beside P2_CSPI/P1_CSPI, visibly marked PI3CH480QE. The [manufacturer datasheet](https://www.mouser.com/datasheet/2/322/PI3CH480-348795.pdf) identifies a four-channel 2:1 mux/demux supporting 1.8 V operation: pin 1 Select, pin 8 GND, pin 15 active-low Enable, pin 16 VCC. Disabled outputs are high impedance. This establishes component behavior, not actual board routing or the cause of the measured isolation.

Next identify **U4_CSPI**, the lower small mux beside P1 in the crop, and its pin-1 marker before probing. In that photo the marker appears at the upper-right package corner; for this orientation the top row runs right-to-left 1–8 and the bottom row left-to-right 9–16. Confirm the physical marker; do not reuse the flash-package orientation. First measure **U4 pin 8 (top-left corner lead in that orientation) to verified P1 header pin 2** in resistance mode, with all cords disconnected, CR2032 removed, and programmer unattached. A ground result provides an orientation/contact check before tracing mux data or supply pins. Actual mux-ground result, supply connection, select/enable wiring, and header-to-mux routes remain pending. Do not power or bridge unknown control pins.

**U4 ground result received:** the user reports **0.6 Ω from U4_CSPI pin 8 to P1_CSPI header pin 2**, matching the fine-tip baseline. This supports the mux-ground connection and is consistent with the identified orientation. The user explicitly reports that this chip is very small and maintaining probe contact is difficult. Limit the next task to one corner contact: **U4_CSPI pin 16 (bottom-right in the saved crop) to P1_CSPI header pin 1**. The purpose is to determine whether the mux uses the same supply net as the flash; no such connection is established yet. Keep all sources disconnected. If single-leg contact cannot be made reliably, stop fine-pin probing and move to identifying/validating the unattached programmer and adapter rather than forcing contact. No hooks on closely spaced mux legs and no control-pin jumpers are requested.

**U4 supply-net result received:** after multiple attempts the user reports **1.22 kΩ from U4_CSPI pin 16 (mux VCC) to P1_CSPI header pin 1 (mapped flash VCC)**. This is not a demonstrated direct shared supply connection; do not wire these nets together or assume applying 1.8 V at P1 pin 1 will operate the mux. The unpowered measurement does not establish U4's operating voltage, prove a fault, or prove mux isolation as the cause of the signal readings. Combined with difficult access and no direct clock/CS# paths found, pause fine mux probing and move to **P-01: actual programmer/adapter identification and standalone validation**. Request clear photographs of both sides of the received CH341A board and 1.8 V adapter with USB unplugged and no router, flash clip, or target attached. Exact board revision, adapter direction, level-translation circuitry, jumper settings, and output points must be established before powered bench measurements. Header signal mapping remains incomplete; do not attach the programmer to P1 based only on its known flash supply/ground connections.

### U2_CSPI mapping record

| Signal / flash pin | P1_CSPI pin and resistance | P2_CSPI pin and resistance | Other path / notes |
| --- | --- | --- | --- |
| GND / 10 | Pending | Pending | |
| VCC / 2 | Pending | Pending | |
| CS# / 7 | Pending | Pending | |
| CLK / 16 | Pending | Pending | |
| MOSI / 15 | Pending | Pending | |
| MISO / 8 | Pending | Pending | |
| HOLD# / 1 | Pending | Pending | |
| RESET# / 3 | Pending | Pending | |
| W# / 9 | Pending | Pending | |

## 5. Programmer validation and read-only acquisition

### P-01 — Validate the programmer with no router attached

- [x] Photograph both sides of the actual CH341A board and 1.8 V adapter: user supplied [IMG_1264](Photos/IMG_1264.jpeg), [IMG_1266](Photos/IMG_1266.jpeg), and [IMG_1268](Photos/IMG_1268.jpeg); see [photo index](Photos/README.md).
- [ ] Record board revision, switch/jumper settings, adapter components, input/output sides, and pin 1.
- [ ] Establish power **and signal** translation from the actual circuit/component specifications.
- [ ] Measure target-side VCC relative to target-side GND: **pending V**. Expected nominal value: about 1.8 V, within the flash operating range.
- [ ] Measure accessible static-high signal outputs and record each signal/condition. A low reading can be an idle-low or undriven signal; it is not automatically a fault.
- [ ] Record the limitation: a multimeter cannot establish fast signal peaks, overshoot, or timing. Supply voltage alone does not validate logic levels.
- [ ] Verify continuity through each cable/breakout contact with the programmer unplugged.

**Actual received hardware, photo inspection:** the black board is labeled CH341A Mini Programmer, with revision text appearing as `V1.512`, an external crystal, a 3.3 V-marked 1117 regulator, a 16-position ZIF socket, and underside legends for `BIOS 25 SPI`, `EEPROM 24 I2C`, CLK/CS/MOSI/MISO/GND/3.3 V/5 V. Its printed jumper legend specifies **1–2 programming, 2–3 TTL**; confirm those actual numbered posts while USB is unplugged rather than inferring a shunt position from perspective.

The green adapter has a blue ZIF socket, underside male contacts, an **1117-marked regulator** whose output variant is not established from its visible code, and a TI-marked 48-pin IC whose marking appears consistent with **74LVC16T245**. The [TI family reference](https://www.ti.com/product/SN74LVC16T245) describes dual-supply translation with configurable direction and 1.65–5.5 V rails. This is a candidate identification, not authentication of the installed IC or verification of the module's wiring, regulator output, input/output orientation, pin mapping, or operating levels. Target supply and signal checks remain pending.

Original photographs are unchanged. Non-generative crop/rotation derivatives and source hashes are indexed under [Photos/inspection](Photos/inspection/README.txt); [the macOS Python utility](scripts/make_programmer_inspection_crops.py) reproduces them with `sips` and verifies preservation of original hashes.

**Bare programmer USB result — basic communication passed with warning:** user ran `flashrom -p ch341a_spi` following the bare-board setup. It warned that driver detachment lacked entitlements/root privilege, then configured interface 1 and reached no-chip-found. A local follow-up, `flashrom -VV -p ch341a_spi -c MT25QU256`, executed without sudo, reported **device revision 3.0.4**, initialized SPI, and received an all-FF ID without USB transfer errors. Exit 1 is expected for this no-target probe; it is not a valid chip detection or read. The detach warning was nonfatal in these observed runs and did not require a permissions/security change. Preserve future errors individually rather than assuming warnings always prevent or never affect access. [Complete command evidence](recovery-prep-20261024/CH341A-BARE-USB-VERIFICATION.txt).

**User root retry:** `sudo flashrom -p ch341a_spi` retained the informational no-capture-entitlements message but omitted the previous access warning / `LIBUSB_ERROR_ACCESS`. It again reported no chip, expected with the programmer empty. No additional driver or macOS security changes are indicated by these results. Adapter and target-side electrical validation remain pending.

- [x] Complete bare-programmer USB initialization / empty-bus SPI probe; evidence above.
- [x] Measure bare-board labeled 3.3 V and 5 V pads relative to labeled GND in DC-voltage mode, keeping socket empty and adapter/clips/routers detached: user reports **3.322 V** and **5.195 V**, respectively. These are unloaded DC readings; they do not validate SPI logic levels or the adapter.
- [x] Record bare-programmer CS, MOSI, and CLK idle DC levels relative to GND, with no flashrom command running: user reports **CS 5.19 V; MOSI 5.182 V; CLK 5.182 V**, in requested order. This establishes approximately 5.18 V at the labeled bare signal pads in this idle state. It does not establish switching peaks, drive strength, or the adapter output. Do not attach these bare signals directly to the 1.8 V router flash.
- [ ] Establish adapter input/output direction, socket mapping, regulator output, and logic levels before fitting it to any router.

**Programmer socket ground mapping result:** the user identifies two accessible points labeled ground: one beside the 3.3 V / 5 V labels on top, and another on the bottom in the row they describe as containing pins 1 and 2, second from the end. Both show **B1 as ground** in our temporary diagram. Record this as user-reported continuity, not two distinct ground nets. Exact resistance values and refreshed lead baseline were not supplied. B1 is a temporary solder-joint position label, not IC pin 1 or an adapter pin assignment.

**Next requested operation:** retain USB unplugged, socket empty, adapter/clips/routers detached, and the same upright `BIOS 25 SPI` orientation. In resistance mode, move the fixed probe to the labeled **3.3 V** pad and scan T1–T4 and B2–B4. Record every near-baseline connection, since more than one contact may connect to the supply; do not select only one or infer a fault from multiple matches. Also record the numerical GND-to-B1 resistance and tips-together baseline so the ground result has a quantitative record. No adapter insertion or power connection is requested.

Some CH341A boards drive signals near 5 V despite a lower socket supply; see [official flashrom documentation](https://raw.githubusercontent.com/flashrom/flashrom/main/doc/supported_hw/supported_prog/ch341ab.rst).

### P-02 — Prepare software

- [x] Install `flashrom`: user completed installation; local version check confirms **v1.8.0 on Darwin 27.0.0 (arm64)**.
- [x] Save version and supported-chip information: [offline software verification](recovery-prep-20261024/FLASHROM-SOFTWARE-VERIFICATION.txt).
- [x] Verify the installed build lists `ch341a_spi` and **Micron MT25QU256, 32768 KiB, SPI**.
- [x] Check communication with the actual programmer with no router or flash chip connected: completed under P-01-USB; see the command evidence above.

**P-02 initial software result (historical): passed on October 24, 2026.** The user supplied successful version output, and local `--version`, `--help`, and `-L` checks confirmed installation and compiled-in support. These offline checks do not establish USB communication, adapter voltage/logic levels, in-circuit access, or physical chip identification. At that initial offline checkpoint the user was waiting for equipment. Equipment has since arrived and bare USB probing is complete under P-01; adapter electrical validation and router attachment remain pending.

These preparation commands do not access a router:

```sh
brew install flashrom
flashrom --version
flashrom -L
```

### R-01 — Read each identified physical chip

Only connect after P-01 and the relevant wiring checks are complete. A header does not automatically provide isolation from the rest of the board. Use short wiring where possible; avoid adding extensions to the 20 cm Dupont wires or clip ribbon.

- [ ] Record chassis serial, physical chip label, wiring photo, programmer/adapter, and battery/cable state.
- [ ] Keep router external power and console/USB disconnected.
- [ ] Check for VCC collapse, unintended board powering, warming, or unstable identification. Disconnect if observed; determine isolation requirements rather than adding voltage or router power.
- [ ] Probe identification and confirm the part/capacity agrees with the physical marking.
- [ ] Resolve ambiguous identification before forcing any chip selection.
- [ ] Save two separate full main-array reads in a private directory for this chassis and physical chip.
- [ ] Confirm each read is **33,554,432 bytes** for the identified Micron devices.
- [ ] Compare full-file hashes and bytes.
- [ ] Inspect data for plausible firmware/board information and address wrapping/repetition, including the upper 16 MiB. Matching all-FF/all-00 files do not validate acquisition.
- [ ] Preserve originals without edits and repeat for the other physical bank.

Example commands, **deferred until electrical setup is verified**. Use the exact chip name supported and identified by the installed build; `MT25QU256` is the expected family name, not a substitute for identification. Run in a new directory per chassis/chip and do not overwrite earlier reads:

```sh
flashrom -p ch341a_spi
flashrom -p ch341a_spi -c MT25QU256 -r read1.bin
flashrom -p ch341a_spi -c MT25QU256 -r read2.bin
wc -c read1.bin read2.bin
shasum -a 256 read1.bin read2.bin
cmp read1.bin read2.bin
```

`cmp` returning success with no output means byte-for-byte equality. Failed identification, inconsistent reads, or suspicious contents lead back to connection/isolation diagnosis. No erase, write, unlock, OTP, or configuration-modification command is included in this acquisition procedure.

### Acquisition register

| Chassis | Physical chip | JEDEC ID / detected name | Read files | Bytes each | SHA-256 / comparison | Assessment |
| --- | --- | --- | --- | --- | --- | --- |
| C8375-A | U1_CSPI | Pending | Pending | Pending | Pending | Not read |
| C8375-A | U2_CSPI | Pending | Pending | Pending | Pending | Not read |
| C8235-A | U2900 | Pending | Pending | Pending | Pending | Not read externally |
| C8235-A | U2901 | Pending | Pending | Pending | Pending | Not read externally |
| C8235-B | Identify first | Pending | Pending | Pending | Pending | Not read |
| C8235-C | Identify first | Pending | Pending | Pending | Pending | Not read |
| C8300-A | Identify first | Pending | Pending | Part-specific | Pending | Not read |

## 6. C8375 restoration after stable acquisition

### C8375-02 — Identify the target using saved evidence

**Use only for chassis `FDO2742M0FK`.**

| Reference | Local file | Bytes | SHA-256 |
| --- | --- | --- | --- |
| Exact original full-chip restore | [Original image](c8375-recovery/restore-original-20261023/C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin) | 33,554,432 | `72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107` |
| Known nonbooting programmed state | [Verified post-write readback](c8375-recovery/spi-backups-20261023/verified-17.18-3r-readback.bin) | 33,554,432 | `68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b` |

The original restore image and both original source reads were rehashed on October 24 and matched the original hash above. The second row documents the prior verified but nonbooting state; it is **not** the planned restore image.

- [ ] Compare both newly acquired physical-chip images against the saved references.
- [ ] Document which chip contains the known modified payload, original stages, and board-specific regions.
- [ ] Resolve differences before deciding which physical chip to restore.
- [ ] Preserve the other bank and all new pre-restoration backups.

Software labels such as “Boot ROM1,” command selector “primary,” and Linux `spi0.1` do not establish a physical chip assignment. Do not assume the small `spi0.1` device is golden ROMMON.

### C8375-03 — Restore and test

The exact write procedure will be entered here after the chip, wiring, access method, and stable backups are established. This sequencing is a technical dependency; it does not introduce a new permission request for already authorized recovery work.

- [ ] Recheck the exact original image hash and chassis/physical target immediately before writing.
- [ ] Record the selected image, target, tool version, and exact programming command/procedure.
- [ ] Program the original main-array image without altering separate OTP/security provisioning.
- [ ] Save a new full-chip readback and verify it equals the original image byte for byte.
- [ ] Remove programmer and all temporary wiring before applying router power.
- [ ] Restore normal assembly, cooling, and battery placement.
- [ ] Capture a cold boot at the known original-firmware setting: **115200, 8N1, no flow control**.
- [ ] Record boot banners, firmware version, STATUS/fans, and reached prompt.

The original backup was captured with manual ROMMON register `0x1820`; stopping at ROMMON after restoration can be expected and is not, by itself, a failed restore. If original ROMMON returns, inspect the environment and BOOT target before re-establishing the previously tested settings:

```text
USER_BOOT_PARAM=maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init
BOOT=bootflash:packages.conf,12;
Configuration register=0x1822
```

Use syntax and full history from [the consolidated C8375 context](C8375-G2-RECOVERY-CONTEXT.md). The EDAC blacklist avoided a reporting-driver crash; it did not establish fault-free memory. Do not blindly substitute `0x2102` or repeat the incompatible release-ROMMON experiment.

**Interpretation:** a programming/readback mismatch means restoration is not verified. If readback matches but boot still fails, preserve that distinction and investigate power/reset, bank routing, boot state, and remaining hardware faults. Returning to IOS is an initial recovery milestone; fan/PSU behavior, stability, and functional testing remain separate work.

## 7. Three C8235s: preserve and compare before choosing firmware

### C8235-01 — Record an independent baseline for each chassis

- [ ] Record exact PID, chassis serial, board barcode/revision, and PSU label for C8235-A/B/C.
- [ ] Record firmware-write history separately: original state, known update, unknown history, or other.
- [ ] Record current assembly, cooling, battery, and external cable state.
- [ ] When properly assembled, capture each unit's startup and LED behavior with a documented console setting. C8235-A's known setting is 115200, 8N1, no flow control; do not assume an untested unit's saved setting.
- [ ] Identify physical flash markings and headers independently on each board.
- [ ] Obtain separate stable backups of both banks per chassis using R-01.

### C8235-02 — Improve mapping on the worked Arata board

C8235-A has identified flashes U2900/U2901 and nearby PI3CH480 muxes U2903/U2904. J2900 remains unidentified. Historical measurements supported one ground pin but did not establish a direct connection from the other pin to mux Select; the reported approximately 6.5 kΩ reading was difficult to obtain with large probes.

- [ ] Repeat uncertain resistance measurements with fine probes and a recorded lead baseline.
- [ ] Map J2900/J2901 to known flash and mux pins where accessible.
- [ ] Verify exact mux pin orientation against the PI3CH480 datasheet before probing.
- [ ] Record direct paths, resistive paths, and open readings without equating them to a ROM selector.
- [ ] Consider powered DC measurements only after safe mounting/cooling and secure lead attachment are practical.

### C8235-03 — Choose an evidence-based recovery candidate

- [ ] Identify which dumps contain old development versus newer release stages.
- [ ] Compare board revisions, firmware components, and unique data regions across chassis.
- [ ] Assess whether a compatible surviving bank or matching original code region is available.
- [ ] Document exact proposed byte ranges and preserved board-specific data before any write experiment.

There is no saved complete original primary development dump for C8235-A. Other units may retain useful code, but that is unverified. Do not whole-chip clone a different chassis as the default approach. Do not clear/replace the TPM, alter fuses, change lifecycle/provisioning, or assume the TPM halt proves a damaged TPM. The earlier hybrid image was not flashed and remains an unproven experiment.

## 8. C8300: determine what “no console” means

### C8300-01 — External console baseline

Cisco lists steady red STATUS as booting and blinking red as a hardware-integrity error. Persistent steady red with silence warrants investigation but does not by itself prove an irreparable router. Green power/fan indications do not validate every CPU or memory rail.

- [ ] Record full PID suffix, serial, installed modules, PSU labels, and elapsed time with steady red STATUS.
- [ ] Confirm the labeled RJ45 CONSOLE port; do not use an Ethernet or AUX port.
- [ ] Physically unplug native USB console at the router during RJ45 testing. Cisco documents USB console priority over RJ45.
- [ ] Validate the Cisco RS-232 cable on another working device if available. Adapter enumeration alone is insufficient.
- [ ] Open one terminal/logging application at **9600, 8N1, no hardware or software flow control** before powering on.
- [ ] Record startup bytes and LEDs at startup, one, five, and ten minutes. Ten minutes is an observation checkpoint, not a definitive failure threshold; allow longer observation where appropriate.
- [ ] If silent, inspect at 115200. If needed, capture one controlled startup at that rate to look for an early banner; check other supported rates if evidence warrants it. Avoid endless resets and allow at least 30 seconds off between cold starts.
- [ ] Test native USB separately using a known data cable. Record whether a new macOS serial device appears and whether USB console-active indication changes.
- [ ] Record whether “silent” means zero received bytes, unreadable bytes, or a readable banner followed by a halt.

Stop a powered test for abnormal heat/smell or a critical environmental indication. A USB serial interface appearing proves enumeration, not successful CPU boot.

| Test path | Cable / Mac serial device | Baud / framing / flow | Startup and observation duration | Console-active LED | Received data / evidence file | Outcome |
| --- | --- | --- | --- | --- | --- | --- |
| RJ45 | Pending | 9600 / 8N1 / none | Pending | Pending | Pending | Not tested in this plan |
| RJ45 alternate | Pending | 115200 / 8N1 / none | Pending | Pending | Pending | Not tested in this plan |
| Native USB | Pending | 9600 initially / 8N1 / none | Pending | Pending | Pending | Not tested in this plan |

### C8300-02 — Physical inspection if both validated console paths remain silent

- [ ] Power off and unplug all power inputs and external cables.
- [ ] Photograph the logic board, installed memory, connectors, and candidate boot flash.
- [ ] Check for visible damage, corrosion, loose connectors, or improperly seated memory.
- [ ] Confirm model-specific memory/service requirements before reseating or trying supported known-good RAM.
- [ ] Consider optional-module isolation only as a later controlled test with required cooling/filler arrangements; record one change at a time.
- [ ] Read the complete marking of each candidate boot flash and establish its package, voltage, pinout, and function.
- [ ] If a suitable SOIC-8 boot flash is identified, evaluate today's clip for read-only acquisition; otherwise select the proper access method.
- [ ] Preserve original storage contents before any firmware write.

No G2 firmware file is a restore image for this platform. The 8-pin clip being mechanically compatible does not establish electrical compatibility, boot-flash identity, isolation, or availability of valid replacement firmware. If inspection points toward power/reset faults, define specific low-voltage test points and expected values before powered probing; do not guess rail voltages or work inside mains PSUs.

## 9. SOIC-16 clip arrival checklist — expected October 25

- [ ] Confirm actual clip/breakout contents and wide-body package fit.
- [ ] Photograph clip pin 1 and breakout numbering.
- [ ] With everything unpowered, meter every clip contact to its breakout connection; cable color is not proof of numbering.
- [ ] Build a signal-based harness from the verified SOIC-16 pin reference to the actual adapter output. Do not map pin numbers one to one.
- [ ] Check for adjacent shorts and establish reset/hold/write-protect handling.
- [ ] Document the complete assembled wiring before USB/programmer power.
- [ ] Apply R-01 independently to each physical chip; keep both-bank backups distinct.

## 10. Session and measurement logs

Append entries; do not overwrite a failed result with a later successful one. Include units, exact endpoints, power state, and evidence filenames. Separate observations from explanations.

### Session template

```text
Session ID: YYYYMMDD-HHMM-<tracking-ID>
Date/time/time zone:
Operator:
Task IDs:
Exact PID / chassis serial / board revision:
Physical flash or component reference:
Assembly / cooling / battery state:
External power and cables:
Meter model / lead jacks / mode / probe-to-probe baseline:
Programmer / adapter revision / software version:
Wiring or board photo path:

Measurements and observations:
- Exact endpoints or test conditions:
- Reading / units / repeatability:
- Evidence file:

Interpretation:
- What the observation supports:
- What remains unverified:

Changes made / exact commands:
Files created / sizes / hashes:
Stop condition encountered:
Task outcome: pending / passed / failed / inconclusive
Next task and reason:
End state: power, cables, battery, assembly, terminal ownership
```

### Results register

| Date/time | Session / task ID | Chassis / component | Measurement or action | Observed result | Interpretation / next step | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-10-24 | PREP-01 | Workspace | Inventory and context review | 300 pre-existing files inventoried; three requested contexts read | Use this file for tracking | Inventory and context links above |
| 2026-10-24 | PREP-02 | C8375-A saved artifacts | Rehash original restore image and both original source reads | All three match `72fc3f…45107` | Original restore reference available; physical target still unknown | Full hash in section 6 |
| 2026-10-24 | P-02-SOFTWARE | Mac workstation | User installation followed by offline version/help/supported-chip checks | flashrom v1.8.0, Darwin 27.0.0 arm64; `ch341a_spi` and MT25QU256 listed | Software ready; actual programmer detection and P-01 electrical checks pending | [Software verification](recovery-prep-20261024/FLASHROM-SOFTWARE-VERIFICATION.txt) |
| 2026-10-24 | C8375-01-PREP | Meter / removed CR2032 during requested C8375 preparation | User lead check and battery removal | Tips touching: 0.2 Ω; separated: OL; battery removed, positive face reported toward chassis center | Lead baseline recorded; battery voltage, physical identity/photo, external disconnection, and residual voltage pending | User-reported measurements in conversation; no instrument capture |
| 2026-10-24 | C8375-01-BATTERY | Removed CR2032 during requested C8375 preparation | User DC-voltage measurement across removed cell | 3.03 V DC, unloaded | Consistent with nominal voltage; no load/health test. Leave out for unpowered mapping; confirm external disconnection and identify board contacts next | User-reported measurement in conversation; no instrument capture |
| 2026-10-24 | C8375-01-ISOLATION | Router during requested C8375 preparation | User confirms all cords disconnected; existing 1260 photo accepted | External disconnection confirmed; CR2032 already removed | Proceed with DC voltage checks at accessible header posts; electrical functions remain unknown | User confirmation and existing IMG_1260 inspection crop |
| 2026-10-24 | C8375-01-P1-1 | P1_CSPI pin 1 to USB shell | User DC-voltage check followed by resistance check | 0 V DC; 980 Ω | Resistive path substantially above 0.2 Ω lead baseline; not evidence of direct shell connection or a signal assignment. Continue pin 2, voltage first | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-P1-3 | P1_CSPI pin 3 to USB shell | User measurements, with immediate pin-number correction | 0.015 V DC (15 mV); OL resistance | Initially called pin 2, then explicitly corrected to pin 3. Actual pin 2 is above pin 1 in the user's orientation and remains pending. No signal assignment or fault conclusion | User-reported measurements and correction in conversation |
| 2026-10-24 | C8375-01-P1-2 | Actual P1_CSPI pin 2 to USB shell | User DC-voltage and resistance measurements | 0 V DC; 0.2 Ω | Matches probe baseline; direct shell connection supported. Record as ground candidate pending verification against flash/circuit ground; continue pin 4 using same shell reference | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-P1-4 | P1_CSPI pin 4 to USB shell | User DC-voltage and resistance measurements | 0.006 V DC (6 mV); OL resistance | Record as reported; function remains unknown. A small DC reading and OL do not establish a faulty trace, active supply, or verified discharge. Request pin 5 DC reading first | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-P1-5 | P1_CSPI pin 5 to USB shell | User DC-voltage and resistance measurements | 0.003 V DC (3 mV); OL resistance | Function unknown; requested stability observation was not reported. Preserve observations without inferring a fault, signal assignment, or verified discharge | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-P1-6 | P1_CSPI pin 6 to USB shell | User DC-voltage and resistance measurements; pin number clarified in follow-up | Voltage fluctuates between 0.001 and 0.000 V DC (0–1 mV); OL resistance | Near-zero displayed voltage; no direct shell connection demonstrated by the resistance reading; signal function remains unknown. Continue pin 7 | User-reported measurements and pin-number clarification in conversation |
| 2026-10-24 | C8375-01-P1-7 | P1_CSPI pin 7 to USB shell | User DC-voltage and resistance measurements | 0.021 V DC (21 mV); OL resistance | Function unknown; no direct shell connection demonstrated. Small DC reading and OL are not a fault or rail-discharge diagnosis. Pin 8 remains to complete this preliminary scan | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-P1-8 | P1_CSPI pin 8 to USB shell | User DC-voltage and resistance measurements | 0 V DC; 5.625 kΩ (5,625 Ω) | Preliminary P1 scan complete. Resistive path; function unknown. Next verify a ground candidate against known flash VSS if probe access is reliable | User-reported measurements in conversation |
| 2026-10-24 | EQUIPMENT-ARRIVAL | Recovery bench equipment | User confirms today's deliveries | CH341A, 1.8 V adapter, Dupont wires, SOIC-8 clip, fine probe points, and hook clips received | Actual programmer/adapter validation and wiring remain pending; SOIC-16 arrival not confirmed. Refresh meter baseline with new attachments before fine-pin resistance checks | User confirmation in conversation |
| 2026-10-24 | C8375-01-GND-REFERENCE | Reported flash pin 10 to chassis | User DC-voltage and resistance checks | 0 V DC; 0.3 Ω | Supports flash-ground-to-chassis connection; new-tip lead baseline not reported | User-reported measurements in conversation |
| 2026-10-24 | C8375-01-PIN2-UNRESOLVED | “Pin 2” to flash pin 10; pin-2 identity unconfirmed | User DC-voltage and resistance checks | 0 V DC; 11.8 Ω | Clarify whether header P1 pin 2 or flash U1 pin 2 (VCC). Do not assign to a net or conclude a fault before clarification | User-reported measurements; clarification requested |
| 2026-10-24 | C8375-01-PIN2-CLARIFIED | P1_CSPI header pin 2 to U1_CSPI chip pin 10 | User explicitly confirms endpoints of previous reading | 0 V DC; 11.8 Ω | Endpoint ambiguity resolved; not a verified direct flash-ground connection. Reconcile with earlier 0.2 Ω to USB shell and U1 pin 10's 0.3 Ω to chassis. USB-shell/chassis check and new-tip lead baseline next | User clarification in conversation |
| 2026-10-24 | C8375-01-REFERENCE-CLARIFIED | USB shell / user-described chassis ground | User clarifies reference identity | Both names refer to the same measurement point | Do not infer a separate shield/chassis network from wording. Earlier P1 pin 2 to ground at 0.2 Ω conflicts with P1 pin 2 to U1 pin 10 at 11.8 Ω and U1 pin 10 to that ground at 0.3 Ω; repeat original header pair with fine probes | User clarification in conversation |
| 2026-10-24 | C8375-01-FINE-TIP-BASELINE | New fine-tip lead configuration and ground repeats | User baseline and repeat resistance measurements | Tips together approximately 0.6 Ω; USB shell to U1 pin 10 0.6 Ω; USB shell to P1 pin 2 varies, most consistently approximately 1.1 Ω | Flash VSS/shell path matches lead baseline. Header pin 2 is a ground candidate with contact variation; repeat direct header-pin-2 to flash-pin-10 pair once to reconcile earlier 11.8 Ω | User-reported measurements and stability description in conversation |
| 2026-10-24 | C8375-01-GND-VERIFIED | P1_CSPI header pin 2 to U1_CSPI flash pin 10 | Extended direct repeat with fine probes | Initially oscillating substantially, then settled at 0.6 Ω | Matches fine-tip baseline; accept measured header-pin-2 to U1 VSS connection. No further repetition requested; next map proposed header-pin-1 to U1 VCC | User-reported settled measurement and stability history in conversation |
| 2026-10-24 | C8375-01-VCC-MAPPED | P1_CSPI header pin 1 to U1_CSPI flash pin 2 | User resistance reading after requested mapping check | 0.3 Ω; DC value for this pair not separately reported | Supports direct VCC connection. Fine-tip baseline previously approximately 0.6 Ω; retain raw reading without inferring negative resistance from contact/baseline variation. Next measure actual flash VCC relative to ground, not merely between two expected-connected supply points | User-reported measurement in conversation |
| 2026-10-24 | C8375-01-VCC-UNPOWERED | P1_CSPI header pin 2 (mapped ground) to U1_CSPI flash pin 2 (VCC) | User DC supply-to-ground measurement with power/cables disconnected and CR2032 removed | 0.000–0.002 V DC (0–2 mV) | Near-zero displayed flash supply voltage in the unpowered setup; proceed with resistance mapping of clock/data. No claim about all board rails or powered supply performance | User-reported measurement in conversation |
| 2026-10-24 | C8375-01-CLK-SCAN | U1_CSPI flash pin 16 to P1_CSPI header pins 3–8 | User unpowered resistance scan, red on flash clock | P1-3 2.95 MΩ; P1-4 2.88 MΩ; P1-5 3.11 MΩ; P1-6 3.08–3.11 MΩ; P1-7 OL; P1-8 6.64 kΩ | No low-resistance clock connection identified. No signal assignment or fault inferred. Check CS# next; mux isolation, alternate routing, and contact effects remain possible | User-reported readings in conversation |
| 2026-10-24 | C8375-01-CS-SCAN | U1_CSPI flash pin 7 to P1_CSPI header pins 3–8 | User unpowered resistance scan | Pins 3–7 described as basically the same as the clock scan, without individual values; pin 8 9.33 kΩ | No direct CS# mapping established; do not invent exact repeated values. Next investigate mux ground/orientation, supply and routing, keeping all equipment unpowered | User qualitative comparison and exact pin-8 reading in conversation |
| 2026-10-24 | C8375-01-U4-GND | U4_CSPI pin 8 to P1_CSPI header pin 2 | User resistance measurement on small mux | 0.6 Ω; user reports difficult fine-pin contact | Matches fine-tip baseline; mux ground connection supported. Next one corner supply-net check, U4 pin 16 to P1 header pin 1; stop if reliable single-leg contact is impractical | User-reported measurement and access limitation in conversation |
| 2026-10-24 | C8375-01-U4-VCC-NET | U4_CSPI pin 16 to P1_CSPI header pin 1 | User unpowered resistance measurement repeated multiple times | 1.22 kΩ | No direct shared mux/flash supply connection demonstrated. Do not bridge supplies or infer a fault. Pause fine mux probing and proceed to standalone programmer/adapter identification; no router attachment | User-reported repeated measurement in conversation |
| 2026-10-24 | P-01-PHOTOS | Actual CH341A and green adapter | Inspect three user-supplied photos; reproduce pixel crops/rotations | Programmer labels/jumper legend readable; candidate TI 74LVC16T245-family translator and 1117 regulator on adapter; no voltage readings | Photograph prerequisite complete; board-mode confirmation, bare USB communication, module orientation, and electrical validation remain pending | [Photos index](Photos/README.md) and inspection derivatives |
| 2026-10-24 | P-01-USB | Bare black CH341A connected to Mac, no target | User initial probe and local non-root verbose follow-up | Driver-detach entitlement warning; initialization continues, device revision 3.0.4, SPI enabled, empty-bus ID FF/FFFF, no chip found | Basic communication confirmed with nonfatal warning in these runs. No flash chip detected; electrical suitability not established. Next bare 3.3 V / 5 V supply measurements | [Command evidence](recovery-prep-20261024/CH341A-BARE-USB-VERIFICATION.txt) |
| 2026-10-24 | P-01-USB-ROOT | Bare black CH341A, user sudo retry | `sudo flashrom -p ch341a_spi` | Informational entitlement line remains; access warning absent; no chip found | Expected empty-programmer outcome. Continue bare supply measurements; this does not verify target power or logic levels | [Command evidence](recovery-prep-20261024/CH341A-BARE-USB-VERIFICATION.txt) |
| 2026-10-24 | P-01-BARE-SUPPLY | Bare CH341A labeled supply pads relative to labeled GND | User DC-voltage measurements following empty-programmer procedure | 3.3 V pad: **3.322 V**; 5 V pad: **5.195 V** | Consistent with nominal labels, unloaded. Does not validate SPI signal voltage, loaded performance, or adapter output. Next record idle CS/MOSI/CLK DC levels | User-reported readings in conversation, in requested order |
| 2026-10-24 | P-01-BARE-SIGNALS | Bare CH341A CS/MOSI/CLK pads relative to labeled GND | User idle DC-voltage readings, no flashrom command running, empty socket | CS **5.19 V**; MOSI **5.182 V**; CLK **5.182 V** | Approximately 5.18 V idle signals despite 3.322 V supply pad. No direct router connection; verify adapter translation. Next unpowered programmer socket ground mapping | User readings in requested order; [bench evidence](recovery-prep-20261024/CH341A-BARE-USB-VERIFICATION.txt) |
| 2026-10-24 | P-01-SOCKET-GND | Programmer BIOS/25-SPI socket, temporary position B1 | User reports checks from both accessible labeled GND reference points | Both identify B1 as ground; exact Ω and refreshed lead baseline not supplied | Ground continuity reported; no adapter pin numbering inferred. Next map labeled 3.3 V to remaining socket joints unpowered and collect numerical ground/baseline readings | User report in conversation; same temporary T/B orientation as requested |
| Pending | | | | | | |

### Decisions and unresolved questions

| Item | Current answer | Evidence needed / next action |
| --- | --- | --- |
| Fleet count | Confirmed: 3 × C8235-G2, 1 × C8375-G2, 1 × C8300-1N1S | Bind physical serials to tracking IDs |
| Exact delivered programmer/adapter revisions | Unknown | Photos and P-01 validation |
| Can C8375 headers provide access today? | Unknown | C8375-01 mapping and circuit/access assessment |
| Which C8375 chip contains the modified active image? | Unknown | Stable reads and C8375-02 comparison |
| Which banks retain original C8235 code? | Unknown | Separate reads from all three chassis |
| C8300 irreparable hardware failure? | Not established | Validated console tests followed by inspection and targeted diagnosis |
| In-circuit isolation sufficient? | Not established on any board | Observe supply behavior, identification, and repeatable plausible reads |

## 11. Recovery milestones and later validation

Do not mark a router recovered solely because a write completed or one boot succeeded.

| Chassis | Stable flash backups | Restore/candidate verified if used | ROMMON or expected firmware starts | IOS boots | Sustained stability and environment | Port/function tests | Final assessment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C8375-A | Original software-captured backup exists; external reads pending | Pending | Pending | Pending | Pending | Pending | Nonworking |
| C8235-A | Pending | Pending | Pending | Pending | Pending | Pending | Nonworking |
| C8235-B | Pending | Pending | Pending | Pending | Pending | Pending | Nonworking |
| C8235-C | Pending | Pending | Pending | Pending | Pending | Pending | Nonworking |
| C8300-A | Pending | If needed | Pending | Pending | Pending | Pending | Nonworking |

After boot recovery, define and log an observation duration, reset/reboot behavior, temperature/rail/fan/PSU status, retained configuration, and meaningful physical-port tests. The C8375 previously passed limited two-port tests before the ROMMON experiment; those historical results do not validate its present state. Preserve its user's INSTALL-mode requirement and saved configuration.

## 12. References and update history

- [C8235 recovery history](C8235-G2-RECOVERY-CONTEXT.txt).
- [C8375 consolidated recovery history](C8375-G2-RECOVERY-CONTEXT.md).
- [C8375 original restore notes](c8375-recovery/restore-original-20261023/RESTORE-NOTES.txt).
- [C8235 board inspection notes](board-photos/board-inspection-notes.txt).
- [Cisco Catalyst 8300 hardware overview and LEDs](https://www.cisco.com/c/en/us/td/docs/routers/cloud_edge/c8300/hardware_installation/b-catalyst-8300-series-edge-platforms-hig/m-overview.html).
- [Cisco Catalyst 8300 console defaults and USB priority](https://www.cisco.com/c/en/us/td/docs/routers/cloud_edge/c8300/hardware_installation/b-catalyst-8300-series-edge-platforms-hig/Preinstall.html).
- [Micron MT25QU256ABA datasheet](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf).
- [PI3CH480 mux datasheet](https://www.mouser.com/datasheet/2/322/PI3CH480-348795.pdf).
- [flashrom CH341A documentation](https://raw.githubusercontent.com/flashrom/flashrom/main/doc/supported_hw/supported_prog/ch341ab.rst).
- [flashrom Micron chip definitions](https://raw.githubusercontent.com/flashrom/flashrom/main/flashchips/micron.c).
- [Homebrew flashrom package](https://formulae.brew.sh/formula/flashrom).

| Date | Update |
| --- | --- |
| 2026-10-24 | Created the Markdown tracking plan from reviewed recovery histories and the initial bench worksheet. Added five-device register, task IDs, per-chip mapping tables, acquisition/restoration criteria, C8300 console isolation, and append-only result templates. No new bench tests performed. |
| 2026-10-24 | Recorded successful flashrom v1.8.0 installation and offline confirmation of CH341A/Micron support. Marked the software preparation items complete; actual USB/programmer communication and electrical validation remain pending. |
| 2026-10-24 | Recorded user-reported 0.2 Ω lead baseline, separated-probe OL, CR2032 removal, and its reported installed orientation. Board measurements remain pending; requested removed-cell voltage and current board identification/photo before header mapping. |
| 2026-10-24 | Recorded removed CR2032 at 3.03 V DC, user-reported. This is an unloaded voltage measurement, not a load test or diagnosis of the boot failure. |
| 2026-10-24 | User confirmed all cords disconnected. Accepted existing clear IMG_1260 for accessible-header identification; requested preliminary P1_CSPI-to-USB-shell DC checks without assuming that the shell is verified logic ground. |
| 2026-10-24 | Recorded first P1_CSPI endpoint result: pin 1 to USB shell, 0 V DC and 980 Ω. Added a per-pin scan table; no ground or SPI signal assignment inferred. |
| 2026-10-24 | Recorded 0.015 V DC and OL on actual P1_CSPI pin 3 after the user's immediate correction. Acknowledged incorrect assistant guidance about pin-2 placement; actual pin 2 is above pin 1 in the user's working orientation and is awaiting measurement. |
| 2026-10-24 | Recorded actual P1_CSPI pin 2 at 0 V DC and 0.2 Ω to the USB shell. This matches the lead baseline and supports a direct shell connection; verification against flash/circuit ground is still pending. |
| 2026-10-24 | Recorded P1_CSPI pin 4 at 0.006 V DC and OL to USB shell. No signal assignment or fault inferred; next requested measurement is pin 5 DC voltage. |
| 2026-10-24 | Recorded P1_CSPI pin 5 at 0.003 V DC and OL to USB shell. Voltage stability over time was not reported; next requested point is pin 6. |
| 2026-10-24 | Recorded P1_CSPI pin 6 fluctuating between 0.000 and 0.001 V DC, with OL resistance to the USB shell. User explicitly clarified that this result belongs to pin 6; next point is pin 7. |
| 2026-10-24 | Recorded P1_CSPI pin 7 at 0.021 V DC and OL to USB shell. Pin 8 is the remaining endpoint in this preliminary header scan. |
| 2026-10-24 | Completed preliminary P1_CSPI scan with pin 8 at 0 V DC and 5.625 kΩ. Saved all user-reported meter/battery/header observations and the pin-number correction; flash-ground and SPI signal mapping remain pending. |
| 2026-10-24 | Recorded today's equipment arrival. Clarified flash-package numbering in photo orientation and the purpose of unpowered DC checks; requested a refreshed lead baseline with the fine points. No programmer attachment, adapter validation, or flash-ground result recorded yet. |
| 2026-10-24 | Recorded flash pin 10 to chassis at 0 V DC / 0.3 Ω, plus an unassigned “pin 2 to pin 10” result at 0 V DC / 11.8 Ω. Requested explicit header-versus-chip endpoint clarification before interpreting or using the latter measurement. |
| 2026-10-24 | User confirmed the 11.8 Ω pair is P1_CSPI header pin 2 to U1_CSPI chip pin 10. Removed its provisional flash-ground status; preserve earlier USB-shell result and reconcile references before programmer wiring. |
| 2026-10-24 | User clarified “USB ground” and “chassis ground” refer to the same point. Corrected the reference interpretation; next repeat P1 pin 2 to the same shell rather than comparing nonexistent separate reference points. |
| 2026-10-24 | Recorded new fine-tip baseline of about 0.6 Ω, matching U1 pin 10 to USB shell. Header pin 2 to shell varies around a most consistent 1.1 Ω. Kept earlier results and requested one direct header-to-flash-ground repeat to assess contact-related discrepancy. |
| 2026-10-24 | Direct P1 header pin 2 to U1 flash pin 10 settled at 0.6 Ω after extended contact variation, equal to fine-tip baseline. Marked this ground connection verified; remaining header/mux/bank mapping is pending. |
| 2026-10-24 | Recorded P1 header pin 1 to U1 flash pin 2 (VCC) at 0.3 Ω. Ground and VCC header connections are now mapped; next check VCC-to-ground DC voltage before further SPI signal tracing. |
| 2026-10-24 | Recorded unpowered U1 VCC-to-mapped-ground reading of 0.000–0.002 V DC. Next trace U1 pin 16 (clock) against remaining P1 header pins, recording actual resistance values without assuming signal assignments. |
| 2026-10-24 | Recorded complete U1-clock-to-P1 scan: pins 3–6 approximately 2.88–3.11 MΩ, pin 7 OL, pin 8 6.64 kΩ. No clock wire found; next check CS# and investigate routing/mux behavior from evidence. |
| 2026-10-24 | Recorded CS# scan as qualitatively similar to the clock scan, with exact P1-pin-8 value 9.33 kΩ. No low-resistance signal mapping established. Prepared unpowered U4 mux-ground/orientation check using the PI3CH480 manufacturer pin reference. |
| 2026-10-24 | Recorded U4 mux pin 8 to P1 header pin 2 at 0.6 Ω, matching the fine-tip baseline. User reports difficult access to the small legs; next limited check is U4 pin 16 to P1 header pin 1, with programmer/adapter validation as the fallback if contact is unreliable. |
| 2026-10-24 | Recorded repeated 1.22 kΩ between U4 mux VCC pin 16 and P1 header pin 1 (flash VCC). No direct shared supply established. Paused fine mux probing; next identify and validate the actual CH341A and 1.8 V adapter without a target connected. |
| 2026-10-24 | Inspected three received-hardware photos under Photos/. Recorded actual programmer legends and candidate adapter components; added reproducible non-generative inspection crops. Next request is bare-programmer USB probing with no adapter/clip/router attached; electrical validation remains incomplete. |
| 2026-10-24 | Recorded bare CH341A USB probing and a local verbose non-root check: basic communication works despite a nonfatal detach warning; empty bus reports all FF. Next check bare-board supply pads. No driver/security change or router/adapter connection performed. |
| 2026-10-24 | Recorded user sudo probe: previous USB access warning absent, informational entitlement line remains, expected no-chip result. Next bare-board DC supply measurements are unchanged. |
| 2026-10-24 | Recorded bare CH341A supply readings: labeled 3.3 V pad 3.322 V, labeled 5 V pad 5.195 V relative to labeled GND. Next record idle CS/MOSI/CLK DC levels with adapter and targets detached; output translation and adapter mapping remain pending. |
| 2026-10-24 | Recorded bare idle CS 5.19 V, MOSI 5.182 V, CLK 5.182 V. Direct bare signal connection to 1.8 V flash is unsuitable. Next map the programmer BIOS/25-SPI socket ground unpowered, followed by adapter input/output mapping and electrical tests. Updated stale P-02 communication checkbox to reference completed USB evidence. |
| 2026-10-24 | Recorded user continuity report from both labeled GND references to temporary programmer socket B1. No numerical resistance or refreshed baseline supplied. Next map labeled 3.3 V to remaining BIOS/25-SPI socket joints with USB unplugged; adapter placement remains pending. |
