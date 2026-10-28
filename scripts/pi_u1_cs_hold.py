#!/usr/bin/env python3
"""AI-assisted U1 chip-select-only control for C8375-A/FDO2742M0FK.

Explicit --hold-u1-cs-low only, with checked U1 translated harness/isolation.
Holds clock low, asserts U1 CS for a bounded interval, then deselects/restores
the SPI0 driver. Sends no bytes or clock pulses. Meter the selected endpoint
independently: U2 CS or P1 flash supply.
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


def acquire(seconds, meter_point="u2-cs"):
    if meter_point not in ("u2-cs", "p1-vcc"):
        raise ValueError("Unknown meter endpoint; no hardware access")
    supply_test = meter_point == "p1-vcc"
    red_endpoint = "P1 pin1/VCC" if supply_test else "U2 physical pin7/CS"
    return run_hardware(
        "C8375-U1-CS-P1VCC-" if supply_test else "C8375-U1-CS-only-",
        f"C8375-A/FDO2742M0FK; short clip on U1; checked translated harness/isolation; meter red {red_endpoint}, black P1 pin2/GND",
        lambda spi, report, directory, save: hold_control(spi, report, directory, save, seconds),
        {"method": "CS-only GPIO control; no flash command or SCLK pulse",
         "chassis": "C8375-A/FDO2742M0FK", "physical_chip_controlled": "U1",
         "physical_chip_measured": None if supply_test else "U2",
         "meter_point": meter_point,
         "meter_endpoints": {"red": red_endpoint, "black": "P1 pin2/GND"},
         "opcodes": [],
         "limitation": "GPIO commands do not measure flash-side levels; meter observations recorded separately"},
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hold-u1-cs-low", action="store_true")
    parser.add_argument("--seconds", type=int, default=120)
    parser.add_argument("--meter-point", choices=("u2-cs", "p1-vcc"), default="u2-cs")
    args = parser.parse_args(argv)
    if not args.hold_u1_cs_low:
        parser.print_help()
        return 0
    if not 10 <= args.seconds <= 180:
        parser.error("Hold must be bounded to10–180seconds")
    return acquire(args.seconds, args.meter_point)


if __name__ == "__main__":
    raise SystemExit(main())
