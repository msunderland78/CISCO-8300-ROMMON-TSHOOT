#!/usr/bin/env python3
"""Build an offline, hash-guarded C8235-A PSU-presence experiment.

AI-assisted original utility. No hardware/network effects, including on import.
Never install the output in an IOS package or persistent filesystem. The only
intended live use is a supervised, temporary RAM overlay on confirmed Router A.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct


SOURCE_SHA256 = "ea570d093bdcbfb34edc534e1e4615e0ad7d32b01e78d0554b02952d65bcf791"
FUNCTION_SHA256 = "39e7a3e4ac53fc438050d5abb63f682d137710fbb8a4d68fe99058f92b2720c3"
START = 0xBCC4
END = 0xBD84


def digest(data):
    return hashlib.sha256(data).hexdigest()


def make_patch():
    # AArch64 instructions. Branch offsets are resolved below; all absolute
    # addresses refer to this exact ELF's link-time virtual addresses.
    ops = [
        ("stp x29,x30,[sp,#-32]!", 0xA9BE7BFD),
        ("stp x20,x19,[sp,#16]", 0xA9014FF4),
        ("mov x29,sp", 0x910003FD),
        ("adrp x8,0x30000", 0xB0000128),
        ("ldr x9,[x8,#0xb58]", 0xF945AD09),
        ("add x9,x9,#1", 0x91000529),
        ("str x9,[x8,#0xb58]", 0xF905AD09),
        ("mov x19,x0", 0xAA0003F3),
        ("cbz x19,null", ("cbz", 0xB4000013, "null")),
        ("adrp x8,0x2f000", 0x90000128),
        ("ldr x8,[x8,#0xf60]", 0xF947B108),
        ("ldr w0,[x8]", 0xB9400100),
        ("cmn w0,#1", 0x3100041F),
        ("b.eq badfd", ("cond", 0x54000000, "badfd")),
        ("mov w1,#0x6651", 0x528CCA21),
        ("movk w1,#0x8006,lsl #16", 0x72B000C1),
        ("mov x2,x19", 0xAA1303E2),
        ("bl ioctl@plt", ("branch", 0x94000000, 0x4A60)),
        ("cbnz w0,done", ("cbz", 0x35000000, "done")),
        ("mov w8,#0x0101", 0x52802028),
        ("strh w8,[x19]", 0x79000268),
        ("b done", ("branch", 0x14000000, "done")),
        ("null: mov w0,#-1", 0x12800000),
        ("b done", ("branch", 0x14000000, "done")),
        ("badfd: mov w0,#19", 0x52800260),
        ("done: ldp x20,x19,[sp,#16]", 0xA9414FF4),
        ("ldp x29,x30,[sp],#32", 0xA8C27BFD),
        ("ret", 0xD65F03C0),
    ]
    labels = {"null": START + 22 * 4, "badfd": START + 24 * 4,
              "done": START + 25 * 4}
    words = []
    listing = []
    for index, (description, encoding) in enumerate(ops):
        pc = START + index * 4
        if isinstance(encoding, tuple):
            kind, word, target = encoding
            target = labels[target] if isinstance(target, str) else target
            displacement = (target - pc) // 4
            if kind == "branch":
                word |= displacement & 0x3FFFFFF
            else:
                word |= (displacement & 0x7FFFF) << 5
        else:
            word = encoding
        words.append(word)
        listing.append({"va": hex(pc), "word": f"{word:08x}",
                        "instruction": description})
    while len(words) * 4 < END - START:
        words.append(0xD503201F)  # NOP padding inside original function only.
    assert len(words) * 4 == END - START
    return struct.pack("<" + "I" * len(words), *words), listing


def build(source):
    if digest(source) != SOURCE_SHA256:
        raise ValueError("Exact source-library hash mismatch")
    if digest(source[START:END]) != FUNCTION_SHA256:
        raise ValueError("Original function hash mismatch")
    patch, listing = make_patch()
    candidate = source[:START] + patch + source[END:]
    assert len(candidate) == len(source)
    assert candidate[:START] == source[:START]
    assert candidate[END:] == source[END:]
    return candidate, patch, listing


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path)
    parser.add_argument("--output-directory", type=Path)
    args = parser.parse_args()
    if args.source is None and args.output_directory is None:
        print("Plan only: explicit source and separate output directory required.")
        return
    if args.source is None or args.output_directory is None:
        parser.error("Both source and output directory are required")
    source = args.source.read_bytes()
    candidate, patch, listing = build(source)
    out = args.output_directory
    out.mkdir(parents=True, exist_ok=True)
    report = {
        "target": "C8235-A / FGL2835L42B / IOS XE 26.02.01",
        "status": "offline candidate; not a verified fix or restore artifact",
        "source_sha256": digest(source),
        "candidate_sha256": digest(candidate),
        "patch_sha256": digest(patch),
        "source_bytes": len(source),
        "modified_function": "dash_fpga_get_poe_psu_status",
        "file_offset_equals_va_start": hex(START),
        "end_exclusive": hex(END),
        "patch_bytes": len(patch),
        "effect": "After successful original status ioctl, set response bytes 0 and 1 to 1; retain bytes 2-5 and return status. Null argument returns -1; unopened fd returns 19. Hardware status/control registers are not written by this function.",
        "preserved": "Original ELF outside this function; ioctl request 0x80066651; six-byte real read; function counter; callee-saved registers and stack; controller/daughter-presence byte 4.",
        "difference_beyond_response": "The replacement omits the original wrapper's error trace calls. Error return values and ioctl output bytes are retained. This is an experiment, not production-quality error logging.",
        "rollback": "One unsynced boot only; reboot to the saved unmodified A4/AFIX1/packages.conf setup removes RAM overlay.",
        "instructions": listing,
    }
    for name, data in [("libdash_fpga_api.so", candidate), ("function-patch.bin", patch),
                       ("candidate.json", (json.dumps(report, indent=2) + "\n").encode())]:
        with (out / name).open("xb") as stream:
            stream.write(data)
    print(json.dumps({k: report[k] for k in
                      ["candidate_sha256", "patch_sha256", "patch_bytes"]}))


if __name__ == "__main__":
    main()
