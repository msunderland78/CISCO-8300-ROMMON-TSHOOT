# C8300-A photograph review

Reviewed **2026-11-02, America/New_York**, under C8300-01/02/03. The October 24 photo request is now fulfilled by ten originals in **[PHOTOS3](../../PHOTOS3)**. Originals remain unchanged in the owner's supplied folder. This replaces “awaiting photographs”; it records no new hardware test.

**Later November 2 session:** the [live console record](../../c8300-recovery/console-20261102/README.md) now documents owner-confirmed assembled startup tests. The newly supplied IOS XE 26.2.1 contains the selected [1N1S ROMMON 26.1(1r) reference](../../ROMMON-extracted/classic-c8300/iosxe-26.02.01/curie1ru/README.md). The observations below describe the earlier offline photo review.

**Memory-label follow-up, November 2:** the owner identifies chassis **FDO25150HVC** and supplies an eleventh original, **IMG_1316.jpeg**, after confirming power off and all external cables disconnected. The installed DIMM label reads **Micron MTA36ASF4G72PZ-2G6E1, 32GB, CPN 15-107071-01**. Both retaining-latch states and contact condition cannot be established from this close-up. Same-module inspection/reseat has been requested; completion and the post-reseat boot test remain pending. [Detailed label, original hash and source review](../../research-evidence/c8300-a-review-20261102/memory-review.json).

**Identification:** `IMG_1310` clearly shows **C8300-1N1S-4T2X**, the classic Catalyst 8300. Chassis serial and PSU labels are not established by these photos. Visible assembly labels include `800-108840-01 03+` near the CPU and `800-108841-01 03+` near the SFP cages; a board label is not substituted for a chassis serial.

The owner reports green power/fan indications, persistent steady red STATUS, and console silence. The October 24 confirmation that native USB was unplugged during the RJ45 attempt remains valid for that attempt. Exact settings, known-good cable validation and a timed byte capture remain unrecorded. Photos show the cover absent and CPU heatsink, fans and DIMM installed; they do not establish present power/cable/battery state. Reflections are not recorded as illuminated LEDs.

| Original | Useful observations |
| --- | --- |
| [IMG_1304](../../PHOTOS3/IMG_1304.jpeg) | Overall interior, fitted cooling/DIMM, board and expansion areas |
| [IMG_1305](../../PHOTOS3/IMG_1305.jpeg) | Lower board, FPGA, regulators and labeled headers |
| [IMG_1306](../../PHOTOS3/IMG_1306.jpeg) | CPU/DIMM, fan connections and board label near SFP cages |
| [IMG_1307](../../PHOTOS3/IMG_1307.jpeg) | Controller, separate flash pair, diagnostic indicators and headers |
| [IMG_1308](../../PHOTOS3/IMG_1308.jpeg) | CPU cooling, DIMM, regulator labels and U1_EM0D area; storage function not established from label alone |
| [IMG_1309](../../PHOTOS3/IMG_1309.jpeg) | Other board devices and console-side connectors |
| [IMG_1310](../../PHOTOS3/IMG_1310.jpeg) | Front-panel PID; RJ45/mini-USB console grouped together, distinct from storage USB ports |
| [IMG_1312](../../PHOTOS3/IMG_1312.jpeg) | Micron U1_BS and U2_BS, both marked RW164; adjacent debug connectors |
| [IMG_1313](../../PHOTOS3/IMG_1313.jpeg) | BOOT OK, BOOT FAIL, PWR OK labels; powered states/logic meanings unmeasured |
| [IMG_1315](../../PHOTOS3/IMG_1315.jpeg) | Macronix U4_UC/U5_UC near Microsemi SmartFusion2 U2_UC; UC GLDN, UC RST, UC BSPI DEDI labels |
| [IMG_1316](../../PHOTOS3/IMG_1316.jpeg) | Later installed-memory close-up: Micron MTA36ASF4G72PZ-2G6E1, 32GB, CPN 15-107071-01; both end latches outside the useful view |

No obvious large burn, broken cooling attachment or disconnected fan plug is apparent. This limited visual observation is not a board-health verdict. DIMM contact quality, underside damage and rails remain untested.

## Installed DIMM follow-up

