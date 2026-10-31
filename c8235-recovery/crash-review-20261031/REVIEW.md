# C8235-B crash review — October 31, 2026

Offline analysis, America/New_York; task **C8235-05**. The archive was acquired October 25 from **FGL2835LBHU / C8235-B**, reporting prototype PID **C8230X-8M2X**, Arata r2. Router-clock dates in filenames are not session dates. No router access or firmware/configuration change occurred in this review.

**Main finding:** network-interface resource attachment fails during packet-processor initialization, before the critical CPP crash. The cleaned 26.2.1 core confirms a **SIGSEGV at address zero**. Resource allocation / platform initialization is the strongest current lead; the underlying firmware, driver, board-profile or hardware cause remains unresolved.

## Evidence preserved and examined

Located `C8235-B-FGL2835LBHU-20261025-REPORTS/` on `/Volumes/CISCO FILES`. Made **48 byte-preserving private copies, 531,659,680 bytes**, independently matching source/destination SHA-256. **45** also match the October 25 archive hash inventory. USB originals were not modified. The three other files are the separately archived baseline crashinfo and cleaned-retest report/info; the baseline hash also matches the previously recorded `c17f32…` digest.

Triaged **20 compressed system reports**; Python tarfile parsed 19 and extracted 227 selected text members. The `173239` report produces a tar ReadError although gzip decompression completes and the result identifies as GNU tar. It was retained without repair and was not used for conclusions. Large uncompressed tar/part files were not recopied or exhaustively analyzed. Reports overlap: repeated log content is not a count of independent crashes.

Source hashes, member paths, methods and limitations are in [analysis.json](analysis.json). Selected device-log lines and debugger output are in the [generated sanitized excerpts](../../sanitized-evidence/c8235-recovery/crash-review-20261031/evidence-excerpts.log). Full reports, configuration-bearing material, cores and scratch analysis remain under restricted `.git/recovery-private/c8235-analysis-20261031/`, outside publication. Pattern/known-value checks cannot prove absence of every unknown secret in binary data.

## Failure sequence in the cleaned 26.2.1 report

The report is **44,201,929 bytes**, SHA-256:

```text
5a6316e66dd9f7bf68a2504f83a087c59f07c85f0c84f105b48275cbe0b1b92e
```

| Observation | What it establishes |
| --- | --- |
| At kernel uptime about 12.29 seconds, RVU reports `Request for NIX0 failed`, `ATTACH_RESOURCES`, error **-28**, beginning with PF0:VF27 and continuing through VF31 | Allocation failures begin during device initialization, well before the process crash |
| The saved dmesg contains **410** NIX0 request failures, including later requests for physical-port VFs and the internal loopback VF | A repeated low-level problem affects more than one interface; these are log-event counts |
| QFP trace printable records show **fpe4–fpe9**, **l2_mod**, and **lbk_ipc_dp** each exhausting **50 attachment attempts**, `att_rc=-28` | The packet processor cannot complete its static interface setup, including its internal IPC path |
| Final IPC failure is router-clock **18:51:57.367**; audit records CPP signal 11 at **18:51:58** | These events precede the CPP held-down/critical-failure messages; temporal association is strong, but the precise code path remains unproven |
| `cpp_cp_svr` held down rc139 at 18:52:34, critical at 18:52:53, process-manager exit at 18:53:54 | This report's failure chain agrees with the October 25 console capture and reboot |

