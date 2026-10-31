#!/usr/bin/env python3
"""Explicit small read-only C8375-A/U1 diagnostic using one full-duplex message.

AI-assisted original implementation. Linux/Python standard library only.
Flash opcodes are restricted to RDID (0x9f) and native four-byte READ (0x13).
No flash register, protection, erase or program command is issued.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import pwd
import subprocess
import tempfile
from datetime import datetime

DEVICE = "/dev/spidev0.0"
START = 0x001F2000
LENGTH = 4096
CHUNK = 512
SPEEDS = (100000, 10000)


class SpiTransfer(ctypes.Structure):
    _fields_ = [
        ("tx_buf", ctypes.c_uint64), ("rx_buf", ctypes.c_uint64),
        ("len", ctypes.c_uint32), ("speed_hz", ctypes.c_uint32),
        ("delay_usecs", ctypes.c_uint16), ("bits_per_word", ctypes.c_uint8),
        ("cs_change", ctypes.c_uint8), ("tx_nbits", ctypes.c_uint8),
        ("rx_nbits", ctypes.c_uint8), ("word_delay_usecs", ctypes.c_uint8),
        ("pad", ctypes.c_uint8),
    ]


def read_packet(address, count):
    if not 0 <= address < 33554432 or not 1 <= count <= CHUNK:
        raise ValueError("Read outside the fixed chip/chunk limits")
    if address + count > 33554432:
        raise ValueError("Read crosses end of chip")
    return b"\x13" + address.to_bytes(4, "big") + bytes(count)


def read_block(transfer, speed):
    output = bytearray()
    for address in range(START, START + LENGTH, CHUNK):
        packet = read_packet(address, CHUNK)
        response = transfer(packet, speed)
        if len(response) != len(packet):
            raise ValueError("Incomplete SPI response")
        output.extend(response[5:])
    if len(output) != LENGTH:
        raise ValueError("Incomplete diagnostic block")
    return bytes(output)


def make_transfer(fd, max_speed=100000):
    if type(max_speed) is not int or not 1 <= max_speed <= 1000000:
        raise ValueError("Controller maximum must be between 1 Hz and 1 MHz")
    if ctypes.sizeof(SpiTransfer) != 32 or SpiTransfer.speed_hz.offset != 20:
        raise RuntimeError("Unexpected Linux SPI ioctl structure layout")
    libc = ctypes.CDLL(None, use_errno=True)
    libc.ioctl.argtypes = [ctypes.c_int, ctypes.c_ulong, ctypes.c_void_p]
    libc.ioctl.restype = ctypes.c_int

    def ioctl(request, value):
        result = libc.ioctl(fd, request, ctypes.byref(value))
        if result < 0:
            error = ctypes.get_errno()
            raise OSError(error, os.strerror(error))
        return result

    # Controller settings only. These ioctls do not send flash commands.
    ioctl(0x40016B01, ctypes.c_uint8(0))       # SPI_IOC_WR_MODE, mode 0
    ioctl(0x40016B03, ctypes.c_uint8(8))       # SPI_IOC_WR_BITS_PER_WORD
    ioctl(0x40046B04, ctypes.c_uint32(max_speed)) # SPI_IOC_WR_MAX_SPEED_HZ

    def transfer(packet, speed):
        tx = (ctypes.c_uint8 * len(packet)).from_buffer_copy(packet)
        rx = (ctypes.c_uint8 * len(packet))()
        message = SpiTransfer(
            tx_buf=ctypes.addressof(tx), rx_buf=ctypes.addressof(rx),
            len=len(packet), speed_hz=speed, bits_per_word=8,
        )
        # SPI_IOC_MESSAGE(1): command/address/data clocked under one CS assertion.
        result = ioctl(0x40206B00, message)
        if result != len(packet):
            raise ValueError("SPI ioctl returned an incomplete transfer length")
        return bytes(rx)

    return transfer


def acquire():
    os.umask(0o077)
    if subprocess.run(["pgrep", "-x", "flashrom"], stdout=subprocess.DEVNULL).returncode == 0:
        raise RuntimeError("Another flashrom process is active; no SPI access")
    fd = os.open(DEVICE, os.O_RDWR)
    try:
        # Open as sudo when needed, then retain only the original user's privileges.
        if os.geteuid() == 0 and int(os.environ.get("SUDO_UID", "0")) != 0:
            uid, gid = int(os.environ["SUDO_UID"]), int(os.environ["SUDO_GID"])
            os.setgroups([])
            os.setgid(gid)
            os.setuid(uid)
        home = Path(pwd.getpwuid(os.getuid()).pw_dir)
        directory = Path(tempfile.mkdtemp(prefix="C8375-U1-direct512-", dir=home))
        report = {
            "started_at": datetime.now().astimezone().isoformat(),
            "chassis": "C8375-A/FDO2742M0FK", "physical_chip": "U1",
            "device": DEVICE, "address": hex(START), "bytes_per_sample": LENGTH,
            "chunk_bytes": CHUNK, "transaction": "single full-duplex SPI_IOC_MESSAGE(1)",
            "opcodes": ["0x9f RDID", "0x13 native 4-byte READ"],
            "directory": str(directory), "status": "started", "samples": [],
        }
        report_file = directory / "report.json"

        def save():
            report_file.write_text(json.dumps(report, indent=2) + "\n")

        save()
        try:
            transfer = make_transfer(fd)
            for speed in SPEEDS:
                identity = transfer(b"\x9f\x00\x00\x00", speed)[1:]
                report.setdefault("identities", {})[str(speed)] = identity.hex()
                save()
                if identity != b"\x20\xbb\x19":
                    raise ValueError("Incorrect chip ID; no force or automatic retry")
                pair = []
                for number in (1, 2):
                    data = read_block(transfer, speed)
                    name = f"U1-001f2000-{speed // 1000}kHz-read{number}.bin"
                    with (directory / name).open("xb") as stream:
                        stream.write(data)
                    pair.append(data)
                    report["samples"].append({
                        "file": name, "requested_kHz": speed // 1000, "pass": number,
                        "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                        "zero_bytes": data.count(0), "ff_bytes": data.count(255),
                    })
                    save()
                report.setdefault("pair_differences", {})[str(speed // 1000)] = sum(
                    a != b for a, b in zip(*pair)
                )
            report["status"] = "completed"
        except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
            report["status"] = "failed/interrupted"
            report["failure"] = str(error) or type(error).__name__
        report["finished_at"] = datetime.now().astimezone().isoformat()
        save()
        print(json.dumps(report, indent=2), flush=True)
        return 0 if report["status"] == "completed" else 1
    finally:
        os.close(fd)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--read", action="store_true", help="run the fixed U1 diagnostic")
    args = parser.parse_args(argv)
    if not args.read:
        parser.print_help()
        return 0
    return acquire()


if __name__ == "__main__":
    raise SystemExit(main())
