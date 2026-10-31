#!/usr/bin/env python3
"""AI-assisted, experimental console boot for C8235-B / 26.2.1 only.

Standard library; no hardware access on import, help, or --plan. Explicit live
mode owns one POSIX serial port exclusively. No firmware, environment sync,
startup-config save, automatic retry, or alternate image selection. On failure
retain capture/control and stop the next autoboot; do not exit a failed shell.
Raw evidence is restricted to .git/recovery-private; stdout contains events only.
After the one-shot sequence, JSON lines accept send/close for supervised work.
"""
import argparse
from datetime import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import subprocess
import sys
import termios
import time

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "experimental-recovery/c8235-b-bound16-20261031/boot-bound16.sh"
SOURCE_HASH = "45af8d05ca9a954bef83a2d59be9951391d322010a0b809304760fc3b875a052"
IMAGE = "c8kg2be-universalk9.26.02.01.SPA.bin"
IMAGE_HASH = "0842a7210a2a0933f0a823bbe71c5ba2109f276ee49635a59ba0a26f17f0f456"
IMAGE_SHA512 = "a35896cf8e95870dd01cb9a8793401eb55d48363ef754d007937d271ef0a1c52115fe09ca53a4794d51286119a126bd28cc9d9a289b2659462191fbb497bcb02"
PATCH_HASH = "32ce11a07bde1fd610b1951a4c143217daec1d3458440bbcbd1fc3ca2c39f857"
HOOK_HASH = "ca13a2513a367cb9451fcc554432fd520aa8c42d0d59d61b5cd386e7f2efffa4"
UUID = "13 FF FF 87 79 AD FB 7C 6D E0 81 A7"
PARAM = "rdinit=/bin/sh -c mount${IFS}-tdevtmpfs${IFS}none${IFS}/dev;sh</dev/ttyAMA0&>/dev/ttyAMA0;exec${IFS}/init"
SHELL = rb"(?:^|\n)sh-5\.0# $"
IOS = rb"(?:^|\n)Router[>#]$"
ROMMON = rb"(?:^|\n)rommon \d+ > $"
WELCOME = rb"Press RETURN to get started[.!]"


class Refused(RuntimeError):
    pass


def require(condition, reason):
    if not condition:
        raise Refused(reason)


def normalized(data):
    return data.replace(b"\r", b"").replace(b"\x00", b"")


def exact_line(data, value):
    return value.encode() in normalized(data).splitlines()


def check_banner(data):
    text = normalized(data).decode("ascii", "replace")
    found = re.findall(r"Soc UUID: ([0-9A-F ]+)", text)
    require(found and found[-1].strip() == UUID, "SoC UUID mismatch/missing")
    require("SDK112312-SoC1-SB-v12.1.22" in text, "Development ROMMON mismatch")
    require("mirabile-arata, Revision: r2" in text, "Board revision mismatch")


def check_prepare(data):
    require(exact_line(data, "C8235_BOUND16_BOOTSTRAP_READY"), "Missing prepare READY")
    require(exact_line(data, "PREPARE_STATUS=0"), "Prepare did not return zero")
    require(exact_line(data, PATCH_HASH + "  /usr/binos/bin/launch_net.sh"), "RAM patch hash mismatch")
    require(exact_line(data, HOOK_HASH + "  /c8235-bound16-hook.sh"), "Hook hash mismatch")


def platform_ready(data):
    data = normalized(data)
    return all(re.search(pattern, data, re.MULTILINE) for pattern in (
        rb"^F0\s+C8230X-8M2X\s+ok, active\s",
        rb"^R0\s+C8230X-8M2X\s+ok, active\s",
        rb"^\s*0/0\s+8M-2xSFP\+\s+ok\s",
    ))


def payload_chunks(payload, limit=400):
    require(hashlib.sha256(payload).hexdigest() == SOURCE_HASH, "Local hook source changed")
    require(b"\nC8235_TRANSFER_EOF\n" not in payload, "Heredoc delimiter collision")
    return [payload[i:i + limit] for i in range(0, len(payload), limit)]


