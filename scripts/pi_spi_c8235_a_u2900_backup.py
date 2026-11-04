#!/usr/bin/env python3
"""AI-assisted read-only full backup pair for C8235-A/FGL2835L42B/U2900.

Explicit --read-pair, pinned successful GPIO references and hardware-SPI
qualification report required before device access. Two exact 32 MiB reads at
requested 1 MHz using native four-byte READ 0x13; only other opcode is RDID 0x9f.
Stop on first mismatch, short response or unexpected ID; keep partial originals.
No flash writes, erases, reset, register operation or address-mode change.
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

from pi_gpio_c8235_a_u2900_samples import preserve
from pi_spi_c8235_a_u2900_read import check_id, load_references
from pi_u1_direct_read import DEVICE, make_transfer, read_packet

CHIP_BYTES = 33554432
CHUNK_BYTES = 512
CHECKPOINT_BYTES = 1048576
SPEED = 1000000


def validate_qualification(path, expected_hash, reference_hash):
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected_hash:
        raise ValueError("Hardware qualification hash mismatch; no device access")
    report = json.loads(raw)
    if (report.get("status") != "passed"
            or report.get("chassis") != "C8235-A/FGL2835L42B"
            or report.get("board") != "FOC28292GUQ"
            or report.get("physical_chip") != "U2900"
            or report.get("reference_report_sha256") != reference_hash
            or len(report.get("samples", [])) != 48
            or any(s.get("different_bytes_from_GPIO") != 0 for s in report["samples"])
            or not any(s["requested_hz"] == SPEED and s["chunk_bytes"] == CHUNK_BYTES
                       for s in report["samples"])):
        raise ValueError("Missing successful target/rate/reference qualification")


def capture_pair(transfer, directory, report, save, references):
    report.update(identities=[], reads=[], reference_checks=[])
    for number in (1, 2):
        stem = f"C8235-A-FGL2835L42B-U2900-full-read{number}"
        partial = directory / (stem + ".partial.bin")
        final = directory / (stem + ".bin")
        entry = {"pass": number, "file": partial.name, "complete": False, "bytes_written": 0}
        report["reads"].append(entry)
        save()
        first = None
        if number == 2:
            first_path = directory / report["reads"][0]["file"]
            if first_path.stat().st_size != CHIP_BYTES:
                raise ValueError("First original is not a complete chip; no second read")
            first = first_path.open("rb")
        digest = hashlib.sha256()
        try:
            fd = os.open(partial, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "wb") as output:
                for address in range(0, CHIP_BYTES, CHUNK_BYTES):
                    if address % CHECKPOINT_BYTES == 0:
                        check_id(transfer, SPEED, report, save, f"full{number}-before-{address:08x}")
                    packet = read_packet(address, CHUNK_BYTES)
                    response = transfer(packet, SPEED)
                    if len(response) != len(packet):
                        name = f"{stem}-{address:08x}-incomplete.response.bin"
                        preserve(directory / name, response)
                        entry["incomplete_response_file"] = name
                        entry["failure_address"] = hex(address)
                        save()
                        raise ValueError("Incomplete full-read response; partial original retained")
                    data = response[5:]
                    output.write(data)
                    digest.update(data)
                    entry["bytes_written"] += len(data)
                    if address in references:
                        equal = data == references[address]
                        report["reference_checks"].append({"pass": number, "address": hex(address),
                                                           "matches_GPIO": equal})
                        save()
                        if not equal:
                            raise ValueError("Full read differs from GPIO sample; partial original retained")
                    if first is not None:
                        previous = first.read(CHUNK_BYTES)
                        if data != previous:
                            differences = [i for i, (a, b) in enumerate(zip(previous, data)) if a != b]
                            entry["mismatch_chunk_address"] = hex(address)
                            entry["first_difference_address"] = hex(address + differences[0]) if differences else None
                            entry["different_bytes_in_chunk"] = len(differences)
                            save()
                            raise ValueError("Full reads differ; both originals retained, no further transfer")
                    if entry["bytes_written"] % CHECKPOINT_BYTES == 0:
                        output.flush()
                        os.fsync(output.fileno())
                        save()
                        print(f"U2900 full read {number}/2: {entry['bytes_written']}/{CHIP_BYTES} bytes", flush=True)
                check_id(transfer, SPEED, report, save, f"full{number}-after-final-byte")
                output.flush()
                os.fsync(output.fileno())
        finally:
            if first is not None:
                first.close()
        if entry["bytes_written"] != CHIP_BYTES:
            raise ValueError("Full-read length mismatch")
        if len([c for c in report["reference_checks"] if c["pass"] == number]) != len(references):
            raise ValueError("Not all GPIO reference locations were checked")
        os.link(partial, final)
        partial.unlink()
        entry.update(file=final.name, complete=True, sha256=digest.hexdigest(),
                     completed_at=datetime.now().astimezone().isoformat())
        save()
    report["pair_equal"] = report["reads"][0]["sha256"] == report["reads"][1]["sha256"]
    save()
    if not report["pair_equal"]:
        raise ValueError("Full-read hashes differ")
    return True


def acquire(reference_directory, reference_hash, qualification, qualification_hash):
    references = load_references(reference_directory, reference_hash)
    validate_qualification(qualification, qualification_hash, reference_hash)
    os.umask(0o077)
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode != 1:
        raise RuntimeError("Flashrom active or process check failed")
    device = Path("/sys/class/spi_master/spi0/device")
    if (device.resolve().name != "1f00050000.spi"
            or (device / "driver").resolve() != Path("/sys/bus/platform/drivers/dw_spi_mmio")):
        raise RuntimeError("Unexpected SPI controller/driver")
    fd = os.open(DEVICE, os.O_RDWR)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if os.geteuid() == 0 and int(os.environ.get("SUDO_UID", "0")):
            os.setgroups([])
            os.setgid(int(os.environ["SUDO_GID"]))
            os.setuid(int(os.environ["SUDO_UID"]))
        directory = Path(tempfile.mkdtemp(prefix="C8235-A-FGL2835L42B-U2900-full-pair-",
                                        dir=pwd.getpwuid(os.getuid()).pw_dir))
        report = {"started_at": datetime.now().astimezone().isoformat(),
                  "chassis": "C8235-A/FGL2835L42B", "board": "FOC28292GUQ", "physical_chip": "U2900",
                  "reset_held_chip": "U2901", "reset_resistor_ohms": 218,
                  "directory": str(directory), "device": DEVICE, "status": "started",
                  "method": "SPI_IOC_MESSAGE(1), mode0/MSB-first, native four-byte address",
                  "chip_bytes": CHIP_BYTES, "requested_hz": SPEED, "chunk_bytes": CHUNK_BYTES,
                  "reference_report_sha256": reference_hash, "qualification_report_sha256": qualification_hash,
                  "opcodes": ["0x9f RDID", "0x13 native four-byte READ"],
                  "limitation": "Matching originals do not establish firmware compatibility, physical bank role or boot"}

        def save():
            (directory / "report.json").write_text(json.dumps(report, indent=2) + "\n")

        save()
        print("U2900 full-pair acquisition started", flush=True)
        try:
            transfer = make_transfer(fd, max_speed=SPEED)
            capture_pair(transfer, directory, report, save, references)
            report["status"] = "passed"
        except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
            report["status"] = "failed/interrupted"
            report["failure"] = str(error) or type(error).__name__
    finally:
        os.close(fd)
    report["device_closed"] = True
    report["finished_at"] = datetime.now().astimezone().isoformat()
    save()
    print("REPORT_JSON_BEGIN", flush=True)
    print(json.dumps(report, indent=2), flush=True)
    return 0 if report["status"] == "passed" else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--read-pair", action="store_true")
    parser.add_argument("--reference-directory", type=Path)
    parser.add_argument("--reference-report-sha256")
    parser.add_argument("--qualification-report", type=Path)
    parser.add_argument("--qualification-report-sha256")
    args = parser.parse_args(argv)
    if not args.read_pair:
        parser.print_help()
        return 0
    if not all([args.reference_directory, args.reference_report_sha256,
                args.qualification_report, args.qualification_report_sha256]):
        parser.error("--read-pair requires pinned GPIO and hardware-SPI qualification reports")
    return acquire(args.reference_directory, args.reference_report_sha256,
                   args.qualification_report, args.qualification_report_sha256)


if __name__ == "__main__":
    raise SystemExit(main())
