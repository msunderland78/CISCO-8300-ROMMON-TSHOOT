#!/usr/bin/env python3
"""AI-assisted bounded read-only samples for C8235-A/FGL2835L42B/U2900.

Explicit --read only after current fixture/voltage/ownership checks. Three
passes over four fixed 512-byte regions (6 KiB total); only RDID 0x9f and native
four-byte READ 0x13. Stop on bad/incomplete ID, short read or first mismatch.
No flash write, erase, reset, register operation or address-mode change.
Original responses and samples remain in a new private acquisition directory.
Uses the existing checked Pi5 GPIO transport and driver cleanup.
"""
import argparse
import hashlib
import os

from pi_gpio_c8235_a_u2900_id import EXPECTED_ID, ID_PACKET
from pi_gpio_loopback import run_hardware
from pi_u1_direct_read import read_packet

ADDRESSES = (0x00000000, 0x001F2000, 0x01000000, 0x01FFFE00)
SAMPLE_BYTES = 512
PASSES = 3


def preserve(path, data):
    """Create an exact original with private permissions; never overwrite."""
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)
    os.chown(path, int(os.environ.get("SUDO_UID", str(os.getuid()))),
             int(os.environ.get("SUDO_GID", str(os.getgid()))))


def check_identity(spi, report, save, stage):
    response = spi.transfer(ID_PACKET)
    report["identities"].append({
        "stage": stage, "bytes_received": len(response),
        "response_hex": response.hex(), "id": response[1:].hex(),
    })
    save()
    if len(response) != 4 or response[1:] != EXPECTED_ID:
        raise ValueError("Unexpected/incomplete chip ID; no further transfer")


def capture(spi, report, directory, save):
    packets = {address: read_packet(address, SAMPLE_BYTES) for address in ADDRESSES}
    report.update({"identities": [], "samples": [], "comparisons": [],
                   "array_bytes_received": 0})
    baseline = {}
    for number in range(1, PASSES + 1):
        for address, packet in packets.items():
            stage = f"pass{number}-address{address:08x}"
            check_identity(spi, report, save, stage)
            stem = f"C8235-A-FGL2835L42B-U2900-{address:08x}-read{number}"
            response = spi.transfer(packet)
            raw_name = stem + ".response.bin"
            preserve(directory / raw_name, response)
            entry = {
                "pass": number, "address": hex(address),
                "requested_bytes": SAMPLE_BYTES, "response_bytes": len(response),
                "response_file": raw_name,
                "response_sha256": hashlib.sha256(response).hexdigest(),
                "complete": len(response) == len(packet),
            }
            report["samples"].append(entry)
            save()
            if not entry["complete"]:
                raise ValueError("Incomplete SPI read; original response preserved")
            data = response[5:]
            name = stem + ".bin"
            preserve(directory / name, data)
            entry.update({
                "file": name, "bytes": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
                "zero_bytes": data.count(0), "ff_bytes": data.count(255),
                "distinct_byte_values": len(set(data)),
            })
            report["array_bytes_received"] += len(data)
            if number == 1:
                baseline[address] = data
            else:
                previous = baseline[address]
                differences = [i for i, (a, b) in enumerate(zip(previous, data)) if a != b]
                report["comparisons"].append({
                    "address": hex(address), "baseline_pass": 1, "pass": number,
                    "different_bytes": len(differences),
                    "different_bits": sum(bin(a ^ b).count("1") for a, b in zip(previous, data)),
                    "first_difference_address": hex(address + differences[0]) if differences else None,
                })
                save()
                if differences:
                    raise ValueError("Sample mismatch; both originals preserved, no further transfer")
            save()
            print(f"U2900 pass {number}/{PASSES}, {address:08x}: {len(data)} bytes saved", flush=True)
    check_identity(spi, report, save, "after-all-samples")
    report["nonuniform_regions"] = [hex(a) for a, data in baseline.items() if len(set(data)) > 1]
    report["equal_cross_region_pairs"] = [
        [hex(a), hex(b)] for i, a in enumerate(ADDRESSES)
        for b in ADDRESSES[i + 1:] if baseline[a] == baseline[b]
    ]
    report["limitation"] = (
        "Repeated samples establish equality only for these regions and this fixture; "
        "not whole-array accuracy, firmware compatibility, bank role or a full backup"
    )
    save()
    if not report["nonuniform_regions"]:
        raise ValueError("All sampled regions are uniform; read-path qualification inconclusive")
    return True


def acquire():
    return run_hardware(
        "C8235-A-FGL2835L42B-U2900-samples-",
        "C8235-A/FGL2835L42B/FOC28292GUQ/U2900; unchanged reseated clip; "
        "checked 1.8V adapter; U2901 physical RESET pin3 through measured218ohm "
        "to J2507-8/GND; native router sources and bench supply disconnected",
        capture,
        {"chassis": "C8235-A/FGL2835L42B", "board": "FOC28292GUQ",
         "physical_chip": "U2900", "reset_held_chip": "U2901",
         "reset_resistor_ohms": 218, "expected_id": EXPECTED_ID.hex(),
         "addresses": [hex(a) for a in ADDRESSES], "bytes_per_sample": SAMPLE_BYTES,
         "passes": PASSES, "maximum_array_bytes": len(ADDRESSES) * SAMPLE_BYTES * PASSES,
         "maximum_transactions": len(ADDRESSES) * PASSES * 2 + 1,
         "opcodes": ["0x9f RDID", "0x13 native four-byte READ"]},
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--read", action="store_true")
    args = parser.parse_args(argv)
    if not args.read:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
