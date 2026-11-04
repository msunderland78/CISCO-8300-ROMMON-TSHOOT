#!/usr/bin/env python3
"""AI-assisted ID-only GPIO diagnostic for C8235-A/FGL2835L42B/U2900.

Explicit --identify only, after current fixture/voltage/ownership checks.
Sends only three bounded 0x9f RDID transactions, stopping on the first bad or
incomplete response. No array read, write, erase, reset or register command.
Uses the existing checked Pi5/libgpiod-v2 transport and driver cleanup; sibling
pi_gpio_loopback.py, pi_spi_loopback.py and pi_u1_direct_read.py are dependencies.
Importing this module or requesting help does not access hardware.
"""
import argparse

from pi_gpio_loopback import run_hardware

EXPECTED_ID = b"\x20\xbb\x19"
ID_PACKET = b"\x9f\x00\x00\x00"
ATTEMPTS = 3


def identify(spi, report, directory, save):
    report["identities"] = []
    report["limitation"] = (
        "ID responses do not prove physical bank role, array integrity, "
        "complete bus isolation or a complete backup"
    )
    for number in range(1, ATTEMPTS + 1):
        response = spi.transfer(ID_PACKET)
        report["identities"].append({
            "attempt": number,
            "bytes_received": len(response),
            "response_hex": response.hex(),
            "id": response[1:].hex(),
        })
        save()
        if len(response) != len(ID_PACKET):
            raise ValueError("Incomplete chip identification; no further transfer")
        if response[1:] != EXPECTED_ID:
            raise ValueError("Unexpected chip ID; no force or automatic retry")
        print(f"C8235-A U2900 ID {number}/{ATTEMPTS}: {response[1:].hex()}", flush=True)
    return True


def acquire():
    return run_hardware(
        "C8235-A-FGL2835L42B-U2900-ID-",
        "C8235-A/FGL2835L42B/FOC28292GUQ/U2900; checked 1.8V harness; "
        "U2901 physical RESET pin3 held through measured218ohm to J2507-8/GND; "
        "native router sources and bench supply disconnected",
        identify,
        {"chassis": "C8235-A/FGL2835L42B", "board": "FOC28292GUQ",
         "physical_chip": "U2900", "reset_held_chip": "U2901",
         "reset_resistor_ohms": 218, "expected_id": EXPECTED_ID.hex(),
         "opcodes": ["0x9f RDID"], "maximum_transactions": ATTEMPTS,
         "array_bytes_read": 0},
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--identify", action="store_true")
    args = parser.parse_args(argv)
    if not args.identify:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
