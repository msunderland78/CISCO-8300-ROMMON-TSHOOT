#!/usr/bin/env python3
"""Read two C8375-A U1 SPI regions twice through Pi SPI0 at requested 100 kHz.

AI-assisted original acquisition/analysis utility; not extracted vendor code.
Requires Python 3 standard library, flashrom, sudo and pgrep on the Pi.
Only --read starts hardware access. Main-array samples stay in a private folder.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from datetime import datetime

REGIONS = {"lower": 0x001F0000, "upper": 0x01F30000}
SIZE = 65536
PROGRAMMER = "linux_spi:dev=/dev/spidev0.0,spispeed=100"


def compare_region(first, second, start):
    if len(first) != SIZE or len(second) != SIZE:
        raise ValueError("A sample is not exactly 65536 bytes; comparison rejected")
    offsets = [i for i, (a, b) in enumerate(zip(first, second)) if a != b]
    return {
        "different_bytes": len(offsets),
        "first_difference": f"0x{start + offsets[0]:08X}" if offsets else None,
        "last_difference": f"0x{start + offsets[-1]:08X}" if offsets else None,
    }


def acquire():
    os.umask(0o077)
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode == 0:
        print("STOP: another flashrom process is running; nothing started.", flush=True)
        return 1
    directory = Path(tempfile.mkdtemp(prefix="C8375-U1-Pi100kHz-", dir=Path.home()))
    layout = directory / "regions.layout"
    layout.write_text("001f0000:001fffff lower\n01f30000:01f3ffff upper\n")
    report = {
        "started_at": datetime.now().astimezone().isoformat(),
        "chassis": "C8375-A / FDO2742M0FK", "physical_chip": "U1",
        "programmer": PROGRAMMER, "requested_kHz": 100,
        "directory": str(directory), "status": "started", "reads": [],
    }
    report_file = directory / "comparison.json"

    def save():
        report_file.write_text(json.dumps(report, indent=2) + "\n")

    save()
    print(f"Capture directory: {directory}", flush=True)
    print("Two regions, two independent passes. Keep wiring still; monitor P1 voltage.", flush=True)
    try:
        for number in (1, 2):
            files = {name: directory / f"U1-{name}-read{number}.bin" for name in REGIONS}
            logfile = directory / f"U1-read{number}.log"
            for path in [*files.values(), logfile]:
                path.touch(mode=0o600, exist_ok=False)
            argv = ["sudo", "flashrom", "-V", "-p", PROGRAMMER, "-c", "MT25QU256",
                    "-l", str(layout), "-r", "-o", str(logfile)]
            for name, path in files.items():
                argv.extend(["-i", f"{name}:{path}"])
            record = {"pass": number, "argv": argv, "status": "started", "samples": {}}
            report["reads"].append(record)
            save()
            print(f"Starting pass {number}/2...", flush=True)
            result = subprocess.run(argv)
            record["exit_code"] = result.returncode
            if result.returncode:
                record["status"] = "failed; any empty files are placeholders, not captures"
                raise ValueError(f"flashrom pass {number} failed; no automatic retry")
            for name, path in files.items():
                data = path.read_bytes()
                if len(data) != SIZE:
                    raise ValueError(f"{path.name}: {len(data)} bytes; expected 65536")
                record["samples"][name] = {
                    "file": path.name, "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(),
                    "unique_byte_values": len(set(data)),
                    "zero_bytes": data.count(0), "ff_bytes": data.count(255),
                }
            record["status"] = "read completed; sizes checked"
            save()
        comparisons = {}
        for name, start in REGIONS.items():
            first = (directory / f"U1-{name}-read1.bin").read_bytes()
            second = (directory / f"U1-{name}-read2.bin").read_bytes()
            comparisons[name] = compare_region(first, second, start)
        report["comparisons"] = comparisons
        report["repeatable"] = all(item["different_bytes"] == 0 for item in comparisons.values())
        report["status"] = "completed"
        report["finished_at"] = datetime.now().astimezone().isoformat()
        report["limitation"] = "Short-region equality does not establish whole-array accuracy or bank identity. No full read or write selected."
        save()
        print("\nCOMPARISON RESULT (no binary contents):", flush=True)
        print(json.dumps(report, indent=2), flush=True)
        print("Keep all captures/logs. Send the comparison result before further reads.", flush=True)
        return 0 if report["repeatable"] else 2
    except (OSError, ValueError, subprocess.SubprocessError, KeyboardInterrupt) as exc:
        report["status"] = "failed/interrupted"
        report["failure"] = str(exc) or type(exc).__name__
        report["finished_at"] = datetime.now().astimezone().isoformat()
        save()
        print(f"STOP: {report['failure']}. Evidence preserved in {directory}", flush=True)
        return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--read", action="store_true",
        help="read C8375-A/FDO2742M0FK/U1 using the already checked Pi/1.8 V harness",
    )
    args = parser.parse_args(argv)
    if not args.read:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
