#!/usr/bin/env python3
"""AI-assisted read-only hardware-SPI qualification for C8235-A/U2900.

Explicit --samples with a SHA-256-pinned, successful GPIO reference directory.
Only 0x9f RDID and 0x13 native four-byte READ; no writes or mode-change command.
Four fixed 512-byte regions, two reads at each 64/512-byte chunk shape and
requested 100/500/1000 kHz. Stop on first bad ID, short response or mismatch.
Imports and help have no hardware effects. Originals stay in a private directory.
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

from pi_gpio_c8235_a_u2900_id import EXPECTED_ID, ID_PACKET
from pi_gpio_c8235_a_u2900_samples import ADDRESSES, SAMPLE_BYTES, preserve
from pi_u1_direct_read import DEVICE, make_transfer, read_packet

SPEEDS = (100000, 500000, 1000000)
CHUNKS = (64, 512)


def load_references(directory, report_sha256):
    raw = (directory / "report.json").read_bytes()
    if hashlib.sha256(raw).hexdigest() != report_sha256:
        raise ValueError("GPIO reference report hash mismatch; no hardware access")
    report = json.loads(raw)
    if (report.get("status") != "passed"
            or report.get("chassis") != "C8235-A/FGL2835L42B"
            or report.get("board") != "FOC28292GUQ"
            or report.get("physical_chip") != "U2900"):
        raise ValueError("Wrong or unsuccessful GPIO reference identity")
    references = {}
    for address in ADDRESSES:
        entries = [s for s in report["samples"] if int(s["address"], 16) == address]
        if sorted(s["pass"] for s in entries) != [1, 2, 3]:
            raise ValueError("Reference requires three samples at every fixed address")
        copies = []
        for entry in entries:
            name = entry["file"]
            if Path(name).name != name:
                raise ValueError("Invalid reference basename")
            data = (directory / name).read_bytes()
            if len(data) != SAMPLE_BYTES or hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise ValueError("Reference sample size/hash mismatch")
            copies.append(data)
        if copies[0] != copies[1] or copies[0] != copies[2]:
            raise ValueError("GPIO reference copies disagree")
        references[address] = copies[0]
    if not any(len(set(data)) > 1 for data in references.values()):
        raise ValueError("All references uniform; insufficient read-path qualification")
    return references


def check_id(transfer, speed, report, save, stage):
    response = transfer(ID_PACKET, speed)
    report["identities"].append({"stage": stage, "requested_hz": speed,
                                 "response_hex": response.hex(), "id": response[1:].hex()})
    save()
    if len(response) != 4 or response[1:] != EXPECTED_ID:
        raise ValueError("Unexpected/incomplete ID; no further transfer")


def capture(transfer, directory, report, save, references):
    if set(references) != set(ADDRESSES) or any(len(d) != 512 for d in references.values()):
        raise ValueError("Invalid fixed reference set; no transfer")
    report.update(samples=[], identities=[], array_bytes_received=0)
    for speed in SPEEDS:
        for address in ADDRESSES:
            for chunk in CHUNKS:
                for number in (1, 2):
                    stem = f"C8235-A-FGL2835L42B-U2900-{address:08x}-{speed}Hz-{chunk}B-read{number}"
                    check_id(transfer, speed, report, save, stem)
                    data, raw = bytearray(), bytearray()
                    entry = {"address": hex(address), "requested_hz": speed,
                             "chunk_bytes": chunk, "pass": number, "complete": False,
                             "response_file": stem + ".response.bin", "frames": []}
                    report["samples"].append(entry)
                    for offset in range(0, SAMPLE_BYTES, chunk):
                        packet = read_packet(address + offset, chunk)
                        response = transfer(packet, speed)
                        raw.extend(response)
                        entry["frames"].append({"address": hex(address + offset),
                                                "response_bytes": len(response)})
                        if len(response) != len(packet):
                            preserve(directory / entry["response_file"], raw)
                            entry["response_sha256"] = hashlib.sha256(raw).hexdigest()
                            save()
                            raise ValueError("Incomplete read; partial original response preserved")
                        data.extend(response[5:])
                    preserve(directory / entry["response_file"], raw)
                    name = stem + ".bin"
                    preserve(directory / name, data)
                    different = [i for i, (a, b) in enumerate(zip(references[address], data)) if a != b]
                    entry.update({"file": name, "bytes": len(data), "complete": True,
                                  "sha256": hashlib.sha256(data).hexdigest(),
                                  "response_sha256": hashlib.sha256(raw).hexdigest(),
                                  "different_bytes_from_GPIO": len(different),
                                  "different_bits_from_GPIO": sum(bin(a ^ b).count("1")
                                                                  for a, b in zip(references[address], data)),
                                  "first_difference_address": hex(address + different[0]) if different else None})
                    report["array_bytes_received"] += len(data)
                    save()
                    if different:
                        raise ValueError("Hardware-SPI differs from GPIO reference; no further transfer")
        check_id(transfer, speed, report, save, "after-speed-samples")
        print(f"U2900 requested {speed} Hz: all bounded samples match GPIO references", flush=True)
    return True


def acquire(reference_directory, reference_sha256):
    references = load_references(reference_directory, reference_sha256)
    os.umask(0o077)
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode != 1:
        raise RuntimeError("Flashrom active or check failed; no SPI access")
    device = Path("/sys/class/spi_master/spi0/device")
    if (device.resolve().name != "1f00050000.spi"
            or (device / "driver").resolve() != Path("/sys/bus/platform/drivers/dw_spi_mmio")):
        raise RuntimeError("Unexpected controller/driver; no SPI access")
    fd = os.open(DEVICE, os.O_RDWR)
    report = None
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if os.geteuid() == 0 and int(os.environ.get("SUDO_UID", "0")):
            os.setgroups([])
            os.setgid(int(os.environ["SUDO_GID"]))
            os.setuid(int(os.environ["SUDO_UID"]))
        directory = Path(tempfile.mkdtemp(prefix="C8235-A-FGL2835L42B-U2900-SPI-samples-",
                                        dir=pwd.getpwuid(os.getuid()).pw_dir))
        report = {"started_at": datetime.now().astimezone().isoformat(),
                  "chassis": "C8235-A/FGL2835L42B", "board": "FOC28292GUQ",
                  "physical_chip": "U2900", "reset_held_chip": "U2901",
                  "reset_resistor_ohms": 218, "directory": str(directory), "device": DEVICE,
                  "status": "started", "method": "SPI_IOC_MESSAGE(1), mode0/MSB-first",
                  "reference_report_sha256": reference_sha256,
                  "reference_hashes": {hex(a): hashlib.sha256(d).hexdigest() for a, d in references.items()},
                  "requested_hz": list(SPEEDS), "chunks": list(CHUNKS),
                  "opcodes": ["0x9f RDID", "0x13 native four-byte READ"],
                  "maximum_array_bytes": 24576, "maximum_samples": 48,
                  "timing_limit": "Requested rates only; no measured waveforms",
                  "limitation": "Small sample agreement is not full-array accuracy, bank role or a backup"}

        def save():
            (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")

        save()
        try:
            transfer = make_transfer(fd, max_speed=max(SPEEDS))
            capture(transfer, directory, report, save, references)
            report["status"] = "passed"
        except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
            report["status"] = "failed/interrupted"
            report["failure"] = str(error) or type(error).__name__
    finally:
        os.close(fd)
    report["device_closed"] = True
    report["finished_at"] = datetime.now().astimezone().isoformat()
    save()
    print(json.dumps(report, indent=2), flush=True)
    return 0 if report["status"] == "passed" else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", action="store_true")
    parser.add_argument("--reference-directory", type=Path)
    parser.add_argument("--reference-report-sha256")
    args = parser.parse_args(argv)
    if not args.samples:
        parser.print_help()
        return 0
    if not args.reference_directory or not args.reference_report_sha256:
        parser.error("--samples requires the pinned GPIO reference directory and report hash")
    return acquire(args.reference_directory, args.reference_report_sha256)


if __name__ == "__main__":
    raise SystemExit(main())
