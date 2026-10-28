# Received programmer and adapter photographs

User-supplied photos added October 24, 2026. Preserve these original files.


| File | Coverage |
| --- | --- |
| [IMG_1264.jpeg](IMG_1264.jpeg) | Top of black CH341A programmer and green adapter, sockets and components |
| [IMG_1266.jpeg](IMG_1266.jpeg) | Undersides of programmer and adapter; adapter male contacts, traces, board labels |
| [IMG_1268.jpeg](IMG_1268.jpeg) | Closer programmer underside, SPI/I2C regions, signal pads, programming/TTL jumper legend |

The macOS filesystem exposes the user-described `photos` folder as `Photos`; use the capitalized tracked path in GitHub links.

Non-generative crops/rotations in `inspection/` improve reading orientation and isolate details without reconstructing markings. Reproduce them with:

```sh
python3 scripts/make_programmer_inspection_crops.py
```

The script uses macOS `sips`, checks the expected source dimensions, verifies that original hashes remain unchanged, and records crop coordinates/rotation and source hashes in `inspection/README.txt`.

Visible programmer labels include `CH341A Mini Programmer`, revision text appearing as `V1.512`, `BIOS 25 SPI`, `EEPROM 24 I2C`, and pads for CLK, CS, MOSI, MISO, GND, 3.3 V, and 5 V. The jumper legend specifies 1–2 programming and 2–3 TTL. Read these labels from the actual board before changing or powering it; no jumper position is assumed solely from the photo.

The adapter has an 1117-marked regulator and a 48-pin TI-marked IC whose text appears consistent with the 74LVC16T245 family. The full suffix, regulator output variant, module wiring/direction, socket mapping, and actual power/signal levels remain unverified. Component-family capability does not validate this particular module. See the [active test plan](../ROUTER-RECOVERY-TEST-PLAN.md) for bench results and next steps.

No router, programmer, or adapter operation is established by a photograph alone. At initial inspection, the next requested powered check is **bare programmer USB communication only**, with adapter, clips, and all targets detached.


## Partial eight-pin clip assessment — October 24

Four additional original user photographs were inspected without modification:

| File | Observed coverage |
| --- | --- |
| [IMG_1269.jpeg](IMG_1269.jpeg) | Actual black eight-contact clip, ribbon/keyed connector, and separate green clip breakout with eight male legs. Its electrical pin mapping is not yet measured. This is distinct from the green 1.8 V adapter with blue ZIF socket. |
| [IMG_1270.jpeg](IMG_1270.jpeg) | Close view of clip placed over the CS# end of right-hand U1_CSPI, away from its visible pin-1 dot. Individual jaw-to-leg contacts are partly obscured. |
| [IMG_1271.jpeg](IMG_1271.jpeg) | Opposite/rotated angle of clip placement and surrounding board; does not establish every electrical contact or absence of bridges. |
| [IMG_1273.jpeg](IMG_1273.jpeg) | Wider view of the same clip/board setup, showing U1/U2 and P1/P2 context. |

The position appears consistent with the proposed U1 pins 5–8/9–12 contact window; appearance is not electrical verification. No clip output pin number, stable contact, lack of shorts, or safe powered harness is inferred solely from the photos. The clip breakout's male legs make individual Dupont wiring feasible if the connectors fit securely, but it must not be inserted straight into the programmer/1.8 V adapter in this offset use.

Next, with all router power/cables disconnected, CR2032 removed, programmer USB unplugged and clip breakout separate from the programmer/adapter: in ohms mode, black on **router P1_CSPI pin 2 / known ground**, scan red across the **eight exposed male legs on the clip breakout**. Report how many give a near-lead-resistance reading and their actual resistance. Mark identified leg(s) so their physical identity is retained; multiple low matches need review before assigning a contact. This verifies the new clip connection through U1's ground, not a new unknown-board-node search. Electrical clip mapping remains pending.

Follow the [hybrid wiring worksheet](../C8375-CH341A-HEADER-WIRING.md) and [active plan](../ROUTER-RECOVERY-TEST-PLAN.md). No powered operation is requested.


## Current direct-pin U2 harness — October 27

Four new original user photographs document the changed harness after repeated chip-ID failures. The USB plug appears exposed in the overview; that records the photograph, not present power confirmation. No cable length, hidden contact or complete pin map is established visually.

| Original | Coverage |
| --- | --- |
| [IMG_1274.jpeg](IMG_1274.jpeg) | Programmer/adapter, grouped colored leads and chip clip on the user-identified U2 setup |
| [IMG_1276.jpeg](IMG_1276.jpeg) | Adapter socket/interposer and grouped connector detail |
| [IMG_1277.jpeg](IMG_1277.jpeg) | One angle of clip housing and chip-edge area |
| [IMG_1278.jpeg](IMG_1278.jpeg) | Opposite angle, visible RW170 marking and neighboring board context |

