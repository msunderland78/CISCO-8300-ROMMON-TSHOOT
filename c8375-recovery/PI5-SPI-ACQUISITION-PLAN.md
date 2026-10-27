# Pi5 SPI acquisition plan — C8375-A

Updated October 27, 2026, America/New_York. Task **P-03**; chassis **C8375-A / FDO2742M0FK**, Crestone/SoC2. Read-only SSH inventory is now complete; electrical setup and router acquisition remain planned.

## Verified Pi inventory — October 27, approximately 16:06 EDT

SSH succeeded using the existing private credential record. The Pi reports **Raspberry Pi 5 Model B Rev 1.1**, **Ubuntu 26.04.1 LTS**, **aarch64**, kernel **7.0.0-1020-raspi**. Header SPI is already enabled with `dtparam=spi=on`; no installation, configuration change or reboot was necessary. Installed **flashrom 1.6.0 / package 1.6.0-2ubuntu1.1** lists both `linux_spi` and **MT25QU256 / 32768 KiB** offline. Its installed manual documents `spispeed` in kHz and region-sized `-i region:file` reads.

Sysfs/device-tree identify **`/dev/spidev0.0` as RP1 SPI0 / CE0**, through `/axi/pcie@1000120000/rp1/spi@50000/spidev@0`. `/dev/spidev0.1` is the other chip select. **Leave `/dev/spidev10.0` alone**: it belongs to the separate SoC controller, not the selected header interface. None of these nodes was opened. `sudo -n true` requires interactive authentication; unprivileged `pinctrl get 8-11` returned `Must be root`, so that command did not verify pin functions. No privileged GPIO command ran.

The owner replied “yes” to the grouped chassis/U1/isolation/disconnected-GPIO reconfirmation; individual conditions were not independently inspected. [Public inventory metadata](acquisition-evidence/20261027-Pi5-live-inventory.json); raw SSH output remains private. Earlier no-login statements below describe the preparation checkpoint before this inventory.

## Saved state and equipment

The owner now reports **Raspberry Pi 5**, **256 GB microSD**, and **Ubuntu Server 26.04.1 LTS**. This supersedes the earlier belief that the card ran Ubuntu 24 LTS. Preserve the current installation; no reimage or EEPROM update is selected. The supplied SSH endpoint and credentials are saved only in the restricted local `.git/recovery-private/pi5-ssh.json` (directory 0700, file 0600). The password is registered with the local publication guard. Do not copy the credential record into public evidence.

The owner confirms receipt of **two new SOIC-16 clips, each with a 40 cm cable**, plus **10 cm Dupont cables**. Keep these separate from both the earlier 35 cm assembly (unavailable or modified) and the direct-pin short harness photographed October 27. Label the new clips A/B before comparative captures. Their exact model, package fit, contact mapping and assembled length are unverified. A route using both a 40 cm ribbon and a 10 cm jumper would be approximately 50 cm before connectors/board traces; this is arithmetic, not a measured assembled path.

Requesting a lower SPI clock may improve timing margin. It does not establish reliable contact, correct translation, acceptable loading or clean edges. Longer cables are a test variable, not an accepted fix. Prefer the shortest practical route and change one assembly at a time. The Pi's SPI clock is configurable; owning a Pi5 does not itself make the bus slower. Start with a requested **100 kHz**; actual clock has not been configured or measured.

## Evidence that must survive the transition

- Last confirmed physical target is **U1**, after comparison with U2. Last reported U1 P1 rail was **1.786 V DC**; adapter output4→P1-2 and output8→P1-1 were each **0.3 ohm**. These are historical measurements, not validation of a future Pi setup.
- Router normal power, console/other cables and CR2032 were removed under the session setup. CH341A USB unplug was requested; confirmation is pending. Reconfirm actual chassis, chip, isolation and console/programmer ownership before any hardware interaction.
- Corrected U1 short reads completed but differed at **332 bytes** in `0x001F0000–0x001FFFFF` and **7 bytes** in `0x01F30000–0x01F3FFFF`. Earlier U1 full read5/read6 matched each other but retain systematic accuracy concerns. See [U1 validation](acquisition-evidence/20261027-U1-comparison-partial-validation.json).
- Both historical U2 full pairs failed repeatability: **3,897,877** and **1,775,520** differing bytes. Latest U2 short pair differed at **58,005** bytes in the lower region, while its upper region matched. Later probes failed ID despite CH341A initialization. No stable U2 backup exists. See [U2 short validation](acquisition-evidence/20261027-U2-short-harness-partial-validation.json).
- The failed U1 command with the agent's `MT25QU156` typo stopped before hardware initialization; the corrected candidate is **MT25QU256**. Preserve the failed script/log. A software typo is not a chip failure.
- Unloaded adapter zero-voltage reports were withdrawn after wrong probes were found; corrected outputs7/8→4 were both **1.803 V DC**. Later loaded values were about 1.7–1.8 V. No regulator fault was established.
- Clip jaws hide the flash legs and connector blocks hide terminal metal. All proposed clip-side probing was withdrawn as inaccessible. Do not repeat those requests or use mux-routed header signals as direct substitutes for covered flash legs.
- No cause, primary/golden bank mapping, restore image or write target is established. Main-array reads do not establish that U2 contains the desired IOS configuration. Preserve original captures; do not reconstruct or patch unique data.

## 1. Inventory the Pi with its GPIO disconnected

Use the saved SSH record or the Pi console. Verify host identity through normal SSH host-key handling; a changed key must be investigated. Capture only OS/kernel/model, SPI node/configuration inventory and flashrom version. The previously prepared read-only block is local at `.git/recovery-private/pi-preparation-20261027/PI5-INITIAL-CHECKS.txt`; it has not been executed on the Pi.

Check the actual model and release, then inspect `/dev/spidev*`. A missing flashrom command or absent SPI node is setup information, not a router-chip failure. Select the **GPIO-header SPI controller** from actual device-tree/sysfs evidence; do not assume a numbered node or open a Pi internal boot-EEPROM controller. No raw Pi EEPROM access is part of this plan.

Check installed/package flashrom version and `MT25QU256` support offline. Install a supported package if needed. If header SPI is disabled, inspect `/boot/firmware/config.txt` and its sections, preserve a backup, then enable the appropriate header SPI configuration and reboot as needed. Do not blindly append configuration or reimage a working card. Verify nodes again after any change. Validate partial-read syntax for that installed version without opening a programmer.

## 2. Validate the Pi-to-adapter interface with the router disconnected

### Next physical step and proposed input wiring

Run `sudo poweroff` on the Pi, wait for shutdown, then unplug its power supply before handling the header. With CH341A USB unplugged, disconnect the router's harness from the adapter output and remove the adapter from the CH341A. The clip can stay on U1. Identify the adapter's **underside INPUT contacts**, their pin-1 orientation and accessible connection method before connecting wires. Blue-socket OUTPUT numbering is a different endpoint. Do not infer underside orientation by mirroring a photo.

