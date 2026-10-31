# Cisco 8200 and 8300 ROMMON Recovery Research

[![Repository checks](https://github.com/msunderland78/CISCO-8300-ROMMON-TSHOOT/actions/workflows/repository-check.yml/badge.svg)](https://github.com/msunderland78/CISCO-8300-ROMMON-TSHOOT/actions/workflows/repository-check.yml)

A working recovery journal for five nonworking Cisco routers: **three C8235-G2s, one C8375-G2 / C8375-E-G2, and one C8300-1N1S**. It brings together troubleshooting plans, board photographs, console evidence, extracted ROMMON firmware, verified flash backups, and Python tools that make the work reproducible.

The repository name mentions 8300; the project covers **both 8200 and 8300 work**. Some examined units show development firmware or preproduction characteristics, so results must be tied to the actual chassis and board revision.

**Start with the [active test plan and tracking log](ROUTER-RECOVERY-TEST-PLAN.md).** It contains task checklists, measurement tables, decision points, and session templates. This repository records an ongoing investigation; it does not yet document a completed recovery of these five routers.

## Current recovery status

The fleet overview retains dated hardware baselines; **C8375-A flash acquisition was updated October 31, 2026 (America/New_York)**. Check the active plan and current contexts for the latest fixture and results. Acquisition tests do not establish successful router boot.

| Device | What we know | Next evidence needed |
| --- | --- | --- |
| C8235-A: worked Arata unit | Console ID `FGL2835L42B`; newer firmware reaches a TPM manufacturing-status halt before Cisco ROMMON. No complete original primary development-flash backup is available. | Separate reads of both flash chips; identify surviving development code and physical bank routing |
| C8235-B: other assembled unit | `FGL2835LBHU`, Arata r2, development ROMMON retained. Installed 17.18.3a and verified USB 26.2.1 reach CLI, then `cpp_cp_svr` fails with rc139 and F0 goes offline. 26.2.1 subsequently reloads after 300 seconds of missed keepalives. Maintenance Linux archived/verified and removed 59 reports, leaving about 10.6 GB available; the cleaned USB retest still failed with CPP rc139/F0 offline and reload while about 9.5 GB remained free. It is now stopped at ROMMON. Two matching read-only snapshots of one logical SPI device are preserved on USB; physical bank mapping remains unresolved. | Inspect the preserved fresh system report and initialization evidence; map and back up both physical flash chips |
| C8235-C: disassembled unit | User confirms this remaining unit is taken apart; serial is pending. Earlier C8235 measurements were on another replica, rather than the primary-flashed unit. | Bind measurements to its actual serial and preserve both flash banks |
| C8375-A: Crestone unit | Chassis `FDO2742M0FK`; no normal startup after the ROMMON experiment. Original snapshot retained; October31 two full physical U2reads exactly match the failed-update image, using unused U1RESET inhibit without board rework. | Restore the exact same-chassis original to identified U2, verify full readback, then cold-boot test; independent U1acquisition remains pending |
| C8300-A | Reported steady red STATUS with green power/fan indications and no console through either connection type. Full PID suffix and serial are pending. | Validate each console path separately, then inspect hardware and identify boot storage if still silent |

The labels above are tracking IDs, not proof that a physical chassis has been labeled. A quiet console, an LED, or a matching flash readback alone does not establish the failing component or successful recovery.

## What the work has established

- Extracted canonical **SoC1 and SoC2 ROMMON packages, raw images, and update capsules** from IOS-XE, retaining vendor checksums and extraction metadata.
- Documented the worked C8235's development firmware, release-firmware TPM halt, board components, uncertain header/mux connections, and unsuccessful recovery-transfer experiments.
- On October 25, reproduced C8235-A's pre-ROMMON TPM halt and booted separately identified C8235-B from USB into **26.2.1**. Both 17.18.3a and 26.2.1 on B subsequently reported critical `cpp_cp_svr` rc139 failures. Full bootflash and other warnings are recorded; the root cause is unresolved. See the [dated results and captures](ROUTER-RECOVERY-TEST-PLAN.md#c8235-01--record-an-independent-baseline-for-each-chassis).
- Previously booted the C8375 into IOS-XE INSTALL mode with documented workarounds and completed limited physical-port tests. It subsequently stopped booting after the ROMMON experiment; the earlier success is historical, not its current condition.
- Captured two identical original C8375 SPI reads before that native firmware write, investigated the updater's extra writes, and verified the later programmed state. Exact bytes matching an intended image did not make that firmware compatible with the board.
- Prepared a five-router test plan, including unpowered header mapping, 1.8 V programmer validation, read-only acquisition, original-image restoration, and C8300 console isolation.
- Added Python tooling for public evidence sanitization, file/hash manifests, publication checks, and repeatable Git synchronization.

Detailed chronology, commands, limitations, and source references are linked below. Experimental outputs remain explicitly unproven; they are not general-purpose recovery images.

## Find the right record

| Record | Use it for |
| --- | --- |
| [Active test plan](ROUTER-RECOVERY-TEST-PLAN.md) | Current priorities, five-device register, measurements, decisions, and test outcomes |
| [C8235 recovery context](C8235-G2-RECOVERY-CONTEXT.txt) | Arata hardware identity, firmware history, TPM halt, and prior investigations |
| [C8375 consolidated context](C8375-G2-RECOVERY-CONTEXT.md) | Crestone chronology, original backups, failed upgrade, and prepared restoration |
| [C8375 condensed handoff](C8375-E-G2-RECOVERY-CONTEXT.txt) | Shorter summary of the known state |
| [ROMMON extraction notes](ROMMON-extracted/README.txt) | Package contents, extraction chain, versions, and verification limits |
| [Original C8375 restore notes](c8375-recovery/restore-original-20261023/RESTORE-NOTES.txt) | Chassis-specific original-image identity and restoration prerequisites |
| [Sanitized evidence guide](sanitized-evidence/README.md) | Public log/config copies and their limitations |
| [Publication manifest](REPOSITORY-MANIFEST.json) | Included file sizes and SHA-256 hashes, plus excluded local files and reasons |
| [Agent instructions](AGENTS.md) | Working conventions for coding agents and future maintenance |

Older notes describe intermediate stages and may say that a write had not yet occurred. Read the consolidated context before using historical instructions. C8300 findings currently live in the active plan.

## Repository layout

```text
+-- README.md                         Project overview and contributor entry point
+-- AGENTS.md                         Persistent instructions for coding agents
+-- ROUTER-RECOVERY-TEST-PLAN.md       Active tasks and results
+-- *RECOVERY-CONTEXT*                Router-specific handoffs and history
+-- ROMMON-extracted/                 Canonical SoC1/SoC2 ROMMON artifacts
+-- c8375-recovery/                   Crestone backups, analyses, and evidence
+-- board-photos/                     Arata photos, inspection crops, notes
+-- Photos/                          Received programmer/adapter photos and inspection crops
+-- experimental-recovery/           Unproven firmware experiments and board data
+-- c8kg2be-*/                        Selected image listings and platform evidence
+-- research-evidence/                Reference sources and retained tools
+-- purchase-research/                Tool-selection notes, excerpts, and photos
+-- recovery-prep-20261024/           Initial bench worksheet and workspace inventory
+-- sanitized-evidence/               Generated public console/configuration copies
+-- scripts/                         Authored publication, inspection and bounded-acquisition tools
+-- tests/                           Offline utility regression tests; no router access
+-- .githooks/                       Local pre-commit/pre-push guards
+-- .github/workflows/               GitHub checks
+-- REPOSITORY-MANIFEST.json          Generated selection and content hashes
+```

Some historical paths refer to ignored local originals. For a published console/config copy, look under `sanitized-evidence/` followed by the same relative path. A public clone does not contain every file from the original workstation.

## Get started without connecting a router

Repository utilities require **Python 3 and Git** and use Python's standard library. Publishing additionally requires write access to this GitHub repository and an authenticated Git credential helper. These steps do not open a serial port or attach to a programmer.

```sh
git clone https://github.com/msunderland78/CISCO-8300-ROMMON-TSHOOT.git
cd CISCO-8300-ROMMON-TSHOOT

# Enable the repository-local guards after cloning.
python3 scripts/repository_tools.py install-hooks

# Inspect the publication tool and run its regression checks.
python3 scripts/repository_tools.py --help
python3 -m unittest discover -s tests -v
```

Read the active plan and the relevant router context before bench work. If you already work in the existing checkout, use it rather than cloning over the directory containing private originals.

### Record a recovery session

1. Match the physical chassis to its tracking ID, serial, board revision, and physical chip labels.
2. Use the existing task IDs and session template in the active plan. Record power/cable state, exact settings and endpoints, commands, units, and evidence paths.
3. Separate observations from explanations. Leave unperformed work unchecked and keep failed tests in the record.
4. Preserve original captures, photographs, and exact binary images. Give derived files distinct names and retain checksums.
5. Update the relevant context when a finding changes the next session's starting point. Then prepare, inspect, and sync the publishable evidence.

Use actual session dates and time zones; several historical router clocks were incorrect. A passing write verification is a programming result, not a boot or stability test.

## Hardware workflow

**Active C8375-A acquisition uses a Pi 5, the checked 1.8 V adapter and short SOIC-16 clip on U2.** A 10 kΩ resistor and grabber hold unused U1's dedicated RESET# pin 3 low, after separate contact, supply and reset-net qualification. This produced matching samples against a saved reference through both GPIO and hardware SPI. The [current Pi acquisition plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md) records the exact fixture and validation gates; the [older CH341A/header wiring sheet](C8375-CH341A-HEADER-WIRING.md) retains historical routing work.

The owner requires this C8375 work to keep chips and leads intact: no chip removal, leg lifting or trace cutting. The SOIC-16 clip, breadboard, resistors and grabber are now received and in use; earlier delivery expectations are historical. Current Pi work keeps the CH341A, normal router power/console/cables and CR2032 disconnected. Preserve the [original hardware photographs](Photos/README.md), and do not restart completed broad header scans.

For identified Micron RW170/MT25QU256 G2 flashes, establish **1.8 V power and compatible signal levels**, correct package orientation, control-pin handling, and board loading before acquisition. An SOIC-8 clip does not fit these SOIC-16 packages. Never guess a bank-select jumper or pinout.

C8300 unpowered board inspection is a later available task, separate from the active C8375 header work. The user confirmed its native USB console was unplugged during the silent RJ45 attempt, ruling out console priority for that attempt. Chassis-label and motherboard photographs are requested under [Photos/C8300](Photos/C8300/README.md) before choosing internal test points or identifying a boot-flash candidate.

The read-first sequence is: identify the part and physical target, obtain two matching plausible full reads, compare with saved evidence, choose a justified restoration, verify the complete readback, remove programming equipment, and capture a normal assembled boot. Preserve per-chassis identity/security data throughout. The classic C8300 uses its own diagnosis and firmware; G2 images are not substitutes.

Follow the detailed plan for electrical precautions and stop conditions. Firmware/TPM/fuse changes and hardware repair should follow observed evidence, not an assumption that all five routers share the same fault.

## Firmware and backup integrity

Canonical ROMMON artifacts are under `ROMMON-extracted/`. Vendor checksum matches and SHA-256 manifests establish file/extraction consistency; they are not independent authentication of every Cisco signature or proof of board compatibility.

The exact original C8375 main-array restore image is:

```text
Chassis: FDO2742M0FK
File: c8375-recovery/restore-original-20261023/C8375-FDO2742M0FK-ORIGINAL-SPI-32MiB.bin
Size: 33,554,432 bytes
SHA-256: 72fc3f11283783d035c8c918f79a4d1aaee800cc027fcec02d01938fa3845107
```

This is a full-chip original for that chassis, not an IOS-XE upgrade package or a generic donor image. The saved candidate and final verified release-firmware readback represent the later **nonbooting** state; do not confuse them with the original restore target. Main-array dumps do not necessarily capture separate OTP/security/configuration registers.

## Public files, private originals, and size policy

The owner requested a public repository with supplied/configured passwords removed. The publication tools remove discovered password values, configured hashes, password-prompt replies, recognizable access tokens, private keys, and credentials in URLs from generated public text copies. Original raw captures/configurations remain local and ignored.

Exact ROMMON and SPI binaries remain **byte-exact**. They are scanned against locally known passwords and recognizable credential patterns. If a binary is flagged, it stays local rather than being patched. The intermediate `after-native-flash-crc-failure.bin` contains detected credential material and is excluded; the original restore and final verified readback are separate included artifacts.

Local known-value material is stored only under `.git/recovery-private/` with restricted permissions. Authentication uses the existing credential helper; tokens do not belong in repository files or remote URLs. A fresh clone has sanitized evidence but not the workstation's original captures or known-password list. Pattern scanning cannot prove that every unknown binary security field is absent; device identifiers and other recovery evidence remain public as requested.

Every tracked file must be **smaller than 50,000,000 bytes**, the owner's project cap. `.gitignore` keeps the following local:

- Full IOS-XE images and large unpacked mono packages.
- Redundant extracted ROMMON trees already represented by canonical artifacts.
- Original raw logs/config snapshots and the credential-bearing intermediate dump.
- Raw shopping HTML, credential files, caches, and OS metadata.

The manifest lists actual inclusions and exclusions. No Git LFS, file splitting, or compressed-image workaround is used to evade the policy. Historical checksum files can still reference an intentionally excluded artifact.

## Prepare, audit, and sync

Run commands from the repository root after reviewing the files you intend to publish:

```sh
# Regenerate sanitized copies and the file/hash manifest; no commit or push.
python3 scripts/repository_tools.py prepare

# Inspect the change summary before staging/publishing.
git status --short
git diff --stat

# Prepare, stage, audit, commit if changed, and push to origin/main.
python3 scripts/repository_tools.py sync --message "Record today's recovery measurements"
```

**Sync stages all nonignored changes.** Keep unrelated edits out of a publication commit and inspect generated content when introducing a new type of evidence. Generated copies are refreshed from local sources; do not edit files in `sanitized-evidence/` or the manifest directly.

The tool expects `main` and this repository's configured `origin`. It rejects a non-fast-forward push and does not force-push or automatically merge remote work. Sync is an explicit command, not a background upload service.

Local pre-commit checks inspect staged bytes. Pre-push checks inspect new Git blobs, including content removed in a later local commit. GitHub Actions runs the regression tests and audits the published tree; it cannot access local known-password material. Install hooks explicitly after a clone, and never bypass a guard to publish a flagged original.

To inspect an existing stage or commit without syncing:

```sh
python3 scripts/repository_tools.py audit-index
python3 scripts/repository_tools.py audit-tree
```

## Python tools and AI-assisted work

| Tool | Purpose | Execution considerations |
| --- | --- | --- |
| [Repository utilities](scripts/repository_tools.py) | Sanitized copies, credential/size checks, manifest, hooks, and Git sync | Standard library; explicit CLI commands |
| [Regression tests](tests/test_repository_tools.py) | Redaction, preservation of originals, binary detection, size and sync boundaries | Offline tests with temporary fixtures; no router access |
| [Photo inspection crop utility](scripts/make_programmer_inspection_crops.py) | Reproduce documented crops/rotations of the received hardware photos while checking original hashes | Uses macOS `sips`; no hardware/network access or generated reconstruction |
| [Pi U1 short-read diagnostic](scripts/pi_u1_short_reads.py) | Two independent reads of two 64 KiB regions on C8375-A/FDO2742M0FK/U1; preserve private samples/logs and compare hashes/bytes | Python standard library, Linux `flashrom`, `sudo`, `pgrep`; only explicit `--read` opens SPI. Requires the checked Pi/1.8 V harness and router isolation in the [Pi acquisition plan](c8375-recovery/PI5-SPI-ACQUISITION-PLAN.md) |
| [Pi U1 direct-read control](scripts/pi_u1_direct_read.py) | Experimental 4 KiB read with 512-byte full-duplex transactions at requested 100/10 kHz | Linux/Python standard library, sudo, pgrep; explicit `--read` only. Hardware trial failed repeatability and stopped on invalid 10 kHz ID; see [results](c8375-recovery/acquisition-evidence/20261027-Pi5-ShortReturn-U1-validation.json). Private captures; no automatic retry |
| [Pi isolated loopback](scripts/pi_spi_loopback.py) | Known-pattern SPI control with router fully disconnected; Pi-only or adapter-only setup | Linux/Python standard library and sibling direct-reader module; explicit mutually exclusive `--isolated-loopback` / `--adapter-loopback`. Sends arbitrary bytes: never run against flash. [Pi pass](c8375-recovery/acquisition-evidence/20261027-Pi5-isolated-loopback-result.json), [adapter pass](c8375-recovery/acquisition-evidence/20261027-Pi5-adapter-loopback-result.json) |
| [GPIO adapter loopback](scripts/pi_gpio_loopback.py) | Software-generated SPI control with router disconnected; [12-transfer pass](c8375-recovery/acquisition-evidence/20261027-Pi5-GPIO-adapter-loopback-result.json) | Python/libgpiod v2 plus sibling loopback/direct modules; sudo, explicit `--adapter-loopback`; temporary SPI0 driver ownership restored afterward. Arbitrary test bytes: never run against flash |
| [GPIO U1 bounded reader](scripts/pi_gpio_u1_read.py) | Experimental two-pass 4 KiB U1 read through software-generated SPI; [result and exact AND finding](c8375-recovery/acquisition-evidence/20261027-Pi5-GPIO-U1-short-read.json) | Python/libgpiod v2 and sibling modules; sudo and explicit `--read`; ID guard, RDID/READ only, private samples, temporary SPI0 ownership cleanup; physical/voltage checks required |
| [U1 chip-select control](scripts/pi_u1_cs_hold.py) | Timed CS-only control while metering U2 select or P1 supply; [observed select response](c8375-recovery/acquisition-evidence/20261028-Pi5-U1-CS-control-U2-response.json) | Python/libgpiod v2 plus sibling GPIO/loopback/direct modules; sudo and explicit `--hold-u1-cs-low`; no clock pulses/bytes commanded; timeout/stop-file deselection and SPI0 restoration |
| [U2 reverse CS control](scripts/pi_u2_cs_hold.py) and [bounded reader](scripts/pi_gpio_u2_read.py) | Explicit U2-controlled/U1-metered check and conditional 4 KiB U2read; [preparation](c8375-recovery/acquisition-evidence/20261028-Pi5-U2-reverse-control-preparation.json) | Python/libgpiod v2 plus sibling helpers; explicit flags, checked U2physical setup; no read automatically follows control; U2capture names remain separate |
| [U2 reset-held read matrix](scripts/pi_u2_read_matrix.py) | Seven 4 KiB ranges, two chunk sizes and requested 100/500/1000 kHz, with repeatability and cross-shape checks; [verified results](c8375-recovery/acquisition-evidence/20261031-Pi5-U2-reset-read-matrix.json) | Python standard library and sibling native-reader helper; Linux SPI0, explicit `--read --u1-reset-low`, fresh physical/reset/supply checks; original samples remain private |
| [C8235 serial bridge](c8235_serial_console.py) | JSON-controlled serial logging and triggers | Opens a hardware port; historical port/log-directory defaults are embedded in the source |
| [C8375 RJ45 bridge](c8375-recovery/rj45_serial_console.py) | Serial logging, triggers, and baud switching | Optional initial baud argument; verify port ownership and settings first |
| [C8375 USB bridge](c8375-recovery/serial_console.py) | Native USB serial logging and triggers | Historical device name/log directory must be reviewed |

The legacy serial bridges use `termios` and `fcntl`, were used on macOS, and are not Windows-native utilities. They execute hardware-opening code at module scope: do not import them as a test or run them just to request help. Do not open a port already owned by another terminal application. Publication utilities are separate from hardware control.

AI-assisted work is documented through actual scripts, tests, technical notes, manifests, and Git commits. Extracted vendor code, third-party sources, and downloaded tools retain their own provenance; they are not represented as newly authored work. No license to third-party firmware or reference material is granted by its inclusion here.

## Contributing findings

For a useful report or proposed change, include the exact model/board revision, relevant task ID, reproducible test conditions, sanitized evidence, observed result, and what remains unknown. Share no passwords or private originals in issues or pull requests. Preserve the distinction between a candidate, a verified flash write, a successful boot, and sustained functional operation.

Documentation changes should validate links, claims, and the publication manifest. Tool changes should include meaningful regression coverage and pass `python3 -m unittest discover -s tests -v`. See [AGENTS.md](AGENTS.md) for the full maintenance workflow and evidence-preservation rules.
