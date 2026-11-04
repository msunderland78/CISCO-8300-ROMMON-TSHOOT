#!/usr/bin/env python3
"""Explicit, one-shot C8235-A/U2900 development-ROMMON restore and readback.

AI-assisted orchestration, not a new flash driver. Uses installed flashrom 1.6.0
for a full pre-read, selected-region write and automatic full verification.
Then independently captures the entire chip with native four-byte SPI reads.
Imports/help have no hardware side effects. No force, verification bypass,
whole-chip erase, protection-disable, OTP, fuse or provisioning CLI options.
Requires exact input hashes, unchanged boot, no interface owners and one-shot
output files. A failed write is never automatically relaunched by this worker.
"""
import argparse
from datetime import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

from pi_u1_direct_read import make_transfer, read_packet

SIZE = 0x2000000
BOUNDARY = 0xD10000
BLOCK = 4096
SPEED = 1000000
EXPECTED_SECTORS = 1156
EXPECTED_RUNS = 27
BEFORE_HASH = "17c8b589f6af59a47aa4d7c10a540e1bd6669136cf4da89ea130c6e9f206d6c5"
CANDIDATE_HASH = "65e2ef5aa3814302fcf29e8344a720943a3f008c6bb9e4b9d59848ef928adf07"
HELPER_HASH = "a9931f4108bc8501cbaa9f25ec656f6b2a9b9b501b11f14125da250a5ea7873e"
DEVICE = "/dev/spidev0.0"
BASE_COMMAND = ["flashrom", "-V", "--progress", "-p",
                "linux_spi:dev=/dev/spidev0.0,spispeed=1000", "-c", "MT25QU256"]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def now():
    return datetime.now().astimezone().isoformat()


def exclusive(path, data):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def validate_inputs(before, candidate):
    require(len(before) == len(candidate) == SIZE, "Input size mismatch")
    require(sha(before) == BEFORE_HASH, "Current-image backup hash mismatch")
    require(sha(candidate) == CANDIDATE_HASH, "Candidate hash mismatch")
    require(before[BOUNDARY:] == candidate[BOUNDARY:], "Candidate changes preserved suffix")
    runs, sectors = [], 0
    for address in range(0, SIZE, BLOCK):
        if before[address:address + BLOCK] == candidate[address:address + BLOCK]:
            continue
        require(address + BLOCK <= BOUNDARY, "Change outside firmware area")
        sectors += 1
        if runs and runs[-1][1] == address:
            runs[-1][1] += BLOCK
        else:
            runs.append([address, address + BLOCK])
    require(sectors == EXPECTED_SECTORS and len(runs) == EXPECTED_RUNS, "Unexpected sector plan")
    return runs


def layout_text(runs):
    return "".join(f"{start:08x}:{end - 1:08x} fw{number:02d}\n"
                   for number, (start, end) in enumerate(runs))


def write_command(directory, count):
    command = BASE_COMMAND + ["--sacrifice-ratio", "0", "-l", str(directory / "restore.layout")]
    for number in range(count):
        command += ["-i", f"fw{number:02d}"]
    return command + ["-w", str(directory / "candidate.bin"), "-o", str(directory / "write.log")]


def environment_gate(expected_boot):
    require(os.geteuid() == 0, "Worker must start with device access privileges")
    boot = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
    require(boot == expected_boot, "Pi rebooted since qualification")
    device = Path("/sys/class/spi_master/spi0/device")
    require(device.resolve().name == "1f00050000.spi" and
            (device / "driver").resolve() == Path("/sys/bus/platform/drivers/dw_spi_mmio"),
            "Unexpected SPI controller/driver")
    holders = []
    for process in Path("/proc").iterdir():
        if not process.name.isdigit():
            continue
        try:
            for fd in (process / "fd").iterdir():
                try:
                    if str(fd.resolve()) in (DEVICE, "/dev/gpiochip0"):
                        holders.append(process.name)
                except FileNotFoundError:
                    pass
        except FileNotFoundError:
            pass
    require(not holders, "SPI/GPIO already owned by another process")
    require(subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode == 1,
            "Flashrom active or process check failed")
    require(shutil.disk_usage(Path(__file__).parent).free > 512 * 1024 * 1024,
            "Insufficient output space")
    return boot


def id_status(transfer):
    replies = [transfer(packet, SPEED) for packet in (b"\x9f\0\0\0", b"\x05\0", b"\x70\0")]
    require([len(r) for r in replies] == [4, 2, 2], "Incomplete ID/status response")
    result = {"id": replies[0][1:].hex(), "sr": replies[1][1], "fsr": replies[2][1]}
    require(result["id"] == "20bb19", "Unexpected flash ID")
    # WEL may be set by flashrom's temporary address-mode setup; do not alter it.
    require(result["sr"] & 0xFD == 0, "Flash busy or status protection bits set")
    require(result["fsr"] & 0xFE == 0x80, "Flash suspended, busy or error flag set")
    return result


def physical_gate():
    fd = os.open(DEVICE, os.O_RDWR)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return id_status(make_transfer(fd, max_speed=SPEED))
    finally:
        os.close(fd)


