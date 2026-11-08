# C8375 analog NIM support-check failure — November 7, 2026

Task **C8375-06**, America/New_York (EST). Live SSH observations were captured from 18:47 to 18:54; the agent connection was closed about 18:55. **The NIM remains unsupported and powered off. No functional repair or telephone-call test passed.**

## Verified target and present state

| Item | November 7 observation |
| --- | --- |
| Chassis | C8375-A, C8375-E-G2/V01, FDO2742M0FK; R0 FDO27380KFQ |
| Endpoint | SSH 192.168.4.62:22, hostname CAT8375-G2; current credentials restricted locally |
| Software | IOS XE 26.01.02 / 26.01.2 fc1, Autonomous, committed IMG C 26.01.02.0.3639, bootflash:packages.conf, confreg 0x1822 |
| Firmware | Original SDK112308 / SoC2 v9.2.1 development ROMMON; CPLD 2408272B |
| New card | Slot 0/1, **NIM-2FXS/4FXOP**, V01, FOC23152BE1, hardware 1.0, module type 3051 |
| Card state | Unsupported, present, power Off, zero enumerated voice ports, zero active call legs |
| Power | P0 empty; P1 Unknown/incompatible. Owner confirms the same PWR-CC1-250WAC remains installed; 400 W supply is in the mail |
| Other modules | 0/0, R0 and F0 remain ok; no chassis reboot during this work |

The owner confirmed the assembled, normally powered target, no programmer and no other person changing it before the module action. Phone/telephone-line connections were not specifically answered; IOS showed no voice ports or active calls. Battery and serial-cable state were not separately restated. No physical interaction or serial-port access occurred. The owner's existing admin VTY was left untouched.

This is a different, P-suffix NIM from October 31's non-P NIM-2FXS/4FXO / FOC2145106C. The previous 17.15.6 and November 2 shared-PSU handoffs are historical, superseded by these fresh observations. The owner also reports failure with this card on 26.2.1; this session did not repeat that live software comparison.

## Support and suggested commands

Cisco lists NIM-2FXS/4FXOP on C8375-E-G2 starting with 26.1 in Routing (CLI) mode. The observed PID, release and Autonomous mode satisfy those published conditions. Cisco's 55 W figure is **typical consumption with the default PSU and no modules**. It is not a maximum rating or a statement that every higher-wattage supply is compatible. [Cisco 8300 Series Secure Routers datasheet](https://www.cisco.com/site/us/en/products/collateral/networking/sdwan-routers/8000-secure-routers/8300-series-secure-routers-ds.html).

The proposed sequence cannot be entered as written in the current state:

- `voice-card 0` returns `% Incomplete command.` and leaves the session in global configuration mode.
- `voice-card 0 ?` and `controller TDM 0/1 ?` are unrecognized; global `vdsp ?` is also unrecognized.
- No `dsp services dspfarm`, `vdsp service-pool 1` or `mode voice` line was sent in the wrong CLI context.

The analog-NIM datasheet describes onboard DSP resources. Cisco's C8375 virtual-DSP guide describes an IOx/app-hosting deployment for media services. Neither source establishes the proposed pool commands as a fix for this pre-initialization rejection. [Analog NIM datasheet](https://www.cisco.com/c/en/us/products/collateral/routers/4000-series-integrated-services-routers-isr/datasheet-c78-733646.html), [C8375 virtual DSP guide](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/software-config-guide/secure-8300-series-scg/m-virtual-dsp.html).

## Controlled start and immediate failure

IOMD OIR tracing was temporarily changed from Notice to Debug. At 18:49:56.771, `hw-module subslot 0/1 stop force` was rejected because the module was already stopped/out of service. At 18:50:17.731, `hw-module subslot 0/1 start` was accepted. **The interval was 20.960 seconds, not the planned 30 seconds, and no successful stop/power-cycle occurred.** The module was already powered off for more than ten minutes; the start generated a fresh insertion/support check.

The resulting current-PID trace shows:

