#!/usr/bin/env python3
"""AI-assisted observer for one explicitly authorized C8235-C reset.

No hardware access on import/default invocation. Live mode owns the console,
allows the first matching C reset to autoboot without transmitting, and stops
any subsequent reset (or mismatched banner). It never boots or patches IOS.
Afterward the established JSON control interface supports supervised commands.
"""
import argparse
from datetime import datetime
import hashlib
import os
import re
from pathlib import Path
import select
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from c8235_b_console_boot import Console, Refused, normalized, require, hold


def check_banner(data):
    text = normalized(data).decode("ascii", "replace")
    found = re.findall(r"Soc UUID: ([0-9A-F ]+)", text)
    require(found and found[-1].strip() == "13 FF FF 87 79 AD FB 83 CA 80 82 43",
            "C SoC UUID mismatch/missing")
    require("SDK112312-SoC1-SB-v12.1.22" in text, "Development ROMMON mismatch")
    require("mirabile-arata, Revision: r2" in text, "Board revision mismatch")


class OneAutobootConsole(Console):
    def receive(self, timeout):
        ready, _, _ = select.select([self.fd], [], [], timeout)
        if not ready:
            return b""
        data = os.read(self.fd, 65536)
        if data:
            self.log.write(data)
            self.buffer += data
            self.reset_tail = (self.reset_tail + data)[-32768:]
            if b"UUID Len: 0xC" in self.reset_tail:
                self.reset_count += 1
                try:
                    check_banner(self.reset_tail)
                    matched = True
                except Refused:
                    matched = False
                if self.reset_count == 1 and matched:
                    self.event("first_matching_reset_observed_without_transmission")
                else:
                    self.send(b"\x03\x03\x03")
                    self.event("autoboot_stopped", count=self.reset_count,
                               identity_matched=matched)
                self.reset_tail = b""
        return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--port")
    parser.add_argument("--confirmed-chassis", choices=["FGL2835L41Z"])
    args = parser.parse_args()
    if not args.live:
        print("Plan only: observe one matching C reset without transmission; stop later resets.")
        return
    if not args.port or not args.confirmed_chassis:
        parser.error("Live mode requires explicit port and confirmed chassis")
    os.umask(0o077)
    directory = ROOT / ".git/recovery-private/c8235-c-baseline-20261101" / (
        datetime.now().strftime("%Y%m%d-%H%M%S") + "-one-autoboot")
    directory.mkdir(parents=True, exist_ok=False)
    console = OneAutobootConsole(args.port, directory)
    try:
        console.event("one_autoboot_observer_armed", directory=str(directory),
                      source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
        hold(console)
    finally:
        console.close()


if __name__ == "__main__":
    main()