[Inspection record and original hashes](../c8375-recovery/acquisition-evidence/20261027-U2-current-harness-photo-inspection.json), [non-generative crop metadata and reproduction commands](inspection-20261027/CROP-METADATA.json), [derivative limitations](inspection-20261027/README.txt). Original bytes were rehashed unchanged after crop generation.

The user confirms no clip-side measurement access. The in-place and detached-connector continuity proposals were based on assumed probeable endpoints and are **withdrawn/unperformed**. No electrical signal-path checks are claimed from these photographs. These photos document U2 placement before the later user-confirmed move to U1. U1 subsequently has reported P1 supply1.786V and completed corrected short comparison reads, but region pairs differ at332/7bytes; it is not a validated backup. See the [U1 preflight](../c8375-recovery/acquisition-evidence/20261027-U1-comparison-preflight.json). See the [active plan](../ROUTER-RECOVERY-TEST-PLAN.md) and [inspection record](../c8375-recovery/acquisition-evidence/20261027-U2-current-harness-photo-inspection.json).

## Detached adapter for Pi interface — October 27

Original [IMG_1279.jpeg](IMG_1279.jpeg) shows the green 1.8V adapter top, blue ZIF socket, translator/regulator and printed 1/4/5/8 input-footprint labels. [IMG_1280.jpeg](IMG_1280.jpeg) shows its underside and two rows of four male input contacts. Appearance does not establish electrical mapping, underside pin numbering, connector grip or current power/cable state. No new measurements or hardware operations were performed. [Inspection metadata/original hashes](../c8375-recovery/acquisition-evidence/20261027-Pi5-adapter-photo-inspection.json).

The owner asks to avoid a custom three-way Dupont cable. Proposed method: one connected five-hole solderless-breadboard strip and four ordinary female-to-male jumpers distribute Pi3.3V to adapter INPUT8/3/7; SPI signals remain direct through the adapter. No assembly or powered test is claimed. See [connection example and prerequisites](../c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md#no-custom-cable-distribute-33-v-on-a-solderless-breadboard).


[IMG_1281.jpeg](IMG_1281.jpeg) records the remaining available loose pin headers and SPI/package breakout boards. Owner reports these plus Dupont cables are all other parts; no breadboard is available. No four-contact common node or safe fan-out is established from appearance. The next proposed check is isolated adapter INPUT8→3 and INPUT8→7 resistance, with every adapter wire removed and all power disconnected; no values have been reported.

## Pi-to-adapter harness with capped junction — October 27

Original [IMG_1282.jpeg](IMG_1282.jpeg) shows the underside adapter wiring and a capped junction with three black wires and a white/light-colored feed. [IMG_1283.jpeg](IMG_1283.jpeg) shows the Pi header connections and adapter. Owner confirms intended white Pi1/3.3V→junction→INPUT8/3/7, continuity among all four junction connectors, Pi powered on, CH341A removed and adapter output empty. Photos do not certify hidden connections, cap grip or all pin numbers. Read-only pin-function inventory succeeded; unloaded OUTPUT8/3/7 DC levels to OUTPUT4 remain requested/pending. No router probe/read/write ran. [Evidence and original hashes](../c8375-recovery/acquisition-evidence/20261027-Pi5-capped-junction-harness.json).


## U1/U2 access inspection — October 28

Five original owner photographs are retained unchanged.

| Original | Coverage |
| --- | --- |
| [IMG_1284.jpeg](IMG_1284.jpeg) | Overview of U1_CSPI/U2_CSPI, neighboring controller, U3/U4 and headers; both flash packages bare in photograph. |
| [IMG_1285.jpeg](IMG_1285.jpeg) | P1_CSPI/P2_CSPI and U3/U4 region, with U2 and other connectors in view; no new electrical assignments established. |
| [IMG_1286.jpeg](IMG_1286.jpeg) | Wider PSO/controller region with additional 16-lead package U11_IO; no part or bank/firmware identity inferred for that package. |
| [IMG_1287.jpeg](IMG_1287.jpeg) | Close oblique U1/U2 package/lead rows and spacing; no clip or individual grabber fitted in photograph. |
| [IMG_1289.jpeg](IMG_1289.jpeg) | Closest U1 view with U1_CSPI text above package, pin-1 marker at upper-right, U2 below. Under Micron SO16 top-view numbering, U1 pin7 is second lead from left on upper/outer row. |

These images show both flash packages bare; present power and clip state require owner confirmation. No alternate CS header/pad or grabber fit is established visually. In IMG_1289 only, U1 pin7 is the second lead from the left on the upper row, using the visible upper-right pin1 marker and Micron Figure6 numbering. Owner confirmation of prior probe endpoint is requested; no earlier value is discarded. [Original hashes, observations and limits](../c8375-recovery/acquisition-evidence/20261028-Pi5-CS-access-new-photos.json).
