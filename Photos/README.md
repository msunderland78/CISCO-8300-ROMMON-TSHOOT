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