```text
18:50:17.748291571  In plugin analyze module_type=3051 slot=0 subslot=1
18:50:17.846050784  >>> Failed to open [/tmp/rp/chasfs/pf/oper-mode]]
18:50:17.846051413  IOMD Check >>> failed to read pf oper mode chasfs entry
18:50:17.846699991  %IOMD-3-UNSUPPORTED_MODULE ... NIM-2FXS/4FXOP ...
```

The module was then removed from service and powered off again. A complete `show platform software chasfs R0` listing contains no `pf/oper-mode` property; it reports incompatible P1 with zero recognized capacity. Current-PID VDSP-CC boot records show the same missing-property rejection. Those early-boot records carry an incorrect January 8, 2025 clock. Retained traces from other boots were not treated as new November 7 events.

## Offline corroboration and its limit

Exact vendor objects were extracted from the existing **26.2.1** mono package at SquashFS offset 4096 and disassembled using `xcrun llvm-objdump`. They were neither executed nor modified. See [object/package hashes and addresses](results.json) and [selected disassembly](offline-disassembly.txt).

In this object, the Crestone path recognizes the exact P-suffix PID and then calls a checker that reads `/tmp/rp/chasfs/pf/oper-mode`. Failure to read it returns false and takes the unsupported-module branch. The checker tests `nebs_500`; cmand obtains a power operating-mode string and publishes the same property, with normal/NEBS/DC categories. **This is a power/NEBS-mode check, not the Autonomous/SD-WAN setting.**

The exact running 26.1.2 objects were not acquired or hash matched, so this is corroboration of the runtime error, not proof of identical code in both versions. The analysis does not establish why the property producer failed on this boot. A legacy-module override was observed offline but was not enabled; it would bypass the check instead of resolving the missing state. A native shell request was refused pending secure consent-token authentication; no shell or bypass was obtained.

**Inference:** missing power-mode publication is the immediate support-check blocker. The incompatible 250 W PSU is a strong lead. Development firmware/platform initialization remains another possible contributor. There is no measured overload and no demonstrated guarantee that the 400 W replacement will fix initialization.

## Restoration and next test

Before/after running and startup configurations were independently compared from `version` through `end`; both are unchanged. OIR tracing was restored to Notice, and both OIR and IOMD levels were read back as Notice. No firmware, boot variable, saved configuration or CPU allocation was changed. The first SSH helper's malformed JSON termination and an earlier historical-endpoint timeout are retained in [results](results.json); their owned SSH children were terminated. Both current connections are closed; the router remains on.

When the ordered supply arrives, reconfirm chassis/assembly/access and its actual label. Cisco lists **PWR-CC1-400WAC** for C8375-E-G2. Replace the sole supply with AC disconnected, retaining normal cooling and covers, then hold IOS/configuration/firmware constant for the comparison. [Ordering guide](https://www.cisco.com/c/en/us/products/collateral/networking/sdwan-routers/8000-secure-routers/8000-secure-router-og.html), [replacement procedure](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8300-series/hardware_installation-guide/secure-8300-series-hig/install-fru-8300-series-secure-routers/remove-and-replace-the-power-supplies.html).

Capture PSU recognition, `pf/oper-mode`, NIM state, IOMD errors and voice-port enumeration separately. If the property remains absent with a recognized supported supply, investigate the platform/firmware producer using this evidence. Do not infer that production-ROMMON flashing is safe for this prototype from the published support matrix; the prior recovery history remains relevant. FXS/FXO configuration and real calls follow only after successful NIM initialization. Fan behavior is a separate C8375-05 acceptance test.

## Evidence handling

[Selected sanitized session](../../sanitized-evidence/c8375-recovery/voice-nim-20261107/selected-session.log) is generated from an ignored derived selection log. Full original SSH captures, configurations, extracted objects and temporary helpers remain restricted in `.git/recovery-private/c8375-voice-20261107/`. The selection removes carriage returns for readability and labels filtered sections; original bytes remain preserved privately. The temporary explicit SSH helper uses Python's standard library plus installed sshpass, performs no action on import, and is AI-assisted diagnostic work rather than extracted vendor code. No maintained publication-tool behavior changed. Known-value/pattern checks cannot prove the absence of every unknown secret.
