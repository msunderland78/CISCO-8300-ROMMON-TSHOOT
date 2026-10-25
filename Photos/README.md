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
