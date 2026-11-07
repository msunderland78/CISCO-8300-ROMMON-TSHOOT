"""Emulate exact vendor dispatch code offline; never open router hardware.

AI-assisted analysis utility. Requires Unicorn 2.1.4 and the hash-pinned local
26.02.01 libraries. Hardware, chassis-property and logging calls are mocked.
This checks software predicates, not controller population or PoE operation.
"""

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import struct
from zoneinfo import ZoneInfo


HASHES = {
    "libcmlib_ngio.so": "4c2d8e2099c3c7d9a1608ea75456eeb85bbedfeabbf04ba07dc1cf923dd99d88",
    "libmirabilesw.so": "376ed0b8c45832cc0ae7f6e62e3a0d471e75dc9741a7a3359ab2421e69ceca74",
}
STOP = 0x3f0000


def load_exact(directory, name):
    data = (directory / name).read_bytes()
    if hashlib.sha256(data).hexdigest() != HASHES[name]:
        raise ValueError(f"Unexpected source: {name}")
    if data[:6] != b"\x7fELF\x02\x01":
        raise ValueError("Expected little-endian ELF64")
    return data


def machine(data, api):
    uc = api["Uc"](api["UC_ARCH_ARM64"], api["UC_MODE_ARM"])
    uc.mem_map(0, 0x400000)
    uc.mem_map(0x500000, 0x100000)
    offset = struct.unpack_from("<Q", data, 32)[0]
    size, count = struct.unpack_from("<HH", data, 54)
    for index in range(count):
        kind, _, start, address, _, length, _, _ = struct.unpack_from(
            "<IIQQQQQQ", data, offset + index * size
        )
        if kind == 1:
            uc.mem_write(address, data[start:start + length])
    uc.reg_write(api["SP"], 0x5f0000)
    uc.reg_write(api["LR"], STOP)
    return uc


def run(directory):
    # Deferred import keeps ordinary module import dependency-free and inert.
    import unicorn
    from unicorn import arm64_const

    api = {name: getattr(unicorn, name) for name in
           ("Uc", "UC_ARCH_ARM64", "UC_MODE_ARM", "UC_HOOK_CODE")}
    for name in ("PC", "SP", "LR", "X0", "X3"):
        api[name] = getattr(arm64_const, "UC_ARM64_REG_" + name)

    def return_to_caller(uc, value=0):
        uc.reg_write(api["X0"], value & ((1 << 64) - 1))
        uc.reg_write(api["PC"], uc.reg_read(api["LR"]))

    cmlib = load_exact(directory, "libcmlib_ngio.so")
    switch = load_exact(directory, "libmirabilesw.so")
    enums = {}
    for name, expected in (("ARATA", 0x79), ("ARATA_E", 0x85)):
        uc = machine(cmlib, api)
        uc.mem_write(0x1ff50, struct.pack("<Q", 0x390000))
        uc.mem_write(0x20628, struct.pack("<Q", 1))

        def property_hook(uc, address, size, user):
            if address == 0x2a20:  # chasfs_property_get_string PLT
                uc.mem_write(uc.reg_read(api["X3"]), name.encode() + b"\0")
                return_to_caller(uc)

        uc.hook_add(api["UC_HOOK_CODE"], property_hook)
        uc.emu_start(0x66d4, STOP, count=10000)
        actual = uc.reg_read(api["X0"])
        if uc.reg_read(api["PC"]) != STOP or actual != expected:
            raise AssertionError((name, actual, expected))
        enums[name] = actual

    predicates = []
    for mask in range(64):
        flags = bytes((mask >> bit) & 1 for bit in range(6))
        expected = 0 if flags[4] and flags[1] else -2
        predicates.append((flags, 0, expected))
    predicates.append((bytes(6), -1, -1))
    for flags, status_result, expected in predicates:
        uc = machine(switch, api)
        for got, target in ((0x1ef6c8, 0x390000),
                            (0x1ef8d8, 0x390010),
                            (0x1ef7a8, 0x390020)):
            uc.mem_write(got, struct.pack("<Q", target))
        calls = []

        def presence_hook(uc, address, size, user):
            if address == 0x22d20:  # dash_fpga_get_poe_psu_status PLT
                calls.append("mocked_status")
                uc.mem_write(uc.reg_read(api["X0"]), flags)
                return_to_caller(uc, status_result)
            elif address == 0x22560:  # chassis enumeration PLT
                return_to_caller(uc, enums["ARATA"])
            elif address in (0x21fe0, 0x24fc0, 0x403b4):
                return_to_caller(uc)  # trace formatting only
            elif 0x21000 <= address < 0x27000:
                raise AssertionError(f"Unexpected external call: {address:#x}")

        uc.hook_add(api["UC_HOOK_CODE"], presence_hook)
        uc.emu_start(0xa4610, STOP, count=10000)
        actual = struct.unpack("<i", struct.pack(
            "<I", uc.reg_read(api["X0"]) & 0xffffffff))[0]
        if (uc.reg_read(api["PC"]) != STOP or actual != expected
                or calls != ["mocked_status"]):
            raise AssertionError((list(flags), status_result, actual, expected, calls))

    return {
        "recorded_at": datetime.now(ZoneInfo("America/New_York")).isoformat(),
        "scope": "Offline emulation only; all hardware/property/log calls mocked",
        "unicorn_version": unicorn.__version__,
        "source_sha256": HASHES,
        "chassis_enum_results": enums,
        "arata_presence_callback": "libmirabilesw.so+0xa4610",
        "arata_presence_predicate": "status[4] != 0 AND status[1] != 0",
        "status_read_error_result": -1,
        "false_presence_result": -2,
        "passed_cases": len(enums) + len(predicates),
        "limits": "No live runtime dispatch, physical presence, rail voltage, reset or firmware write tested",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library-directory", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    report = run(args.library_directory)
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(f"{report['passed_cases']} offline cases passed; no hardware access")


if __name__ == "__main__":
    main()
