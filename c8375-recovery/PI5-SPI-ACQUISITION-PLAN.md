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

## 4. Preserve full backups before considering recovery writes

After repeatable, plausible bounded reads, take two fresh independent **33,554,432-byte** full reads for the identified chip, compare bytes/hashes and retain both originals privately. Review plausibility and comparisons with historical references; matching captures alone do not exclude systematic read errors. Acquire and label U1 and U2 separately. A U1 result cannot certify U2.

Only after stable full backups and physical bank/region analysis can a separate recovery-write decision specify the exact candidate hash, target, expected changed/preserved regions and readback verification. No write, erase, protection, OTP, fuse, TPM or provisioning change is selected now. Do not treat extracted configuration or a boot result as implied by a readable flash.

## Handoff and sources

[Active tracking plan](../ROUTER-RECOVERY-TEST-PLAN.md), [consolidated context](../C8375-G2-RECOVERY-CONTEXT.md), [detailed wiring/history](../C8375-CH341A-HEADER-WIRING.md), [Pi preparation status](acquisition-evidence/20261027-Pi5-preparation.json). Private acquisition pointers and a local resume copy are retained under `.git/recovery-private/`.

The [official Pi GPIO/SPI documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html) supports the header and logic-level checks. The [flashrom v1.8.0 manual](https://raw.githubusercontent.com/flashrom/flashrom/v1.8.0/doc/classic_cli_manpage.rst) documents `linux_spi` and `spispeed` in kHz; check the actual Pi build before use. [Ubuntu Pi boot configuration](https://ubuntu.com/hardware/docs/boards/how-to/special_hardware/rpi-config-txt/) documents configuration location and section handling. These references do not verify the owner's installed OS, adapter or new harness.
