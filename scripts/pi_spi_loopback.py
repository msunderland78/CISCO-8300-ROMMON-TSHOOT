#!/usr/bin/env python3
"""AI-assisted original Pi SPI loopback diagnostic; no action without explicit flag.

Use ONLY with every router/adapter lead removed from the Pi header and a jumper
between physical pins 19 (MOSI) and 21 (MISO). Arbitrary test bytes are sent;
this is not a flash-reading script and must never run against a flash chip.
Linux/Python standard library; pi_u1_direct_read.py must be beside this file.
"""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import pwd
import random
import subprocess
import tempfile

from pi_u1_direct_read import DEVICE, make_transfer

SPEEDS = (100000, 50000, 10000)
LENGTHS = (4, 17, 517, 4091)
PATTERNS = ("zeros", "ones", "55", "aa", "ramp", "pseudorandom")


def pattern_bytes(name, length):
    if name in ("zeros", "ones", "55", "aa"):
        value = {"zeros": 0, "ones": 255, "55": 85, "aa": 170}[name]
        return bytes([value]) * length
    if name == "ramp":
        return bytes(i % 256 for i in range(length))
    if name == "pseudorandom":
        generator = random.Random(8375)
        return bytes(generator.randrange(256) for _ in range(length))
    raise ValueError("Unknown test pattern")


def compare(expected, received):
    if len(expected) != len(received):
        raise ValueError("Incomplete loopback response")
    differences = [i for i, (a, b) in enumerate(zip(expected, received)) if a != b]
    return {
        "different_bytes": len(differences),
        "different_bits": sum(bin(a ^ b).count("1") for a, b in zip(expected, received)),
        "lost_one_bits": sum(bin(a & (~b & 255)).count("1") for a, b in zip(expected, received)),
        "added_one_bits": sum(bin(b & (~a & 255)).count("1") for a, b in zip(expected, received)),
        "first_difference_offset": differences[0] if differences else None,
        "last_difference_offset": differences[-1] if differences else None,
    }


def run_matrix(transfer, report, save):
    for speed in SPEEDS:
        for length in LENGTHS:
            for name in PATTERNS:
                expected = pattern_bytes(name, length)
                for number in (1, 2):
                    received = transfer(expected, speed)
                    report["tests"].append({
                        "requested_kHz": speed // 1000, "bytes": length,
                        "pattern": name, "pass": number,
                        "tx_sha256": hashlib.sha256(expected).hexdigest(),
                        "rx_sha256": hashlib.sha256(received).hexdigest(),
                        **compare(expected, received),
                    })
                    save()
        failed = sum(t["different_bytes"] != 0 for t in report["tests"]
                     if t["requested_kHz"] == speed // 1000)
        print(f"Requested {speed // 1000} kHz: {failed}/48 transfers differ", flush=True)


def acquire():
    os.umask(0o077)
    active = subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL)
    if active.returncode != 1:
        raise RuntimeError("Flashrom active or process check failed; no SPI access")
    fd = os.open(DEVICE, os.O_RDWR)
    try:
        if os.geteuid() == 0 and int(os.environ.get("SUDO_UID", "0")) != 0:
            uid, gid = int(os.environ["SUDO_UID"]), int(os.environ["SUDO_GID"])
            os.setgroups([])
            os.setgid(gid)
            os.setuid(uid)
        home = Path(pwd.getpwuid(os.getuid()).pw_dir)
        directory = Path(tempfile.mkdtemp(prefix="Pi5-isolated-loopback-", dir=home))
        report = {
            "started_at": datetime.now().astimezone().isoformat(),
            "setup": "Pi-only; all adapter/router GPIO leads removed; physical 19-to-21 jumper",
            "device": DEVICE, "mode": 0, "bits_per_word": 8,
            "transaction": "single full-duplex SPI_IOC_MESSAGE(1)",
            "directory": str(directory), "status": "started", "tests": [],
        }

        def save():
            (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")

        save()
        try:
            run_matrix(make_transfer(fd), report, save)
            report["status"] = "passed" if all(t["different_bytes"] == 0 for t in report["tests"]) else "failed"
        except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
            report["status"] = "failed/interrupted"
            report["failure"] = str(error) or type(error).__name__
        report["finished_at"] = datetime.now().astimezone().isoformat()
        save()
        print(json.dumps({"directory": str(directory), "status": report["status"],
                          "transfers": len(report["tests"]),
                          "different_bytes": sum(t["different_bytes"] for t in report["tests"])}, indent=2), flush=True)
        return 0 if report["status"] == "passed" else 1
    finally:
        os.close(fd)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--isolated-loopback", action="store_true",
                        help="confirm router and adapter fully disconnected from Pi header")
    args = parser.parse_args(argv)
    if not args.isolated_loopback:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
