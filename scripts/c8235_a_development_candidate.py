#!/usr/bin/env python3
"""Offline, hash-pinned C8235-A candidate analysis; never accesses hardware.

AI-assisted research utility, Python standard library only. TIM field meanings
below are inferred from these exact images, corroborated by payload SHA-256 and
the embedded layout DTB. This is not a general TIM parser or signature verifier.
Original inputs are read-only. Derived bytes can only be saved beneath the
repository's private recovery directory, using exclusive creation.
"""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import struct
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parents[1]
SIZE = 0x2000000
BOUNDARY = 0xD10000
A_HASH = "17c8b589f6af59a47aa4d7c10a540e1bd6669136cf4da89ea130c6e9f206d6c5"
B_HASH = "cadaa2c651ae8c8157982fcd1015434f0e03c614dc07369c868e20f54dff4857"
RELEASE_HASH = "a84cad033d019a46d13b99b0908422fe421632b240e131716624402555e21c0e"
A_DIR = ROOT / ".git/recovery-private/c8235-a-20261103/full-pair-20261103-234026/originals"
B_DIR = ROOT / ".git/recovery-private/acquisitions/C8235-B-FGL2835LBHU/20261103-usb-reference-review"
RELEASE = ROOT / "ROMMON-extracted/soc1/mirabile_soc1_uefi64_rel_ios_upgrade_SPA.bin"
OFFSETS = (0x10000, 0x20000, 0x40000, 0xA0000, 0xD0000, 0x100000,
           0x460000, 0x490000, 0x4C0000, 0x540000, 0x600000, 0xA00000, 0xA60000)
NAMES = {"tim0", "gserp-cn10xx.fw", "scp_bl1.bin", "mcp_bl1.bin", "ecp_bl1.bin",
         "init.bin", "gserm-cn10xx.fw", "bl2.bin", "bl31.bin", "uefi.bin",
         "npc_mkex-cn10xx.fw", "cisco-bootstub.bin"}
