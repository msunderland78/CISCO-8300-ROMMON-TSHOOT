# C8375-A voice NIM presence and fan speed

**November 11, 2026, 16:39–16:49 EST (America/New_York) · C8375-05/06**

The owner's observation is reproduced: removing the voice NIM lowers the three chassis fans to **5,220–5,460 RPM**; reinserting it restores roughly **9,500 RPM**. Stopping the module in software leaves the faster speed in place. The same card is restored and initialized at handoff. No quieter profile has been applied with the card installed.

## Controlled comparison

Target: **C8375-A / C8375-E-G2 / FDO2742M0FK**, P1 **PWR-CC1-400WAC / LIT2727C7NE**, NIM 0/1 **NIM-2FXS/4FXOP / FOC23152BE1**. IOS remains committed **26.1.2**, with the original development ROMMON and CPLD. Same-session owner confirmation covered the fitted chassis cover, normal power and no programmer; fresh SSH verified identity and zero active calls. A separate VTY left the owner's SecureCRT session intact. No serial port was opened.

The owner authorized temporary NIM shutdown and performed physical removal, blank fitting and reinsertion. Telephone cables were requested disconnected during reseating; their individual attachment state was not separately reported. The chassis remained powered throughout.

| State | Controller samples | Three chassis fans, raw RPM | Observed table field |
| --- | ---: | ---: | ---: |
| Installed and running | 3 | 9,540–9,600 | 1 |
| Software stopped; power off but physically present | 5 | 9,480–9,660 | 1 |
| Removed, after settling; owner confirms blank fitted | 4 | 5,220–5,460 | 2 |
| Same NIM reinserted and running | 4 | 9,420–9,660 | 1 |

At **16:40:38.619**, `hw-module subslot 0/1 stop force` succeeded. `show platform software iomd 0/1 oir` explicitly reported **Power: Off / Present: Yes**. The fans remained fast across five samples. Absence was first captured at **16:43:11.361**. The first subsequent controller frame already had table 2 while RPM was still high; this transition is retained in the results and excluded only from the clearly labeled settled range above. At 16:43:38, raw readings had fallen to 5,400/5,340/5,220 RPM while the environmental CLI still showed cached high readings. Later CLI samples caught up.

Reinsertion was observed by 16:45:39.838. The owner reported audible acceleration within seconds. Table 1 and high RPM returned without an explicit start command. All 17 frames show temperature level 0 and zero host/controller override fields. CPU rose from 34°C to 37°C during the module-out interval and returned to 34°C after reinsertion. All displayed environmental sensor states remained Normal. The PSU fan also decreased to 4,672 RPM with the NIM out and returned to about 6,080 RPM after reinsertion.

**Inference:** physical NIM presence selects or triggers the faster cooling policy in this setup; NIM activity and traffic load are not required for it. This is stronger than the earlier untested voice-module hypothesis. It does not establish whether the policy distinguishes this voice model from every other NIM, or reveal the complete policy implementation.

The controller field mapping reuses prior vendor accessor analysis and validates independent fan identity/byte-order anchors on every dump. The running 26.1.2 driver was not independently hash matched, so these interpreted fields are not a validated write interface.

**Later November 11 follow-up:** the [exact installed 26.1.2 package analysis](../fan-profile-research-20261111/README.md) now confirms these selected offsets. Raw dump callbacks also omit each 4 KiB block's final byte; all fields and identity anchors used here precede the first boundary and remain correctly positioned. This closes the cross-version offset limitation, not the missing write-interface semantics or a live module-memory integrity check.

## Restoration and other findings

- Same NIM serial restored; IOMD ready, power on/present/OK, DM8147 DSP **UP**, firmware **66.1.0**, six signaling channels. Two FXS and four FXO ports are admin up, dormant/on-hook; **no DSP errors**. Actual calls and performance testing remain deferred to the owner.
- R0/F0 and built-in 0/0 remain ready; P1 and fan tray are OK. Management is 1 Gb/s up/up with zero input/output errors. Empty P0 remains the only critical facility alarm.
- **NTP is now synchronized**, stratum 3, normal CTRL loop, reference 192.168.3.10. This supersedes the earlier settling observation without a configuration change.
- A second **Marvell CGX port 0:2 command 11 timeout** appeared at **16:45:13.548**, during reinsertion, before NIM online/DSP up. The startup event at 16:16:43.212 remains in the log. No further event appeared through the final query at about 16:49. This corrects any ongoing interpretation of the earlier event as startup-only; neither cause nor functional impact is established by this comparison.
- Both running and startup configurations are unchanged across the two captures each. No chassis reboot, saved configuration, firmware, fan-register/PWM or thermal-policy change. Agent SSH closed normally; the post-close socket inventory shows only owner SecureCRT connected to the router.

## Quieter home-lab profile investigation

The owner accepts a slower profile for home-lab use and expects traffic far below rated capacity. A reversible adjustment remains a valid research objective; lack of a supported knob does not rule out an undocumented method.

Current IOS help exposes only EEPROM/status beneath the fan show branch and **fault generation** beneath the R0/P2 fan test branch. Chassis-manager slot tests offer init/remove. No speed setting was found in those inspected branches, and no fault was injected. Revisited vendor evidence exposes read-only fan-table/override diagnostic nodes and generic PWM setter wrappers, but no established Crestone actuator or understood override handshake. Cisco's [environmental monitoring guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_01100.html) documents status monitoring; it does not supply the missing profile transaction.

**Unresolved:** how to request a lower idle profile while retaining temperature response. Next technical work is to match the current controller access implementation, identify the exact transaction and rollback, and determine thermal behavior before a bounded trial. Merely writing the observed table value would assume those semantics. Software stop is not an effective noise workaround; physical removal with a blank produced the lower-speed state but makes the voice NIM unavailable.

## Evidence and scope

[Structured results and hashes](results.json) · [sanitized command selection](../../sanitized-evidence/c8375-recovery/fan-nim-comparison-20261111/selected-session.log) · [earlier health check](../health-20261111/README.md) · [historical controller research](../acquisition-evidence/20261031-C8375-fan-fix.json)

The sequence follows Cisco's [NIM online insertion/removal procedure](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/hardware_installation-guide/secure-8300-series-hig/oir-8300-series-secure-routers/online-insertion-and-removal-and-hot-swapping.html). Full raw capture, configurations and authored capture/collation helpers remain local under `.git/recovery-private/c8375-fan-nim-20261111/`; originals are preserved. Public selection omits configurations/raw controller dumps and removes terminal line-erasure artifacts. Invalid CLI attempts remain recorded. Known-value and pattern checks cannot prove every unknown secret absent. This short comparison is not a 45-minute fan qualification, module-absent cold boot, forwarding test or voice-call test.
