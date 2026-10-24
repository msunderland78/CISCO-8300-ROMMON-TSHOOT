# Cisco router recovery: test plan and tracking log

Created: **2026-10-24** · Time zone: **America/New_York**  
Last updated: **2026-10-24**  
Workspace: `/Users/games/Documents/SOFTWARE`

This is the active tracking document for the five routers below. It expands the discussion and [initial bench worksheet](recovery-prep-20261024/TODAY-BENCH-PLAN.txt). Use this Markdown file for subsequent measurements, results, decisions, and next steps. The earlier recovery-context files remain the detailed history.

**Immediate priority:** map the C8375 flash headers with the board unpowered. If a header provides verified electrical access, attempt read-only backups before the SOIC-16 clip arrives. Otherwise, prepare the harness and wait for the clip. While awaiting tools, perform the C8300 external console checks.

**Execution status:** no new physical measurements, programmer connections, flash reads/writes, or router console tests have been performed during this planning session. Checkboxes below distinguish completed preparation from planned bench work.

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
- [x] Check local software availability: Homebrew present; `flashrom` not installed at the planning inspection.
- [ ] Tie tracking IDs to physical labels and chassis serials.

## 2. Equipment and connection rules

Delivery expectations were reported on October 24, 2026; actual receipt and bench verification remain to be recorded.

| Equipment | Reported availability | Intended use | Verification still needed |
| --- | --- | --- | --- |
| CH341A programmer | Owned / expected available for today's work | SPI identification, reads, eventual recovery writes | Actual board revision, operating mode, pinout, logic levels |
| 1.8 V adapter | Owned / expected available for today's work | Target power and signal-level translation | Input/output orientation, circuit/component identification, output measurements |
| SOIC-8 clip | Owned / expected available for today's work | Only independently identified compatible 8-pin devices | Cable continuity, orientation, fit, target voltage |
| 40 × 20 cm Dupont wires | Expected October 24 | Mapped headers and SOIC-16 breakout wiring | Connector genders, continuity, secure fit |
| Needle meter probe tips | Expected October 24 | Fine unpowered connection mapping | Meter compatibility and safe exposed tip length |
| Meter hook clips | Expected October 24 | Secure connections on adequately spaced test points/headers | Actual hook jaw size and insulation; 4 mm connector size does not establish IC-leg clearance |
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
- [ ] Disconnect all external cables/power and record battery state.
- [ ] Establish absence of residual voltage before resistance measurements.
- [ ] Record probe-to-probe resistance: **pending Ω**.
- [ ] Identify each flash's pin-1 marker and number the headers from clear photos. Do not equate a header's numbering with flash numbering.
- [ ] Map ground first, then the required power/data/control signals.
- [ ] Record the path to **both** flash chips, including higher resistance or open readings.
- [ ] Determine whether muxes or other circuitry interrupt header-to-flash access.
- [ ] Decide whether there is enough evidence for a header-based read or whether to wait for the clip.

Values near the meter lead baseline support a direct connection. Higher resistance may indicate a series resistor or another circuit path. A kΩ reading does not establish a direct trace. An unpowered mux may leave a valid route disconnected; an open reading alone does not prove a failed trace or component.

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
| GND / 10 | Pending | Pending | |
| VCC / 2 | Pending | Pending | |
| CS# / 7 | Pending | Pending | |
| CLK / 16 | Pending | Pending | |
| MOSI / 15 | Pending | Pending | |
| MISO / 8 | Pending | Pending | |
| HOLD# / 1 | Pending | Pending | |
| RESET# / 3 | Pending | Pending | |
| W# / 9 | Pending | Pending | |

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

- [ ] Photograph both sides of the actual CH341A board and 1.8 V adapter.
- [ ] Record board revision, switch/jumper settings, adapter components, input/output sides, and pin 1.
- [ ] Establish power **and signal** translation from the actual circuit/component specifications.
- [ ] Measure target-side VCC relative to target-side GND: **pending V**. Expected nominal value: about 1.8 V, within the flash operating range.
- [ ] Measure accessible static-high signal outputs and record each signal/condition. A low reading can be an idle-low or undriven signal; it is not automatically a fault.
- [ ] Record the limitation: a multimeter cannot establish fast signal peaks, overshoot, or timing. Supply voltage alone does not validate logic levels.
- [ ] Verify continuity through each cable/breakout contact with the programmer unplugged.

Some CH341A boards drive signals near 5 V despite a lower socket supply; see [official flashrom documentation](https://raw.githubusercontent.com/flashrom/flashrom/main/doc/supported_hw/supported_prog/ch341ab.rst).

### P-02 — Prepare software

- [ ] Install `flashrom` if still absent.
- [ ] Save version and supported-chip information.
- [ ] Verify the installed build supports `ch341a_spi` and the full 32 MiB Micron part.

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
