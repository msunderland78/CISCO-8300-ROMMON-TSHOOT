#!/usr/bin/env python3
"""AI-assisted U1 chip-select-only control for C8375-A/FDO2742M0FK.

Explicit --hold-u1-cs-low only, with checked U1 translated harness/isolation.
Holds clock low, asserts U1 CS for a bounded interval, then deselects/restores
the SPI0 driver. Sends no bytes or clock pulses. Meter U2 CS independently.
Dependencies: Python/libgpiod v2 and sibling GPIO/loopback/direct modules.
"""
import argparse
from datetime import datetime
import os
from pathlib import Path
import time

from pi_gpio_loopback import CS, CLK, run_hardware


def hold_control(spi, report, directory, save, seconds, now=time.monotonic, sleep=time.sleep):
    spi.write(CLK, 0)
    started = now()
    try:
        spi.write(CS, 0)
        report["hold"] = {
            "phase": "U1 CS commanded low; SCLK commanded low",
            "requested_seconds": seconds,
            "started_at": datetime.now().astimezone().isoformat(),
            "pid": os.getpid(), "stop_file": str(directory / "stop"),
            "clock_pulses_commanded": 0, "flash_bytes_sent": 0,
        }
        save()
        print(json_safe_progress(report, directory), flush=True)
        while now() - started < seconds:
            if (directory / "stop").exists():
                report["hold"]["end_reason"] = "stop file requested"
                break
            sleep(0.25)
        else:
            report["hold"]["end_reason"] = "bounded interval expired"
    except KeyboardInterrupt:
        report.setdefault("hold", {})["end_reason"] = "interrupted; cleanup requested"
    finally:
        spi.write(CLK, 0)
        spi.write(CS, 1)
        report.setdefault("hold", {})["phase"] = "U1 CS commanded high; SCLK commanded low"
        report["hold"]["elapsed_seconds"] = round(now() - started, 3)
        save()
    return True


def json_safe_progress(report, directory):
    import json
    return json.dumps({"phase": report["hold"]["phase"], "directory": str(directory),
                       "seconds": report["hold"]["requested_seconds"]})


def acquire(seconds):
    return run_hardware(
        "C8375-U1-CS-only-",
        "C8375-A/FDO2742M0FK; short clip on U1; checked translated harness/isolation; meter on U2 pin7",
        lambda spi, report, directory, save: hold_control(spi, report, directory, save, seconds),
        {"method": "CS-only GPIO control; no flash command or SCLK pulse",
         "chassis": "C8375-A/FDO2742M0FK", "physical_chip_controlled": "U1",
         "physical_chip_measured": "U2", "opcodes": [],
         "limitation": "GPIO commands do not measure flash-side levels; meter observations recorded separately"},
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hold-u1-cs-low", action="store_true")
    parser.add_argument("--seconds", type=int, default=120)
    args = parser.parse_args(argv)
    if not args.hold_u1_cs_low:
        parser.print_help()
        return 0
    if not 10 <= args.seconds <= 180:
        parser.error("Hold must be bounded to10–180seconds")
    return acquire(args.seconds)


if __name__ == "__main__":
    raise SystemExit(main())
