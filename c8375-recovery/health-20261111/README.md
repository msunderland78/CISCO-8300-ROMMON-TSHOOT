# C8375-A health check with the 400 W supply — November 11, 2026

**Basic system health and voice-module initialization pass this short check.** The previous unsupported/powered-off NIM condition is absent. Performance, actual calls and extended stability remain untested and are deferred to the owner at their request.

Tasks **C8375-05 / C8375-06**. Host-dated commands span **16:28:08–16:31:56 EST, America/New_York (227.244 seconds)**, including a host-service interruption and final reconnect. This was a series of snapshots, not uninterrupted monitoring. [Structured results, exact commands and hashes](results.json); [generated sanitized capture](../../sanitized-evidence/c8375-recovery/health-20261111/selected-session.log).

## Identity and conditions

The owner confirmed C8375-A / **C8375-E-G2 / FDO2742M0FK**, the installed new 400 W supply, fitted cover and no programmer. Their broad confirmation did not separately specify battery or telephone-line connections. Only a separate SSH VTY at **192.168.4.62:22** was used; no physical or serial-port operation occurred. The existing owner SecureCRT/admin VTY was preserved. The replacement and cold boot preceded this capture; AC-disconnection procedure and full startup were not independently observed.

IOS XE remains **26.01.02 / committed IMG C 26.01.02.0.3639**, Autonomous, `bootflash:packages.conf`, confreg `0x1822`. Reported original SDK112308 / SoC2 v9.2.1 development ROMMON and CPLD `2408272B` remain. Last reload is **PowerOn** and final IOS uptime is 16 minutes. No reboot, configuration/save, firmware, module restart, support override or fan-control write was issued.

## Observations

| Check | Observed result |
| --- | --- |
| Power | **P1 PWR-CC1-400WAC/V01/LIT2727C7NE: ok**; 400 W available; `show power` Normal and chasfs `pf/oper-mode` now `normal` |
| Voice card | Same **NIM-2FXS/4FXOP/V01/FOC23152BE1** in 0/1: **ok**, 6 W reported; service engine up/up |
| DSP and ports | **DM8147 UP**, firmware 66.1.0; six signaling channels allocated; two FXS and four FXO ports admin up, dormant/on-hook; no DSP errors, no active calls |
| Base platform | 0/0, R0, F0 and fan tray ok; control processor Healthy; RAM 62% used / 38% free; QFP processing load 0% under light load |
| Temperatures/rails | All displayed sensor states Normal; CPU **33–34°C**, inlets **23–24°C**, outlets **24–27°C**; board 12 V **11.957–11.965 V** |
| PSU telemetry | About **47 W input / 37–38 W output**, 26–31°C; these are reported sensor values, not meter measurements |
| Fans | Chassis CLI samples **9,480–9,660 RPM**, PSU fan **6,112–6,144 RPM**. Three controller snapshots corroborate the chassis range. Owner reports fast steady fans with no old cycling |
| Management | GigabitEthernet0 up/up, full duplex 1 Gbps, zero input/CRC/output errors and drops; gateway 192.168.4.1 and remote management host 192.168.3.10 each answer **20/20** pings, maximum 4 ms |
| Data ports | All six administratively down. No data-port forwarding, throughput or load test |
| Processes/storage | CPP PID24738/session23720 and IOMD PIDs917/27504/28117 unchanged; no new or changed core payload entries. One-byte `.callhome` marker timestamp changed. Final free bootflash **9,814,302,720 bytes** |
| Licensing | Current advantage entitlement **AUTHORIZED**; startup out-of-compliance messages are followed by in-compliance and report acknowledgements |

The new power identity and restored mode property, together with successful initialization of the same card on the same IOS build, strongly support PSU compatibility as the earlier blocker. This resolves the **observed initialization failure**, without establishing voice-call quality or production-firmware compatibility. Cisco lists this PSU for C8375-E-G2 and the P-suffix card from 26.1 Routing (CLI) mode. [PSU guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/hardware_installation-guide/secure-8300-series-hig/install-fru-8300-series-secure-routers/remove-and-replace-the-power-supplies.html), [router datasheet](https://www.cisco.com/site/us/en/products/collateral/networking/sdwan-routers/8000-secure-routers/8300-series-secure-routers-ds.html).

## Remaining observations and limits

- **One active critical alarm identifies empty P0**, not failure of the healthy P1 supply. Configured redundant power has only one installed supply, so actual power redundancy is unavailable. Informational PoE-module/disabled-port/absent-transceiver entries are retained.
- **NTP is still unsynchronized**, with a selected reachable peer (reach377), offset about 1.74 ms and loopfilter `FREQ`/drift measurement. Recheck synchronization after settling; no time configuration was changed. Incorrect January2025 early-boot timestamps are not the work date.
- The startup log contains **one Marvell-CGX-RPM port0:2 command11 timeout at 16:16:43.212 EST**. Its count stays one across three log snapshots. It did not recur during this short check, but the affected data-path significance remains unresolved because ports are disabled and untested. Eight `Ipv6NoRoute` QFP drops stay unchanged.
- No old large fan oscillation appears in these snapshots and the owner reports it stopped. This does **not** complete the planned 45-minute watch. Historical field decoding with independent fan-identity anchors reports N2H table1/temperature level0/override0, versus historical table2; the current 26.1.2 driver was not hash-matched. The cause of the higher steady speed is not isolated to the voice card. No fan-speed change is selected. Cisco documents periodic environmental updates, so CLI snapshots alone can miss short excursions. [Environmental monitoring guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/isr9000swcfg-xe-16-12-book_chapter_01100.html).
- Three captures each of running and startup configuration are **unchanged during today's check**. Across visits, running gains voice/service-engine defaults; startup serialization differs from November7 (version26.2→26.1, explicit insecure-mode/default/proxy-ARP/NTP lines). Therefore a byte-identical cross-visit configuration experiment is **not claimed**. Existing development/security state was not modified or certified.
- FXS/FXO electrical signaling, ringing, dialing, audio and calls remain untested. The owner explicitly reserved all performance and voice-card functional tests for later. Independent U1 acquisition and broader prototype qualification remain separate.

## Evidence and handoff

Original SSH byte captures and configurations remain restricted in `.git/recovery-private/c8375-health-20261111/`. The temporary AI-assisted Python helper uses the standard library, installed `sshpass` and existing private credentials, and connects only through its explicit main entry point. The offline collation helper has no router side effects. Neither changes publication tooling. Failed/incomplete diagnostic CLI attempts are retained in the command record; none supplies a successful diagnostic result.

The initial identity session exited on stdin EOF. The main session ended when the host service restarted; a fresh process/socket inventory showed only the owner's connection before the final bounded reconnect. The final helper exited normally after its last command at 16:31:56; a 16:32:30 host check confirmed only the owner's SecureCRT socket remained. Router left powered and assembled. Full raw captures are not published; the selected sanitized text omits configuration bodies and raw controller dumps. Known-value/pattern checks cannot prove absence of every unknown secret.

Next: owner-led performance/voice tests when convenient; recheck NTP and retain the startup controller timeout for that data-port test. No additional hardware intervention is selected by this check.
