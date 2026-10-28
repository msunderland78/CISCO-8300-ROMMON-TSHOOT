#!/usr/bin/env python3
"""AI-assisted bounded read-only GPIO diagnostic for C8375-A/FDO2742M0FK/U1.

Explicit --read only, after target/mapping/isolation/voltage checks. Sends only
RDID 0x9f and native four-byte READ 0x13; no write/reset/register/erase command.
Linux/Python libgpiod v2; uses sibling checked GPIO ownership/cleanup utility.
"""
import argparse
import hashlib
import os

from pi_gpio_loopback import run_hardware
from pi_u1_direct_read import START, LENGTH, CHUNK, read_packet


def capture(spi, report, directory, save, chip="U1"):
    if chip not in ("U1", "U2"):
        raise ValueError("Unknown physical chip; no SPI transfer")
    samples = []
    report["samples"] = []
    report["identities"] = []
    for number in (1, 2):
        response = spi.transfer(b"\x9f\x00\x00\x00")
        if len(response) != 4:
            raise ValueError("Incomplete chip identification")
        identity = response[1:]
        report["identities"].append({"pass": number, "id": identity.hex()})
        save()
        if identity != b"\x20\xbb\x19":
            raise ValueError("Incorrect chip ID; stop without force or automatic retry")
        print(f"{chip} GPIO pass {number}/2: expected chip identified; reading fixed 4 KiB block", flush=True)
        output = bytearray()
        for address in range(START, START + LENGTH, CHUNK):
            packet = read_packet(address, CHUNK)
            response = spi.transfer(packet)
            if len(response) != len(packet):
                raise ValueError("Incomplete SPI read response")
            output.extend(response[5:])
            report["progress"] = {"pass": number, "completed_bytes": len(output)}
            save()
        if len(output) != LENGTH:
            raise ValueError("Incomplete diagnostic sample")
        data = bytes(output)
        name = f"{chip}-001f2000-GPIO-read{number}.bin"
        path = directory / name
        with path.open("xb") as stream:
            stream.write(data)
        os.chmod(path, 0o600)
        os.chown(path, int(os.environ.get("SUDO_UID", str(os.getuid()))),
                 int(os.environ.get("SUDO_GID", str(os.getgid()))))
        samples.append(data)
        report["samples"].append({"file": name, "pass": number, "bytes": len(data),
                                  "sha256": hashlib.sha256(data).hexdigest(),
                                  "zero_bytes": data.count(0), "ff_bytes": data.count(255)})
        save()
    differences = [i for i, (a, b) in enumerate(zip(*samples)) if a != b]
    report["comparison"] = {
        "different_bytes": len(differences),
        "first_difference_address": hex(START + differences[0]) if differences else None,
        "last_difference_address": hex(START + differences[-1]) if differences else None,
    }
    report["limitation"] = "4 KiB equality does not establish whole-array accuracy, bank identity or a complete backup"
    save()
    return not differences


def acquire(chip="U1"):
    if chip not in ("U1", "U2"):
        raise ValueError("Unknown physical chip; no hardware access")
    return run_hardware(
        f"C8375-{chip}-GPIO-target4KiB-",
        f"C8375-A/FDO2742M0FK/{chip}; short clip; checked translated harness; loopback jumper removed",
        lambda spi, report, directory, save: capture(spi, report, directory, save, chip),
        {"chassis": "C8375-A/FDO2742M0FK", "physical_chip": chip,
         "start_address": hex(START), "bytes_per_sample": LENGTH, "chunk_bytes": CHUNK,
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