class Console:
    def __init__(self, port, directory):
        # Check before opening; TIOCEXCL additionally blocks competing opens.
        owners = subprocess.run(["lsof", "-t", port], capture_output=True)
        require(owners.returncode == 1 and not owners.stdout, "Console is owned or ownership check failed")
        self.fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
        try:
            fcntl.ioctl(self.fd, termios.TIOCEXCL)
            owners = subprocess.run(["lsof", "-t", port], capture_output=True)
            require(owners.returncode == 0 and set(owners.stdout.split()) == {str(os.getpid()).encode()},
                    "Another console owner appeared during handoff")
            attrs = termios.tcgetattr(self.fd)
            attrs[0] = attrs[1] = attrs[3] = 0
            attrs[2] = termios.CLOCAL | termios.CREAD | termios.CS8
            attrs[4] = attrs[5] = termios.B115200
            attrs[6][termios.VMIN] = attrs[6][termios.VTIME] = 0
            termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
            self.log = (directory / "console.log").open("xb", buffering=0)
            self.events = (directory / "events.jsonl").open("x", buffering=1)
        except BaseException:
            os.close(self.fd)
            raise
        self.buffer = b""
        self.reset_count = 0
        self.reset_tail = b""
        self.event("console_open", port=port, baud=115200)

    def event(self, state, **details):
        record = {"time": datetime.now().astimezone().isoformat(), "state": state, **details}
        line = json.dumps(record)
        self.events.write(line + "\n")
        print(line, flush=True)

    def send(self, data):
        require(len(data) <= 900, "Command/chunk exceeds bounded transfer size")
        self.log.write(("\n[TX " + datetime.now().astimezone().isoformat() + "] " + repr(data) + "\n").encode())
        deadline = time.monotonic() + 5
        while data:
            remaining = deadline - time.monotonic()
            require(remaining > 0, "Serial send deadline")
            _, writable, _ = select.select([], [self.fd], [], remaining)
            require(writable, "Serial write timeout")
            data = data[os.write(self.fd, data):]

    def baud(self, rate):
        require(rate in (9600, 115200), "Baud outside observed profile")
        attrs = termios.tcgetattr(self.fd)
        attrs[4] = attrs[5] = getattr(termios, "B" + str(rate))
        termios.tcsetattr(self.fd, termios.TCSANOW, attrs)
        self.event("console_baud", baud=rate)

    def receive(self, timeout):
        ready, _, _ = select.select([self.fd], [], [], timeout)
        if not ready:
            return b""
        data = os.read(self.fd, 65536)
        if data:
            self.log.write(data)
            self.buffer += data
            self.reset_tail = (self.reset_tail + data)[-32768:]
            # One stop per fresh banner, including unexpected resets after failure.
            if b"UUID Len: 0xC" in self.reset_tail:
                self.send(b"\x03\x03\x03")
                self.reset_count += 1
                self.reset_tail = b""
                self.event("autoboot_stopped", count=self.reset_count)
        return data

    def expect(self, pattern, timeout=30, allow_reset=False):
        deadline = time.monotonic() + timeout
        while True:
            data = normalized(self.buffer)
            if not allow_reset:
                require(b"UUID Len: 0xC" not in data, "Unexpected reset; autoboot stopped")
            if re.search(pattern, data):
                result, self.buffer = self.buffer, b""
                return result
            require(len(self.buffer) < 8 * 1024 * 1024, "Response exceeds capture bound")
            remaining = deadline - time.monotonic()
            require(remaining > 0, "Expected response timeout")
            self.receive(min(1, remaining))

    def command(self, command, prompt=SHELL, timeout=30):
        # Ctrl-C can generate multiple prompts. Drain to a bounded quiet period
        # so an old prompt cannot acknowledge the next command.
        deadline = time.monotonic() + 3
        while self.receive(0.2):
            require(time.monotonic() < deadline, "Console did not settle before command")
        require(b"UUID Len: 0xC" not in normalized(self.buffer), "Unexpected reset while draining; autoboot stopped")
        self.buffer = b""
        self.send(command.encode() + b"\r")
        return self.expect(prompt, timeout)

    def close(self):
        os.close(self.fd)
        self.log.close()
        self.events.close()