TAGS = {b"BTAD", b"BSNI", b"VNAM", b"OTAD", b"TDOL", b"TASR", b"IDOL",
        b"IHSH", b"RTCC", b"COIM", b"TNSD"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def checked_pair(first, second, expected_hash, size=SIZE):
    a, b = first.read_bytes(), second.read_bytes()
    require(len(a) == len(b) == size, "Input size mismatch")
    require(a == b, "Input pair differs")
    require(sha(a) == expected_hash, "Input hash mismatch")
    return a


def tim(image, offset):
    """Decode only the observed TIM subset, rejecting incomplete boundaries."""
    require(offset >= 0 and offset + 48 <= len(image), "Truncated TIM header")
    words = struct.unpack_from("<12I", image, offset)
    require(words[:3] == (0x54494D48, 0x00300001, 1), "Unexpected TIM format")
    total, signed = words[3:5]
    require(48 <= signed < total <= 0x10000 and offset + total <= len(image),
            "Invalid TIM bounds")
    packages, pos = [], 48
    while pos < total:
        require(pos + 8 <= total, "Truncated TIM package")
        tag = bytes(image[offset + pos:offset + pos + 4])
        length = struct.unpack_from("<I", image, offset + pos + 4)[0] >> 16
        require(tag in TAGS and length >= 8 and length % 4 == 0,
                "Unknown or invalid TIM package")
        require(pos + length <= total, "TIM package exceeds header")
        require(pos >= signed or pos + length <= signed, "Package crosses signed boundary")
        require((pos < signed and tag != b"TNSD") or
                (pos == signed and tag == b"TNSD" and pos + length == total),
                "Unexpected signature package position")
        packages.append((tag, image[offset + pos + 8:offset + pos + length]))
        pos += length
    name, payload, digest, relative = None, None, None, False
    for tag, value in packages:
        if tag == b"OTAD" and len(value) >= 8 and struct.unpack_from("<I", value)[0] == 3:
            require(name is None, "Duplicate component name")
            name = value[8:].rstrip(b"\0").decode("ascii")
            require(name in NAMES, "Unrecognized component name")
        if tag == b"COIM":
            require(value == struct.pack("<II", 4, 1), "Unsupported COIM flags")
            relative = True
    for tag, value in packages:
        if tag == b"IDOL":
            require(payload is None and len(value) == 32, "Invalid payload descriptor")
            length, address = struct.unpack_from("<II", value, 12)
            start = address + (offset if relative else 0)
            require(length > 0 and start >= 0 and start + length <= len(image),
                    "Payload outside image")
            require(start >= offset + total, "Payload overlaps its TIM")
            payload = (start, start + length)
        if tag == b"IHSH":
            require(digest is None and len(value) == 40 and
                    struct.unpack_from("<II", value) == (0, 32), "Unsupported image digest")
            digest = value[8:].hex()
    require(name is not None, "Missing component name")
    require((payload is None) == (digest is None), "Unpaired payload/digest")
    spans = [(offset, offset + total)]
    record = {"offset": hex(offset), "name_in_header": name,
              "header_bytes": total, "signed_length_field": signed,
              "header_sha256": sha(image[offset:offset + total]),
              "packages": [tag.decode("ascii") for tag, _ in packages],
              "signature_authentication": "not performed; original bytes retained"}
    if payload:
        start, end = payload
        require(sha(image[start:end]) == digest, "Payload SHA-256 mismatch")
        spans.append(payload)
        record["payload"] = {"start": hex(start), "end_exclusive": hex(end),
                             "bytes": end - start, "sha256": digest,
                             "embedded_sha256_matches": True,
                             "address_interpretation": "TIM-relative" if relative else "absolute"}
    return record, spans


def cover(image, offsets):
    covered = bytearray(len(image))
    records = []
    for offset in offsets:
        record, spans = tim(image, offset)
        records.append(record)
        for start, end in spans:
            require(not any(covered[start:end]), "Overlapping firmware components")
            covered[start:end] = b"\1" * (end - start)
    require(all(c or value == 255 for c, value in zip(covered, image)),
            "Unclassified non-FF bytes outside components")
    return records


def fdt_properties(blob):
    """Bounded FDT token reader; no execution or arbitrary strings in output."""
    require(len(blob) >= 40, "Truncated FDT")
    magic, total, start, strings, _, version, _, _, string_size, tree_size = struct.unpack_from(
        ">10I", blob)
    require(magic == 0xD00DFEED and version >= 17 and total <= len(blob), "Invalid FDT")
    end = start + tree_size
    require(40 <= start < end <= total and 40 <= strings <= strings + string_size <= total,
            "Invalid FDT bounds")
    pos, stack, result = start, [], {}
    while pos + 4 <= end:
        token = struct.unpack_from(">I", blob, pos)[0]
        pos += 4
        if token == 1:
            stop = blob.index(0, pos, end)
            stack.append(blob[pos:stop].decode("ascii"))
            pos = (stop + 4) & ~3
        elif token == 2:
            require(bool(stack), "FDT node underflow")
            stack.pop()
        elif token == 3:
            require(pos + 8 <= end and bool(stack), "Truncated FDT property")
            length, name_offset = struct.unpack_from(">II", blob, pos)
            pos += 8
            require(pos + length <= end and name_offset < string_size, "Invalid FDT property")
            name_start = strings + name_offset
            name_end = blob.index(0, name_start, strings + string_size)
            key = "/".join(stack) + "/" + blob[name_start:name_end].decode("ascii")
            require(key not in result, "Duplicate FDT property")
            result[key] = blob[pos:pos + length]
            pos = (pos + length + 3) & ~3
        elif token == 4:
            pass
        elif token == 9:
            require(not stack, "Unclosed FDT nodes")
            return result
        else:
            raise ValueError("Unexpected FDT token")
    raise ValueError("Missing FDT end")


def embedded_dtbs(image, components):
    init = next(c["payload"] for c in components if c["name_in_header"] == "init.bin")
    start, end = int(init["start"], 16), int(init["end_exclusive"], 16)
    result, pos = [], start
    while (pos := image.find(b"\xd0\x0d\xfe\xed", pos, end)) >= 0:
        require(pos + 8 <= end, "Truncated embedded FDT")
        length = struct.unpack_from(">I", image, pos + 4)[0]
        require(pos + length <= end, "Embedded FDT outside payload")
        data = image[pos:pos + length]
        result.append(({"offset": hex(pos), "bytes": length, "sha256": sha(data)},
                       fdt_properties(data)))
        pos += length
    require(len(result) == 2, "Unexpected embedded FDT count")
    return result


def compose(target, donor, boundary):
    require(len(target) == len(donor) and 0 < boundary < len(target), "Invalid composition bounds")
    return donor[:boundary] + target[boundary:]


def changed_runs(before, after, block=4096):
    require(len(before) == len(after) and len(before) % block == 0, "Invalid block comparison")
    runs = []
    for start in range(0, len(before), block):
        if before[start:start + block] != after[start:start + block]:
            if runs and runs[-1][1] == start:
                runs[-1][1] += block
            else:
                runs.append([start, start + block])
    return [{"start": hex(start), "end_exclusive": hex(end), "bytes": end - start,
             "sectors_4096": (end - start) // block,
             "before_sha256": sha(before[start:end]), "after_sha256": sha(after[start:end]),
             "differing_bytes": sum(x != y for x, y in zip(before[start:end], after[start:end]))}
            for start, end in runs]


def write_exclusive(path, data):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    require(path.read_bytes() == data, "Derived file verification failed")


def analyze():
    a = checked_pair(A_DIR / "C8235-A-FGL2835L42B-U2900-full-read1.bin",
                     A_DIR / "C8235-A-FGL2835L42B-U2900-full-read2.bin", A_HASH)
    b = checked_pair(B_DIR / "linux-mtd0ro-read1.bin", B_DIR / "linux-mtd0ro-read2.bin", B_HASH)
    release = RELEASE.read_bytes()
    require(len(release) == BOUNDARY and sha(release) == RELEASE_HASH and a[:BOUNDARY] == release,
            "Current A release reference mismatch")
    ac, bc = cover(a[:BOUNDARY], OFFSETS), cover(b[:BOUNDARY], OFFSETS)
    ad, bd = embedded_dtbs(a, ac), embedded_dtbs(b, bc)
    require(ad[0][1] == bd[0][1], "Firmware layout FDT differs")
    changed = sorted(k for k in set(ad[1][1]) | set(bd[1][1]) if ad[1][1].get(k) != bd[1][1].get(k))
    vf = "/soc@0/pci@878020000000/rvu-admin@0/num-rvu-vfs"
    require(changed == [vf], "Unexpected runtime FDT difference")
    layout = []
    for key, value in bd[0][1].items():
        if "/firmware-layout/" in key and key.endswith("/reg"):
            require(len(value) == 8, "Unexpected layout reg size")
            start, size = struct.unpack(">II", value)
            layout.append({"node": key, "start": hex(start), "bytes": size,
                           "end_exclusive": hex(start + size)})
    candidate = compose(a, b, BOUNDARY)
    require(cover(candidate[:BOUNDARY], OFFSETS) == bc, "Candidate components differ from donor")
    runs = changed_runs(a, candidate)
    require(all(int(r["end_exclusive"], 16) <= BOUNDARY for r in runs), "Changes exceed boundary")
    # No names or arbitrary strings from unclassified suffixes are published.
    report = {
        "schema": 1, "date": datetime.now(ZoneInfo("America/New_York")).isoformat(),
        "task_ids": ["C8235-03", "C8235-01", "R-01"],
        "status": "offline experimental development-firmware restore candidate; NOT PROGRAMMED",
        "target": {"chassis": "C8235-A/FGL2835L42B", "board": "FOC28292GUQ", "chip": "U2900",
                   "pair_bytes_each": len(a), "pair_equal": True, "sha256": A_HASH},
        "donor": {"chassis": "C8235-B/FGL2835LBHU", "source": "logical /dev/mtd0ro spi0.0",
                  "physical_chip": "unresolved", "pair_bytes_each": len(b), "pair_equal": True,
                  "sha256": B_HASH, "firmware_provenance": "Historical B console: SDK112312-SoC1-SB-v12.1.22 development ROMMON"},
        "release": {"file": str(RELEASE.relative_to(ROOT)), "sha256": RELEASE_HASH,
                    "bytes": len(release), "matches_all_of_A_prefix": True},
        "method": "Observed TIM package lengths/IDOL/COIM/IHSH fields; corroborated by all payload SHA-256s and embedded layout. Not a general format specification.",
        "A_components": ac, "B_components": bc,
        "classification": {"headers_each": len(ac), "payload_hash_matches_each": 11,
                           "non_ff_bytes_outside_headers_and_payloads_in_prefix_each": 0,
                           "unclassified_suffix": "All A bytes retained; no role inferred merely from offset."},
        "embedded_layout": {"A": ad[0][0], "B": bd[0][0], "byte_hashes_equal": ad[0][0]["sha256"] == bd[0][0]["sha256"], "entries": layout,
                            "limitations": "The identical table also declares tee.bin at 0xac0000 overlapping the bootstub slot. No independent TIM there; actual hash-validated payload spans take precedence. Generic runtime DTB has other defaults; it is not a measured physical partition map."},
        "embedded_runtime_dtb": {"A": ad[1][0], "B": bd[1][0],
                                 "property_count_each": len(ad[1][1]),
                                 "only_property_difference": vf,
                                 "A_value": int.from_bytes(ad[1][1][vf], "big"),
                                 "B_value": int.from_bytes(bd[1][1][vf], "big"),
                                 "interpretation": "Original donor retained, including 32-VF setting. ROMMON recovery does not establish IOS stability; B required a separate runtime resource correction."},
        "candidate": {"bytes": len(candidate), "sha256": sha(candidate),
                      "composition": "B[0:0xd10000] + A[0xd10000:0x2000000]",
                      "replacement_window": {"start": "0x0", "end_exclusive": hex(BOUNDARY), "sha256": sha(candidate[:BOUNDARY])},
                      "preserved_window": {"start": hex(BOUNDARY), "end_exclusive": hex(SIZE),
                                           "bytes": SIZE - BOUNDARY, "sha256": sha(candidate[BOUNDARY:]),
                                           "exact_A_equality": candidate[BOUNDARY:] == a[BOUNDARY:]},
                      "differing_bytes_from_A": sum(r["differing_bytes"] for r in runs),
                      "changed_4096_byte_sectors": sum(r["sectors_4096"] for r in runs),
                      "changed_sector_runs": runs,
                      "signature_authentication": "not independently performed",
                      "compatibility": "plausible same-family recovery experiment, not proven on A",
                      "boot_test": "not performed", "hardware_write": "not performed"},
        "preserved_native_updater_regions": [
            {"label_from_A_native_flashmon": "board manufacturing data", "start": "0xfd0000", "end_exclusive": "0x1000000", "sha256": sha(a[0xfd0000:0x1000000]), "candidate_equal_A": candidate[0xfd0000:0x1000000] == a[0xfd0000:0x1000000]},
            {"label_from_A_native_flashmon": "monitor environment", "start": "0x1f30000", "end_exclusive": "0x1f50000", "sha256": sha(a[0x1f30000:0x1f50000]), "candidate_equal_A": candidate[0x1f30000:0x1f50000] == a[0x1f30000:0x1f50000]}],
        "limitations": ["B backup is not A's original and its physical bank remains unresolved.",
                        "U2901 unread; physical primary/golden selection unresolved; reading U2901 is optional preservation work.",
                        "Preserving signature bytes and matching embedded hashes is not cryptographic authentication or proof A will accept the image.",
                        "Fresh hardware identity, ownership, voltage/RESET and write/readback qualification remain before an actual flash experiment.",
                        "No fuse, TPM, provisioning, board/security-data patch, signature bypass, SoC2 substitution or hardware access in this utility."],
    }
    return candidate, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True,
                        help="New directory beneath .git/recovery-private; refuses existing directories")
    args = parser.parse_args()
    output = args.output_dir.resolve()
    require(output.is_relative_to((ROOT / ".git/recovery-private").resolve()), "Output must stay private")
    require(not output.exists(), "Output directory already exists")
    candidate, report = analyze()
    output.mkdir(mode=0o700, parents=True, exist_ok=False)
    name = "C8235-A-FGL2835L42B-U2900-B-development-code-A-preserved-EXPERIMENTAL.bin"
    write_exclusive(output / name, candidate)
    report["candidate"]["private_file"] = str((output / name).relative_to(ROOT))
    report["candidate"]["saved_file_byte_verified"] = True
    report["utility_sha256"] = sha(Path(__file__).read_bytes())
    write_exclusive(output / "analysis.json", (json.dumps(report, indent=2) + "\n").encode())
    print(json.dumps({"status": report["status"], "candidate_sha256": sha(candidate),
                      "report": str((output / "analysis.json").relative_to(ROOT)),
                      "changed_sectors": report["candidate"]["changed_4096_byte_sectors"]}))


if __name__ == "__main__":
    main()
