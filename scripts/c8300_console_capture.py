#!/usr/bin/env python3
"""AI-assisted C8300 receive-only console capture, Python standard library.

No hardware access on import or --help. Explicit --live mode checks both macOS
serial aliases and claims exclusive access. Never transmits bytes or BREAK.
Raw bytes remain under .git/recovery-private; stdout reports metadata only.
Stdin accepts JSON controls: status, mark, baud (9600/115200), and close.
"""

import argparse
from datetime import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import select
import subprocess
import sys
import termios
import time


def aliases(port):
    name = Path(port).name
    if not name.startswith(("cu.", "tty.")):
        raise ValueError("Expected an explicit macOS serial device")
    suffix = name.split(".", 1)[1]
    return ["/dev/cu." + suffix, "/dev/tty." + suffix]


def rate_value(rate):
    if type(rate) is not int or rate not in (9600, 115200):
        raise ValueError("Only 9600 and 115200 are supported")
    return getattr(termios, "B" + str(rate))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, choices=(9600, 115200), default=9600)
    parser.add_argument("--confirmed-pid", required=True, choices=("C8300-1N1S-4T2X",))
    args = parser.parse_args()
    if not args.live:
        parser.error("Hardware access requires --live after current physical-state confirmation")
    ports = aliases(args.port)
    owners = subprocess.run(["lsof", "-t", *ports], capture_output=True)
    if owners.returncode != 1 or owners.stdout:
        raise RuntimeError("Serial port is owned or ownership check failed")
    os.umask(0o077)
    root = Path(__file__).resolve().parents[1]
    directory = root / ".git/recovery-private/c8300-console-20261102" / datetime.now().strftime("%Y%m%d-%H%M%S")
    directory.mkdir(parents=True, mode=0o700, exist_ok=False)
    raw = (directory / "console.log").open("xb", buffering=0)
    events = (directory / "events.jsonl").open("x", buffering=1)
    fd = None
    total = 0
    phase_bytes = 0
    baud = args.baud
    digest = hashlib.sha256()
    start = phase_start = time.monotonic()

    def event(kind, **extra):
        record = {"time": datetime.now().astimezone().isoformat(), "event": kind,
                  "port": args.port, "baud": baud, "pid": args.confirmed_pid,
                  "received_bytes": total, "phase_bytes": phase_bytes,
                  "elapsed_seconds": round(time.monotonic() - start, 3),
                  "phase_seconds": round(time.monotonic() - phase_start, 3),
                  "sha256": digest.hexdigest(), "receive_only": True, **extra}
        line = json.dumps(record)
        events.write(line + "\n")
        temporary = directory / "status.tmp"
        temporary.write_text(line + "\n")
        temporary.replace(directory / "status.json")
        print(line, flush=True)

    try:
        fd = os.open(args.port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        fcntl.ioctl(fd, termios.TIOCEXCL)
        # lsof returns 1 when one requested alias has no open descriptor even
        # if the other is owned by us. Check the actually opened node here;
        # both aliases were checked before open and TIOCEXCL is now active.
        owners = subprocess.run(["lsof", "-t", args.port], capture_output=True)
        if owners.returncode != 0 or set(owners.stdout.split()) != {str(os.getpid()).encode()}:
            raise RuntimeError("Competing serial owner appeared")
        attrs = termios.tcgetattr(fd)
        attrs[0] = attrs[1] = attrs[3] = 0
        attrs[2] = termios.CLOCAL | termios.CREAD | termios.CS8
        attrs[4] = attrs[5] = rate_value(baud)
        attrs[6][termios.VMIN] = attrs[6][termios.VTIME] = 0
        termios.tcsetattr(fd, termios.TCSANOW, attrs)
        event("capture_ready", evidence=str(directory.relative_to(root)), framing="8N1", flow_control="none")
        heartbeat = time.monotonic() + 30
        while True:
            ready, _, _ = select.select([fd, sys.stdin], [], [], 1)
            if fd in ready:
                data = os.read(fd, 65536)
                if data:
                    raw.write(data)
                    digest.update(data)
                    total += len(data)
                    phase_bytes += len(data)
                    event("received", chunk_bytes=len(data))
            if sys.stdin in ready:
                line = sys.stdin.readline()
                if not line:
                    break
                try:
                    control = json.loads(line)
                    if control.get("close"):
                        break
                    if "baud" in control:
                        value = rate_value(control["baud"])
                        attrs = termios.tcgetattr(fd)
                        attrs[4] = attrs[5] = value
                        termios.tcsetattr(fd, termios.TCSANOW, attrs)
                        baud = control["baud"]
                        phase_bytes = 0
                        phase_start = time.monotonic()
                        event("baud_changed")
                    if "mark" in control:
                        event("operator_marker", marker=str(control["mark"])[:160])
                    if control.get("status"):
                        event("status")
                except (ValueError, TypeError, AttributeError):
                    event("control_rejected")
            if time.monotonic() >= heartbeat:
                event("heartbeat")
                heartbeat = time.monotonic() + 30
    except (OSError, RuntimeError, KeyboardInterrupt) as exc:
        event("capture_error", error_type=type(exc).__name__)
        raise
    finally:
        if fd is not None:
            os.close(fd)
        event("capture_closed")
        raw.close()
        events.close()


if __name__ == "__main__":
    main()