def reload_from_ios(console):
    console.command("", IOS)
    console.command("enable", IOS)
    console.command("terminal length 0", IOS)
    console.command("terminal width 512", IOS)
    inventory = console.command("show inventory", IOS)
    require(re.search(rb"PID: C8230X-8M2X[^\n]*SN: FGL2835LBHU", normalized(inventory)), "IOS chassis identity mismatch")
    version = console.command("show version", IOS)
    require(b"Version 26.02.01" in version, "IOS release mismatch")
    require(b"Configuration register is 0x3922" in version, "Configuration register changed")
    result = console.command("verify /sha512 usb0:" + IMAGE, IOS, 240)
    require(exact_line(result, "verify /sha512 (usb0:" + IMAGE + ") = " + IMAGE_SHA512), "USB image hash mismatch")
    console.event("ios_preflight_pass", chassis="FGL2835LBHU")
    result = console.command("reload", rb"(?:Save\? \[yes/no\]:|Proceed with reload\? \[confirm\])", 30)
    if b"Save? [yes/no]:" in result:
        console.command("no", rb"Proceed with reload\? \[confirm\]", 30)
    console.event("reload_confirmed_without_save")
    console.buffer = b""
    console.send(b"\r")


def boot_once(console, payload):
    banner = console.expect(ROMMON, 180, allow_reset=True)
    check_banner(banner)
    console.event("rommon_identity_pass", uuid=UUID)
    result = console.command('set USER_BOOT_PARAM "' + PARAM + '"', ROMMON)
    require(b"too large" not in result.lower(), "ROMMON parameter rejected")
    env = console.command("set", ROMMON)
    require(exact_line(env, "USER_BOOT_PARAM=" + PARAM), "Boot parameter readback mismatch")
    console.event("temporary_boot_parameter_verified")
    console.buffer = b""
    console.send(("boot usb0:/" + IMAGE + "\r").encode())
    console.expect(rb"EFI stub: Exiting boot services\.\.\.", 150)
    # Historical entry emits NULs until the shell is prompted. Bounded grace.
    until = time.monotonic() + 8
    while time.monotonic() < until:
        console.receive(min(0.5, until - time.monotonic()))
    # Opening ttyAMA0 defaults to 9600 in this initramfs (October 25 evidence,
    # reverified October 31). Change the host, then both ends back to 115200.
    console.baud(9600)
    console.command("", SHELL, 30)
    console.send(b"stty 115200\r")
    # Wait beyond the complete 9600-baud command transmission, not merely the
    # first echoed byte (which can arrive while the transmit queue is nonempty).
    termios.tcdrain(console.fd)
    until = time.monotonic() + 0.3
    while time.monotonic() < until:
        console.receive(min(0.05, until - time.monotonic()))
    console.baud(115200)
    console.command("", SHELL)
    parent = console.command("mkdir -p /proc /sys; mount -t proc proc /proc; mount -t sysfs sysfs /sys; tr '\\000' ' ' < /proc/1/cmdline; echo", SHELL)
    require(exact_line(parent, "/bin/sh -c " + PARAM.split(" -c ", 1)[1] + " "), "PID1 command differs from verified continuation")
    # Verify the USB copy on every cold/warm attempt; mount read-only, unmount
    # before applying the RAM-only script. Never alter a vendor image.
    console.command("mkdir -p /verify-usb; mount -t vfat -o ro /dev/sda1 /verify-usb", SHELL)
    digest = console.command("busybox sha256sum /verify-usb/" + IMAGE, SHELL, 240)
    require(exact_line(digest, IMAGE_HASH + "  /verify-usb/" + IMAGE), "Maintenance USB image hash mismatch")
    unmount = console.command("umount /verify-usb; echo UNMOUNT_STATUS=$?", SHELL)
    require(exact_line(unmount, "UNMOUNT_STATUS=0"), "USB read-only mount not released")
    console.event("maintenance_identity_and_image_pass")
    console.buffer = b""
    console.send(b"cat > /prepare-bound16.sh <<'C8235_TRANSFER_EOF'\n")
    console.expect(rb"(?:^|\n)> $", 10)
    for chunk in payload_chunks(payload):
        console.send(chunk)
        console.receive(0.2)
    console.send(b"C8235_TRANSFER_EOF\n")
    console.expect(SHELL, 15)
    digest = console.command("bash -n /prepare-bound16.sh && busybox sha256sum /prepare-bound16.sh")
    require(exact_line(digest, SOURCE_HASH + "  /prepare-bound16.sh"), "Transferred script hash mismatch")
    prepared = console.command("bash /prepare-bound16.sh --prepare-only; echo PREPARE_STATUS=$?", SHELL, 45)
    check_prepare(prepared)
    console.event("ram_patch_verified", source_sha256=SOURCE_HASH, patch_sha256=PATCH_HASH)
    console.buffer = b""
    console.send(b"exit\r")
    hooks = console.expect(rb"(?:^|\n)C8235_BOUND16_HOOK_COMPLETE(?:\n|$)", 90)
    require(exact_line(hooks, "C8235_BOUND16_HOOK_BEGIN"), "Hook BEGIN missing")
    require(b"HOOK_REFUSED" not in hooks, "Runtime hook refused")
    console.event("runtime_hook_complete")
    console.expect(WELCOME, 240)
    console.command("", IOS)
    console.command("enable", IOS)
    console.command("terminal length 0", IOS)
    console.command("terminal width 512", IOS)
    console.event("ios_prompt_reached", qualification="Health/stability checks still required")
    deadline = time.monotonic() + 120
    while not platform_ready(console.command("show platform", IOS)):
        require(time.monotonic() < deadline, "F0/R0/0/0 readiness timeout")
        until = time.monotonic() + 5
        while time.monotonic() < until:
            console.receive(min(0.5, until - time.monotonic()))
    console.event("platform_ready", qualification="Boot readiness only; keepalive, config and stability checks still required")