The readable label also records **DPAPN31002**, identifier **MXA2435CNYT**, marking **2034**, and Product of CHINA; no date interpretation is assigned. Micron's [family datasheet](https://www.mouser.lt/datasheet/2/671/asf36c4gx72pz_8576911-3698462.pdf) identifies MTA36ASF4G72PZ as a 32 GB, 288-pin, dual-rank registered ECC DDR4 module. The -2G6 speed grade is 2666 MT/s, with nominal VDD 1.2 V. These are component specifications, not measured board rails; they are unrelated to the BS flash programming supply.

Cisco's [ordering guide](https://www.cisco.com/c/en/us/products/collateral/routers/catalyst-8300-series-edge-platforms/cat-8300-8200-series-edge-plat-og.html) supports a 32 GB upgrade in the C8300's single DIMM slot and lists MEM-C8300-32GB. This establishes supported capacity, not proof of this module's health or an exact public CPN-to-orderable-SKU qualification. No SPD read, memory test, contact inspection or reseat has yet been reported. Preserve the initial seating/latch observation before one controlled same-DIMM reseat, restore the cover, and leave power off until the next capture is ready.

## Flash identification and limits

| Physical devices | Identification | Device specifications | Inference / unresolved issue |
| --- | --- | --- | --- |
| U1_BS, U2_BS beside DIMM/debug connectors | Micron RW164 → **MT25QL256ABA8ESF-0SIT** using Micron decoder; U2 marking fainter | 256 Mbit = **33,554,432 bytes each**; **2.7–3.6 V**, wide SOIC-16/SOP2 | Strong CPU boot-storage candidates; actual contents, primary/golden assignment, selection and routes unverified |
| U4_UC, U5_UC near Microsemi U2_UC | **MX25L12835FMI-10G** visible on both | 128 Mbit = **16,777,216 bytes each**; **2.7–3.6 V**, 16-pin package | Separate pair, plausibly controller firmware; proximity/UC labels do not establish function or ROMMON targets |

Sources: [Micron decoder](https://www.micron.com/sales-support/design-tools/fbga-parts-decoder), [saved manufacturer response](../../research-evidence/c8300-a-review-20261102/micron-rw164-response.json), [Micron-authored datasheet, mirrored text](https://device.report/m/fceb28e67ae38113c9ca24b44f4b36594ad417cad67f74e07f004cef89882437), [Macronix datasheet](https://www.macronix.com/Lists/Datasheet/Attachments/9173/MX25L12835F%2C%203V%2C%20128Mb%2C%20v1.7.pdf). Datasheet voltage limits are not measurements of this board.

**Do not carry over the G2 1.8 V setup.** These devices need a qualified 3.3 V-class supply and compatible signals. Historical bare black CH341A outputs were about 5.18 V: a labeled 3.3 V supply does not make those signals safe. Qualify actual outputs for this target; do not merely remove the 1.8 V adapter and attach it. Board loading/isolation remains a separate prerequisite.

Do not bridge UC GLDN, UC RST, BOOT SEL or debug headers from their labels. Pinouts, selector polarity and a recovery-switch procedure are unestablished. Onboard LED labels offer possible observations, not a verified truth table; no open-cover powered test is requested by this review.

## Review method and next step

All ten originals were visually inspected with macOS sips previews. Selected original-pixel crops clarified the flash pairs and board label. Temporary derivatives reside in `/tmp/c8300-review-20261102`; no generative enhancement was used. Original SHA-256 hashes: [results.json](../../research-evidence/c8300-a-review-20261102/results.json).

The [supplied package analysis](../../ROMMON-extracted/classic-c8300/C8000-2N2S-17-18-1r/README.md) preserves a 24 MiB upgrade payload and separate capsule, neither approved as a whole-chip restore. The filename's 2N2S target needs reconciliation with the 1N1S chassis.

Follow [section 8 of the active plan](../../ROUTER-RECOVERY-TEST-PLAN.md#8-c8300-determine-what-no-console-means): reconfirm identity/state, complete only missing console controls, then consider a documented DIMM reseat and targeted power/reset/flash investigation. Independently read both BS devices before choosing firmware. No router was powered, connected, measured, read or written during this review.
