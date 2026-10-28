#!/usr/bin/env python3
"""AI-assisted U2 CS-only reverse control for C8375-A/FDO2742M0FK.

Explicit --hold-u2-cs-low only, after checked U2 clip/isolation/voltage setup.
Meter red U1 physical pin7/CS, black P1pin2/GND. No bytes or clock pulses sent.
Uses sibling checked GPIO ownership/cleanup and timed chip-select helper.
"""
import argparse

from pi_gpio_loopback import run_hardware
from pi_u1_cs_hold import hold_control


def acquire(seconds):
    return run_hardware(
        "C8375-U2-CS-U1meter-",
        "C8375-A/FDO2742M0FK; short clip on U2; checked translated harness/isolation; meter on U1pin7 to P1ground",
        lambda spi, report, directory, save: hold_control(
            spi, report, directory, save, seconds, target_chip="U2"),
        {"method": "U2 CS-only GPIO reverse control; no flash command or SCLK pulse",
         "chassis": "C8375-A/FDO2742M0FK", "physical_chip_controlled": "U2",
         "physical_chip_measured": "U1", "meter_point": "u1-cs",
         "meter_endpoints": {"red": "U1 physical pin7/CS", "black": "P1 pin2/GND"},
         "opcodes": [], "limitation": "Commanded control state; meter observations recorded separately"},
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hold-u2-cs-low", action="store_true")
    parser.add_argument("--seconds", type=int, default=120)
    args = parser.parse_args(argv)
    if not args.hold_u2_cs_low:
        parser.print_help()
        return 0
    if not 10 <= args.seconds <= 180:
        parser.error("Hold must be bounded to10–180seconds")
    return acquire(args.seconds)


if __name__ == "__main__":
    raise SystemExit(main())
