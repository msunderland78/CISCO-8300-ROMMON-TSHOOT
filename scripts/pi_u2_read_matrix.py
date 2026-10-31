#!/usr/bin/env python3
"""AI-assisted bounded read-only U2 validation with unused U1 held in reset.

Explicit --read --u1-reset-low only after current physical/meter checks.
Python standard library plus sibling pi_u1_direct_read.py; no import side effects.
Only RDID 0x9f and native four-byte READ 0x13. No flash configuration/write/reset.
Samples remain private. Requested clock rates are not measured waveforms.
"""
import argparse
from datetime import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import pwd
import subprocess
import tempfile

from pi_u1_direct_read import DEVICE, make_transfer, read_packet

ADDRESSES = (0, 0x001F2000, 0x006E0000, 0x00FFF800,
             0x01002000, 0x01F30000, 0x01FFF000)
SPEEDS = (100000, 500000, 1000000)
CHUNKS = (64, 512)
SIZE = 4096


def read_at(transfer, address, size, chunk, speed):
    if not 0 <= address < 33554432 or not 1 <= size <= SIZE:
        raise ValueError("Invalid bounded diagnostic range")
    if address + size > 33554432 or not 1 <= chunk <= 512:
        raise ValueError("Invalid chip boundary or chunk size")
    output = bytearray()
    for offset in range(0, size, chunk):
        packet = read_packet(address + offset, min(chunk, size - offset))
        response = transfer(packet, speed)
        if len(response) != len(packet):
            raise ValueError("Incomplete SPI response")
        output.extend(response[5:])
    return bytes(output)


def capture(transfer, directory, report, save, addresses=ADDRESSES,
            speeds=SPEEDS, chunks=CHUNKS, size=SIZE):
    baseline = {}
    report.update(samples=[], identities=[], comparisons=[])
    for speed in speeds:
        for address in addresses:
            for chunk in chunks:
                pair = []
                for number in (1, 2):
                    response = transfer(b"\x9f\0\0\0", speed)
                    identity = response[1:] if len(response) == 4 else b""
                    report["identities"].append({"requested_hz": speed,
                        "address": hex(address), "chunk_bytes": chunk,
                        "pass": number, "id": identity.hex()})
                    save()
                    if identity != b"\x20\xbb\x19":
                        raise ValueError("Incorrect chip ID; no force or automatic retry")
                    data = read_at(transfer, address, size, chunk, speed)
                    name = f"U2-{address:08x}-{speed}Hz-{chunk}B-read{number}.bin"
                    path = directory / name
                    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                    with os.fdopen(fd, "wb") as stream:
                        stream.write(data)
                    pair.append(data)
                    report["samples"].append({"file": name, "start": hex(address),
                        "requested_hz": speed, "chunk_bytes": chunk, "pass": number,
                        "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
                    save()
                reference = baseline.setdefault(address, pair[0])
                pair_diff = sum(a != b for a, b in zip(*pair))
                baseline_diff = [sum(a != b for a, b in zip(reference, data)) for data in pair]
                report["comparisons"].append({"start": hex(address),
                    "requested_hz": speed, "chunk_bytes": chunk,
                    "pair_different_bytes": pair_diff,
                    "baseline_different_bytes": baseline_diff})
                save()
                if pair_diff or any(baseline_diff):
                    return False
    return True


def acquire():
    os.umask(0o077)
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode != 1:
        raise RuntimeError("Flashrom active or process check failed; no SPI access")
    device = Path("/sys/class/spi_master/spi0/device")
    if device.resolve().name != "1f00050000.spi" or (device / "driver").resolve().name != "dw_spi_mmio":
        raise RuntimeError("Unexpected SPI0 controller/driver; no SPI access")
    fd = os.open(DEVICE, os.O_RDWR)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if os.geteuid() == 0 and int(os.environ.get("SUDO_UID", "0")) != 0:
            os.setgroups([])
            os.setgid(int(os.environ["SUDO_GID"]))
            os.setuid(int(os.environ["SUDO_UID"]))
        directory = Path(tempfile.mkdtemp(prefix="C8375-U2-RESET-matrix-",
                                        dir=pwd.getpwuid(os.getuid()).pw_dir))
        report = {"started_at": datetime.now().astimezone().isoformat(),
            "chassis": "C8375-A/FDO2742M0FK", "physical_chip": "U2",
            "unused_chip_control": "Owner-confirmed U1pin3 RESET low through10k toP1ground",
            "device": DEVICE, "directory": str(directory), "status": "started",
            "method": "Single full-duplex SPI_IOC_MESSAGE(1), mode0/MSB-first",
            "requested_hz": list(SPEEDS), "chunk_bytes": list(CHUNKS),
            "addresses": [hex(a) for a in ADDRESSES], "bytes_per_sample": SIZE,
            "opcodes": ["0x9f RDID", "0x13 native four-byte READ"],
            "timing_limit": "Requested clocks only; no actual edge-rate measurement",
            "limitation": "Bounded validation is not a full backup or physical bank-role assignment"}

        def save():
            (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")

        save()
        try:
            transfer = make_transfer(fd, max_speed=max(SPEEDS))
            passed = capture(transfer, directory, report, save)
            report["status"] = "passed" if passed else "failed/inconsistent"
        except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
            report["status"] = "failed/interrupted"
            report["failure"] = str(error) or type(error).__name__
        report["finished_at"] = datetime.now().astimezone().isoformat()
        save()
        print(json.dumps(report, indent=2), flush=True)
        return 0 if report["status"] == "passed" else 1
    finally:
        os.close(fd)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--read", action="store_true")
    parser.add_argument("--u1-reset-low", action="store_true")
    args = parser.parse_args(argv)
    if not args.read:
        parser.print_help()
        return 0
    if not args.u1_reset_low:
        parser.error("--read also requires fresh physical confirmation --u1-reset-low")
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
