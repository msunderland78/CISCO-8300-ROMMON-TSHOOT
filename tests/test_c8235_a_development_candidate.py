"""Offline candidate integrity, parsing boundaries, and original preservation."""
from pathlib import Path
import struct
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import c8235_a_development_candidate as candidate


def package(tag, value):
    return tag + struct.pack("<I", (len(value) + 8) << 16) + value


def example(relative=True):
    image = bytearray(b"\xff" * 0x10000)
    offset, start, payload = 0x1000, 0x3000, bytes(range(251))
    parts = [package(b"OTAD", struct.pack("<II", 3, 0) + b"init.bin" + bytes(24))]
    if relative:
        parts.append(package(b"COIM", struct.pack("<II", 4, 1)))
    parts += [package(b"IDOL", struct.pack("<8I", 0, 0, 0, len(payload),
                                          start - offset if relative else start, 0, 0, 0)),
              package(b"IHSH", struct.pack("<II", 0, 32) + bytes.fromhex(candidate.sha(payload)))]
    signed = 48 + sum(map(len, parts))
    parts.append(package(b"TNSD", bytes(12)))
    total = 48 + sum(map(len, parts))
    header = struct.pack("<12I", 0x54494D48, 0x00300001, 1, total, signed, 0, 0, 0, 1, 0x402, 0, 0)
    image[offset:offset + total] = header + b"".join(parts)
    image[start:start + len(payload)] = payload
    return bytes(image), offset, start


class CandidateTests(unittest.TestCase):
    def test_relative_and_absolute_payload_addresses_verify(self):
        for relative in (False, True):
            image, offset, start = example(relative)
            record, spans = candidate.tim(image, offset)
            self.assertEqual(record["payload"]["start"], hex(start))
            self.assertTrue(record["payload"]["embedded_sha256_matches"])
            self.assertEqual(len(candidate.cover(image, [offset])), 1)
            self.assertEqual(spans[-1], (start, start + 251))

    def test_payload_corruption_rejected(self):
        image, offset, start = example()
        image = bytearray(image)
        image[start + 10] ^= 1
        with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
            candidate.tim(image, offset)

    def test_incorrect_address_mode_not_silently_accepted(self):
        image, offset, _ = example()
        image = bytearray(image)
        # Force an absolute location into a relative descriptor, while retaining digest.
        pos = image.index(b"IDOL")
        struct.pack_into("<I", image, pos + 24, 0x3000)
        with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
            candidate.tim(image, offset)

    def test_package_zero_length_and_overrun_rejected(self):
        for length in (0, 0xFFF0):
            image, offset, _ = example()
            image = bytearray(image)
            struct.pack_into("<I", image, offset + 52, length << 16)
            with self.assertRaises(ValueError):
                candidate.tim(image, offset)

    def test_truncated_header_and_payload_rejected(self):
        image, offset, start = example()
        for end in (offset + 47, offset + 80, start + 10):
            with self.assertRaises(ValueError):
                candidate.tim(image[:end], offset)

    def test_unclassified_bytes_and_overlapping_components_rejected(self):
        image, offset, _ = example()
        with self.assertRaisesRegex(ValueError, "Overlapping"):
            candidate.cover(image, [offset, offset])
        image = b"\0" + image[1:]
        with self.assertRaisesRegex(ValueError, "Unclassified"):
            candidate.cover(image, [offset])

    def test_composition_preserves_all_target_suffix_bytes_and_inputs(self):
        a, b = bytes(range(256)) * 16, bytes(reversed(range(256))) * 16
        result = candidate.compose(a, b, 1024)
        self.assertEqual(result[:1024], b[:1024])
        self.assertEqual(result[1024:], a[1024:])
        self.assertEqual(len(result), len(a))
        self.assertNotEqual(result, b)
        for boundary in (0, len(a), len(a) + 1):
            with self.assertRaises(ValueError):
                candidate.compose(a, b, boundary)

    def test_changed_runs_include_erase_boundaries_without_other_blocks(self):
        before = bytes(5 * 4096)
        after = bytearray(before)
        after[4095] = after[4096] = after[4 * 4096 + 1] = 1
        runs = candidate.changed_runs(before, after)
        self.assertEqual([(r["start"], r["end_exclusive"], r["differing_bytes"]) for r in runs],
                         [("0x0", "0x2000", 2), ("0x4000", "0x5000", 1)])

    def test_pair_hash_gate_and_exclusive_private_file(self):
        with tempfile.TemporaryDirectory() as directory:
            first, second = Path(directory) / "first.bin", Path(directory) / "second.bin"
            candidate.write_exclusive(first, b"original")
            candidate.write_exclusive(second, b"original")
            self.assertEqual(first.stat().st_mode & 0o777, 0o600)
            self.assertEqual(candidate.checked_pair(first, second, candidate.sha(b"original"), 8), b"original")
            with self.assertRaises(FileExistsError):
                candidate.write_exclusive(first, b"changed!")
            self.assertEqual(first.read_bytes(), b"original")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                candidate.checked_pair(first, second, "0" * 64, 8)
            second.write_bytes(b"different")
            with self.assertRaisesRegex(ValueError, "size mismatch"):
                candidate.checked_pair(first, second, candidate.sha(b"original"), 8)
            second.write_bytes(b"changed!")
            with self.assertRaisesRegex(ValueError, "pair differs"):
                candidate.checked_pair(first, second, candidate.sha(b"original"), 8)

    def test_fdt_bounds_and_property_content(self):
        tree = struct.pack(">I", 1) + bytes(4)
        tree += struct.pack(">III", 3, 4, 0) + struct.pack(">I", 32)
        tree += struct.pack(">II", 2, 9)
        names = b"num-rvu-vfs\0"
        total = 40 + len(tree) + len(names)
        blob = struct.pack(">10I", 0xD00DFEED, total, 40, 40 + len(tree), 0,
                           17, 16, 0, len(names), len(tree)) + tree + names
        self.assertEqual(candidate.fdt_properties(blob), {"/num-rvu-vfs": struct.pack(">I", 32)})
        with self.assertRaises(ValueError):
            candidate.fdt_properties(blob[:-1])
        broken = bytearray(blob)
        struct.pack_into(">I", broken, 52, 0xFFFFFFFF)
        with self.assertRaises(ValueError):
            candidate.fdt_properties(broken)


if __name__ == "__main__":
    unittest.main()