def capture_readback(transfer, directory, candidate, report, save):
    require(len(candidate) == SIZE, "Readback comparison image size mismatch")
    path = directory / "U2900-development-full-readback.partial.bin"
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    digest, differences, first_difference = hashlib.sha256(), 0, None
    report["readback"] = {"file": path.name, "bytes": 0, "complete": False, "identities": []}
    with os.fdopen(fd, "wb") as stream:
        for address in range(0, SIZE, 512):
            if address % 0x100000 == 0:
                report["readback"]["identities"].append({"address": hex(address), **id_status(transfer)})
            packet = read_packet(address, min(512, SIZE - address))
            raw = transfer(packet, SPEED)
            require(len(raw) == len(packet), "Incomplete native readback response")
            data = raw[5:]
            stream.write(data)
            digest.update(data)
            wanted = candidate[address:address + len(data)]
            if data != wanted:
                for relative, (actual, expected) in enumerate(zip(data, wanted)):
                    if actual != expected:
                        differences += 1
                        if first_difference is None:
                            first_difference = hex(address + relative)
            report["readback"]["bytes"] += len(data)
            if report["readback"]["bytes"] % 0x100000 == 0:
                stream.flush()
                os.fsync(stream.fileno())
                save()
                print(f"Independent readback: {report['readback']['bytes']}/{SIZE}", flush=True)
        report["readback"]["identities"].append({"address": "end", **id_status(transfer)})
        stream.flush()
        os.fsync(stream.fileno())
    final = directory / "U2900-development-full-readback.bin"
    os.link(path, final)
    path.unlink()
    report["readback"].update(file=final.name, complete=True, sha256=digest.hexdigest(),
                              differing_bytes=differences, first_difference=first_difference)
    save()
    require(differences == 0 and digest.hexdigest() == sha(candidate), "Full readback mismatch")


def run_phase(directory, name, command, report, save, runner=subprocess.run):
    stdout = directory / f"{name}-stdout.log"
    require(not stdout.exists() and not (directory / f"{name}.log").exists(), "Log already exists")
    report["phase"] = name
    report.setdefault("commands", {})[name] = command
    report.setdefault("phase_started_at", {})[name] = now()
    save()
    with stdout.open("xb") as log:
        # No external timeout can interrupt an erase/program operation.
        result = runner(command, stdout=log, stderr=subprocess.STDOUT,
                        timeout=1200 if name == "pre-read" else None)
    report.setdefault("returncodes", {})[name] = result.returncode
    report.setdefault("phase_finished_at", {})[name] = now()
    save()
    require(result.returncode == 0, f"{name} failed; no automatic write retry")


def execute(directory, expected_boot):
    os.umask(0o077)
    directory = directory.resolve(strict=True)
    before = (directory / "before.bin").read_bytes()
    candidate = (directory / "candidate.bin").read_bytes()
    runs = validate_inputs(before, candidate)
    helper = Path(__file__).with_name("pi_u1_direct_read.py")
    require(sha(helper.read_bytes()) == HELPER_HASH, "SPI helper hash mismatch")
    version = subprocess.run(["flashrom", "--version"], capture_output=True, text=True, check=True).stdout
    require(version.startswith("flashrom v1.6.0 "), "Unexpected flashrom version")
    environment_gate(expected_boot)
    exclusive(directory / "write-once.lock", (now() + "\n").encode())
    exclusive(directory / "restore.layout", layout_text(runs).encode())
    report = {"target": "C8235-A/FGL2835L42B/U2900", "board": "FOC28292GUQ",
              "started_at": now(), "boot_id": expected_boot, "directory": str(directory),
              "before_sha256": BEFORE_HASH, "candidate_sha256": CANDIDATE_HASH,
              "status": "running", "phase": "preflight", "complete": False,
              "changed_sector_count": 1156, "changed_runs": runs,
              "flashrom_version": version, "owner_voltage_v": [1.718, 1.718, 0.308],
              "fixture": "U2900 clip, 1.8V adapter, U2901 RESET through 218 ohms; native/bench/battery isolated",
              "signature_or_boot_validation": "not established by this operation"}

    def save():
        temp = directory / "progress.tmp"
        with temp.open("w") as stream:
            json.dump(report, stream, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, directory / "progress.json")

    save()
    try:
        report["initial_status"] = physical_gate()
        save()
        pre_read = directory / "U2900-prewrite-full-read.bin"
        require(not pre_read.exists(), "Pre-read output exists")
        run_phase(directory, "pre-read", BASE_COMMAND + ["-r", str(pre_read), "-o",
                  str(directory / "pre-read.log")], report, save)
        fresh = pre_read.read_bytes()
        report["pre_read"] = {"bytes": len(fresh), "sha256": sha(fresh), "matches_backup": fresh == before}
        save()
        require(fresh == before, "Fresh pre-read differs from original; NO WRITE")
        environment_gate(expected_boot)
        report["before_write_status"] = physical_gate()
        save()
        run_phase(directory, "write", write_command(directory, len(runs)), report, save)
        text = (directory / "write-stdout.log").read_text(errors="replace")
        report["automatic_verify_reported"] = "VERIFIED" in text
        require(report["automatic_verify_reported"], "No flashrom verification success marker")
        environment_gate(expected_boot)
        report["phase"] = "independent-native-full-readback"
        save()
        fd = os.open(DEVICE, os.O_RDWR)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            capture_readback(make_transfer(fd, max_speed=SPEED), directory, candidate, report, save)
        finally:
            os.close(fd)
        report["status"] = "verified"
        report["complete"] = True
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError, KeyboardInterrupt) as error:
        report["status"] = "failed/interrupted"
        report["failure"] = str(error) or type(error).__name__
    report["finished_at"] = now()
    save()
    exclusive(directory / "completion.json", (json.dumps(report, indent=2) + "\n").encode())
    print(json.dumps({"status": report["status"], "complete": report["complete"]}), flush=True)
    return 0 if report["complete"] else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--restore-and-readback", action="store_true")
    parser.add_argument("--directory", type=Path)
    parser.add_argument("--expected-boot-id")
    args = parser.parse_args(argv)
    if not args.restore_and_readback:
        parser.print_help()
        return 0
    if not args.directory or not args.expected_boot_id:
        parser.error("Explicit directory and current boot ID required")
    return execute(args.directory, args.expected_boot_id)


if __name__ == "__main__":
    raise SystemExit(main())
