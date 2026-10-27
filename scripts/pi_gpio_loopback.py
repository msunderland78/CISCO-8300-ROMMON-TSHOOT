#!/usr/bin/env python3
"""AI-assisted GPIO SPI control: adapter-only loopback, router disconnected.

Explicit --adapter-loopback only. Temporarily unbinds the verified SPI0 driver,
requests GPIO8/9/10/11 through libgpiod, and restores the driver in finally.
Arbitrary bytes are sent: NEVER use with a flash chip or router attached.
Requires Linux, Python libgpiod v2, and sibling loopback/direct-reader modules.
"""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import pwd
import subprocess
import tempfile
import time

from pi_spi_loopback import PATTERNS, pattern_bytes, compare

CS, MISO, MOSI, CLK = 8, 9, 10, 11
DELAY_SECONDS = 0.0002
DRIVER = Path("/sys/bus/platform/drivers/dw_spi_mmio")
CONTROLLER = "1f00050000.spi"


class BitBang:
    def __init__(self, write, read, wait):
        self.write, self.read, self.wait = write, read, wait

    def transfer(self, packet):
        received = bytearray()
        self.write(CLK, 0)
        self.write(CS, 0)
        self.wait()
        try:
            for value in packet:
                result = 0
                for shift in range(7, -1, -1):
                    self.write(MOSI, (value >> shift) & 1)
                    self.wait()
                    self.write(CLK, 1)
                    self.wait()
                    result = (result << 1) | int(self.read(MISO))
                    self.write(CLK, 0)
                    self.wait()
                received.append(result)
            return bytes(received)
        finally:
            self.write(CLK, 0)
            self.write(CS, 1)
            self.wait()


def acquire():
    import gpiod
    from gpiod.line import Direction, Value

    os.umask(0o077)
    if os.geteuid() != 0:
        raise RuntimeError("Needs sudo for temporary driver ownership change")
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode != 1:
        raise RuntimeError("Flashrom active or process check failed")
    device = Path("/sys/class/spi_master/spi0/device")
    if device.resolve().name != CONTROLLER or (device / "driver").resolve() != DRIVER:
        raise RuntimeError("Unexpected SPI0 controller/driver; no changes")
    with gpiod.Chip("/dev/gpiochip0") as chip:
        if chip.get_info().label != "pinctrl-rp1":
            raise RuntimeError("Unexpected GPIO chip; no changes")
        for line in (CS, MISO, MOSI, CLK):
            if chip.get_line_info(line).name != f"GPIO{line}":
                raise RuntimeError("Unexpected GPIO line mapping; no changes")
    uid, gid = int(os.environ.get("SUDO_UID", "0")), int(os.environ.get("SUDO_GID", "0"))
    directory = Path(tempfile.mkdtemp(prefix="Pi5-adapter-gpio-loopback-", dir=pwd.getpwuid(uid).pw_dir))
    os.chown(directory, uid, gid)
    report = {
        "started_at": datetime.now().astimezone().isoformat(),
        "setup": "Adapter-only OUTPUT2-to5 jumper; router fully disconnected",
        "method": "libgpiod GPIO software SPI, mode0/MSB-first; no SPI engine transfers",
        "gpiod_version": gpiod.__version__, "gpiochip": "/dev/gpiochip0",
        "controller": CONTROLLER, "driver": str(DRIVER),
        "CS_GPIO": CS, "MISO_GPIO": MISO, "MOSI_GPIO": MOSI, "CLK_GPIO": CLK,
        "requested_wait_seconds_per_phase": DELAY_SECONDS,
        "timing_limit": "Three waits per bit plus Python/Linux/GPIO overhead; no exact clock claim",
        "directory": str(directory), "status": "started", "tests": [],
    }

    def save():
        path = directory / "report.json"
        path.write_text(json.dumps(report, indent=2) + "\n")
        os.chown(path, uid, gid)

    save()
    unbound = False
    try:
        (DRIVER / "unbind").write_text(CONTROLLER)
        unbound = True
        settings = {
            CS: gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.ACTIVE),
            MISO: gpiod.LineSettings(direction=Direction.INPUT),
            MOSI: gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.INACTIVE),
            CLK: gpiod.LineSettings(direction=Direction.OUTPUT, output_value=Value.INACTIVE),
        }
        with gpiod.request_lines("/dev/gpiochip0", consumer="isolated-adapter-control", config=settings) as request:
            def write(line, value):
                request.set_value(line, Value.ACTIVE if value else Value.INACTIVE)

            def read(line):
                return request.get_value(line) == Value.ACTIVE

            spi = BitBang(write, read, lambda: time.sleep(DELAY_SECONDS))
            for name in PATTERNS:
                expected = pattern_bytes(name, 64)
                for number in (1, 2):
                    received = spi.transfer(expected)
                    report["tests"].append({
                        "pattern": name, "pass": number, "bytes": len(expected),
                        "tx_sha256": hashlib.sha256(expected).hexdigest(),
                        "rx_sha256": hashlib.sha256(received).hexdigest(),
                        **compare(expected, received),
                    })
                    save()
        report["status"] = "passed" if all(t["different_bytes"] == 0 for t in report["tests"]) else "failed"
    except (OSError, RuntimeError, ValueError, KeyboardInterrupt) as error:
        report["status"] = "failed/interrupted"
        report["failure"] = str(error) or type(error).__name__
    finally:
        if unbound:
            try:
                (DRIVER / "bind").write_text(CONTROLLER)
                report["driver_restored"] = (device / "driver").resolve() == DRIVER
            except OSError as error:
                report["driver_restored"] = False
                report["restore_failure"] = str(error)
        else:
            report["driver_restored"] = (device / "driver").resolve() == DRIVER
        if not report["driver_restored"]:
            report["status"] = "failed/interrupted"
        report["finished_at"] = datetime.now().astimezone().isoformat()
        save()
    print(json.dumps(report, indent=2), flush=True)
    return 0 if report["status"] == "passed" else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adapter-loopback", action="store_true")
    args = parser.parse_args(argv)
    if not args.adapter_loopback:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
