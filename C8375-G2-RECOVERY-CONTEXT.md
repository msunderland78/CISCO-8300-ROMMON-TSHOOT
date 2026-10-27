# C8375-G2 recovery context — October 23, 2026

This is the consolidated handoff for the device identifying as **C8375-E-G2**, chassis **FDO2742M0FK**. Read this file before acting on older notes. It records the working IOS state achieved earlier today, the subsequent ROMMON experiments, and the later failure to boot.

Workspace: `/Users/games/Documents/SOFTWARE`  
Actual session date: **2026-10-23**, America/New_York. Router timestamps such as May 29, 2025, and 1970/1979 file dates were incorrect clock values; they are not the actual dates of this work.

## 1. Current state — start here

**The router no longer boots normally after the recommended ROMMON experiment. Do not mistake the earlier successful IOS tests for its current condition.**

**Pi script-file handoff — October 27, America/New_York (R-01):** owner requests a script file instead of pasted Python. Added AI-assisted original [`scripts/pi_u1_short_reads.py`](scripts/pi_u1_short_reads.py): same two-region/two-pass read/compare, but only explicit **`--read`** opens SPI; default/help/import have no hardware action. Seven new offline mocked acquisition tests plus existing publication tests **all18pass**. Source and dependency/usage record are public; samples remain private. Delivery will use a commit-pinned GitHub download with SHA256 verification and a short run command, avoiding the earlier rejected saved SSH login. **No script installed on Pi or reads executed by agent; no sample result yet.** [Preparation/delivery evidence](c8375-recovery/acquisition-evidence/20261027-Pi5-U1-ID-and-short-read-preparation.json).

**Pi U1 identification PASSED / bounded reads prepared — October 27, America/New_York (R-01):** owner-pasted Pi output reports `linux_spi`, `/dev/spidev0.0`, **Using100kHzclock**, **id1=0x20/id2=0xbb19**, **MicronMT25QU256/32768kB**, **status0x00/WELclear/WIPclear**, **No operations were specified**. This verifies communication in that attempt, not array accuracy. Original Pi log `C8375-U1-ID-100kHz-1HaQgr.log` remains on Pi, not independently fetched/hashed. Last P1 loaded supply1.789V; no during-ID continuous range reported. Next command is copied to clipboard: fresh private Pi folder, **two passes over001f0000–001fffff and01f30000–01f3ffff**, four65536-byte samples/two logs, size/SHA256/byte comparisons. Python/shell syntax and three synthetic comparator checks passed; **samples not yet executed/verified**. User owns SPI execution; no agent probe or full capture/write. [ID/preparation evidence](c8375-recovery/acquisition-evidence/20261027-Pi5-U1-ID-and-short-read-preparation.json).

**Pi loaded U1 supply / ID command prepared — October 27, America/New_York (P-03 / R-01):** owner reports **router P1-1→P1-2 =1.789VDC** after the Pi-off/reconnect/Pi-only-power instruction. Freshly confirmed physical target remains **C8375-A/FDO2742M0FK/U1**, router power/other cables/CR2032 disconnected, no active competing session; no setup change reported. Value is within1.7–2.0V, not proof of clean transients or reliable reads. A **user-executed ID-only** command is now prepared for `linux_spi:dev=/dev/spidev0.0,spispeed=100`, exact `MT25QU256`, with a fresh mode0600 log via `mktemp`; local shell syntax passes. **Not executed by agent; no ID result yet.** An extra SSH-only log-template dry-run was rejected at login (255/authentication denied), so it did not execute; earlier successful SSH/pinctrl remains historical. Continue from the owner’s Pi terminal; no login retry or credential search. Keep wiring still and monitor supply. Expected prior identity20BB19/32768KiB; incorrect/zero ID stops before samples. [Evidence/prepared command](c8375-recovery/acquisition-evidence/20261027-Pi5-capped-junction-harness.json).

**Pi adapter unloaded voltage result — October 27, America/New_York (P-03):** owner reports **OUTPUT8/VCC, OUTPUT3/WP# and OUTPUT7/HOLD# each1.804 VDC relative to OUTPUT4/GND**, Pi-powered with adapter output empty. Supports nominal unloaded supply/static control highs; loaded voltage, dynamic translation and acquisition remain unverified. Owner reconfirms **C8375-A/FDO2742M0FK/U1**, router power/other cables and CR2032 disconnected, no active console/programmer. Next: **shut down/unplug Pi before reconnecting the existing mapped U1 output harness**, check junction grip while off, then Pi-only power and **loaded P1-1→P1-2 DC voltage** (must remain1.7–2.0V) before flashrom. This step is planned; no loaded measurement or SPI operation yet. [Updated evidence](c8375-recovery/acquisition-evidence/20261027-Pi5-capped-junction-harness.json).

**Pi harness checkpoint — October 27, approximately 16:50 EDT (P-03):** inspected [IMG_1282](Photos/IMG_1282.jpeg)/[IMG_1283](Photos/IMG_1283.jpeg): capped white/three-black junction and colored Pi-to-adapter jumpers. Owner confirms intended white Pi1/3.3V→junction→adapter INPUT8/3/7, CH341A removed, **Pi powered on**, **nothing connected to adapter output**, and continuity among all four junction connectors (no Ω/baseline or test timing supplied). This supersedes the earlier no-junction inventory; breadboard is no longer the necessary next purchase if this harness passes checks. SSH `sudo pinctrl get 8-11` read-only succeeds: GPIO9/10/11 SPI0 MISO/MOSI/SCLK, GPIO8 output high; no pin settings changed or SPI device opened. **Await unloaded DC volts OUTPUT8/3/7, all to OUTPUT4/GND**; each expected around1.8V. Keep router disconnected and powered wiring still. Cap grip/complete end-to-end map, loaded supply and reliable SPI remain unverified. [Evidence](c8375-recovery/acquisition-evidence/20261027-Pi5-capped-junction-harness.json).

