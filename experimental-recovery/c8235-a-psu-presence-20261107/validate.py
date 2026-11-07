#!/usr/bin/env python3
"""Offline differential AArch64 validation; requires unicorn==2.1.4.

AI-assisted original validation code. No serial, router or network access.
The ioctl is mocked: this checks code/ABI behavior, not hardware compatibility.
"""
import argparse
from datetime import datetime
import importlib.util
import itertools
import json
from pathlib import Path
import random
import struct
from zoneinfo import ZoneInfo

import unicorn
from unicorn import Uc, UC_ARCH_ARM64, UC_MODE_ARM, UC_HOOK_CODE
from unicorn.arm64_const import (UC_ARM64_REG_X0, UC_ARM64_REG_X1,
                                UC_ARM64_REG_X2, UC_ARM64_REG_X19,
                                UC_ARM64_REG_X20, UC_ARM64_REG_X29,
                                UC_ARM64_REG_X30, UC_ARM64_REG_SP,
                                UC_ARM64_REG_PC)


BASE = 0x100000
DATA = 0x500000
STOP = 0x700000
STACK = 0x901F00


def load_builder():
    path = Path(__file__).with_name("prepare.py")
    spec = importlib.util.spec_from_file_location("psu_prepare", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def emulate(library, status, fd=3, result=0, null=False):
    emu = Uc(UC_ARCH_ARM64, UC_MODE_ARM)
    for address, size in [(BASE, 0x40000), (DATA, 0x1000),
                          (STOP, 0x1000), (0x900000, 0x2000)]:
        emu.mem_map(address, size)
    phoff = struct.unpack_from("<Q", library, 32)[0]
    entsize, count = struct.unpack_from("<HH", library, 54)
    for index in range(count):
        kind, flags, offset, va, pa, filesz, memsz, align = struct.unpack_from(
            "<IIQQQQQQ", library, phoff + index * entsize)
        if kind == 1:
            emu.mem_write(BASE + va, library[offset:offset + filesz])
    emu.mem_write(BASE + 0x2FF60, struct.pack("<Q", DATA))
    emu.mem_write(BASE + 0x2FF78, struct.pack("<Q", DATA + 0x10))
    emu.mem_write(BASE + 0x2FFB8, struct.pack("<Q", DATA + 0x30))
    emu.mem_write(DATA, struct.pack("<i", fd))
    emu.mem_write(DATA + 0x10, b"\x01\x00")
    emu.mem_write(DATA + 0x20, struct.pack("<i", 5))
    output = DATA + 0x100
    emu.mem_write(output - 8, b"BEFORE!!" + b"\xa5" * 6 + b"AFTER!!!")
    preserved = {UC_ARM64_REG_X19: 0x19191919,
                 UC_ARM64_REG_X20: 0x20202020,
                 UC_ARM64_REG_X29: 0x29292929}
    for reg, value in preserved.items():
        emu.reg_write(reg, value)
    emu.reg_write(UC_ARM64_REG_SP, STACK)
    emu.reg_write(UC_ARM64_REG_X30, STOP)
    emu.reg_write(UC_ARM64_REG_X0, 0 if null else output)
    calls = []
    trace_calls = []

    def hook(machine, address, size, user_data):
        if address == STOP:
            machine.emu_stop()
            return
        if address == BASE + 0x4A60:  # Original ioctl PLT entry.
            assert machine.reg_read(UC_ARM64_REG_X0) == fd
            assert machine.reg_read(UC_ARM64_REG_X1) == 0x80066651
            assert machine.reg_read(UC_ARM64_REG_X2) == output
            calls.append(address)
            # Model an ioctl that fills the buffer even on error, to prove
            # failed reads are never overwritten with simulated presence.
            machine.mem_write(output, status)
            for reg in range(UC_ARM64_REG_X1, UC_ARM64_REG_X1 + 17):
                machine.reg_write(reg, 0xDEAD0000 + reg)
            machine.reg_write(UC_ARM64_REG_X0, result & 0xFFFFFFFF)
            machine.reg_write(UC_ARM64_REG_PC, machine.reg_read(UC_ARM64_REG_X30))
        elif address == BASE + 0x4A10:  # __errno_location
            machine.reg_write(UC_ARM64_REG_X0, DATA + 0x20)
            machine.reg_write(UC_ARM64_REG_PC, machine.reg_read(UC_ARM64_REG_X30))
        elif address in (BASE + 0x4670, BASE + 0x49E0):
            trace_calls.append(address)
            machine.reg_write(UC_ARM64_REG_X0, 0)
            machine.reg_write(UC_ARM64_REG_PC, machine.reg_read(UC_ARM64_REG_X30))

    emu.hook_add(UC_HOOK_CODE, hook)
    emu.emu_start(BASE + 0xBCC4, STOP + 4, count=300)
    assert emu.reg_read(UC_ARM64_REG_PC) == STOP
    assert emu.reg_read(UC_ARM64_REG_SP) == STACK
    for reg, value in preserved.items():
        assert emu.reg_read(reg) == value
    assert bytes(emu.mem_read(output - 8, 8)) == b"BEFORE!!"
    assert bytes(emu.mem_read(output + 6, 8)) == b"AFTER!!!"
    assert struct.unpack("<Q", emu.mem_read(BASE + 0x30B58, 8))[0] == 1
    return {"return": emu.reg_read(UC_ARM64_REG_X0) & 0xFFFFFFFF,
            "bytes": bytes(emu.mem_read(output, 6)),
            "ioctl_count": len(calls), "trace_count": len(trace_calls)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    builder = load_builder()
    original = args.source.read_bytes()
    candidate, patch, listing = builder.build(original)
    # Exhaust boolean status flags and include arbitrary non-boolean bytes.
    samples = [bytes(x) for x in itertools.product((0, 1), repeat=6)]
    rng = random.Random(8235)
    samples += [bytes(rng.randrange(256) for _ in range(6)) for _ in range(32)]
    cases = 0
    for status in samples:
        for result in (0, -1, 5):
            before = emulate(original, status, result=result)
            after = emulate(candidate, status, result=result)
            assert before["return"] == after["return"] == result & 0xFFFFFFFF
            assert before["ioctl_count"] == after["ioctl_count"] == 1
            assert before["bytes"] == status
            expected = b"\x01\x01" + status[2:] if result == 0 else status
            assert after["bytes"] == expected
            cases += 1
    for null, fd, expected in [(True, 3, 0xFFFFFFFF), (False, -1, 19)]:
        before = emulate(original, b"\0" * 6, fd=fd, null=null)
        after = emulate(candidate, b"\0" * 6, fd=fd, null=null)
        for observation in (before, after):
            assert observation["return"] == expected
            assert observation["bytes"] == b"\xa5" * 6
            assert observation["ioctl_count"] == 0
        cases += 1
    mutated = bytearray(original)
    mutated[0x80] ^= 1
    try:
        builder.build(bytes(mutated))
    except ValueError:
        pass
    else:
        raise AssertionError("Mutated source was accepted")
    report = {
        "recorded_at": datetime.now(ZoneInfo("America/New_York")).isoformat(),
        "unicorn_version": unicorn.__version__, "cases_passed": cases,
        "source_sha256": builder.digest(original),
        "candidate_sha256": builder.digest(candidate),
        "checks": ["64 boolean and 32 arbitrary status vectors, each with three ioctl results",
                   "null argument and unopened fd", "exact ioctl request and buffer pointer",
                   "caller-saved register clobber across ioctl", "callee-saved registers and stack",
                   "adjacent output-buffer canaries", "original function counter",
                   "only response bytes 0/1 forced after successful read; bytes 2-5 retained",
                   "failed read output/return retained", "source hash mismatch rejected",
                   "all library bytes outside the function unchanged"],
        "limits": "Offline emulation with mocked ioctl and trace calls; no router access, electrical test, hardware compatibility, or functional PoE result."
    }
    with args.report.open("x") as stream:
        stream.write(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"cases_passed": cases, "candidate_sha256": builder.digest(candidate)}))


if __name__ == "__main__":
    main()