def hold(console):
    console.event("supervised_capture", controls="JSON send/close; no automatic retries")
    while True:
        ready, _, _ = select.select([sys.stdin, console.fd], [], [], 1)
        if console.fd in ready:
            console.receive(0)
            console.buffer = console.buffer[-65536:]
        if sys.stdin in ready:
            line = sys.stdin.readline()
            if not line:
                return
            try:
                control = json.loads(line)
                if control.get("close"):
                    return
                if "baud" in control:
                    console.baud(int(control["baud"]))
                if "send" in control:
                    console.send(control["send"].encode())
                    console.event("supervised_command_sent")
            except (ValueError, Refused) as exc:
                console.event("control_refused", reason=str(exc))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--plan", action="store_true")
    modes.add_argument("--reload-from-ios", action="store_true")
    modes.add_argument("--wait-reset", action="store_true")
    modes.add_argument("--reset-from-rommon", action="store_true")
    parser.add_argument("--port")
    parser.add_argument("--confirmed-chassis", choices=["FGL2835LBHU"])
    args = parser.parse_args(argv)
    payload = SOURCE.read_bytes()
    payload_chunks(payload)
    if not (args.reload_from_ios or args.wait_reset or args.reset_from_rommon):
        print(json.dumps({"chassis": "FGL2835LBHU", "image": IMAGE, "image_sha256": IMAGE_HASH,
                          "source_sha256": SOURCE_HASH, "parameter": PARAM,
                          "requires": "Fresh physical confirmation; exclusive console; preserved running/startup/boot state",
                          "writes": "RAM only; reload mode declines config save; no environment sync",
                          "result": "Console-assisted boot only; does not establish standalone persistence"}, indent=2))
        return 0
    require(args.port and args.confirmed_chassis, "Explicit port and current physical chassis confirmation required")
    os.umask(0o077)
    directory = ROOT / ".git/recovery-private/c8235-analysis-20261031/repeatable-boot" / datetime.now().strftime("%Y%m%d-%H%M%S")
    directory.mkdir(parents=True, exist_ok=False)
    console = Console(args.port, directory)
    try:
        mode = "reload" if args.reload_from_ios else "rommon-reset" if args.reset_from_rommon else "wait-reset"
        console.event("trial_started", mode=mode, evidence=str(directory),
                      helper_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
        try:
            if args.reload_from_ios:
                reload_from_ios(console)
            elif args.reset_from_rommon:
                console.command("", ROMMON)
                console.buffer = b""
                console.send(b"reset\r")
            boot_once(console, payload)
        except (Refused, OSError) as exc:
            console.baud(115200)
            console.event("trial_stopped", reason=str(exc), automatic_retry=False)
        hold(console)
    finally:
        console.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