**Adapter input resistance result — October 27, America/New_York (P-03):** owner reports **INPUT8→3 =632 Ω**, **INPUT7→3 =632 Ω**. Preserve the second pair as reported; requested8→7 and fresh lead baseline are unreported. Detached/unpowered conditions were requested, not separately restated. Values do not establish a direct common supply node, diagnose an internal component or justify a single-input8 feed. No further repeat solely for the all-three-common hypothesis. Proposed fixed-rail Pi method still needs a secure common junction; mini solderless breadboard/four standard female-to-male leads is a no-custom-cable option, not an order/delivery. No new wiring, GPIO, SPI or router operation. [Measurement record](c8375-recovery/acquisition-evidence/20261027-Pi5-adapter-photo-inspection.json), [updated plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md#available-parts-clarification-and-next-isolated-adapter-check).

**Available-parts clarification — October 27, America/New_York (P-03):** new [IMG_1281](Photos/IMG_1281.jpeg) shows loose pin headers and SPI/package breakouts; owner reports these plus Dupont cables are all remaining parts. No breadboard available or four-contact common node verified. Prior breadboard proposal stays contingent. Next isolated check: detached1.8V adapter, every wire removed, no residual voltage; record ohms lead baseline and measure **INPUT8→3 / INPUT8→7** to determine whether separate supply feeds are needed. Earlier fitted CH341A checks did not establish internal ties. No result, powered connection or router operation. [Updated plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md#available-parts-clarification-and-next-isolated-adapter-check), [inspection metadata](c8375-recovery/acquisition-evidence/20261027-Pi5-adapter-photo-inspection.json).

**Adapter connection checkpoint — October 27, America/New_York (P-03):** inspected new original adapter top/underside photos IMG_1279/1280. Underside male contacts are visible; numbering, connector fit and new Pi interface remain unverified. Owner requests no custom Dupont cable. Proposed one connected five-hole solderless-breadboard strip with four ordinary female-to-male jumpers distributes Pi3.3V to adapter INPUT8/3/7; keep SPI signals direct through adapter. No assembly, measurement or powered operation performed. [Photo record](c8375-recovery/acquisition-evidence/20261027-Pi5-adapter-photo-inspection.json), [connection example](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md#no-custom-cable-distribute-33-v-on-a-solderless-breadboard).

**Verified Pi checkpoint — October 27, approximately 16:06 EDT (P-03):** read-only SSH inventory now confirms **Pi 5 Model B Rev 1.1 / Ubuntu 26.04.1 LTS / aarch64 / kernel 7.0.0-1020-raspi**. SPI is already enabled; installed **flashrom 1.6.0** lists **MT25QU256** and `linux_spi` offline. Sysfs/device-tree identifies **`/dev/spidev0.0` as RP1 GPIO-header SPI0/CE0**; leave separate SoC `/dev/spidev10.0` alone. No device node opened, install/config/reboot, GPIO connection or router probe/read/write. `sudo -n` needs interactive authentication; unprivileged pinctrl query could not verify pin functions. Owner replied yes to grouped chassis/U1/isolation/disconnected-GPIO reconfirmation. Next: shut down/unplug Pi, detach adapter from CH341A and router output harness, identify actual adapter INPUT contacts, then validate Pi3.3V↔flash1.8V interface before requested100kHz ID/short reads. [Inventory metadata](c8375-recovery/acquisition-evidence/20261027-Pi5-live-inventory.json), [updated wiring/acquisition plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md). Raw SSH captures/credentials remain private. Earlier no-login checkpoint is retained below as history.

**Latest preparation checkpoint — October 27, America/New_York (P-03):** the owner now reports **Pi5 / 256 GB microSD / Ubuntu Server 26.04.1 LTS**, superseding the earlier Ubuntu24 belief. Supplied SSH endpoint/login credentials are saved only in restricted local `.git/recovery-private/pi5-ssh.json`; the password is registered with the publication guard. No remote login or OS/kernel/SPI verification performed. **Two new SOIC-16 clips with 40 cm cables and 10 cm Dupont cables have arrived**, user-confirmed; model/fit/mapping remain unverified. About50cm applies only if both cable lengths are in the route, not a measured assembled length. A requested100kHz Pi SPI trial is planned; longer-cable reliability remains unproven. [Complete Pi acquisition/resume plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md). No Pi configuration, GPIO/router operation or firmware write performed.

**Latest hardware result — October27, America/New_York: U1 comparison completed, repeatability FAILED.** Current physical target is **C8375-A / FDO2742M0FK / U1**. User confirms **adapter output4→P1-2 =0.3 Ω**, **output8→P1-1 =0.3 Ω**, **P1 VCC =1.786 V DC** and asks a read test. Normal router power/other cables and CR2032 remain disconnected under the session setup; no chassis change reported. The earlier identification-only command was prepared but never released/performed.

The first sample command was **rejected before programmer initialization**: the agent’s broad U2→U1 label replacement changed **MT25QU256 to MT25QU156**. This was a command-generation error, not a hardware test; [failed log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U1-comparison-command-chip-name-error.log) and original bad script preserved. Corrected commands specify **MT25QU256** in both argv lists, checked against installed offline `flashrom -L`, plus shell/comparison-Python syntax checks. The subsequent user-run corrected reads **both detect Micron MT25QU256/32768KiB**, complete in **one second each**, and create four **65,536-byte, mode0600** samples. Independent offline verification finds **332 differing bytes at 0x001F0000–0x001FFFFF** and **7 at 0x01F30000–0x01F3FFFF**. **Neither region pair is repeatable.** [Independent validation](c8375-recovery/acquisition-evidence/20261027-U1-comparison-partial-validation.json), [read1](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U1-comparison-partial-read1.log), [read2](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U1-comparison-partial-read2.log).

Against the rehashed original reference, lower samples differ at **8,080 / 8,078 bytes**, all differences losing original one bits; the older matching U1 read5 region differed at **58,802 bytes**. Upper samples differ from original at **54 / 59 bytes**, versus **8,237** in old U1 read5. These are bounded region comparisons, not proof the original is the correct image for this physical bank or that changed cable length caused improvement. Neither new sample equals either known reference. Prior U1 read5/read6 remain byte-identical as a historical result, with accuracy concerns retained. Read2 reports status0x02/WEL as observed, not proof of array programming. The corrected setup communicates with U1 but remains unreliable; U2-specific failure/dead chip is **not established**. No full read, restore selection or write is selected. Raw samples remain private and unchanged.

**Next:** unplug CH341A USB, leave the clip/wiring on U1; unplug confirmation pending. No unchanged retry or inaccessible clip-side measurement is requested. The original35cm clip/ribbon/breakout remains unavailable or modified; the newly arrived40cm clips are separate assemblies. Preserve the reported Ubuntu Server26.04.1 installation and perform read-only Pi inventory with GPIO disconnected, using the credentials stored privately. Then identify the GPIO-header SPI device, verify installed flashrom and the Pi3.3V↔flash1.8V interface with CH341A removed, and only then test ID and bounded repeatability at requested100kHz. Slower SPI may improve timing margin but does not establish contact, loading or whole-array accuracy. Current router target remains U1; normal router power/cables/CR2032 were removed under the session setup and must be reconfirmed before hardware access. No reimage, EEPROM update, GPIO connection or router operation performed. [Complete plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md), [Pi preparation record](c8375-recovery/acquisition-evidence/20261027-Pi5-preparation.json), [programmer options](c8375-recovery/acquisition-evidence/20261027-alternate-programmer-options.json). Earlier U2 failures, probe corrections, U1 comparison and withdrawn measurement plans remain preserved below.

**Earlier October27 session history — initial U2 setup (R-01-U2-SHORT-HARNESS):** the user confirms **C8375-A / FDO2742M0FK / U2**, normal router power and all other cables disconnected, **CR2032 removed**, no console/programmer command running, and all eight connections checked against the actual mapping. New tool/clip model is unspecified; total wire path is reported as **a little longer than 10 cm**. User measurements: **P1-1→active 1.8 V adapter output 8 = 0.3 Ω**, **P1-2→output 4 = 0.3 Ω**, and **P1-1→P1-2 = 1.787 V DC with CH341A USB connected**. Resistance measurement power-off/residual-voltage conditions and fresh lead baseline were not separately restated. The loaded DC supply is within the Micron 1.7–2.0 V range; it does not establish read reliability or prove the earlier long wiring caused failures. Host inventory sees **1A86:5512**, no flashrom process. Agent used host/offline checks only; no programmer access. The initial user-run logged sudo probe **initialized CH341A but failed identification: id1 0x00 / id2 0x00, RDID byte-0 parity violation; no flash found**. No partial/full capture started. [Preserved probe log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-short-harness-initial-no-id.log). **Historical reconciliation:** October 25 U2 also returned 00/00, then 20/0000, before successfully identifying as 20 BB 19 and completing reads; this failed attempt does not establish permanent communication failure or a dead/erased chip. Both old full pairs still failed repeatability. The subsequent user-run retry **succeeded: 20 BB 19 / Micron MT25QU256, 32768 KiB, status 0x00; no operations specified**. [Successful ID log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-short-harness-retry1-id-success.log). No hardware change between probes was reported. This establishes communication on this attempt, not stable array acquisition or a cable-length diagnosis. Last pre-probe supply was 1.787 V; during-probe voltage was not separately reported. The user executed the prepared **two-region/two-read partial diagnostic** at **10:28:46 EDT** (comparison-file timestamp); the agent independently verified all files offline. **Repeatability FAIL:** **0x001F0000–0x001FFFFF differs at 58,005 / 65,536 bytes**; **0x01F30000–0x01F3FFFF matches exactly**. All four samples are 65,536 bytes, mode 0600; both read logs report done in one second, no flashrom process remains. Neither region matches either saved reference. Against the known nonbooting reference, lower samples lose one bits at **58,849 / 59,273 byte positions**, upper samples at **42 positions each**, with no added one bits; this records a directional pattern without diagnosing its cause or authorizing reconstructed bytes. Read2 reports status **0x02 / WEL set**, retained as an observed status, not proof of array programming; commands selected reads only. [Independent sample validation](c8375-recovery/acquisition-evidence/20261027-U2-short-harness-partial-validation.json), [read1 log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-short-harness-partial-read1.log), [read2 log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-short-harness-partial-read2.log). **No new full captures selected.** Programmer USB unplug requested, wiring left seated; confirmation pending. **Voltage follow-up:** the user was not watching continuously, but every spot check stayed very close to **1.787 V**. This supports approximately normal DC supply at those moments; no exact minimum/maximum or transient measurement exists, and mechanical stability was not separately answered. **Requested clip-reseat trial outcome:** the user ran the `clip-reseat1/` sample script, but its first read stopped at identification: **00/00, RDID byte-0 parity violation; no chip found**. Both precreated read1 files remain **zero-byte placeholders**, not captures; no read2 outputs or comparison were created. Physical reseating, refreshed post-reseat voltage and unplug were not separately confirmed. [Failure record](c8375-recovery/acquisition-evidence/20261027-U2-clip-reseat1-no-id.json), [failed probe log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-clip-reseat1-no-id.log). Earlier successful IDs after 00/00 remain relevant. **Unchanged-wiring retry outcome:** the user ran `clip-reseat1/retry1/`; it again initialized CH341A but failed identification **00/00 with RDID byte-0 parity violation**. The two read1 placeholders are **zero bytes**; no sample, second read or comparison was acquired. [Retry log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-clip-reseat1-retry1-no-id.log), [updated failure history](c8375-recovery/acquisition-evidence/20261027-U2-clip-reseat1-no-id.json). No flashrom process remains. At that point, historical failed-then-successful probes remained valid, but another unchanged software retry was not selected after those two consecutive failures. **Earlier loaded control measurements, user-reported October 27:** **P1 VCC 1.79 V**, **pin 3/RESET# 1.73 V**, **active 1.8 V adapter output 7 = 0 V**. The user explicitly confirms output 7 is the mapped lead to **U2 physical pin 1/HOLD#**, black **P1-2/GND**, CH341A USB connected. With VCC 1.79 V, nominal **VIH minimum is 1.253 V**, **VIL maximum 0.537 V**. Reported RESET is high; output 7/HOLD route is low at the measured point. If this reaches U2 and HOLD is enabled, it can inhibit communication; this does not identify the fault or establish the level during earlier successful probes/failed samples. **Connection constraint / revised next check:** the user reports a **four-position connector covering adapter positions 5–8**, preventing output 7 from being disconnected individually. The earlier one-lead source/load-isolation instruction was **not performed and is superseded**; leave the connector and U2 clip intact. **Unpowered resistance result:** after explicitly clarifying that the reference is **adapter output 4, not P1 pin 2**, the user reports **output 7→output 4/GND approximately 4,700 Ω / 4.7 kΩ**. Conditions were requested as USB off, router power/other cables disconnected, CR2032 removed, residual P1 DC near zero, meter ohms red 7/black 4; not separately restated in the numeric reply. Fresh lead baseline was not supplied. This is not a near-zero static ground path, but does not locate a resistor/fault or explain the powered 0 V. **Programmer source-rail result:** the user instead uses the documented CH341A side supply pins: **3.3 V→side GND = 3.318 V DC**, and **same side 3.3 V→1.8 V adapter output 4/GND = 3.318 V DC**. This supports normal source voltage and a common ground reference; it is **not a direct measurement of hidden adapter input 7/8 contacts**. Historical input mapping supplies those from 3.3 V, but individual current contact voltage remains unverified. **Corrected fully unloaded adapter result:** the user explicitly withdraws the last unloaded **OUTPUT 7→4 = 0 V** and **OUTPUT 8→4 = 0 V** reports: **wrong probes were plugged in**. These are invalid measurement reports, retained as correction history, **not a supply collapse**. With the correct probes, **OUTPUT 7→OUTPUT 4 = 1.803 V DC** and **OUTPUT 8→OUTPUT 4 = 1.803 V DC**, under the previously confirmed USB-connected, adapter-seated, all-router-leads-disconnected setup. Both unloaded outputs provide nominal1.8V DC. This does not establish loaded HOLD level, drive capability, full signal translation or accurate reads. The follow-up regulator-tab/source/reference checks motivated by the invalid unloaded zeros are **canceled, not performed**. Earlier loaded P1 **1.79 V**, RESET **1.73 V**, source **3.318 V**, and loaded output7 **0 V** reports remain recorded; only the last unloaded zero pair was explicitly withdrawn, so a current loaded recheck is needed before concluding that the board pulls HOLD low. **Latest loaded recheck / adjusted-connections sample result:** the user reports **further clip and connection adjustment**, **P1-1→adapter output8 =0.3 Ω**, **P1-2→output4 =0.3 Ω**, **P1-1→P1-2 =1.787 V DC**, and **both loaded output8→4 and output7→4 approximately 1.7–1.8 V DC**. The earlier loaded output7 zero is an earlier report, not the present reported level. Clip seating and connections changed together; no single fault/repair cause or stable backup is established. Resistance-test power-off timing/fresh lead baseline and exact new control minima were not separately supplied. The user ran the fresh two-region quick test, but it **initialized CH341A revision 3.0.4 and then failed flash-chip identification 00/00 with RDID byte-0 parity violation**. Both precreated read1 files are **zero-byte placeholders**, not samples; no second read or comparison was created, runtime one second. [Failure record](c8375-recovery/acquisition-evidence/20261027-U2-connections-adjusted-no-id.json), [preserved log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-connections-adjusted-no-id.log). **User USB reconnect / fresh retry outcome:** user describes no CH341A detection and unplugs/replugs USB; saved logs distinguish successful programmer initialization from failed chip detection. Read-only host inventory afterward sees **USB UART-LPT / 1A86:5512**, no flashrom process. The user executes the fresh guarded sample retry in private `usb-reconnect-120935-EDT/`; it **again initializes CH341A revision3.0.4 but fails flash-chip ID00/00 with RDID byte0 parity violation**. Both read1 files remain zero-byte placeholders; no region data, second read or comparison acquired, runtime0seconds. [USB-reconnect failure log](sanitized-evidence/c8375-recovery/programmer-logs/20261027-U2-usb-reconnect-no-id.log), [combined failure record](c8375-recovery/acquisition-evidence/20261027-U2-connections-adjusted-no-id.json). All earlier files preserved; no agent programmer access. **Current harness photographs received/inspected:** user adds [IMG_1274](Photos/IMG_1274.jpeg), [IMG_1276](Photos/IMG_1276.jpeg), [IMG_1277](Photos/IMG_1277.jpeg) and [IMG_1278](Photos/IMG_1278.jpeg) on October27. Original bytes are preserved/rehashed; labeled [non-generative inspection crops](Photos/inspection-20261027/CROP-METADATA.json) record exact pixel coordinates/commands and hashes. Photos show the direct-pin spring chip clip, grouped colored-lead connectors, adapter/socket/interposer and neighboring board context; RW170 marking is visible. Exposed USB plug is visible at capture, not confirmation of current power state. No individual wrong wire/bridge, complete pin1 orientation, hidden jaw-to-leg contact or dynamic signal integrity is established visually. [Photo inspection record](c8375-recovery/acquisition-evidence/20261027-U2-current-harness-photo-inspection.json). **Access correction:** the user confirms the clip covers U2, all TOP metal is hidden, and there is **nowhere to measure on the clip**. The agent’s in-place and free-connector continuity proposals assumed accessible probe endpoints that were not established. Both requests are **withdrawn/unperformed**; no signal-resistance values or successful checks exist. Stop clip-side/under-clip measurement requests. P1 VCC/ground associations remain supported; mux/header/U1 signals are not direct SPI proxies for covered U2 legs. **Subsequent U1 comparison:** the user now confirms the clip is on **U1**, power/ground paths each0.3 Ω and loaded P1 **1.786 V DC**, then requests a read test. The first U1 command was rejected before hardware initialization due the agent’s chip-name typo; the corrected **MT25QU256** partial pair completed with **332 / 7 byte mismatches**, no full capture selected. See the latest U1 checkpoint above and [preflight record](c8375-recovery/acquisition-evidence/20261027-U1-comparison-preflight.json). The original ID-only command was prepared but never copied/performed, superseded by the read request. Prior U1 repeatability remains separate from accuracy; neither outcome alone diagnoses chip health or bank role. All U2 results/bytes preserved; no agent hardware access. No connector depinning/cutting, partial-group powered disconnection, HOLD-to-VCC jumper, voltage increase or full-array capture is selected at this checkpoint. October 25 breakout readings **RESET 1.707 V / HOLD 1.770 V with prior VCC 1.759 V** are retained as older evidence, not current values for this changed harness. Readings at a breakout/contact alone do not prove contact at the package leg or behavior during an SPI transaction. No new full captures, control jumper, voltage increase, firmware write, protection/OTP operation or agent programmer access selected. Short wiring and successful ID do not establish stable acquisition or isolate a cause. Partial samples are not backups. Preserve all older failures; U2 still lacks a stable full backup. Main-array recovery evidence does not establish that U2 contains IOS configuration. See [preflight record](c8375-recovery/acquisition-evidence/20261027-U2-short-harness-preflight.json).

**Historical end-of-day handoff — October 25, 2026, America/New_York:** the user requests stopping for today. Final read-only verification at **2026-10-25T20:42:42.113173-04:00** confirms **eight full captures**, each 33,554,432 bytes and mode0600, rehashed unchanged against recorded values; **16 private programmer logs** remain present, no flashrom process. [End-of-day integrity/checkpoint inventory](c8375-recovery/acquisition-evidence/20261025-end-of-day-checkpoint.json). Raw dumps stay ignored/local in `.git/recovery-private/`; public sync contains documents, generated sanitized logs, hashes/validation metadata and manifest. No further hardware action is selected. **Shutdown instruction:** unplug CH341A USB; U2 clip may stay seated, normal router power/console/cables disconnected and CR2032 removed. USB unplug confirmation was not supplied; reconfirm actual physical state next session. **Resume:** confirm new direct-pin clip receipt (expected October 26, not yet observed), identify its own mapping with all sources off, support the adapter, verify VCC/ID and bounded repeatability before new full captures. U1’s matching pair does not yet establish raw-byte accuracy; both U2 pairs failed. The original-matching small region in U2-read4 does not identify U2 as primary/golden or the native-updater target. **No restore target, firmware write, OTP/provisioning change or successful boot is claimed.** All failures and original bytes remain preserved.

**Latest U2 acquisition result — shorter USB, October 25, 2026, America/New_York (R-01-U2-SHORTER-USB):** user-run **read3/read4** completed at **33,554,432 bytes each**, **4m37s / 4m36s**, but **repeatability FAIL: 1,775,520 differing bytes**, **87 aligned 64-KiB windows**, first **0x10000**, last **0x1F31FFF**. SHA-256 read3 **`7c9380d44cb71d1af0cdb7726d46f52403c0070895ce8364ab2603e0564c5cb5`**, read4 **`3aebc8dbe548730f296d3c1b1f24661295a365c423e4a2be1338a676e72a1498`**. [Validation metadata](c8375-recovery/acquisition-evidence/20261025-U2-shorter-usb-retry.json); [read3](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-shorter-usb-read3.log) / [read4](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-shorter-usb-read4.log) logs. Both files/logs remain unchanged, user-owned **0600**, in private `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-201130-EDT-shorter-usb/`. Neither full capture matches the original, known nonbooting reference, U1 or either older U2 capture. Read4’s bounded **0x10000–0x17FFF** region equals the saved original exactly, while read3 differs there at **1,490 bytes**; this does not authenticate firmware or establish whole-array accuracy/bank identity. The separate U1-read5 and older U2-read1/U2-read2 header-region comparisons also show losses of original one bits, retained in metadata. A lower mismatch count than the first U2 pair does not establish a causal USB-cable improvement. **U2 still lacks a stable backup; no restore target or write selected.** Last pre-read P1 was **1.758 V**, during-read value not separately supplied. Agent observed flashrom exit and requested **USB unplugged, U2 clip left seated**; unplug confirmation pending. Normal router power/console/cables and CR2032 remain removed. Next recommended hardware test is the ordered direct-pin clip on arrival (expected October 26, not received), with stable adapter support, unpowered mapping and voltage/ID/bounded repeatability before more full reads. All earlier captures/failures preserved; agent used only offline files/process metadata.

### Earlier October 25 acquisition checkpoints (historical)

**Shorter-USB retry prepared, October 25, 2026, America/New_York — R-01-U2-SHORTER-USB:** user moves the device closer, shortens the USB connection (length unspecified), and requests another attempt. User reports **P1-1→P1-2 = 1.758 V DC**; read-only host inventory sees **1A86:5512** with no flashrom process. U2 clip/adapter/wires are retained; this is a USB-side change, not confirmed removal/shortening of the 35-cm SPI ribbon. A fresh guarded user-terminal **U2-read3/read4** command is copied to the clipboard and offered to run immediately in private `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-201130-EDT-shorter-usb/`; each read probes first, second runs only after first succeeds, then user ownership/mode-0600 cleanup. **Capture outcome pending**. Expected full size is 33,554,432 bytes each. Preserve all previous failed logs/read1/read2 unchanged. Keep adapter/clip/wires still, normal router power/console/cables/CR2032 removed, monitor DC VCC at P1 and unplug outside 1.7–2.0 V. No agent programmer access or write. Shorter USB is a new variable, not an established fix. [Retry metadata](c8375-recovery/acquisition-evidence/20261025-U2-shorter-usb-retry.json).

**Earlier U2 retry outcome / handoff, October 25, 2026, America/New_York — R-01-U2-ADAPTER:** after USB enumeration returned, the user’s fresh read3 command successfully initializes CH341A/SPI but returns **id1 0x00 / id2 0x0000**, RDID byte-0 parity violation, no chip. Agent verifies **no read3/read4 dump and no read4 log**: neither new full capture started. [Failure metadata](c8375-recovery/acquisition-evidence/20261025-U2-adapter-reseated-no-id.json), [generated log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-adapter-reseated-usb-restored-no-id.log). The prior USB-open failure is separate and retained. Last P1 supply was **1.752 V** before this probe; during-probe voltage not separately reported. Earlier U2 full read1/read2 remain preserved and failed repeatability at **3,897,877 bytes**; U1 read5/read6 remain repeatable with separate accuracy concerns. The moving adapter has been user-reseated, but neither it nor clip seating/cabling/board loading is established as the cause. **USB unplug is requested; leave clip seated on U2**, normal router power/console/cables/CR2032 removed. Recommended next hardware change is the ordered direct-pin clip on arrival (expected October 26, not received), with stable adapter support, fresh unpowered mapping/voltage/ID and bounded repeatability before full reads. No additional unchanged full-read retry is selected; no firmware write or bank/restore target assignment. The agent used only offline files/process/USB inventory checks, not programmer access.

**USB enumeration restored / fresh pair released, October 25, 2026, 20:03:07 America/New_York — R-01-U2-USB:** user confirms a **direct Mac USB connection** and requests a recheck. Read-only host-device inventory now lists **USB UART-LPT, VID 0x1A86 / PID 0x5512**, 13 USB device nodes, no active flashrom process. Previous absent-device observations remain earlier results; the exact reason for the transition is not established. Last user-reported P1 supply is **1.752 V DC**. A new guarded **U2-read3/read4** command is copied to the clipboard and offered to run immediately in private `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-200000-EDT-usb-reconnect-retry/`, avoiding the failed initialization log in the prior directory. Each read probes first; read4 follows successful read3, then user ownership/mode-0600 cleanup. **Fresh capture results pending**. Preserve every prior log/dump unchanged. U2 clip/adapter/wires remain seated; router power/console/cables and CR2032 removed; monitor target VCC at P1 without pressing adapter, unplug outside 1.7–2.0 V. No agent programmer access, forced detection or write.

**Earlier USB-access failure, October 25, 2026, America/New_York — R-01-U2-USB:** the adapter-reseated user read3 command stops **before chip probing**: `Couldn’t open device 1a86:5512; Programmer initialization failed`. The agent verifies **no U2-read3.bin, U2-read4.bin or read4 log** in the retry folder; failed read3 log is preserved unchanged. [Failure metadata](c8375-recovery/acquisition-evidence/20261025-U2-adapter-reseated-usb-open-failed.json), [generated log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-adapter-reseated-usb-open-failed.log). A repeated old guarded command would stop on that existing log; a fresh private directory is prepared but its command is not released. User reconnects USB under the requested setup and reports **P1 1.752 V DC**, within range. Read-only `ioreg -r -c IOUSBHostDevice -a` checks list **12 USB device nodes, no WCH vendor 0x1a86**, including after the reply. Initial IOUSB-plane/system-profiler inventories exposed zero device nodes and are insufficient by themselves; host-device class inventory supplies the meaningful check. This is USB access/enumeration evidence, not a new chip/contact diagnosis. **Pending:** user USB connection path (direct Mac, hub/dock/extension/adapter, or other source) requested before selecting the next reconnect action. Keep U2 clip/adapter/wires seated, router power/cables/CR2032 removed. Agent has not accessed the programmer; no new full read or write.

**Adapter-reseated retry released, October 25, 2026, America/New_York — R-01-U2-ADAPTER:** user confirms **P1 supply remains 1.757 V DC** after the requested USB-off seating/support and hands-off-adapter voltage check. The guarded **U2-read3/read4** command is now copied to the clipboard and offered to run immediately in private `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-195526-EDT-adapter-reseated/`. Each full read probes first; read4 runs only after successful read3, then ownership/mode-0600 cleanup. **New captures pending**, expected 33,554,432 bytes each and about 9–10 minutes total. Preserve failed read1/read2 and all earlier IDs unchanged. Leave U2 clip/wires and adapter still; monitor DC VCC at P1 without pushing the adapter. Router power/console/cables and CR2032 remain removed; unplug for supply outside 1.7–2.0 V. User owns programmer; agent handles files/process metadata only. No force or write.

**Subsequent adapter observation / requested retry, October 25, 2026, America/New_York — R-01-U2-ADAPTER:** after the failed full pair, the user requests another attempt and reports **reseating the 1.8 V adapter because it moves when pressed during voltage measurement**. This is a new contact-stability variable, not proof of the cause; timing of the reseat relative to USB power was not supplied. Instructed **USB unplugged before securing/reseating**, U2 clip/wires left seated, then USB-only supply measurement at **P1-1/P1-2 in DC volts without pressing the adapter**. Normal router power/cables/CR2032 remain removed. **Post-reseat loaded voltage pending**. Fresh private mode-0700 `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-195526-EDT-adapter-reseated/` is prepared for **U2-read3/read4** and separate logs; the command is not copied/released or run until supply is acceptable. Prior read1/read2 failure and bytes remain unchanged. One new pair is authorized by the user’s retry request; no force or write. The replacement direct-pin clip remains expected October 26, not received, as a later option.

**Latest hardware result — U2 pair completed, repeatability failed, October 25, 2026, America/New_York (R-01):** user-run **U2-read1/read2** both completed at **33,554,432 bytes**, **4m36s each**, but differ at **3,897,877 byte positions** across **105 aligned 64-KiB windows** (first 0x1FFBF, last 0x1F9407F). SHA-256 read1 **`66856b955526c85bb5ec9cccb09e1a347e59fc4497d7f25dc190163fd89e3c8b`**, read2 **`b07ad18bcfd71520e61ad2ef75b578185e5c598815105e47065a84f35d6478cf`**. Both original logs report expected Micron detection and done. The agent checked files/hashes/bytes offline and observed flashrom exit; no agent programmer access. Captures/logs remain unchanged, user-owned **0600**, in private **`.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-194109-EDT-full-reads/`**. [Validation metadata](c8375-recovery/acquisition-evidence/20261025-U2-full-read-validation.json), [read1 log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-full-read1.log), [read2 log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-full-read2.log). Neither equals the exact original, known nonbooting readback or stable U1 capture. **U2 is not a stable backup; array accuracy, physical bank role and restore target remain unresolved.** Last pre-read VCC was 1.757 V; during-read supply report is requested/pending. Programmer USB disconnection is requested after completion, not yet confirmed; leave clip seated on U2 per user preference, normal router power/cables and CR2032 removed. Next hardware test is the ordered direct-pin replacement clip, expected October 26, not received: reconfirm setup/mapping, check voltage/ID and a bounded repeatability sample before new full captures. It removes the 35-cm ribbon, but no specific cable/contact/board-loading cause is established. No write, protection/OTP operation, speculative jumper or voltage increase. U1 remains repeatable with separate accuracy concerns; all earlier failures remain preserved.

**Earlier repeatable acquisition, October 25, 2026, America/New_York — repeatable U1 pair:** the subsequent user-run **U1-read5.bin / U1-read6.bin** completed at **33,554,432 bytes each**, both SHA-256 **`4f6511d64b834935c4e7ba696dc6ed71494e08e5e36bda4cea7afbcce40ef760`**, **byte-identical**. Logs report **4m36s / 4m37s**, expected chip detection and done. Agent monitored only files/process state and verified bytes/hashes offline, without opening the programmer. Files/logs are user-owned mode 0600 under **`.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U1/20261025-182549-EDT-user-read-retry/`**; original earlier mismatched reads/failure logs remain unchanged. [Validation metadata](c8375-recovery/acquisition-evidence/20261025-U1-short-leads-matching-reads.json), generated [read5](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U1-short-leads-read5.log)/[read6](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U1-short-leads-read6.log) logs. Captures show nonuniform firmware-like data and different 16-MiB halves, but **neither equals the rehashed original 72fc3f…45107 or nonbooting 68c695…e88b reference**. Repeatability is established; signature authentication, complete exclusion of systematic errors, physical primary/golden role and restore-target choice are not. No firmware write or successful boot is claimed; separate OTP is not included. Shorter leads and changed clip seating/reconnections are combined variables, not proof that cable length alone caused prior failures.

The user also reported **unpowered adapter output 2/MISO→4/GND = OL**; no installed MISO-to-breakout value was supplied, and the user instead selected another full read retry. That pair now passes repeatability; do not insist on the earlier unperformed intermediate test or new clip photographs as a prerequisite to recording that fact.

**Next chip — U2 preparation:** USB-off/U2 board label/own pin-1 dot are confirmed. The user reports U2 rail **0 V DC**, internal **U2-10↔U2-2 = 976 Ω**, **U2-2↔U2-1 = 4,762 Ω**, and the same 4,762 Ω for U1-2↔U1-1. After clarifying that P1 means the board header, the requested cross-references are **U2-10→P1-2 = 0.2 Ω** and **U2-2→P1-1 = 0.2 Ω**. These support shared ground/VCC and allow P1 supply monitoring for U2. RW170 is the expected historical-photo marking, not separately retyped; U2/own dot are identified. The user is instructed to fit the existing harness to U2 only while all sources are disconnected, then check DC supply at P1-1/P1-2 under CH341A USB only, normal router power/console/cables and CR2032 removed. Unplug for VCC outside 1.7–2.0 V. **Loaded voltage was subsequently reported at 1.759 V; see the ID-only preparation checkpoint below.**

**U2 loaded harness / ID-only preparation, October 25, 2026, America/New_York:** the user reports the clip properly fitted to U2, **adapter output 4→P1-2 = 0.3 Ω**, **adapter output 8→P1-1 = 0.4 Ω**, and **P1-1→P1-2 = 1.759 V DC with CH341A USB connected**. These support the installed supply/ground paths and acceptable loaded voltage. The previously confirmed C8375-A/FDO2742M0FK router-power/console/other-cables disconnected and CR2032-removed setup continues. At the user’s request, a fresh private U2 identification-only command was prepared and copied to the clipboard: `sudo flashrom -V -p ch341a_spi -c MT25QU256 -o U2-identification.log`, guarded against overwriting the log in `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-190849-EDT-identification/`. This selects a candidate for probing; it does not force a match. Expected JEDEC is 20 BB 19 / 32768 KiB; **Initial U2 identification subsequently failed, 00/00; see the result below**, no U2 main-array read or firmware write selected. The agent only prepared files/clipboard and did not open the programmer. User terminal owns programmer control; keep the harness still and monitor DC VCC.

**U2 initial identification failed, October 25, 2026, America/New_York — R-01-U2-ID:** the user ran the logged sudo probe. CH341A revision 3.0.4/SPI initialized, but RDID byte 0 had a parity violation and returned **id1 0x00 / id2 0x00; no flash found**. The original log is preserved unchanged; [generated log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-initial-no-id.log) and [metadata](c8375-recovery/acquisition-evidence/20261025-U2-identification-no-id.json). No U2 full read or write ran. Prior loaded VCC was 1.759 V; the during-probe value was not separately supplied. Low-resistance power paths do not verify SPI contacts or establish a cause. The Darwin informational entitlement line also appeared during successful U1 access and does not by itself establish a permission failure. **Next, requested/planned:** unplug USB, reseat U2 clip once using its own pin-1 dot, reconnect only programmer USB and recheck 1.7–2.0 V DC before a fresh ID-only attempt. A guarded `U2-identification-reseat1.log` command in the same private folder is copied to the clipboard; it subsequently ran and returned 20/0000, as recorded below. Keep router power/console/other cables and CR2032 removed; user terminal owns programmer. Stop on another failed ID for targeted diagnosis rather than forcing detection or starting reads. Agent only handled files/clipboard, not hardware.

**U2 retry result, October 25, 2026, America/New_York — R-01-U2-ID:** the user ran `U2-identification-reseat1.log`; flashrom returned **id1 0x20 / id2 0x0000**, no flash found. Expected device bytes remain **0xBB19**. The first byte matches the expected Micron manufacturer byte, but this incomplete response does not establish chip model, reliable communication or a defective chip. Physical reseating and a new voltage value were requested but not separately confirmed in the pasted result. Original initial and retry logs are retained unchanged; [retry log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-reseat1-partial-id.log), [updated metadata](c8375-recovery/acquisition-evidence/20261025-U2-identification-no-id.json). No full U2 read/write or agent programmer access. **Next requested, not yet measured:** stop software probes, unplug USB, keep router power/cables/CR2032 removed and remove the clip from U2. In Ω mode measure active adapter **output 2→actual inside-jaw contact intended for U2 pin 8 (MISO)** and **output 6→jaw contact intended for U2 pin 16 (CLK)**. These verify complete cable paths including the ribbon with no under-clip chip access; breakout-only measurements are insufficient for this check. Await both values before another command. A low resistance would validate the measured harness path, not jaw-to-chip seating or powered signal integrity.

**U2 next step revised at user request, October 25, 2026, America/New_York:** the user declines removing the clip and is confident it is seated. The proposed off-board MISO/CLK jaw checks are **unperformed and superseded**, not prerequisites to further diagnosis. Leave the clip and all wires in place. With only CH341A USB connected and normal router power/cables/CR2032 removed, use **DC volts, black P1-2/GND**, red first at the mapped breakout terminal reaching **U2-3/RESET#**, then **U2-1/HOLD#**. Await both values; no new software probe, reset tie or jumper selected. These are accessible breakout measurements and do not independently establish jaw-to-chip contact. [Micron datasheet, Figure 6 / signal descriptions, pp. 12–14](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf): RESET# low resets/tri-states outputs; enabled HOLD# can pause serial communication. A seating fault has not been established by the failed IDs.

**U2 static control results, October 25, 2026, America/New_York — R-01-U2-ID:** with the clip left seated, the user reports **RESET# = 1.707 V DC** and **HOLD# = 1.77 V DC** under the requested breakout-to-P1-2/GND check. Both exceed the datasheet input-high minimum of 0.7 × prior VCC 1.759 V (about 1.231 V), supporting inactive/high controls **at the measured breakout points**. This does not prove actual package-leg contact or levels during SPI transfers; U2 remains unidentified (last 20/0000), with no full read or write. [Micron datasheet, Table 47 p.82 and signal descriptions pp.12–14](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). **Next requested, unperformed:** keep U2 clip seated, unplug CH341A USB, retain normal router power/cables and CR2032 removed, verify P1-1/P1-2 approximately zero DC voltage, then in Ω measure active adapter **output 1→bare U1 pin 7/CS#** and **output 2→bare U1 pin 8/MISO**. This targets possible inter-chip paths without removing U2 clip. If those U1 legs are blocked, report access rather than moving the clip. Await both values/access report; no further flashrom command selected. Shared select/data or contention is a hypothesis, not established; unpowered resistance cannot prove powered mux behavior. Agent has not accessed the programmer.

**Confirmed inter-chip resistance paths, October 25, 2026, America/New_York — R-01-U2-ID:** the user reports **U2 pin-7 mapped cable-end terminal→actual U1 pin 7 = 9,360 Ω**, and **U2 pin-8 mapped terminal→actual U1 pin 8 = 0.8 Ω**, then explicitly confirms both endpoints are the U2 clip cable end to actual bare U1 legs. These are the clarified endpoints, not adapter output numbers 7/8. USB unplugged was part of the confirmation question; the separate requested residual-voltage numeric value was not supplied. The low MISO path supports continuity through the installed U2 clip/harness to U1; CS has no measured low-resistance tie. This does not establish a specific pull-up arrangement, permanent hardwire/mux state or contention. Shared MISO alone is insufficient to diagnose interference. **Next requested, unperformed:** leave U2 clip/wires seated; DC volts, black P1-2/GND, only CH341A USB connected with router power/cables/CR2032 removed; measure **actual bare U1 pin 7/CS#** and **mapped U2 cable-end pin 7/CS#** to ground. Await both voltages before another probe. Idle readings do not establish select behavior during a transfer. [Micron signal descriptions, p.14](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf): high S# deselects and tri-states output; low S# enables the chip. No firmware read/write or agent programmer access occurred.

**Idle CS# results / driver-state qualification, October 25, 2026, America/New_York — R-01-U2-ID:** user reports **actual U1 pin 7 = 1.243 V DC**, and **adapter output 1 / U2 mapped clip-breakout pin 7 = 1.306 V DC**, relative to P1-2/GND under the requested USB-only idle setup. With the **earlier**, not yet contemporaneously rechecked, VCC 1.759 V, the 0.7 × VCC input-high minimum is 1.2313 V: nominal margins are about **12 mV / 75 mV**, before measurement uncertainty and transients. These readings do not prove a low/asserted CS#, reliable deselection or bus contention. [Micron Table 47, p.82](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf). A new primary-source check of [upstream flashrom v1.8.0 CH341A driver](https://raw.githubusercontent.com/flashrom/flashrom/v1.8.0/programmers/ch341a_spi.c) shows `ch341a_spi_shutdown()` calls `enable_pins(false)`: the CS latch is set high, then output-direction bits are disabled. Therefore post-exit voltages **do not measure actively driven CS# during a probe**. This is source inspection, not execution or proof of exact installed-build equivalence; no active waveform or new programmer operation. **Next requested:** leave U2 clip/wires seated; only programmer USB connected, router power/cables/CR2032 removed; DC volts black P1-2, red P1-1, report fresh VCC. Await that value before another command; no CS/reset jumper or voltage increase.

**Supply rechecked / fresh ID prepared, October 25, 2026, America/New_York — R-01-U2-ID:** user reports unchanged-harness **P1-1→P1-2 = 1.757 V DC**, within 1.7–2.0 V. This resolves the pending supply reading, not the cause of failed identification. Prior CS# levels are idle observations with CH341A outputs disabled after flashrom exit; no active waveform or contention is established. With U2 clip/wires left untouched, a fresh guarded user-terminal identification-only command is copied to the clipboard, saving `U2-identification-controls-checked.log` in the existing private U2 identification folder. It uses `sudo flashrom -V -p ch341a_spi -c MT25QU256`; no force, full main-array read or write. **The attempt subsequently succeeded with 20 BB 19 / Micron MT25QU256; see the acquisition preparation below.** The agent prepared files/clipboard only.

**U2 identification succeeds / full reads prepared, October 25, 2026, America/New_York — R-01-U2-ID / R-01:** the user’s fresh controls-checked sudo probe returns **JEDEC 20 BB 19**, **Micron MT25QU256, 32768 KiB**, **status 0x00**. The agent verifies these results from the saved log offline; [generated successful ID log](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U2-controls-checked-id-success.log), [updated ID history/metadata](c8375-recovery/acquisition-evidence/20261025-U2-identification-no-id.json). Earlier 00/0000 and 20/0000 failures remain unchanged. The identified interface responds in this attempt; intermittent-cause, array accuracy and physical bank role remain unresolved. **Two full main-array reads are prepared, not yet completed/verified**, in private mode-0700 `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U2/20261025-194109-EDT-full-reads/`: `U2-read1.bin`, `U2-read2.bin`, separate logs. A file-guarded sequential `sudo flashrom -p ch341a_spi -c MT25QU256 -r … -o …` command is copied to the clipboard and offered to run immediately; read2 follows only successful read1, then ownership/mode-0600 cleanup. Expected size is **33,554,432 bytes each**, roughly 4–5 minutes each from U1 experience. User owns programmer control; agent only prepared files/clipboard and may inspect file/process metadata. Leave U2 clip/wires unchanged, keep router power/console/cables and CR2032 removed, monitor P1-1/P1-2 in DC volts under programmer USB only, unplug if outside 1.7–2.0 V. No force, erase/write or protection operation; separate OTP is excluded. On completion compare sizes/hashes/bytes and references privately before target selection.

**U1 accuracy caution:** further offline comparison shows payload 0x00000000–0x00FCFFFF is a bitwise subset of the saved original: **3,668,640 byte positions lose original one bits and none add one bits**. The readout is not an exact AND/OR of the two known reference images. This is a verified data relationship, not a proven hardware/software/flash cause; repeatability alone does not establish raw-byte accuracy, authentication or bank role. Keep both chips read-only and obtain U2 comparison before selecting any restore target. Original dump bytes were not changed and no derived restore image was created. The direct-pin replacement remains expected October 26.

**Earlier result — user sudo ID gate failed, October 25, 2026, America/New_York (superseded by matching pair above):** the clean gated command executed under sudo and initialized CH341A/SPI but returned **0x00 / 0x00**, RDID byte-0 parity violation, no chip. [Preserved log counterpart](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U1-clean-restart-sudo-no-id.log); full details in [failure metadata](c8375-recovery/acquisition-evidence/20261025-U1-short-leads-no-id.json). Local inspection verifies **no read3/read4 dump or read logs**, so neither full capture started. Sudo authentication/file guards did not cause this stop; the exact chip-communication cause remains unresolved. Original mismatched read1/read2 and all failed logs are retained. **Unplug USB.** Next requested single check, with router power/console/cables and CR2032 removed, target residual DC ≈0 V and meter in Ω, is **active 1.8 V adapter output 2/MISO to output 4/GND**, harness intact. Await its value/units/OL before selecting another probe or wiring change. Do not force detection, raise voltage, modify reset/protection/OTP or write firmware. No further agent programmer operation has run.

**Earlier restart result, October 25, 2026, America/New_York:** the user's read3 command failed identification with **zero ID bytes**, so no read3/read4 dump files were created and the `&&` chain did not run read4. The user clarifies an unplugged first attempt, a failed second after reconnecting, and current USB connected/target **about 1.75 V**/no read running. Exact timing relative to the saved log is uncertain; preserve this clarification. The agent verified absent dump files (old binary guards would pass), preserved the failure log, created fresh private **`20261025-172636-EDT-clean-restart/`** beside the earlier acquisition folders, and ran one non-root ID-only probe. It also returned **0x00 / 0x00** with a USB detach access warning; **sudo -n** then required an interactive password and did not reach flashrom. No full agent read ran. Earlier original read1/read2 dumps remain intact and mismatched.

The user now owns programmer control: a **fresh sudo identification-gated two-full-read command** is copied to the clipboard and has been explicitly offered to run immediately in VS Code. It guards existing log/dump names; a successful root ID is required before either capture. Agent hardware access has ended, so do not run a competing probe while that chain is active. Keep clip/wires still and monitor target VCC in DC mode; normal router power/console/cables and CR2032 remain disconnected under the confirmed setup. Do not force detection, erase/write, change protection/OTP/reset or raise voltage. Preserve failed logs and any partial outputs, and use another fresh folder rather than overwriting. No new root-gate or full-read results are reported yet. See [failure/restart metadata](c8375-recovery/acquisition-evidence/20261025-U1-short-leads-no-id.json) and [wiring sheet](C8375-CH341A-HEADER-WIRING.md).

**Earlier update, October 25, 2026, America/New_York — full-read retry after clip adjustment:** the new shorter crimped leads (each individually reported 0.3 Ω) initially produced **about 0.5 V at P1-1/P1-2** with the original 35 cm ribbon clip. The final corrected assembled-path readings were **adapter 4→P1-2 = 0.3 Ω**, **adapter 8→P1-1 = 1,336 Ω**, and **P1-1↔P1-2 = 923 Ω**; earlier intervening reports were withdrawn. The planned A/B positive-path split was not performed/reported. The user instead reports slight clip movement restored target supply to **1.757 V DC with programmer USB connected**, and explicitly requests **two full captures again**. This supersedes the 0.5 V stop for a monitored read-only retry while supply stays in range. Keep the clip/wires still; unplug USB and all router power before any further adjustment. Clip-related contact is a likely contributor to the latest supply issue, but not an identified sole cause of the earlier read mismatch. New lead lengths are unspecified; both leads and clip seating changed, so improved captures would not isolate cable length alone.

A fresh private folder `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U1/20261025-171515-EDT-short-leads-clip-adjusted/` and guarded sequential **U1-read3.bin/U1-read4.bin** plus log command are prepared and copied to the clipboard. No new capture files/results exist yet and the agent has not accessed the programmer. Original read1/read2 files and comparison results are preserved. Keep normal router power/console/other cables and CR2032 disconnected, accepted 1.8 V adapter in circuit, and monitor **P1-1/VCC to P1-2/GND in DC volts** during both reads. Disconnect for VCC outside **1.7–2.0 V**, collapse or warming/unexpected router activity; unplug after completion/error. No force, erase/write, protection/OTP operation, reset jumper or voltage increase is selected. On completion inspect sizes, hashes, bytes and references privately before any bank assignment or restore. Separate U2 acquisition remains pending; the direct-pin replacement is still expected October 26, not received. See [the wiring sheet](C8375-CH341A-HEADER-WIRING.md) for full commands and earlier electrical observations.

**October 25, 2026, America/New_York — current bench update:** active physical target is **C8375-A / FDO2742M0FK / U1_CSPI**. The accepted CH341A/1.8 V adapter is connected through the full SOIC-16 clip and eight mapped Dupont wires. Normal router power/console/cables and CR2032 were confirmed removed; programmer USB disconnection is requested after each test and before wiring changes. The user corrected an intervening P2-2 typo to **P1-2/GND**. Prior loaded supply was **1.727 V**, and user now confirms it stayed around that value during both full reads. Earlier mapped RESET# breakout **0–0.001 V** is retained as unresolved: successful ID/status communication superseded the inference of continuous effective reset during the probe. No RESET# jumper/pull-up, voltage increase or firmware write is selected. Detailed earlier measurements and wiring are retained in [the wiring sheet](C8375-CH341A-HEADER-WIRING.md) and plan.

User-run **`sudo flashrom -V -p ch341a_spi -c MT25QU256`** identified **Micron MT25QU256, 32 MiB, JEDEC 20 BB 19, status 0x00**. Subsequently **both full reads completed but repeatability failed**. Local offline inspection confirms **33,554,432 bytes each**, SHA-256 **`6f82693674aa55c64176541d398b4d93c6ac06a9af227c4849ff6e21ded1fb43`** and **`73c2d10a76d799e37ef0237f7d607c7aa858b78a2ceb07dc0eaa4fff64b64606`**, and **2,989,540 differing byte positions**. Both original program logs report done and **4 min 37 sec**. Neither dump matches the rehashed original or nonbooting reference. Files are preserved unchanged, mode 0600, under `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U1/20261025-151243-EDT/`; dump contents were not printed/published. [Public validation metadata](c8375-recovery/acquisition-evidence/20261025-U1-full-read-validation.json) and generated [read 1](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U1-full-read1.log)/[read 2](sanitized-evidence/c8375-recovery/programmer-logs/20261025-U1-full-read2.log) logs preserve the result. Main-array reads exclude separate OTP. This is not a validated stable backup, a physical primary/golden assignment, or evidence that the chip is defective.

**Next hardware step — replacement clip expected October 26, 2026, America/New_York:** the user now reports ordering a clip with pins directly on its body, intended to remove the **35 cm ribbon** and leave only short Dupont wires. This is an expectation, not confirmed receipt/model/package fit or a successful read. The earlier path was approximately **55 cm** (35 cm ribbon plus 20 cm jumpers); shortening jumpers alone would still leave roughly 40–45 cm. Prefer testing the replacement design on arrival and keep the old clip/cable intact rather than modifying its ribbon. With all power disconnected, reconfirm the chassis/state, identify the new clip's contacts against physical U1 legs, confirm wide SOIC-16 fit, and use the same accepted 1.8 V adapter signal map with secure **5–10 cm Dupont leads** where practical; exact length matching is unnecessary. New contact numbers must not be assumed from the previous breakout.

After checking the new harness's power/ID setup, use the prepared **two 64-KiB samples at 0x006E0000–0x006EFFFF** before more long reads. Installed-v1.8.0 extraction syntax was already validated using a dummy programmer only. A small-region pass is preliminary; two fresh stable full U1 reads, credible content/reference checks, and separate U2 acquisition remain required before restoration. No replacement clip test or new programmer command has occurred, and cable-length causation remains unproven. Keep programmer USB and router power/console/cables disconnected before handling the clip, retain the CR2032 state, and do not raise voltage or add a reset jumper to overcome unreliable reads. The [wiring sheet](C8375-CH341A-HEADER-WIRING.md) has the prepared private diagnostic folder and detailed handoff.

- Original development firmware was backed up with **two independent, identical 32 MiB SPI reads** before the native firmware write. Verified copies now exist on both the Mac and USB.
- The Cisco-recommended **17.18(3r).s2.cp** payload was programmed to the command's **primary** target.
- The old native updater also wrote beyond the firmware payload and failed verification there. Those extra regions were restored from the original backup under diagnostic Linux, while the new firmware payload and current environment were retained.
- A complete **32 MiB device readback then exactly matched the intended assembled image**. This proves the bytes matched that image; it does not establish compatibility with this board or successful secure boot.
- After a soft restart and a user-confirmed cold power cycle, there was **no normal SCP, ROMMON, or IOS startup output**. Only brief power-transition noise appeared on serial.
- The user reported **blinking red STATUS, other LEDs solid green, and fans at maximum**. Cisco describes blinking red STATUS as a hardware-integrity failure indication. The exact failing boot stage and cause remain unknown.
- The user was asked to turn the router off and move **CISCO FILES** back to the Mac. The user confirmed the USB was connected, and files were copied and verified. Reconfirm the router's actual power state before physical work; there has been no later successful boot observation.
- **Console capture is stopped and the serial port is released to the user.** Do not claim a capture is still running or reclaim the console without checking the user's use of it.
- The next prepared recovery step is an **external-programmer restoration of the exact original flash**, after identifying the physical chip/bank and verifying the programmer, package, voltage, and wiring. This restoration has **not** yet been attempted or proven.

No TPM provisioning, fuse, secure-boot key, lifecycle, or manufacturing-state changes were attempted. No eMMC erase or factory reset was performed. We never issued an explicit `2/g` golden-ROM write, but the physical bank mapping is unconfirmed: **do not claim the golden bank is independently verified or untouched solely from the command selector or “Boot ROM1” label.**

## 2. User intent and scope

The user initially asked us to:

1. Read `C8235-G2-RECOVERY-CONTEXT.txt`, which concerns a **separate router**.
2. Copy the original extracted Cisco 8300/SoC2 ROMMON to the USB drive **CISCO FILES**.
3. Troubleshoot this second device, which failed to boot IOS XE 26.2.1, and investigate whether it is early development hardware or an ordinary C8375-E-G2.
4. Assess its approximately 8 GiB RAM and empty DDR5 slot before buying memory.

The user explicitly required **INSTALL mode**, later authorized flashing the recommended ROMMON, and then requested a full current-ROMMON backup and another upgrade attempt. They were open to experimental recovery because the devices might otherwise be scrap.

The user believes ROMMON caused the rapid, loud fan cycling. That connection was **not established**. An unsupported/unknown PSU indication also remained unresolved before the flash experiment.

The user said equipment ordered for the C8235 is arriving in the next few days. The exact purchased programmer kit has **not been verified**. Later discussion identified the previously proposed CH341A setup; do not treat a reviewed listing as a confirmed order.

**Keep the routers separate:** this device uses **SoC2 / Crestone** firmware. The C8235 uses **SoC1 / Arata**. No C8235 SoC1 or experimental hybrid image was flashed to this C8375.

## 3. Hardware and original firmware identification

| Item | Observed value |
|---|---|
| Reported PID / VID | `C8375-E-G2` / `V01` |
| Chassis serial | `FDO2742M0FK` |
| PCA serial | `FDO27380KFQ` |
| EBF board | `mirabile-crestone`, revision `r3` |
| Board version | `5` |
| SoC / SKU | CN10616 B0 / `MV-CN10616-B0-AAP` |
| Physical CPU cores reported by SCP | 16 |
| Original ROMMON | `SDK112308-UEFI-ROMMON-SoC2-v9.2.1-Release` |
| ROMMON classification / build | **DEVELOPMENT SOFTWARE**, September 21, 2023 |
| Original boot stub / EBF | September 22, 2023 / `11.23.08` |
| Original BL2 / BL31 | Marvell `11.23.08`, built September 21, 2023 |
| CPLD | `2408272B`, also shown as `2.B`, dated August 27, 2024 |
| EBF board serial | `unknown`; chassis/PCA cookies were nevertheless readable |
| ROMMON running-image label | `Boot ROM1` |
| SCP boot-source label | `SPI0.CS0 (Primary image0)` |
| Boot security state in old SCP output | `provisioning`; secure, non-encrypted boot |
| Linux SPI flash identification | `spi0.0`: `mt25qu256a`, 32 MiB |

“Boot ROM1” and “Primary image0” are different software labels. They do not establish the physical golden-bank mapping.

Development firmware, early board revision, unusual memory arrangement, and topology discrepancies suggest an early development unit. They **do not conclusively prove** the unit's production/prototype classification.

### Memory findings

- User explicitly answered that there is **only one DDR5 slot and it is empty**.
- Firmware initialized `DMC2: 8 GB/ch, 1Rx8, UDIMM, 32-bit data, 4-bit ECC`.
- Total detected DRAM: **8 GB DDR5 at 4800 MT/s**. IOS reported `8388608K` physical memory.
- Raw inventory described memory as `16GB,Cisco,Onboard Memory`. This descriptor conflicts with measured/detected capacity and is **not proof** that 16 GB is physically fitted or that half the memory failed.
- Production documentation lists a single 16 GB default DIMM and a 32 GB upgrade, but that does not establish the layout or generic UDIMM compatibility of this board.
- No RAM purchase, installation, or physical memory repair occurred. Hold off selecting a DIMM until the board layout and supported module are established.

### Other pre-flash observations

- `P0`: PSU `Unknown`, `incompatible`; PID/VID/serial were blank even in raw inventory.
- `P1`: empty.
- `P2`: `C8300-FAN-1R`, OK.
- User was asked for the installed PSU's visible label/part number; no answer is recorded.
- Temperatures and measured voltage rails were Normal. CPU approximately 34–36°C, inlet sensors 25–27°C, power 34–36 W, and chassis fan snapshots approximately 5,280–5,520 RPM.
- Filtered logs showed startup fan insertion and the missing PSU-bay alarm, without captured thermal/fan-failure alerts during the cycling investigation.
- Brief audible fan surges were not correlated with a large measured RPM change. Cisco documents approximately 60-second updates for the displayed environmental readings, so short changes could be missed.

## 4. Initial staging and preservation of existing files

The original SoC2 ROMMON set extracted from `c8kg2be-universalk9.26.02.01.SPA.bin` was copied to:

```text
/Volumes/CISCO FILES/C8375-E-G2-ROMMON-17.18-3r/
```

This folder contains the original `firmware_mirabile_soc2.pkg`, raw IOS-upgrade image, UEFI capsule, vendor MD5/SHA1 files, and supporting checksum/metadata files. Eight payload/metadata source files were verified against the extraction manifest. Finder also created `._` sidecar files; these are not firmware payloads.

Cisco's 26.2 compatibility table lists:

| Platform / IOS XE | Minimum ROMMON | Recommended ROMMON |
|---|---|---|
| C8375-E-G2 / 26.2.1 | `17.15(3.2r).s2.cp` | `17.18(3r).s2.cp` |

The image checks established extraction/copy integrity, not independent validation of every Cisco RSA signature or compatibility with this physical unit.

Existing internal files were preserved to `usb0:/C8375-ORIGINAL-BACKUPS/` before firmware programming:

| USB backup | Size | Verified source/USB MD5 |
|---|---:|---|
| `SDK112310-UEFI-SoC2-SB-v11.2.7_RSA4K.img` | 16,580,608 | `a8b9efb975c1213525fe33bd37dc871f` |
| `SDK112312-Prod-SoC2-v17.15.1_13d-cp-RSA2K.pkg` | 5,753,916 | `d947e04256c496a7d881c7baf1778ec8` |
| `original-development-ios.SSA.bin` | 1,000,259,196 | `e245f58d04438feb8bbbb08c9b7d409c` |

The development IOS source was `c8kg2be-universalk9.BLD_POLARIS_DEV_LATEST_20250204_002714.SSA.bin`. These preserved files were **pre-existing staged files, not dumps of the installed v9.2.1 ROMMON**. Neither staged ROMMON version was flashed today. They remain potential intermediate-version leads, not validated recovery choices.

## 5. Boot troubleshooting before firmware flashing

### 5.1 Original 26.2.1 failure: secondary CPU startup

Initial saved boot parameter:

```text
USER_BOOT_PARAM=maxcpus=24 failure_shell
```

The old ROMMON read the verified USB 26.2.1 image, printed integrity/signature-verification messages and `%ERROR% Booting an incompatible image for this platform`, but continued into Linux 6.6.95.

At secondary CPU startup it halted with `Unhandled Exception in EL3`, including `elr_el3=0xB5F08C`, `esr_el3=0xBE000011`, and `x19=x20=0x10`. No IOS prompt was reached. A historical October 22 capture of IOS 17.15.6 showed the same Crestone revision and EL3 failure with `maxcpus=24`; that capture was copied into this task for comparison.

### 5.2 Temporary single-CPU diagnostic

After a power cycle, a temporary, unsaved parameter was tested:

```text
maxcpus=1 failure_shell
```

It bypassed the EL3 startup fault and eventually reached IOS. The console was quiet for a significant interval after UART handoff. The assistant initially proposed another power cycle too soon; the user correctly pointed out slowed fans and green LEDs. We waited instead, and IOS output appeared. **A quiet console alone was not proof of a hang.**

However, the one-CPU boot did not provide a healthy forwarding plane: `qfp_ucode_mirabile` failed with `rc134`, and forwarding/module processes went offline.

At about 234 seconds, Linux panicked in `edac-poller` / `octeontx_edac_device_wq`:

```text
octeontx_edac_wq_handler+0xbc/0x2b0
__memcpy_fromio+0x50/0x98
```

The fault involved a firmware RAS-ring read beyond mapped memory, with uninitialized-looking `A5A5` fields. A driver/old-firmware record-layout incompatibility was suspected, not proven as the sole cause.

The crash dump completed in approximately 157 seconds, then the router automatically rebooted. The compressed core was about **1,749,903,412 bytes**, named `kernel.rp_RP-MIRABILE_0_19700101000010.core.gz`, with a corresponding text file. The unsaved single-CPU setting did not persist.

### 5.3 Sixteen CPUs and console-path diagnosis

Tested temporarily:

```text
maxcpus=16 failure_shell keep_bootcon
```

All CPU0–15 activated. F0 and the built-in network module became operational. This strongly implicated attempted activation of nonexistent/unsupported core16+ entries under the old 24-entry topology in the earlier EL3 fault, although the exact firmware defect was not independently established.

The native USB console later stopped responding while Linux heartbeats continued and fans/LEDs suggested operation. Reconnecting native USB and sending XON did not restore the prompt. The user swapped to the FTDI USB-to-RJ45 cable and unplugged native USB; the RJ45 prompt responded immediately without a router reboot. At that point the silence was a console-path problem, not a total system hang.

### 5.4 Sixteen CPUs alone did not fix EDAC

After saving `maxcpus=16 failure_shell` without `keep_bootcon`, an internal 26.2.1 boot panicked at approximately **53.3 seconds** in the same EDAC read path, this time on CPU10. Therefore the CPU limit did not solve the EDAC problem.

A second compressed core, approximately **2,325,885,277 bytes**, was saved in about 166 seconds as `kernel.rp_RP-MIRABILE_0_19700101000007.core.gz`. Both large dumps remained on internal storage; no cleanup was performed.

With automatic boot enabled before a BOOT target had been set, ROMMON fell back to the existing February 2025 development IOS. That image reached IOS with 16 CPUs and F0 online; its version was `17.18.20250204:011211`. We then returned to controlled manual ROMMON boot. A serial BREAK sent during image verification did not abort that load.

### 5.5 EDAC initialization workaround

The original 26.2.1 kernel was inspected offline. It contains `octeontx_edac_init` and supports Linux `initcall_blacklist`. A Marvell-authored driver patch corroborated the initialization/workqueue names.

Tested and later persisted:

```text
maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init
```

The kernel explicitly logged `blacklisting initcall octeontx_edac_init`. IOS and the forwarding/module processes started without the previous early EDAC panic.

**This disabled an OS error-reporting driver. It did not repair memory or prove hardware fault-free.** Early firmware separately reported MDC double-bit ECC rows `0x33e` and `0xe64`, and a later single-bit row `0xee9`, all Chain1/Hub8/Node0. The physical component has not been mapped; these reports cannot automatically be assigned to the empty DIMM slot.

ChipGuard CPU UUID validation also continued to fail in the development ROMMON, but the old firmware proceeded to boot. Its keys/state were not modified.

## 6. IOS XE 26.2.1 installation and successful tests

The 26.2.1 installer image was copied from USB to internal bootflash and verified:

```text
Size:   1,048,008,916 bytes
SHA256: 0842a7210a2a0933f0a823bbe71c5ba2109f276ee49635a59ba0a26f17f0f456
MD5:    f25a1154427adbbad4a1993e0969d08c
```

At the user's direction, the final configuration was converted to **INSTALL mode**:

```text
install add file bootflash:c8kg2be-universalk9.26.02.01.SPA.bin activate commit
```

Add, Activate, postcheck, and Commit passed. The installer saved configuration and reloaded. The original startup configuration had already been backed up. `packages.conf` was 8,405 bytes, with 14 expanded package files observed.

After saving the tested boot workaround and automatic boot register, an unattended reset loaded `bootflash:packages.conf` without a manual boot command. Verification showed:

```text
System image file is "bootflash:packages.conf"
IMG C 26.02.01.0.263
Auto abort timer: inactive
```

The install summary alone was not treated as proof of install mode; the system-image path and automatic boot were also checked.

### Physical two-port test

The user connected a spare patch cable between **data ports 0/0/0 and 0/0/1**. Temporary separate VRFs forced traffic through the physical ports:

- `RECOVERY-A`, `TwoGigabitEthernet0/0/0`, `198.18.83.1/30`.
- `RECOVERY-B`, `TwoGigabitEthernet0/0/1`, `198.18.83.2/30`.
- Both negotiated **2500 Mbps full duplex**.
- ARP resolved the opposite physical MACs, `e80a.b995.77a0` and `.77a1`.
- Initial short ping: 4/5, likely initial ARP resolution; this explanation was an inference.
- Longer test: **1000/1000 successful 1500-byte pings in each direction**, RTT min/average/max **1/1/4 ms**.
- After counters refreshed: each port had 2015 RX and 2015 TX packets, 3,031,756 bytes each direction, zero CRC/input/output errors and zero drops.

This proved physical two-port packet exchange, **not rated transit throughput**. All test IPs, VRF associations, and RECOVERY-A/B VRFs were removed. Both ports were verified back to their original `no ip address` / `negotiation auto` configuration. Test configuration was not saved. The user was told the loop cable could be removed.

The control processor reported Healthy, all 16 CPUs were present, RAM use approximately 57–58% of 7,904,544 KB, and temperatures/rails were Normal. No long burn-in, full DRAM test, all-port/module test, or rated forwarding benchmark was completed.

## 7. Fan cycling, reboot checks, and console handoff

When the user asked whether the router had rebooted, console checks showed uptime increasing from approximately 6 to 10 and then 14 minutes, with last reload reason still `Image Install`. There was no new reboot evidence at those checks. Fan noise alone was not counted as a reset.

The user later reported repeated loud fan ramps. Environmental readings, logs, and platform status were checked; readings were Normal, while the PSU remained unidentified/incompatible. The source of the audible noise—main chassis versus PSU fan—and its exact cycle period were not resolved.

The user requested console access. The bridge was closed and capture stopped. The user configured SSH and returned the console. The actual resulting hostname was **`CAT3875-G2`**; preserve that spelling rather than silently “correcting” it in evidence.

The assistant did not create a username, login password, or enable password. Existing credentials were not printed. Before further maintenance:

| Backup | Size | Meaning |
|---|---:|---|
| `original-startup-config.txt` | 2,436 bytes | Original startup before installer changes |
| `pre-rommon-current-running-20261023.txt` | 6,984 bytes | Running configuration after the user's SSH setup |
| `pre-rommon-startup-20261023.txt` | 3,209 bytes | Startup before saving that current running configuration |

The current running configuration was then successfully copied to startup to preserve the user's changes. These config files may contain credentials. **Do not print or publish their contents.**

## 8. First ROMMON upgrade attempt — packaged secure update failed

`show rom-monitor R0` confirmed the original v9.2.1 development ROMMON. The user's reference to “16.2.1” was interpreted as **26.2.1**, the image actually installed.

The raw SoC2 image was copied to `bootflash:rommon-17.18-3r-soc2.bin`; MD5 matched the vendor/local value `82c750449cd0ed8609296f2e89ef6ddf`. IOS rejected this raw form:

```text
File bootflash:rommon-17.18-3r-soc2.bin is corrupt or is not a valid package.
```

The exact embedded package was then copied as `bootflash:rommon-17.18-3r-soc2.pkg`, MD5 `a0856bd81efaa8f2f08e8cec2f2e8b55`, and accepted by:

```text
upgrade rom-monitor filename bootflash:rommon-17.18-3r-soc2.pkg all
```

IOS reported a single ROMMON, Booted/Selected1, and that secure upgrading would occur after reload. It copied ROMMON environment/key-area data, switched to ROM0 while updating/verifying environment data, switched back to ROM1, and printed “ROMMON upgrade complete.” **That message represented staging, not a successfully installed new ROMMON.**

After reload, the old firmware detected the secure upgrade request and identified target `v17.18(3r).s2.cp`, then failed:

```text
%ERROR: Locate BIOS protection protocol failed
StartImage returned 8
Unable to start package Status = 8
%ERROR% Failed to launch upgrade
Continuing with current ROMMON version ...
```

IOS returned in install mode, F0 and the network module became online, and `show rom-monitor R0` still showed the original development firmware. `bootflash:EFI/UpdateCapsule/` did not exist when checked afterward. No manual capsule cleanup was performed.

The missing BIOS-protection interface suggested an incompatibility with the old development firmware. No exact public Cisco fix was found; this was not established as the only issue with the board.

## 9. Full current-ROMMON backup through temporary diagnostic Linux

The user specifically requested a true current-ROMMON backup before another attempt. A normal IOS system-shell request returned:

```text
% Please secure authentication via request consent-token
```

No consent token, development key, fuse, or security-state change was made. Instead, we used a temporary boot of the original installed IOS initramfs into its Linux shell.

### Console lessons and temporary boot parameters

The first diagnostic boot used `rdinit=/bin/sh` with the existing parameters, but its shell was inaccessible on the RJ45 console. Default kernel console was `ttyAMA1`, the disconnected native USB path. A user power cycle returned normal IOS because the diagnostic parameter was unsaved.

For the corrected boot, we entered manual ROMMON through IOS `config-register 0x1820` and reload. A late `B` keystroke once buffered into the ROMMON command line and produced an invalid `Bset`; it did not enter an EBF menu or modify firmware.

ROMMON rejected a 160-byte command line as too large; a 122-byte command was accepted. The successful **temporary, unsaved** diagnostic command was:

```text
set USER_BOOT_PARAM "maxcpus=1 rdinit=/bin/sh -c mount${IFS}-tdevtmpfs${IFS}none${IFS}/dev;sh</dev/ttyAMA0&>/dev/ttyAMA0"
boot bootflash:packages.conf
```

Do not append `failure_shell` to this diagnostic form: bare unrecognized kernel arguments can become shell arguments. The normal EDAC blacklist was not present in this shortened diagnostic form; polling was later deferred through RAM-only sysfs settings before extended repair work.

Opening `ttyAMA0` reset the RJ45 UART to **9600 baud**, producing NULs at the Mac's 115200 setting. The bridge was enhanced to accept an initial baud argument and a JSON baud-change action. Opening at 9600 produced `sh-5.0#`; `stty 115200` on the router followed by changing the bridge back to 115200 restored readable interaction. This avoided another unnecessary physical power cycle.

The original initrd was inspected offline from gzip offset `38665384` in the original 26.2.1 image. It contained bash, BusyBox, `dd`, `mount`, and the needed libraries. Kernel configuration showed built-in MTD SPI NOR, Cadence XSPI, USB storage/XHCI, and VFAT support.

### Read-only device identification and backup

After mounting devtmpfs, `/proc`, and `/sys`, the layout was:

```text
dev:    size      erasesize  name
mtd0:   02000000  00001000   "spi0.0"
mtd1:   00400000  00001000   "spi0.1"
```

`mtd0` was **33,554,432 bytes**, erase size 4096. `mtd1` was **not read or programmed**; it was not established as a golden-ROM bank and may represent another device. Prior C8235 mapping must not be assumed to apply here.

`blkid` identified USB `/dev/sda1`, VFAT, label `CISCO FILES`, UUID `4480-1609`. It was mounted at `/mnt/usb`. Two independent reads were made:

```sh
dd if=/dev/mtd0 of=/mnt/usb/C8375-SPI-BACKUP-20261023/current-spi0-cs0-32MiB-read1.bin bs=65536
dd if=/dev/mtd0 of=/mnt/usb/C8375-SPI-BACKUP-20261023/current-spi0-cs0-32MiB-read2.bin bs=65536
```

Each read returned 512 complete records / 33,554,432 bytes in about 11.46 seconds. Both SHA-256 hashes matched:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

Additional metadata saved to USB included `/proc/mtd`, diagnostic command line, `dmesg`, and the 98,073-byte runtime DTB from `/sys/firmware/fdt`. The USB was synced and cleanly unmounted before rebooting to ROMMON. These were the first actual complete flash backups of this router, distinct from earlier copies of staged firmware files.

## 10. Native primary ROMMON programming — CRC failure

Before programming, normal boot settings were restored and synced:

```text
set USER_BOOT_PARAM "maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init"
confreg 0x1822
sync
```

The raw SoC2 file on USB was reverified:

```text
File:   mirabile_soc2_uefi64_rel_ios_upgrade_SPA.bin
Size:   16,580,608 bytes = 0xFD0000
SHA256: cfcf1ae38c2886e9d28138d3428636c2c8345b903bbef522f8e9ebfb363ff985
```

ROMMON help documented `1/p` for primary and `2/g` for golden. The user-authorized native write was:

```text
flashmon usb0:/C8375-E-G2-ROMMON-17.18-3r/mirabile_soc2_uefi64_rel_ios_upgrade_SPA.bin 1
```

The warning was confirmed with `y`. No interrupt/reset was sent during programming. The updater printed protection claims for:

```text
monitor environment: 0x01F30000 - 0x01F4FFFF
manufacturing data:  0x00FD0000 - 0x0002FFFF
uncovered area:      0x00FD0000 - 0x01FFEFFF
```

The manufacturing endpoint above is nonsensical/backward **as printed**. Do not silently turn that printout into a verified physical map.

Actual reported programming ranges were:

| Range, inclusive | Observation |
|---|---|
| `0x00000000–0x00FCFFFF` | Programmed, then verified OK; exactly the payload span |
| `0x01001000–0x01F2FFFF` | Programmed beyond payload, then verification failed |
| `0x01F50000–0x01FFFFFF` | Programmed beyond payload; final state assessed by readback later |

The operation ended with:

```text
spi: failed to program BIOS firmware (CRC Error)
monitor: failed to burn BIOS!
```

**We did not reset at this point.** The original ROMMON was still running from RAM, so we booted diagnostic Linux directly through that running firmware to inspect and repair the result.

## 11. Readback, repair of extra writes, and complete verification

The same temporary one-CPU shell was used, again recovering UART9600 →115200 without a reset. A complete post-write flash dump was saved as `after-native-flash-crc-failure.bin`.

Comparisons established:

1. The first **253 ×65536 bytes** exactly matched the original Cisco SoC2 payload hash `cfcf…f985`.
2. The observed preserved span **`0xFD0000–0x1000FFF`** matched the original backup.
3. The two upper ranges programmed beyond payload end differed from the original backup.

For longer diagnostic work, polling was deferred in this Linux session only:

```sh
for f in /sys/devices/system/edac/cpu/poll_msec /sys/devices/system/edac/mdc/poll_msec /sys/devices/system/edac/llc/poll_msec; do
    echo 600000 > "$f"
    cat "$f"
done
```

All three read back `600000`. We did not unbind the EDAC drivers because the remove-handler safety was not established. This polling change was in RAM and did not provision or alter firmware security state.

Internal eMMC `/dev/mmcblk0p1` was mounted **read-only, `noload`**, at `/mnt/bootflash`. The installed mono package was mounted **read-only squashfs, loop, offset4096**, at `/mnt/mono` to use its native ARM `flash_erase` utility. No internal eMMC files were erased or modified in this diagnostic repair.

An expected full image was assembled in `/tmp/expected-spi.bin`:

1. Start with the exact original 32 MiB backup.
2. Overlay the exact new Cisco payload at offset0, length `0xFD0000`.
3. Retain the **current** post-write environment at `0x1F30000–0x1F4FFFF` (128 KiB), because known boot settings had legitimately changed after the original capture.

That assembled image was also saved to USB as `candidate-17.18-3r-with-preserved-data.bin`.

The following are **historical repair commands, not instructions to run against an unidentified chip or the currently nonbooting device**. They restored only the extra upper areas from the expected RAM image:

```sh
/mnt/mono/usr/sbin/flash_erase -q /dev/mtd0 0x1001000 3887 && dd if=/tmp/expected-spi.bin of=/dev/mtd0 bs=4096 skip=4097 seek=4097 count=3887 conv=notrunc
/mnt/mono/usr/sbin/flash_erase -q /dev/mtd0 0x1f50000 176 && dd if=/tmp/expected-spi.bin of=/dev/mtd0 bs=4096 skip=8016 seek=8016 count=176 conv=notrunc
```

The first wrote 15,921,152 bytes; the second wrote 720,896 bytes, without reported errors. These repair commands did not write the new payload, manufacturing gap, or environment span.

A complete new **device readback**, `verified-17.18-3r-readback.bin`, then matched the expected full image exactly:

```text
68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b
```

All filesystems were synced and unmounted cleanly before `busybox reboot -f`.

## 12. Boot failure after the verified programming

The soft reset produced no normal startup output. A cold power cycle was requested to reset the flash hardware state as well as the processor; the user confirmed it was back on. No normal startup banner appeared after that either.

At the later cold boot the user reported blinking red status and maximum fans. A brief check at 9600 baud with Enter gave no prompt; 115200 was restored. There was no confirmed post-flash SSH reachability or new IOS uptime. The SSH IP was requested but not provided. A targeted Mac ARP lookup for the known MAC prefix found no entry; that alone is not proof of a network failure.

We therefore recorded **a failed boot after the firmware experiment**, not a successful upgrade. Repeated power cycles without new evidence were not prescribed. The router was to remain off pending recovery preparation.

### Offline checks after USB returned to Mac

All captured `.bin` files were copied to the Mac and source/destination SHA-256 hashes matched. The original two dumps still matched each other. Offline comparison confirmed:

- The programmed payload exactly equals the original extracted Cisco raw image.
- Outside the payload, only the specifically retained environment differs from the original backup.
- The first **64 KiB is all `FF` in both original and programmed images**; that is not evidence that an original populated header was accidentally erased.
- Old and new TIM/header structures differ. At `0x10000` and `0x20000`, the old total-minus-length-field difference was `0x114`; the new difference was `0x214`, and header word9 changed from0 to`0x402`.

These header/signing differences are a lead for compatibility investigation, **not proof of an RSA-key/fuse mismatch or a specific secure-boot failure**. No fuse values or required provisioning state were determined. A full readback matching our expected image does not establish that every firmware component is compatible with this early board.

## 13. Exact restore artifacts and hashes

### Original restore image — use this set for planning restoration

Mac directory:

```text
/Users/games/Documents/SOFTWARE/c8375-recovery/restore-original-20261023/
```

USB directory, last confirmed mounted on the Mac:

```text
/Volumes/CISCO FILES/C8375-RESTORE-ORIGINAL-20261023/
```

Contents:

```text
C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin
SHA256SUMS.txt
RESTORE-NOTES.txt
```

The `.bin` is an **unmodified exact original full-chip read**, 33,554,432 bytes:

```text
72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

It is not a ROMMON upgrade package and must not be passed blindly to `flashmon`. It may contain unique device data and must remain private. External restoration is not yet tested. The captured original environment selected manual boot (`0x1820`), so restored firmware may stop at ROMMON and need the known working automatic settings re-established.

### Raw capture and comparison directory

Mac: `c8375-recovery/spi-backups-20261023/`  
USB: `C8375-SPI-BACKUP-20261023/`

| File | Bytes | SHA-256 |
|---|---:|---|
| `current-spi0-cs0-32MiB-read1.bin` | 33,554,432 | `72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107` |
| `current-spi0-cs0-32MiB-read2.bin` | 33,554,432 | `72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107` |
| `after-native-flash-crc-failure.bin` | 33,554,432 | `117ac567acd7dd08826d5af717dea9afdf2965099e03fb5119fa851beb73c2ca` |
| `candidate-17.18-3r-with-preserved-data.bin` | 33,554,432 | `68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b` |
| `verified-17.18-3r-readback.bin` | 33,554,432 | `68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b` |

The candidate/readback images are the **new, nonbooting firmware state**, not the originals to restore next.

Supporting files include:

- `SHA256SUMS.txt`, `verified-17.18-3r-SHA256SUMS.txt`.
- `README.txt`, `programming-and-repair-notes.txt`.
- `mtd-layout.txt`, `diagnostic-boot-command-line.txt`, `diagnostic-dmesg.txt`, `original-runtime.dtb`.
- `offline-comparison.json` and `tim-header-comparison.txt`, generated on the Mac after the copy.

The local staged-firmware and config copies are in `c8375-recovery/original-staged-firmware/`. The 1 GB development IOS backup remains on USB/internal storage; this session did not copy that entire file into this local directory.

Local raw backup directories and binary/config copies were given restrictive permissions. A `shutil.copy2` attempt to the FAT USB failed while copying unsupported file flags after data copying; the restore set was recopied using `copyfile`, then its USB hash was verified. Do not interpret that resolved metadata-copy error as a corrupt restore image.

## 14. Known working boot settings for after original restoration

These were proven with the **original development ROMMON** earlier today. They do not mean the current flashed firmware can execute:

```text
USER_BOOT_PARAM=maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init
BOOT=bootflash:packages.conf,12;
Configuration register: 0x1822
Console: 115200, 8N1, no flow control
```

ROMMON command syntax, if a working ROMMON prompt is regained:

```text
set USER_BOOT_PARAM "maxcpus=16 failure_shell initcall_blacklist=octeontx_edac_init"
confreg 0x1822
sync
```

Verify the BOOT target and environment before reset. `0x1820` selects manual ROMMON boot; `0x1822` selected automatic boot while preserving the verified 115200 console setting. Do not substitute `0x2102` without checking baud and other register bits.

## 15. External programmer discussion and outstanding hardware checks

The previously discussed C8235 setup was a **CH341A USB SPI programmer**, a genuine **1.8 V power and signal-level adapter**, and a **SOIC-16 clip/breakout**. Reviewed examples were an ACEIRMC CH341A kit (`B07V2M5MVH`) and the separate `SOP16 Clip+Cable+Adapter Board` option (`B07WCB2PZ2`). These were earlier proposals; exact ordered/delivered hardware remains unconfirmed.

The **C8235** board photos identified Micron `RW170` / `MT25QU256ABA8ESF-0SIT`, 1.8 V, SOIC-16. Subsequent C8375 photo inspection on October 23 identified two matching Micron `RW170` SOIC-16 chips: **U2_CSPI (left) and U1_CSPI (right), as oriented in IMG_1260**. They are above the large Microsemi SmartFusion2 device and beside headers P1_CSPI/P2_CSPI. The retained official Micron decoder maps `RW170` to `MT25QU256ABA8ESF-0SIT` (256 Mbit / 32 MiB, 1.8 V). This matches the previously detected `mt25qu256a` family. **Physical primary/golden bank mapping is still unconfirmed. Do not apply the C8235's U2900/U2901 labels or assume the adjacent headers' pinout.**

The C8375 source photo, an inspection crop of this pair, and a copy of the previously retained official Micron decoder response are saved in `c8375-recovery/board-photos/`. Earlier photo candidates were ruled out: the part beside the large processor heatsink was a TI TMP400 temperature sensor; the apparent “HIC” device was a PI7C9X2G304SV PCIe switch with a small EEPROM beside it. Exact ordered programmer hardware remains unconfirmed. No programmer connection, flash read/write, or header probing occurred during this photo identification.

Prepared next steps, not completed actions:

1. Confirm the physical flash chip, package, pin1 orientation, and bank mapping.
2. Confirm programmer/software support for the full 32 MiB chip and correct power **and signal** voltage. Do not connect a generic 3.3/5 V clip setup to a 1.8 V part.
3. With router power, console, and USB disconnected, establish the correct wiring and attempt reads. In-circuit access may work; board interference may require isolation or chip removal.
4. Preserve two matching reads from the programmer before writing, and compare them with the captured images to establish the correct target.
5. Restore the exact original image, verify a full readback, disconnect the programmer, and test booting.
6. If original boot is recovered, reassess the pre-existing intermediate firmware files and fan/PSU issue before any new release-ROMMON experiment.

No programmer attachment, voltage test, new harness mapping, chip removal, soldering, or external flash operation was performed today on this C8375. Hardware restoration is a prepared path, not a guaranteed result.

The original IOS install and saved SSH configuration are on internal eMMC. The prepared restore targets SPI boot firmware; it is not an eMMC wipe or factory reset.

## 16. Console tooling and current ownership

Current known cable/port:

```text
/dev/cu.usbserial-AL00F7EQ
115200 baud, 8 data bits, no parity, 1 stop bit, no flow control
```

Original native USB console port was `/dev/cu.usbmodem4101`. The active path was changed to RJ45 during troubleshooting. Present macOS device names must be rechecked after unplug/replug.

Bridge: `c8375-recovery/rj45_serial_console.py`. It now accepts an optional initial baud argument and newline-delimited JSON actions:

```json
{"send":"show platform\r"}
{"baud":9600}
{"baud":115200}
{"break":true}
{"close":true}
{"expect_send":{"pattern":"rommon 1 > ","send":"set\r"}}
```

There is no break-on-pattern feature. Wait for a prompt before issuing the next dependent command, especially slow ROMMON directory listings. Do not open the same port simultaneously in SecureCRT and the bridge.

Session IDs are historical, not reusable promises: initial native18135, reconnect96722, RJ4573906, reconnect34548, resumed62070, baud-adjustable27665. **The last bridge session27665 was closed cleanly. Capture is stopped and the user has console access.** The final user question about console access was answered with the port/settings and this released state.

## 17. Evidence and previous notes

Important console captures under `c8375-recovery/console-logs/`:

| Capture | Main coverage |
|---|---|
| `20261023-100652-console.log` | Initial native USB boot, identity, CPU/EDAC failures |
| `20261023-102849-console.log` | Native USB reconnect during silence |
| `20261023-103319-console.log` | Working RJ45 session, backups, install and packet tests |
| `20261023-111440-console.log` | Fan checks and first packaged ROMMON attempt |
| `20261023-151731-console.log` | Return from user SSH configuration, early diagnostic attempts |
| `20261023-153046-console.log` | Accessible diagnostic shell, complete SPI backup, native write, repair, verified readback, later silence |

`20261023-111437-console.log` is a short open/close artifact. Readable derivatives of some earlier captures are present. Use raw logs as primary console evidence; readable copies may predate the last appended raw output.

Other useful evidence:

- `c8375-recovery/rommon-upgrade-failure-20261023.txt`: secure-updater BIOS-protection error.
- `c8375-recovery/native-flash-failure-20261023.txt`: native programming/verification failure, with exact printed ranges.
- `c8375-recovery/kernel-edac-symbols.txt` and `mdc-register-header-excerpt.txt`.
- `c8375-recovery/historical-17.15.6-boot-2026-10-22.log`: prior-day comparison, not a new test today.
- `c8375-recovery/usb-staging-notes.txt`, `usb-staging-SHA256SUMS.txt`, `usb-backup-MD5SUMS.txt`.
- `c8375-recovery/initrd-evidence/` and `upgrade-script-evidence/`: extracted original kernel/initrd/script evidence.
- `C8375-E-G2-RECOVERY-CONTEXT.txt`: preceding condensed handoff.
- `c8375-recovery/context-history-through-20261023-rommon-attempt.txt`: longer accumulated chronology, including intermediate states.
- `c8375-recovery/RECOVERY-CONTEXT.txt`: earlier chronological notes; statements such as “no flash performed” apply to their historical point, not the end of today.

## 18. Sources consulted during today's work

- [Cisco 8000 Secure Routers, IOS XE 26.2.x release notes](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/cisco-8000-series-secure-routers-release-26-2-x.html): ROMMON matrix and packaged-upgrade procedure.
- [Cisco 8300 hardware overview](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/hardware_installation-guide/secure-8300-series-hig/m-overview.pdf): hardware and LED meanings.
- [Cisco environmental monitoring guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_01100.html): sensor reports and update intervals.
- [Marvell-authored OcteonTX2/CN10K EDAC driver patch](https://lists.openwall.net/linux-kernel/2024/07/31/710): driver initialization, workqueue, and removal behavior.
- [Linux 6.6 kernel parameters](https://www.kernel.org/doc/html/v6.6/admin-guide/kernel-parameters.html), [serial-console behavior](https://www.kernel.org/doc/html/v6.6/admin-guide/serial-console.html), and `init/main.c` from Linuxv6.6: diagnostic boot and init-argument behavior.
- [Cisco console/reset-button guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_0110.html): the documented `golden.bin` recovery is IOS/config recovery, **not proof of a method to select a golden SPI firmware bank**.
- [Micron MT25QU256ABA8ESF-0SIT part specifications](https://www.micron.com/products/storage/nor-flash/serial-nor/part-catalog/part-detail/mt25qu256aba8esf-0sit): 1.8 V part family; the C8375's exact physical part still needs confirmation.

## 19. Resume rules

- Start from **nonbooting device with original backup available**, not the earlier healthy IOS state.
- Do not reconnect to the console merely because an old session ID appears in notes; it is released to the user.
- Do not repeat the recommended-image flash or claim its successful verification means it booted.
- Keep exact original restore images distinct from the new nonbooting images and from staged intermediate firmware.
- Do not infer golden-bank selection, TPM state, fuse configuration, a RAM defect, or a PSU/fan root cause beyond the evidence above.
- Preserve unique board data and credentials. No full dump or configuration contents should be published.
- Reconfirm physical power/cable/USB state and actual programmer hardware before continuing.


## 20. October 24 bench handoff: programmer accepted, header route unresolved

The detailed current measurements are in [the tracking plan](ROUTER-RECOVERY-TEST-PLAN.md), especially C8375-01-HDR. The user has accepted the CH341A plus 1.8 V adapter and ended further standalone programmer validation. Adapter input measured 3.318 V and regulator tab 1.803 V. The active blue socket is printed 1–8, pin 4 ground; expected output levels were confirmed qualitatively, without separate per-pin numerical readings.

P1_CSPI pin 1 maps to U1 flash VCC and P1 pin 2 to ground. P2_CSPI is a four-post header: pins 1/3 each measured 0.2 Ω to P1 ground, while pins 2/4 were approximately 5 kΩ to ground. U4 Select→P2-2 measured 329 Ω, Select→P2-4 >9 kΩ, and Enable→known ground 331 Ω. No selector setting or supply injection was tried. The mux supply search has not found a direct header feed; latest remaining P1 readings were reported collectively in MΩ, with pin 8 at 5.6 kΩ. Do not conflate these endpoints with the earlier flash-clock scan or invent per-pin values.

The assistant ended repetitive broad scans after the user noted repetition. A complete SPI header access route remains unresolved; no programmer was attached to the router, and no external flash acquisition or write has occurred. The preferred next step is direct access with the SOIC-16 clip expected October 25, then two complete matching reads per physical chip, U1_CSPI and U2_CSPI. Compare with the exact original backup before selecting a restore target. Do not restart programmer validation or the same header matrices without new evidence. C8300 external-console diagnosis is a separate available task today, not work already performed.


## 21. Active priority clarification: continue the CH341A/Dupont/header route

After the preceding recommendation to wait for the clip and the assistant's switch to C8300, the user explicitly asked to return to recovering this router through the CH341A and pin header. Keep this as the immediate task. C8300 notes and the confirmed absence of its USB-console cable during RJ45 testing are retained for later.

Use [C8375-CH341A-HEADER-WIRING.md](C8375-CH341A-HEADER-WIRING.md) as the focused harness/status sheet. Programmer/adapter is accepted; broad supply/ground scans are complete and should not be repeated. Adapter output 8 to P1-1 and output 4 to P1-2 are known net correspondences, not a ready-to-power harness. SPI signals, mux power/control and board loading are unresolved.

The focused unpowered test found **22 Ω from large U1 flash CLK pin 16 to small U4 mux common pin 4 / YA**. The other tested common pins 7/9/12 were reported high, with no individual values/units. This points to channel A as the clock path; a discrete series resistor has not been identified. The user then explicitly corrected an initial U1/U4 wording error: **small U4 pin 2 / IA0 to P1 pin 4 = 33 Ω**. This identifies P1-4 as the header-side clock branch; do not record it as flash VCC or as a powered end-to-end test. The U4 pin 3 / IA1 scan against P1 posts 3–8 then returned **no small readings, most OL**, with other individual values not supplied. Clock branch scans are complete. The user then expanded the CS# scan from large U1 pin 7 to **every U4 pin and every P1/P2 post**, with no reading below approximately **5 kΩ**; individual values were not supplied. The U4 CS# tests are complete and should not be repeated. Next investigate **upper U3 mux common pins 4/7/9/12** from U1 CS# pin 7; these four new pairs are pending. Alternate buffer/logic routing remains possible, and no component fault is established. Mux power/control and other header signals remain unresolved. No programmer-to-router attachment, selector jumper, new chip read or write has occurred.


## 22. User proposes partial SOIC-8 clip plus header access

The user reports difficulty locating U1 CS# despite many searches and proposes using today's eight-contact clip on part of U1, with Dupont/header wires for the remaining connections. They also ask whether guessed powered CH341A wiring can cause permanent damage. This is the immediate assessment; set aside earlier U3/244A-device search questions rather than requesting more random scans.

See [the wiring sheet's hybrid proposal](C8375-CH341A-HEADER-WIRING.md). A naturally fitting clip on the end away from the pin-1 dot could cover U1 pins 5–8 and 9–12, including CS# 7/MISO 8/WP# 9/GND 10. Fit/contact identity is not verified; the wide SOIC-16 body may not suit this clip. The ordinary eight-pin cable mapping would be wrong in this position. Use only individually mapped contacts and leave touched DNU pins 5/6/11/12 electrically disconnected. Do not force the clip.

P1 supply/ground are mapped and its clock branch reaches U4 IA0, but MOSI, powered mux configuration and loading remain unresolved. This is not a ready harness. Four clip-jaw/cable/placement photos are now available under Photos/ (IMG_1269/1270/1271/1273). They show the clip positioned on U1 at the intended CS# end and a separate green male-leg clip breakout. Individual contacts and lack of bridges are not established by these partly obscured views. Next scan the eight breakout male legs to known router P1-2/GND in ohms mode, with all power disconnected and breakout separate from programmer/adapter, and mark/report near-baseline matches and values. This is a new clip-contact test, not another board CS# route search. No new electrical values, powered programmer connection, chip read or write have been reported. A USB-powered CH341A can damage wrongly wired parts even with router power removed; read-only software does not establish electrical safety. Use only the accepted 1.8 V adapter output and disconnect USB before wiring changes.


## 23. October 25: partial-clip ground result needs direct mapping

The user reports changed eight-contact clip alignment: clip 1→U1-5, clip 4→U1-8, clip 5→U1-9, clip 8→U1-12. They report contact 5 at 0.3 Ω / ground and others OL. A specific follow-up confirms the fixed meter probe was router P1-2/GND, so these are **ground-scan readings**, not verified point-to-point contact mappings. Preserve that distinction. WP#/DQ2 is U1 pin 9; VSS is pin 10. A board-held-low WP#, imperfect contact/numbering/alignment, or a clip bridge are possible; no cause is established. Do not assume pin 9 cannot be grounded or drive it high blindly.

Next, with every power source disconnected, remove the clip and measure bare U1 pin 9 (top-left corner lead in the saved photo) to known P1 pin 2/GND in ohms mode. This new single-pair test establishes native WP# ground state without clip influence. All other contact and bridge checks remain pending, along with MOSI and mux power/control. The programmer is accepted; do not restart its validation or broad header searches. The SOIC-16 clip was due October 25 but delivery has not been confirmed. No powered harness/read/write has occurred.


## 24. October 25 correction: U1 pin 10 / clip contact 6 is ground

The user explicitly corrected section 23's numbering error: after checking U1 and reseating/checking the clip, **U1 pin 10, reached by clip contact 6, is ground**; other checked contacts are OL to ground. The earlier 0.3 Ω low ground reading belongs to this corrected contact, not U1 pin 9/clip 5. Withdraw the WP#-ground/misalignment interpretation and the pending clip-removed WP# test. This correction does not by itself establish every non-ground clip contact.

The user then reports the jaw blocks actual U1 pad access. Those two direct clip-to-chip checks are unperformed. A blanket inter-contact OL statement was withdrawn; the explicitly confirmed pair **clip 3→clip 4 = OL** is the only recorded inter-contact result. The user then measured **red clip 3→black P1-8 = 9.33 kΩ**, exactly matching the earlier bare **U1 CS#-7→P1-8 = 9.33 kΩ** reference. This supports intended CS# contact indirectly; matching resistance is not unique proof and P1-8 is not a CS# assignment. The requested six U1-MOSI-15/clip-4-to-U4-7/9/12 attempts then returned **MΩ or OL**, with the user explicitly reporting U4 is too tiny for reliable probe contact. These negatives are inconclusive; stop further tiny-U4 probing with this setup. The full SOIC-16 clip remains about **16 hours away, expected around 4:30 PM October 25 local time**, per the user. Next assess actual test-hook tips beside exposed U1 pins **15/MOSI and 16/CLK**, unpowered and unattached, as a conditional direct-access alternative alongside the partial clip. Secure isolated single-leg fit is not established; do not force hooks or use unstable hand-held contacts for writing. The proper wide SOIC-16 clip remains the full-contact approach when available. Keep the programmer accepted and avoid completed ground/clock/CS# repeats. MISO contact, remaining controls and safe loading/powered setup are unresolved. No powered ID/read/write has occurred.