The existing P-01 input mapping was user-confirmed October 24: ground→4; 3.3 V→8/3/7; CS→1; MISO→2; MOSI→5; CLK→6. The following is the proposed replacement source, subject to reconfirming those actual input contacts and the Pi interface with the router disconnected:

| Pi physical header pin | Signal | Existing adapter INPUT contact |
| --- | --- | --- |
| 1 | 3.3 V supply / inactive control inputs | 8, 3 and 7 |
| 6 | Ground | 4 |
| 19 / GPIO10 | MOSI | 5 |
| 21 / GPIO9 | MISO | 2 |
| 23 / GPIO11 | CLK | 6 |
| 24 / GPIO8 | CE0 / CS# | 1 |

### Current capped junction and unloaded output check — October 27

New original [IMG_1282](../Photos/IMG_1282.jpeg) and [IMG_1283](../Photos/IMG_1283.jpeg) show a capped junction and a fitted Pi-to-adapter harness. The owner confirms white wire **Pi physical1/3.3V → capped junction → three black branches to adapter INPUT8/3/7**, CH341A removed, **Pi now powered on**, and **nothing on the adapter output**. Owner reports continuity among all four connectors; no exact resistance, fresh baseline or test power-off timing supplied. This changes the available setup: a breadboard is no longer necessarily required if this junction is secure and passes interface checks. Do not interpret cap appearance as verified wire-size compatibility or mechanical grip.

Read-only SSH `sudo pinctrl get 8-11` reports GPIO9/10/11 as SPI0 MISO/MOSI/SCLK and GPIO8 output high/pull-up, consistent with inactive GPIO chip select. No pin setting changed and no SPI node opened. Earlier unprivileged pinctrl failure remains historical, now superseded by this successful privileged read-only query. [Harness evidence/original hashes](acquisition-evidence/20261027-Pi5-capped-junction-harness.json).

**Current requested measurement, not yet reported:** keep router disconnected and powered wires still. With meter in **DC volts**, black at **adapter OUTPUT4/GND**, measure red at **OUTPUT8/VCC**, **OUTPUT3/WP#**, then **OUTPUT7/HOLD#**. Expect approximately1.8V each. Do not perform continuity/resistance measurements while powered. No router attachment or flashrom command is selected from photographs/continuity alone. After acceptable unloaded levels, power Pi off/unplug before any target connection, reconfirm chassis/U1/router isolation and whole harness assignments, then check loaded target supply before an ID attempt.

**Unloaded result now reported:** OUTPUT8/VCC, OUTPUT3/WP# and OUTPUT7/HOLD# are **each1.804VDC to OUTPUT4/GND**, owner-measured with Pi on and adapter output empty. This completes the static unloaded check; no loaded supply or dynamic SPI/MISO result exists. Owner then replied yes to reconfirming C8375-A/FDO2742M0FK/U1, router power/all other cables disconnected, CR2032 removed and no active console/programmer session.

**Next user-performed step, not yet completed:**

1. Run `sudo poweroff` on Pi, wait for shutdown and unplug its supply. With power absent, check the cap grips each junction wire gently without loosening any connection; correct any loose connection before proceeding.
2. Reconnect the **same existing mapped U1 clip harness** to the adapter's **1.8V OUTPUT** in its checked orientation. Keep CH341A removed. Verify the Pi INPUT mapping above and OUTPUT-to-package mapping below; do not rebuild or renumber the clip based on wire colors. Router power/cables/CR2032 remain disconnected.
3. Power the Pi alone. Do not move wires or start flashrom. Measure **DC volts, black router P1-2/GND, red P1-1/VCC**, and report the loaded value. Expected supply range **1.7–2.0V**; no increase or additional router supply is selected. If voltage collapses, leaves that range, or unexpected warming/activity occurs, disconnect Pi supply and preserve the failed observation.
4. Only after an acceptable loaded reading, proceed to a fresh logged U1 identification at requested100kHz, then independent bounded reads if ID matches. A command's preparation does not establish execution; all original evidence stays unchanged.

**Loaded result now reported:** owner reports **P1-1/VCC→P1-2/GND =1.789VDC**. Freshly reconfirmed target is C8375-A/FDO2742M0FK/U1 with normal router power/other cables/CR2032 disconnected and no active competing session. The voltage is within1.7–2.0V; the numerical reply does not separately narrate every shutdown/reconnect step or measure transients.

**One user-executed ID-only command is now prepared; no agent SPI access or ID result:** run on the **Pi**, leaving wiring/clip still and normal router power disconnected:

```sh
id_log=$(mktemp "$HOME/C8375-U1-ID-100kHz-XXXXXX.log") &&
sudo flashrom -V -p linux_spi:dev=/dev/spidev0.0,spispeed=100 -c MT25QU256 -o "$id_log"
```

The log is fresh, mode0600 and owned by the Pi user. This requests100kHz, not a measured clock. No main-array capture, force, write/erase or protection/OTP operation is selected. Expected prior identity **20BB19 / Micron MT25QU256 / 32768KiB**; stop on incorrect/zero ID. Local `/bin/sh -n` syntax passes; only an actual user probe/log can establish communication. Await output before bounded reads. Keep VCC in1.7–2.0V and disconnect Pi supply for collapse/out-of-range voltage, warming or unexpected board activity.

**Access follow-up:** an additional SSH-only `mktemp --dry-run` check was rejected at login (255/authentication denied) using the existing saved record. It did not execute or open SPI; no file was created. Earlier successful SSH/pinctrl checks remain valid history. No credential retry/search is selected. The owner can execute the ID command in their Pi terminal; only local shell syntax, not a Pi runtime log-template check, is claimed.

### Available parts clarification and next isolated adapter check

The owner supplied [IMG_1281](../Photos/IMG_1281.jpeg) and says these are all other parts besides Dupont cables. It shows loose pin headers and several SPI/package breakout boards. **No solderless breadboard is reported available**; the breadboard example below remains a contingent option, not the current setup. A loose pin-header strip does not join adjacent pins. None of these breakout boards has a measured four-contact common node or verified secure fan-out connection; do not invent one from the photo or wedge loose male jumpers into unsoldered holes.

Before selecting extra hardware, check whether the **detached 1.8 V adapter itself** already joins the three proposed input feeds. Earlier P-01 measurements were programmer-to-adapter checks while fitted; they do not establish internal ties within the standalone adapter. With Pi power unplugged, CH341A USB unplugged, the adapter removed from the CH341A, and **every input/output wire removed from the adapter**, verify residual voltage absent. Use accessible **eight-pin INPUT contacts/solder pads beside the arrow**, not the blue output socket. With meter leads in COM and V/ohms and resistance mode, record probes-together baseline, then measure:

1. Adapter **INPUT8 → INPUT3**, in ohms.
2. Adapter **INPUT8 → INPUT7**, in ohms.