In the [upstream Marvell RVU driver](https://raw.githubusercontent.com/torvalds/linux/v6.1/drivers/net/ethernet/marvell/octeontx2/af/rvu.c), `rvu_check_rsrc_availability()` emits that failure and returns `-ENOSPC` when no NIX logical-function resource is free. **Here the exhausted resource is a network hardware allocation, not bootflash storage.** This is an upstream semantic reference, not verification that Cisco's private driver fork is identical. Actual resource limits, allocations, firmware reservations and initialization order still need measurement.

The completed CPP core is **21,313,948 compressed bytes**, SHA-256 `c6fbcff09afe4863aceef4e079a75b1147b48a0b52f222cc8b33d9018bff2cf6`; gzip expansion succeeds to **1,957,003,264 bytes**. Offline LLDB identifies AArch64 process 20780, signal SIGSEGV, unmapped address **0x0**, and register **x0=0**. ELF NT_FILE notes map PC `0xffff804c87e4` to `libcpp_sbs.so + 0x87e4` and LR `0xffff80e8fff8` to `libcpp_punt_inject_svr_lib.so + 0x1fff8`.

The existing 26.2.1 package's library has `ldr x27, [x0]` at that PC offset, consistent with the null-address fault. Its executable bytes were not available at the PC in this filtered core for direct equality verification. Symbols/full stack are unavailable; do not invent a source function or claim the entire causal chain is decoded. Firmware libraries were inspected, not executed.

## Comparison with older evidence

- **17.18.3a:** older report boot logs identify the package and CPP signal 11. Seven captured dmesg members repeat NIX0/ATTACH_RESOURCES failures (308–309 each); several are overlapping captures. Three standalone CPP core-generation logs end in write failure, so those files are not completed CPP cores. The full-storage condition impaired evidence collection.
- **26.1.1:** the `20250108-182657` report identifies `c8kg2be-mono-universalk9.26.01.01.SPA.pkg`, prototype model C8230X-8M2X, CPP signal 11 and **360** NIX0 failures. This is newly reviewed historical evidence from B's archived storage, not a new test. An individual serial was not found in the selected members, so provenance rests on the identified archive acquisition; the actual date is unresolved.
- **26.2.1 before cleanup:** baseline crashinfo records **Aborted(6), PuntInject Keepalive Process**. That explains the later IOS-triggered reload, not the earlier packet-processor failure.
- **26.2.1 after cleanup:** [the retest record](../../recovery-prep-20261024/C8235-B-FGL2835LBHU-20261025-RETEST.json) places **9,513,209,856 bytes free** after CPP held-down. The new report supplies the allocation/crash details above. Cleanup fixed the storage symptoms but was insufficient for stability.

## Working hypotheses and test priorities

1. **Platform initialization / resource allocation mismatch — leading inference.** Check NIX capacity and free/assigned logical functions, PF/VF creation counts, driver bindings, actual board/silicon identity, boot firmware and selected platform profile. An old development bundle is a plausible contributor, not a proven cause.
2. **Shared IOS driver or error-handling defect.** Multiple releases can share a faulty path. A null-address crash following initialization failure may be secondary; replacing the crash without restoring forwarding would not be recovery.
3. **Board-specific hardware or firmware state.** Remains possible. A separately identified C8235-C gives a valuable comparison; it has no verified boot result yet. A matching failure on C would strengthen a shared-compatibility hypothesis, not prove identical hardware.
4. **Startup configuration/peripheral influence.** A temporary minimal configuration is a reversible control, though early resource failures make ordinary feature configuration a lower-priority explanation.

No reviewed evidence establishes a physical 12 V rail failure, faulty DRAM, or damaged TPM. The prior 0 mV sensor field needs independent validation; absence of a logged memory error is not a memory test. Do not transfer the C8375 PSU/fan diagnosis to these chassis.

## Release and recovery constraints

Cisco lists C8235-G2 support beginning with **17.18.1a** and a production SoC1 ROMMON baseline, not the retained `SDK112312-SoC1-SB-v12.1.22` development bundle. [17.18.x release notes](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/sec-8200-series/release-notes/17-18-x/release-notes-cisco-8200-series-secure-routers-release-17-18-x.html). The [26.2.x matrix](https://www.cisco.com/c/en/us/td/docs/routers/secure-routers/cisco-8000-series-secure-routers-release-26-2-x.html) similarly lists production SoC1 firmware. Those production matrices do not certify this prototype or justify flashing it: C8235-A already demonstrates the pre-ROMMON TPM halt after a production update.

Do not reuse C8375's 17.15.6 test as a supported C8235 baseline. Current USB inventory has G2 17.18.3a, 26.1.1 and 26.2.1, plus other-family images; filename presence is not compatibility or integrity verification. A genuinely different, verified C8235-supported IOS candidate must be selected before the optional image comparison. No matched crash fix was identified in the reviewed public release notes. Check and preserve IOx/application data before any downgrade; Cisco documents a 26.2-to-earlier disk-layout change that can discard that data.

The ordered bench procedure, acceptance criteria and pending checkboxes are maintained in [C8235-05 in the active test plan](../../ROUTER-RECOVERY-TEST-PLAN.md#c8235-05--crash-analysis-and-controlled-stability-tests). Preserve development ROMMON and unique board/security data throughout the initial tests. No watch-dog suppression, security bypass or speculative register/flash write is proposed.

## Subsequent console check — 15:58 EDT

After the offline review, the owner confirmed B powered with RJ45 serial, identity/assembly/cooling and free console. A fresh ownership check found no process on the cu/tty port. Two bounded four-second reads at 115200/8N1/no flow (the second after one carriage return) received **zero bytes**. The exclusive descriptor was closed each time. No prompt, present IOS version or current crash was observed; no reboot or persistent setting changed. The next bench action is a controlled, captured power-on after confirming current cables/battery and that no transfer/write is active. Quiet serial alone does not prove a dead CPU. Exact capture hashes are in [analysis.json](analysis.json).

## Captured power cycle — 16:00–16:02 EDT

At the owner’s request, continuous logging was armed before the owner cycled power. Clear output identifies Arata r2 / A0, July 17, 2024 boot stub, 16 GB memory and the unchanged `SDK112312-SoC1-SB-v12.1.22` development ROMMON. The SoC UUID matches B’s October 25 capture. A one-shot Ctrl-C sequence stopped autoboot. Read-only `showmon -v`, `set` and `dir bootflash:` confirm PowerOn reset, Boot ROM0, `BOOT=bootflash:packages.conf,12;`, absent maintenance parameter and listed 17.18.3a image/packages. No IOS boot or stability test occurred. This supersedes the earlier inability to observe a prompt; it does not explain why the already-powered console was quiet.

Final state: **powered at `rommon 4 >`**, capture closed cleanly and serial port free at 16:02:29 EDT. USB stays on Mac. [Sanitized continuous capture](../../sanitized-evidence/router-console-logs/20261031-160040-console.log). Next attach the verified USB for the selected diagnostic boot and inspect NIX allocations; no new firmware candidate or write is selected.