Report actual values/OL. Near-baseline readings would support a direct common net; higher resistance does not establish one. This is a new isolated input-side check, not another router/covered-clip scan. **No result, jumper, one-wire power-up or firmware command is selected yet.** A single input8 supply feed is only a possible outcome if internal connectivity and resulting output behavior support it. Do not omit feeds or substitute GPIO outputs based on the photograph.

**Reported result, October 27, America/New_York:** owner reports **INPUT8→3 = 632 Ω** and **INPUT7→3 = 632 Ω**. The second reported pair is **not** the requested INPUT8→7; that pair and fresh lead baseline remain unreported. Detached/unpowered conditions were requested but not separately restated in the numerical reply. Preserve the actual endpoints. These readings do not support a direct common net and do not identify a particular resistor, circuit, fault or chip damage. Do not select a single input8 supply on an internal-short assumption. No repeat is needed solely to reject the all-three-common hypothesis; no additional measurement or powered operation is selected at this checkpoint.

For the proposed fixed-3.3V-input method, a secure common junction is still needed. No photographed accessory is verified to provide it without modification. A [mini solderless breadboard](https://www.adafruit.com/product/65) plus four ordinary female-to-male leads remains the straightforward no-custom-cable option; it is a recommendation, not a purchase/delivery. Only supply/control distribution uses it; keep SPI signals direct through the active adapter. Continue target-disconnected interface checks after a suitable junction is available. [Recorded measurements and limitations](acquisition-evidence/20261027-Pi5-adapter-photo-inspection.json).

### No custom cable: distribute 3.3 V on a solderless breadboard

The owner supplied [adapter top](../Photos/IMG_1279.jpeg) and [underside](../Photos/IMG_1280.jpeg) photographs October 27 and requests ordinary jumpers rather than a custom three-way cable. The underside shows two rows of four male input contacts. Photographs do not establish their pin numbers, dimensions, connector grip or electrical connections; retain the measured historical input mapping and confirm actual orientation before use.

A **small solderless breadboard plus four ordinary female-to-male jumpers** provides a proposed detachable 3.3 V distribution point. Use one connected five-hole terminal strip on one side of the center trench, for example A10–E10 on a board with that labeling:

| Breadboard hole | Other end of female-to-male jumper |
| --- | --- |
| A10 | Pi physical pin 1 / 3.3 V |
| B10 | Adapter INPUT 8 |
| C10 | Adapter INPUT 3 |
| D10 | Adapter INPUT 7 |
| E10 | Unused |

The male ends enter the breadboard; female ends fit the Pi/adapter male pins only if they grip securely. All four holes must belong to the **same connected strip**; F10–J10 across the trench is separate. Verify the bare breadboard strip's continuity while disconnected before assembling. The breadboard makes the common junction without stuffing multiple wires into one Dupont housing, soldering, cutting, or crimping. Pi physical pin17 is another 3.3V contact, but the header supplies only two such contacts, so it alone does not provide three separate source contacts. No GPIO-output substitute is selected.

Keep MOSI, MISO, CLK and CS# direct through the active adapter using short ordinary female-to-female leads, and keep common ground per the table. Only the 3.3 V distribution junction uses the breadboard. Do not use Pi 5 V or the adapter's 1.8 V OUTPUT contacts for this input junction. No breadboard, new harness, power-up, measurement or SPI operation has been performed/confirmed. The target remains disconnected until interface checks pass.

References: [Adafruit breadboard terminal strips](https://learn.adafruit.com/breadboards-for-beginners/breadboards), [official Pi header pin functions](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html). This is a proposed connection method, not a claim that a new accessory has been purchased or tested.

This is a mapping plan, not evidence that a Pi harness has been built or tested. Use no Pi 5 V pin. All four SPI signals pass through the active adapter; the flash-side supply and controls stay at 1.8 V, and returning MISO must remain compatible with Pi 3.3 V GPIO. Verify unloaded adapter supply/translation first, then power off before reattaching the router harness. Recheck accessible loaded P1 VCC/GND against 1.7–2.0 V before probing. Do not compensate for loading by increasing voltage or adding router power.

Once the interface and loaded target are checked, the planned ID-only command on the Pi is:

```sh
sudo flashrom -V -p linux_spi:dev=/dev/spidev0.0,spispeed=100 -c MT25QU256
```

This command has **not** run. `100` requests **100 kHz**, not 100 MHz; actual clock remains unmeasured. Expect prior JEDEC `20 BB 19` and 32768 KiB; stop on incorrect/zero ID rather than forcing detection. Preserve its log in a fresh private acquisition directory. Main-array/configuration recovery remains unproven.

Pi GPIO uses **3.3 V logic**; the flash requires **1.8 V power and signal translation**. The existing active adapter is a candidate for reuse, not a verified Pi interface. Power the Pi off before GPIO wiring, and remove the CH341A entirely from the adapter input. Establish the actual adapter input numbering, supply requirements, ground and translator directions before applying power. A 1.8 V supply alone does not translate SPI signals.

For orientation/reference only, the expected GPIO-header SPI0 signals are:

| Signal | Pi physical header pin | GPIO |
| --- | --- | --- |
| MOSI | 19 | GPIO10 |
| MISO | 21 | GPIO9 |
| CLK | 23 | GPIO11 |
| CE0 / CS# | 24 | GPIO8 |

These pin numbers are not an instruction to connect the target now. Confirm header orientation and actual configured function first. Verify the adapter input-side source and ground against its documented mapping, output-side supply and control levels, and signal translation, including returning MISO. Do not use Pi 3.3 V directly on the flash. Do not connect Pi and CH341A as simultaneous sources, or power the router normally while programming.

The existing validated adapter **OUTPUT-to-package** mapping is retained below; it does not authenticate either new clip's ribbon/breakout mapping:

| Adapter OUTPUT | Signal | U1/U2 SOIC-16 physical pin |
| --- | --- | --- |
| 1 | CS# | 7 |
| 2 | MISO / DQ1 | 8 |
| 3 | WP# / DQ2 | 9 |
| 4 | GND | 10 |
| 5 | MOSI / DQ0 | 15 |
| 6 | CLK | 16 |
| 7 | HOLD# / DQ3 | 1 |
| 8 | VCC 1.8 V | 2 |

RESET# is package pin3; no new jumper is selected. DNU pins remain unconnected. P1 pin1/common VCC and pin2/common ground are supported by prior measurements. Other header SPI paths pass through unresolved muxes. Validate each new assembly unpowered at accessible endpoints **before fitting it to the chip**; do not assume SOIC-8 numbering on a SOIC-16 package. Confirm residual voltage absent before resistance checks, correct meter inputs/mode and probes-together baseline. Do not cut/depin the assembly or invent inaccessible measurements.

## 3. Identify, then compare bounded reads

Reconfirm chassis **FDO2742M0FK**, physical **U1** unless deliberately changed, router power/cables/CR2032 isolation and exclusive programmer ownership. Record clip A/B or the existing short harness, wire route, actual assembled length and mapping evidence. Check loaded VCC against the documented **1.7–2.0 V** range using accessible P1 endpoints. A nominal DC reading does not measure switching transients. No voltage increase or speculative jumper is selected.

Only after those checks, prepare a fresh private acquisition directory for that **physical chip and assembly**. Use the identified header node with flashrom `linux_spi` and `spispeed=100` (kHz), exact candidate `MT25QU256`, separate logs and no overwrite of existing evidence. Do not run a placeholder device path. Probe first; expected prior identity is **20 BB 19**, 32768 KiB. A zero/incorrect ID stops the acquisition; do not force detection.

Read each of the same two 64 KiB regions independently at least twice: `001f0000–001fffff` and `01f30000–01f3ffff`. Check exact file sizes, SHA-256 and differing byte positions. Preserve failures and empty placeholders as failures. Test each clip separately with the same recorded settings; change one variable at a time. Even matching short regions are insufficient to establish whole-array accuracy.

### First Pi U1 ID succeeds; bounded acquisition prepared

Owner-pasted identification output now reports **20BB19 / MicronMT25QU256 /32768kB / status0x00**, using `linux_spi` on `/dev/spidev0.0` with software-reported100kHz and4096-byte kernel buffer. It ends **No operations were specified**. The original Pi logfile basename is `C8375-U1-ID-100kHz-1HaQgr.log`; it has not been independently retrieved or hashed. Separate OTP and untested-WP notices are retained; no OTP/protection command is selected.

An **AI-assisted original Python3 standard-library read/compare command** is prepared locally under `.git/recovery-private/pi-preparation-20261027/` (`pi_u1_short_reads.py`, `PI5-U1-SHORT-READS-COMMAND.txt`) and copied to the owner's clipboard. User pastes it into the **Pi terminal**; no agent SPI access. It uses exact `MT25QU256` and `linux_spi:dev=/dev/spidev0.0,spispeed=100`; the installed/upstream1.6 manual supports `-r -l layout -i region:file` for region-sized reads. No full-array output filename is supplied.

The command refuses an active flashrom process, creates a fresh mode0700 Pi-home directory, then performs two independent passes over the same two64KiB regions. Four sample files and two logs are precreated exclusively as user-owned0600 files, so sudo can write them while the comparison remains user-readable. Failed/empty placeholders are recorded as failures, not samples; no automatic retry or overwrite of old evidence occurs. Each pass must return success and exact65536-byte files before continuing. Results include SHA256, byte diversity, zero/FF counts and changed-byte counts/absolute first/last positions; binary contents are never printed. Preserve everything privately.

Validation: Python AST and shell here-document syntax pass; importing definitions triggers no main/hardware action. Synthetic equal samples give0differences; first/last changes in the upper region give2 at correct absolute offsets; an empty placeholder is rejected. These are offline logic checks, **not Pi acquisition tests**. Keep the same U1 harness and router isolation, monitor P1 supply1.7–2.0V, and share the final comparison metadata before further reads. **No samples or full reads have completed yet.** [ID, dependencies, prepared-command hashes and validation](acquisition-evidence/20261027-Pi5-U1-ID-and-short-read-preparation.json).

### Script-file execution, superseding the pasted here-document handoff

At the owner's request, the prepared wrapper is now an ordinary repository file: [`scripts/pi_u1_short_reads.py`](../scripts/pi_u1_short_reads.py). It is AI-assisted original code using the Python3 standard library plus installed `flashrom`, `sudo` and `pgrep`. Hardware and acquisition-file creation require the explicit invocation:

```sh
python3 /path/to/pi_u1_short_reads.py --read
```

Running without `--read`, using `--help`, or importing definitions does not access SPI. The fixed target/settings remain **C8375-A/FDO2742M0FK/U1**, **MT25QU256**, **RP1 `/dev/spidev0.0`**, requested100kHz, the two existing64KiB regions and two passes. No full capture/write/protection/OTP operation is added. Keep the checked harness still, normal router power/cables/CR2032 removed, and supply1.7–2.0V.

Delivery: owner runs a short `curl` download from the existing public repository pinned to a specific published commit, verifies SHA256 with `sha256sum`, then invokes the downloaded file with `--read`. A fresh private Pi tools directory prevents overwriting another script. This avoids retrying the rejected saved SSH login. Downloading is not installation/execution until the owner runs the command; no agent SPI command is selected.

Validation: `python3 -m unittest discover -s tests -v` passes **18tests**, including **7offline mocked acquisition tests** for safe import/help/default, competing-process guard, comparison offsets, incomplete samples, failed-read stop, differing samples, original-byte preservation and private modes. No hardware was used. [Source hash and delivery record](acquisition-evidence/20261027-Pi5-U1-ID-and-short-read-preparation.json). No Pi read result exists yet; preserve any captures and share the comparison before further reads.

### First bounded Pi acquisition passes repeatability; import before full reads

Owner output for `C8375-U1-Pi100kHz-mbprng0s` now reports **two successful passes, four65536-byte samples, both region pairs byte-identical** (0/0 differences). Lower pair SHA256 `6c39b76271b961e11e745f09eede3b69c6181d704b40dadf21e8dc73400d4c84`; upper pair `e0c7d36013e11f91b484ea6d2c7d70b0acbb93611c50c96f014702f8b258d67e`. Both samples are nonconstant. Pi-reported interval17:15:32–17:16:01EDT. Pass1status00/pass2status02(WELset,WIPclear) retained; both argv lists select reads only. No inference of array programming from WEL alone.

This improves bounded repeatability versus the last CH341A U1 pair332/7differences. It does not isolate clock speed as the cause, since programmer/interface/setup also changed. Independently rehashed **local** original, known nonbooting and older U1-read5 images all have different corresponding region hashes. The lower Pi sample reports8151zero bytes versus423in the original lower region; this is a count relationship, not proof of a read fault or a wrong bank. Actual Pi byte arrays are needed for bitwise/address/reference analysis.

**Next selected step is private file import, not a full read yet.** The owner-run SCP command on the **Mac terminal** copies the Pi result folder into a fresh0700 `.git/recovery-private/acquisitions/C8375-FDO2742M0FK/U1/` destination, preserving Pi originals and avoiding overwrite of old evidence. It uses interactive SSH authentication without embedding credentials. The command is in the clipboard; no transfer has run. Keep Pi on/network-accessible for file copying and leave hardware wiring still; no additional SPI process is needed. Once originals arrive, verify sizes/hashes/metadata and compare bytes against references before deciding whether to spend roughly90minutes or more on a full pair at100kHz (raw32MiB payload alone is about45minutes per read, before overhead). [Result, reported sample metadata and independent local reference hashing](acquisition-evidence/20261027-Pi5-U1-short-read-result.json).

### Dedicated SSH key and private originals now verified

The owner explicitly requested another login attempt and key access. The saved password login worked on retry; no cause for the earlier rejection is established. A dedicated Ed25519 key now provides verified **key-only command execution and SCP**. Its private material remains local in restricted `.git/recovery-private/ssh/`; the existing private connection record points to it. The added authorized-key line uses `restrict` and a `from` condition for the currently observed Mac source IP, preserving prior authorized-key bytes. Remote `.ssh` is0700 and authorized_keys0600. No SSH-daemon or sudo-policy change was made. A Mac source-IP change may require updating the restriction. [OpenSSH option semantics](https://man.openbsd.org/sshd.8).

Agent used key-only SCP to import all8original result files into fresh private storage, then independently verified the four65536-byte samples against the owner's hashes and byte-compared each pair: **lower0/upper0differences**. The Pi originals remain unchanged. Actual byte comparisons find **8024lower-region differences from original, all losing originalonebits**, and **119upper differences,118losingones/1addingones**. The upper sample differs from the known nonbooting reference at117bytes, all losingones. Relative to the latest CH341A read1, Pi differs at488lower/67upperbytes. These are measured byte relationships, not a diagnosis of bank role, current intended contents or a physical fault.

The matching pairs are preserved but accuracy remains unresolved. No new SPI acquisition, full read or write occurred during access setup/import. Continue controlled read-path/clock and bit/address analysis before long full acquisitions. The prior manual Mac-import clipboard command is no longer needed; originals are already here. [Private import hashes, key access status and independent comparisons](acquisition-evidence/20261027-Pi5-key-access-and-independent-validation.json).

### Recommended next comparison: first new40cm factory-wired clip

At the owner's old-versus-new question, recommend **trying one new40cm clip next**, labeled **New40cm-A**, on the **same physical U1**. Keep current short/custom assembly intact as the preserved comparison baseline; it is not the older unavailable/modified35cm assembly. Keep Pi input wiring, capped3.3V junction, active1.8V adapter, `/dev/spidev0.0` and requested100kHz unchanged. Do not simultaneously reduce clock speed. Another clip/contact/cable assembly provides independent read-path evidence now that the current setup has produced a repeatable pair. Factory assembly may improve contacts while additional length can reduce margin; neither outcome is guaranteed. Treat the whole assembly as the changed variable, without attributing a result solely to length or crimp quality. [General upstream cable/contact guidance](https://raw.githubusercontent.com/flashrom/flashrom/v1.6.0/doc/user_docs/in_system.rst); its generic alternate power/reset suggestions are not selected here.

Next inspect a photo of the new clip, cable connector and breakout **detached**, then verify wideSOIC16 fit, pin1 orientation and actual eight-signal mapping at accessible endpoints before fitting. Do not assume factory wiring makes SOIC8/16 numbering compatible or repeat inaccessible under-clip probing. Shutdown/unplug Pi before any wiring/clip change; keep CH341A removed and normal router power/cables/CR2032 isolated. Before powered access reconfirm chassisFDO2742M0FK/U1 and programmer ownership; verify loaded P1 supply1.7–2.0V. Then ID first and, if acceptable, two passes over the same two64KiB regions, retaining all raw samples privately and comparing both within-pair and against current-short baseline/references. No physical change, new read or full/write selection has occurred. [Specific comparison plan](acquisition-evidence/20261027-Pi5-new-clip-comparison-plan.json).

### New40cm-A tested: repeatable large samples, failed independent4KiB control

Owner connected the new factory-wired clip toU1 and reports P1VCC**1.747VDC**, power/ground paths each**0.5Ω**; fresh lead baseline and power-off resistance timing not separately reported. Owner explicitly reconfirms chassisFDO2742M0FK/U1, normal router power/all other cables/CR2032 isolation, CH341A removed, no other programmer and all8connections checked. That mapping confirmation supersedes the pending detached-photo request for proceeding with this bounded test; no new mapping was inferred from appearance.

Agent performs one SSH ID probe at100kHz:20BB19/MT25QU256/32768kB/status00. Checksum-verified existing script then reads both64KiBregions twice. All four65536byte files are fetched and verified: each pair matches, but new versus short clip differs**57539lower/7upperbytes**. New lower sample is allFF over001f2000–001fffff; neither new region matches saved references. This does not establish erasure or chip damage.

A targeted follow-up reads001f2000–001f2fff twice at100kHz and twice at50kHz in a fresh private directory. The100kHz pair differs**4072/4096bytes**. Its first sample differs**8bytes** from original; second differs**4077**. Both50kHz samples equal the second100kHzsample and still differ4077from original. They also disagree with the corresponding earlier64KiBslice, showing read-shape/state-dependent disagreement that defeats a simple repeatability claim. One sample's unique anchors align to original001f2000with8differences; no unique-anchor alignment found for the second. No cause is established and no bytes are reconstructed.

Owner replied yes to voltage remaining1.7–2.0V during the initial ID/two-pass test; exact min/max and mechanical stability were not separately supplied. Voltage monitoring was requested again for targeted follow-up, without a separate numeric report. Supply transients remain unmeasured. Private originals and7original programmer logs are preserved; public logs are generated through normal redaction preparation. No array-write/erase command was issued; no OTP/protection command or full read was selected.

**Next recommended control:** stop reads and preserve the current new-clip setup/result. When ready to change, shut down/unplug Pi, return to the intact short clip on the sameU1, verify assembly/mapping and refreshed loaded supply/isolation/ownership, then repeat the exact independent4KiB test. This distinguishes a clip-dependent result from shared transaction/address/software behavior without presuming either clip accurate. That swap/control has not been performed. [Measurements, timings, sample/log hashes and independent comparisons](acquisition-evidence/20261027-Pi5-New40cmA-U1-validation.json).

### Clock/noise explanation and refinement before more physical changes

Read-only inspection now confirms live RP1SPI0 uses `dw_spi_mmio` with200MHz `clk_sys`. **50kHz is not the lowest rate of this controller family.** RPi rpi-6.12.y DesignWare code caps an even divider at65534, corresponding to about3.05kHz at200MHz. That is a family/source-derived estimate, not verification of installed Ubuntu7.0.0-1020binary limits or an actual waveform.25/10kHz are possible diagnostic requests; neither was executed here. Kernel spidev documentation cautions that requested speed is not a measurement of actual bitrate.

Lower rate gives settling/setup time; it does not automatically increase signal voltage or tame each fast GPIO edge. Ringing, wrong thresholds, board loading/contention and supply transients can still cause systematic errors. Faster transfers reduce time under observation but have less timing margin. Ideal32MiB payload times at100/50/25/10kHz are about45/89/179/447minutes per read, before overhead; short diagnostic blocks remain practical.

Continuity and repeated pair equality are useful but not certificates of byte accuracy or clean waveforms. Current strongest evidence is differing reads of the sameU1address without an array-write command, including read-size dependence. An old-reference mismatch alone can reflect changed contents or unresolved bank identity. Current goal is a trustworthy read path/address interpretation before recovery writes.

Upstreamflashrom1.6 `linux_spi.c` configures mode0/eight-bit and combines command/read phases in `SPI_IOC_MESSAGE(2)`. Its MT25QU256 feature macro includes native4-byte read support, and `spi_nbyte_read` chooses that when supported by programmer; a generic3/4byte-mode mistake is therefore not established. Source review neither proves exact installed binary equivalence nor identifies a defect. Actual command/chip-select/chunk/address behavior merits independent validation.

**Refinement:** leave the current physical assembly alone while completing that audit, then select one independent same-address small-block transaction control and controlled clock comparison. This precedes another clip swap; the earlier short-clip reversal remains an available control afterward. No new SPI access, clock setting, firmware or GPIO mutation occurred during this review. [Live clock inventory, source hashes, hypotheses and limits](acquisition-evidence/20261027-Pi5-clock-and-read-path-review.json).

### Short-clip return and independent transaction control — October 27, 18:19–18:22 EDT

The owner returned to the intact short clip on C8375-A/FDO2742M0FK/U1 before this test, reporting loaded P1 **1.769 VDC**. Fresh confirmation covers router power/all other cables/CR2032 disconnected, CH341A removed, eight mapped connections checked and no competing programmer. The owner subsequently confirms voltage stayed within1.7–2.0V and nothing moved; no numeric min/max supplied.

At **001f2000–001f2fff**, flashrom identification passes20BB19. Two100kHz reads match each other but differ from the saved original at15bytes: first11bytes and fourbytes in the final five-byte transaction. Two50kHz reads also match each other but differ from the original at3688bytes. The installed4096-byte kernel buffer yields4091+5byte flashrom data chunks; this motivates a transaction-boundary control, without proving a software defect.

AI-assisted original [`pi_u1_direct_read.py`](../scripts/pi_u1_direct_read.py) uses Linux/Python standard library, `pgrep` and sudo for opening `/dev/spidev0.0`; it drops privileges afterward. Import/default/help perform no hardware action; only explicit `--read` executes the fixed diagnostic. RDID0x9f and native four-byte READ0x13 are its only flash opcodes. Eight512-byte chunks each combine command/address/data in one full-duplex `SPI_IOC_MESSAGE(1)`. No flash reset, register, protection, program, erase or OTP command is sent. The deployed source SHA256 is recorded in the evidence; it was verified before execution. This is an experimental diagnostic, not a proven replacement acquisition tool, and should not be rerun automatically.

At requested100kHz its ID passes, but the two4096-byte samples differ at**928bytes**, and respectively3224/3695from the saved original. At requested10kHz ID returns**001319**, so the guard stops with exit1 before any10kHz data sample. A requested rate is not a measurement of actual clock. Independent read failure means the evidence does not isolate flashrom's transaction splitting as the cause; controller/driver, electrical translation, loading/contention and contact-path effects remain unresolved.

All six4096-byte samples, reports and logs are retained on Pi and privately imported locally, with sizes/SHA256 independently verified. Five original flashrom logs are retained for generated sanitization. No active flashrom/direct-reader process remains. Offline standard-library tests pass**22tests**, including four direct-reader packet, chunk, safe-entry and Linux-structure checks; those do not establish hardware accuracy. No full capture or array-write command was selected. **Stop unchanged retries; preserve the assembly and review accessible waveform test points/instrumentation or independent interface controls before another hardware step.** [Hashes, commands/provenance and validation](acquisition-evidence/20261027-Pi5-ShortReturn-U1-validation.json).

### Software diagnostics without an oscilloscope — planned October 27

The owner has no scope/analyzer or alternate interface. Read-only SSH confirms the running kernel has a matching `spi-gpio` module available; `gpiod` and `python3-libgpiod` are available from Ubuntu at2.2.1-3build1 but uninstalled. No package/module/pin configuration or SPI operation was performed at this checkpoint. Software can compare known digital data and bypass a controller; it cannot measure analog voltage margins, ringing or supply transients.

Offline bit comparison finds all six recent4KiB samples only lose one bits relative to the saved original: flashrom100kHz29lost bits per sample,50kHz8343, direct100kHz7302/8387; no added ones. Zero bit shift gives best alignment among±8bits. This suggests investigating high-level loss/masking, but current contents and the physical cause remain unresolved. Do not manufacture corrected bytes from this observation.

1. **Pi-only loopback first:** shut down/unplug Pi, remove every adapter/router connection from its GPIO header including supply, retain router isolation, and use one ordinary lead from physical19/MOSI to21/MISO. Leave clip seated if desired. Reconfirm physical isolation before any powered test. Known patterns and several transfer lengths/rates test the Pi transmit/receive path. A pass does not test chip select or loaded interface behavior.
2. **Adapter-only loopback if first passes:** Pi-off changes; router harness disconnected from adapter output. Reconnect the already checked adapter input harness and supply; after verifying endpoints, loop OUTPUT5/MOSI toOUTPUT2/MISO. This tests forward/return translation without the router, under light load only.
3. **Software-generated SPI control if both pass:** first prepare and offline-check reversible kernel/GPIO ownership/mapping, inactive chip select and guarded read-only script. After fresh physical/voltage checks, use the translated U1 harness for identification and bounded reads with explicit settling intervals. This bypasses the dedicated RP1 SPI engine/driver; software timing is variable and success is not guaranteed.

These tests are **planned, not executed**. A loopback failure directs investigation upstream of the router; passing isolated tests followed by in-circuit failure points toward load/selection/control interactions without establishing a faulty clip. Do not join Pi3.3V GPIO directly to the1.8V flash. [Detailed test record and primary sources](acquisition-evidence/20261027-Pi5-software-diagnostic-next-steps.json).

### Pi-only loopback completed — October 27, America/New_York

Owner confirms Pi shut down/power unplugged, all Dupont cables removed, physical19→21jumper fitted, then Pi powered. No adapter/router lead remains on the header. Key-only SSH verifies expected host/kernel/SPI node and no active programmer. AI-assisted original [`pi_spi_loopback.py`](../scripts/pi_spi_loopback.py) is deployed with the SHA-verified direct-reader module, imported only for controller transfer support. It needs Linux/Python standard library, `pgrep` and sudo to openSPI; drops privileges for reporting. Import/default/help open no hardware; explicit `--isolated-loopback` is mandatory. **Arbitrary patterns are sent: never execute this utility with a flash chip connected.**

The fixed mode0/eight-bit full-duplex matrix passes **144/144 transfers,166,644 compared bytes,zero byte/bit differences**. Requested rates100/50/10kHz each have48transfers: zeros,ones,55,AA,ramp,seeded pseudorandom; lengths4/17/517/4091;two passes. Every TX/RX SHA pair independently checked from the fetched report. Requested rate is not waveform measurement. No loopback/flashrom process remains. Offline suite passes26tests, including four new loopback tests. No packages, boot configuration or pinmux changed; SPI controller mode/rate settings used only for the test. Router not probed/read/written.

**Next planned:** Pi shutdown/unplug; remove19→21jumper; reconnect the checked adapter input mapping/supply, keep entire router output harness disconnected, verify accessible OUTPUT5/MOSI→OUTPUT2/MISO jumper and mapping before powering. A separately labeled adapter-only run will test forward/return translation under light load. This Pi-only pass does not establish chip-select, flashrom split-phase transfers, loaded waveforms, clip correctness or router readability. [Matrix, timestamps and provenance](acquisition-evidence/20261027-Pi5-isolated-loopback-result.json).

### Adapter-only loopback completed — October 27, America/New_York

Owner confirms all checked Pi→adapter INPUT connections restored and **only OUTPUT2-to5jumper** fitted; router output harness disconnected, Pi powered. No Pi19-to21jumper is part of this setup. Agent verifies expected host, SPI node and no programmer. An initial process-inventory assertion stopped before installation/SPI because its command text matched its own search; corrected stdin-based inventory finds no active process. The loopback source adds mutually exclusive explicit `--adapter-loopback` mode so report/setup and output directories distinguish this control from Pi-only testing. Default/help/import retain no hardware action. Fresh deployment hashes are checked before execution; old Pi-only deployment/report remain unchanged.

The identical mode0/eight-bit full-duplex matrix **passes144/144 transfers,166,644bytes,zero differing bytes/bits** at requested100/50/10kHz. Each rate covers six patterns and four lengths twice. All TX/RX hashes independently verified from fetched report; no programmer/loopback process remains. Offline suite passes27tests, including an additional explicit-mode routing/exclusivity regression. No router probe/read/write, package installation or boot configuration change.

This checks outgoing/returning MOSI/MISO translation under loopback load. It does not establish translated clock/chip-select behavior, analog margins, clip/router loading, or flashrom split-phase behavior. Both isolated controls now pass; no faulty clip or controller is proved. **Next: keep this adapter-only setup unchanged and prepare a GPIO software control, checking it on the loopback before reconnecting U1.** Later router reconnection requires Pi-off changes and fresh target/isolation/mapping/loaded-voltage confirmation. [Full matrix/provenance](acquisition-evidence/20261027-Pi5-adapter-loopback-result.json).

### GPIO software adapter-only control completed — October 27, America/New_York

With the same owner-confirmed adapter-only loopback unchanged, agent installs Ubuntu `gpiod`, `libgpiod3` and `python3-libgpiod`2.2.1-3build1 (three new packages, no upgrades/removals). Python binding reports2.2.0. Read-only line inventory verifies `/dev/gpiochip0` label`pinctrl-rp1`,54lines, GPIO8/9/10/11 names; GPIO8 consumer`spi0 CS0`. SPI0 is`1f00050000.spi` under`dw_spi_mmio`.

AI-assisted original [`pi_gpio_loopback.py`](../scripts/pi_gpio_loopback.py) uses Python/libgpiod v2 and sibling loopback/direct-reader modules; needs sudo for temporary driver/GPIO ownership. Only explicit `--adapter-loopback` acts; import/default/help have no hardware side effects or gpiod requirement. Runtime validates controller/driver/line identity, temporarily unbinds only SPI0, requests CS8initialhigh/MISO9input/MOSI10low/CLK11low, sends arbitrary patterns in software mode0/MSB-first with200µs waits before rising clock/after rising clock/after falling clock, deselects in transfer cleanup, releases GPIO and rebinds SPI0 in outer cleanup. **Never use this loopback utility with a flash/router attached.**

All12transfers (six64-byte patterns twice) **pass:768bytes,zero differing bytes/bits**. Independently fetched report equals execution output and all TX/RX hashes match. Normal`dw_spi_mmio` binding and`/dev/spidev0.0` are restored and independently checked; no programmer process remains.30offline tests pass, including three GPIO protocol/cleanup/entry regressions. Runtime exercised successful driver restoration; offline tests do not exhaust every driver-failure case. Phase waits are requested delays, not measured clock; Linux/GPIO overhead and scheduling apply. No boot configuration, router access, firmware write or full capture.

Both isolated controls pass under light load; neither establishes translated clock/select waveforms or loaded clip/router behavior. **Next: Pi-off remove OUTPUT2↔5 jumper, reconnect checked same-U1 harness, refresh target/isolation/mapping/ownership and P1loaded voltage before software-generated read-only ID/bounded samples.** That router control is not yet executed. [Report, package/mapping and source provenance](acquisition-evidence/20261027-Pi5-GPIO-adapter-loopback-result.json).

### GPIO U1 bounded read prepared — October 27, America/New_York

Owner reports short clip returned to U1 with Pi powered and loaded P1 **1.770VDC**. The grouped fresh chassis/serial/U1, OUTPUT2-to5jumper removal, eight-path mapping, router/CH341A/power/cable/CR2032 isolation, exclusive programmer ownership and voltage-watch confirmation is requested and pending. No hardware access before that confirmation.

AI-assisted original [`pi_gpio_u1_read.py`](../scripts/pi_gpio_u1_read.py) uses Python/libgpiod v2 plus three sibling modules. Only explicit`--read` opens GPIO. The factored`run_hardware` helper retains the prior validated controller/line guards, temporary SPI0 driver release, initial inactiveCS/lowCLK, GPIO mode0/MSB-first with200µs phase waits, deselection/release and driver-restoration cleanup. The reader sends **only0x9fRDID and0x13native four-byte READ**. Each pass checks20BB19 first, then reads **001f2000–001f2fff** in eight512-byte data chunks. Bad/incomplete ID stops without force/retry; incomplete read stops. Two fresh4096-byte mode0600/user-owned samples are created exclusively; report contains sizes/SHA256/byte-difference addresses without binary contents. No write/reset/register/protection/OTP command or full capture is selected.

**34offline tests pass**, including four new reader tests for native address/chunk/pair shape, bad-ID stop, mismatch offsets/original preservation/private modes and safe default/help. Existing software clock/sample-order and transfer-failure deselection tests remain. A fresh Pi deployment is SHA-verified and help passes; read-only SSH sees expected host/SPI0node/driver and no competing programmer. **No GPIO/SPI acquisition is executed yet.** The next action after physical confirmation is the guarded small read, followed by private import and independent comparison. Small-block equality alone cannot establish full backup/bank/accuracy. [Prepared deployment, checks and limits](acquisition-evidence/20261027-Pi5-GPIO-U1-short-read.json).

### GPIO U1 result and exact AND relation — October 27,19:22:35–19:23:27EDT

Owner replies“yes,move forward” to the full fresh physical confirmation. Last loaded P1 is1.770VDC. Agent verifies deployed source hashes/current host/driver/node/no competing programmer, then executes guarded GPIO`--read` once. Both passes identify20BB19 and read001f2000–001f2fff. Two4096-byte samples are identical, SHA256**09327df0f66e6745229cc1681f50c8c301177615f7615abbabee8762f7c55171**. Driver cleanup succeeds; key-only SSH independently verifies normal`dw_spi_mmio`,spidev0.0 and no programmer. Original samples/report are privately imported and sizes/hashes/byte comparisons independently checked. During-test voltage/movement/warmth observations requested, response pending; no continuous numeric range is established.

The matching result differs **3687bytes/8343lost-onebits from the saved original**, and **3638bytes/7933lost-onebits from known nonbooting**, with zero added ones against either. It matches the previous flashrom50kHz first4091bytes; only the finalfivebytes differ. Slow GPIO control therefore reproduces the broad discrepancy without the SPI engine; no controller-only fix is established.

**New verified relation:** for every one of4096addresses, `GPIO_byte = original_byte & known_nonbooting_byte`. Computed AND SHA256 equals the observed sample SHA256,zero differing bytes. The full original reference is independently rehashed72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107; known-nonbooting reference68c6951158b146645bfb7767489010ed6b6f3314d00b4f13b226d0440f5fe88b. This calculation is an offline diagnostic only: no reconstructed/corrected flash artifact is saved and no physical chip/bank is assigned either image.

This exact relation raises **selection/shared-data-line interaction** as a specific hypothesis. Historical October25U2clip-to-bareU1 measurements found MISO0.8Ω and CS9,360Ω; those are historical unpowered endpoints, not current select-state/wiring proof. Simultaneous push-pull outputs do not have a guaranteed logical-AND truth table; electrical contention is not proved by file arithmetic alone. Actual stored contents, selection and other common-path effects still need independent checks. Micron specifies S#HIGH tri-states output and S#LOW enables the chip ([datasheet signal descriptions,p14](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf)).

**Next:** stop unchanged reads/clock/clip sweeps; assess whether exposed U2physicalpin7/CS can be safely reached without disturbing U1clip or adjacent pins. Access is requested, no probing/jumper yet. If accessible, define current U2supply/select checks before further SPI. No under-clip measurement, speculative control jumper, voltage increase, full capture or array write selected. [Runtime/source hashes, comparisons and exact AND validation](acquisition-evidence/20261027-Pi5-GPIO-U1-short-read.json).

### U2 idle S# measurement — October 27, America/New_York

Owner confirms bareU2pin7 access is possible but tricky, with U1clip untouched. Agent performs read-only SSH/process and`pinctrl get8-11`: no programmer, normalSPI0driver/node, GPIO8outputhigh/pullup,GPIO9–11SPI0. No SPI command or pin setting changed. After instructed idle DCV measurement (blackP1pin2/GND,redactualU2physicalpin7), owner reports **0.33–0.35VDC**. Steady single-leg contact is acceptable; duration is not a required limit. Do not bridge adjacent legs. During-read voltage/movement/warmth observations from the prior GPIO capture remain separately pending.

Micron Table47,p82 specifies VILmax0.3×VCC/VIHmin0.7×VCC; Table43,p80 operatingVCC1.7–2.0V. Thus **if U2 has valid operating supply**,0.33–0.35V is guaranteedlow (ceiling0.51–0.60V). Signal descriptions,p14 say highS#tri-states outputs,low enables, and a falling edge is required before a command. This idle observation supports investigating selection but does not establish U2command decoding/driving during U1read. **U2ownVCC is not yet measured**; the last P1=1.770V cannot be assumed to apply to it. Partial powering and other common-path explanations remain unresolved. [Micron datasheet](https://www.mouser.com/datasheet/2/671/mt25q_qljs_u_256_aba_0-3178731.pdf).

Next: liftredprobe; leave setup unchanged, no SPI. If safely accessible, measure DCV **redU2physicalpin2/VCC,blackP1pin2/GND**; do not disturb U1clip or use a blocked endpoint. Await reading/access report before deciding any further control. No pull-up, reset or selector jumper, voltage increase, desoldering or write selected. [Owner observation/precheck/limits](acquisition-evidence/20261027-Pi5-U2-idle-CS-measurement.json).

### U2 VCC below operating range; powered tests stopped — October27, America/New_York

Under the same instructed idle DCV setup, owner reports **U2physicalpin2/VCC=0.931VDC** relative toP1pin2/GND. This is a direct U2supply observation, separate from earlierP1=1.770V. Micron operatingVCC is1.7–2.0V. Therefore the preceding **conditional** S#logic-low interpretation at valid supply cannot be applied to U2at0.931V; normal VIH/VIL behavior is unspecified here. This supports investigating unintended partial powering/shared-line loading. It does not establish the feed path, normal operation of U2, simultaneous valid outputs or the physical cause of the exact-AND data relation. Preserve both owner readings and the earlier conditional reasoning.

Agent stops further powered SPI work, verifies no programmer over SSH, then executes`sudo shutdown -h now`; exit0 records accepted shutdown request. Pi input power unplug and residual voltage are **not yet confirmed**; shutdown acceptance alone does not establish an unpowered header/board.

Next requested: after Pi supply unplug, retain U1clip/wires and normal router power/cables/CR2032 isolation. Meter staysDCV,blackP1pin2/GND: measureP1pin1,then safely accessibleU2pin2. **Await both residual readings before Ω/continuity or wiring changes.** If residual voltage remains, do not short/discharge speculatively; record it. Future unpowered supply/net mapping can distinguish rail coupling from signal back-powering only after this state is established. No U2VCCfeed, select/reset jumper, raised adapter voltage, router normal power, new SPI or firmware write selected. [Meter observations and shutdown evidence](acquisition-evidence/20261027-Pi5-U2-idle-CS-measurement.json).

## 4. Preserve full backups before considering recovery writes

After repeatable, plausible bounded reads, take two fresh independent **33,554,432-byte** full reads for the identified chip, compare bytes/hashes and retain both originals privately. Review plausibility and comparisons with historical references; matching captures alone do not exclude systematic read errors. Acquire and label U1 and U2 separately. A U1 result cannot certify U2.

Only after stable full backups and physical bank/region analysis can a separate recovery-write decision specify the exact candidate hash, target, expected changed/preserved regions and readback verification. No write, erase, protection, OTP, fuse, TPM or provisioning change is selected now. Do not treat extracted configuration or a boot result as implied by a readable flash.

## Handoff and sources

[Active tracking plan](../ROUTER-RECOVERY-TEST-PLAN.md), [consolidated context](../C8375-G2-RECOVERY-CONTEXT.md), [detailed wiring/history](../C8375-CH341A-HEADER-WIRING.md), [Pi preparation status](acquisition-evidence/20261027-Pi5-preparation.json). Private acquisition pointers and a local resume copy are retained under `.git/recovery-private/`.

The [official Pi GPIO/SPI documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html) supports the header and logic-level checks. The [flashrom v1.8.0 manual](https://raw.githubusercontent.com/flashrom/flashrom/v1.8.0/doc/classic_cli_manpage.rst) documents `linux_spi` and `spispeed` in kHz; check the actual Pi build before use. [Ubuntu Pi boot configuration](https://ubuntu.com/hardware/docs/boards/how-to/special_hardware/rpi-config-txt/) documents configuration location and section handling. These references do not verify the owner's installed OS, adapter or new harness.
