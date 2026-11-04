"""Offline full-reader boundaries, preservation and fail-fast controls."""
import contextlib
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_spi_c8235_a_u2900_backup as reader


class Transfer:
    def __init__(self, mismatch=False, short=False, bad_id=False):
        self.calls, self.reads = [], 0
        self.mismatch, self.short, self.bad_id = mismatch, short, bad_id

    def __call__(self, packet, speed):
        self.calls.append(packet)
        if packet[0] == 0x9f:
            return bytes(4) if self.bad_id else b"\0\x20\xbb\x19"
        if packet[0] != 0x13:
            raise AssertionError("Unexpected opcode")
        self.reads += 1
        address = int.from_bytes(packet[1:5], "big")
        data = bytearray((address + i) % 251 for i in range(512))
        if self.mismatch and self.reads == 3:
            data[7] ^= 1
        response = bytes(5) + data
        return response[:-1] if self.short else response


class BackupTests(unittest.TestCase):
    def capture(self, transfer, directory, report, references=None):
        if references is None:
            references = {512: bytes((512 + i) % 251 for i in range(512))}
        with patch.object(reader, "CHIP_BYTES", 1024), patch.object(reader, "CHECKPOINT_BYTES", 512), \
                patch("pi_gpio_c8235_a_u2900_samples.os.chown"), contextlib.redirect_stdout(io.StringIO()):
            return reader.capture_pair(transfer, directory, report, lambda: None, references)

    def test_exact_pair_boundaries_hash_equality_and_original_permissions(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(), {}
            self.assertTrue(self.capture(transfer, Path(temp), report))
            self.assertTrue(report["pair_equal"])
            self.assertEqual([int.from_bytes(p[1:5], "big") for p in transfer.calls if p[0] == 0x13],
                             [0, 512, 0, 512])
            self.assertEqual(len(report["identities"]), 6)
            for entry in report["reads"]:
                path = Path(temp) / entry["file"]
                self.assertTrue(entry["complete"])
                self.assertEqual(path.stat().st_size, 1024)
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(list(Path(temp).glob("*.partial.bin")), [])

    def test_second_read_first_difference_stops_and_preserves_partial(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(mismatch=True), {}
            with self.assertRaisesRegex(ValueError, "Full reads differ"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(transfer.reads, 3)
            self.assertTrue(report["reads"][0]["complete"])
            second = report["reads"][1]
            self.assertFalse(second["complete"])
            self.assertEqual(second["first_difference_address"], "0x7")
            self.assertEqual((Path(temp) / second["file"]).stat().st_size, 512)

    def test_short_response_stops_preserving_original_response(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(short=True), {}
            with self.assertRaisesRegex(ValueError, "Incomplete"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(transfer.reads, 1)
            entry = report["reads"][0]
            self.assertEqual((Path(temp) / entry["incomplete_response_file"]).stat().st_size, 516)
            self.assertFalse(entry["complete"])

    def test_bad_id_prevents_first_array_transfer(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(bad_id=True), {}
            with self.assertRaisesRegex(ValueError, "ID"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(transfer.reads, 0)

    def test_gpio_reference_mismatch_stops_first_pass(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(), {}
            with self.assertRaisesRegex(ValueError, "GPIO sample"):
                self.capture(transfer, Path(temp), report, {0: bytes(512)})
            self.assertEqual(transfer.reads, 1)
            self.assertFalse(report["reference_checks"][0]["matches_GPIO"])

    def test_default_help_and_missing_qualification_are_inert(self):
        with patch.object(reader, "acquire") as acquire:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit):reader.main(["--help"])
                with self.assertRaises(SystemExit):reader.main(["--read-pair"])
            acquire.assert_not_called()

    def test_pinned_qualification_rejects_wrong_target_or_failed_comparison(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "qualification.json"
            record = {"status": "passed", "chassis": "C8235-A/FGL2835L42B",
                      "board": "FOC28292GUQ", "physical_chip": "U2900",
                      "reference_report_sha256": "reference",
                      "samples": [{"different_bytes_from_GPIO": 0, "requested_hz": 1000000,
                                   "chunk_bytes": 512} for _ in range(48)]}
            def save():
                raw = json.dumps(record).encode()
                path.write_bytes(raw)
                return hashlib.sha256(raw).hexdigest()
            digest = save()
            reader.validate_qualification(path, digest, "reference")
            with self.assertRaisesRegex(ValueError, "hash mismatch"):
                reader.validate_qualification(path, "0" * 64, "reference")
            record["physical_chip"] = "U2901"
            with self.assertRaises(ValueError):
                reader.validate_qualification(path, save(), "reference")
            record["physical_chip"] = "U2900"
            record["samples"][0]["different_bytes_from_GPIO"] = 1
            with self.assertRaises(ValueError):
                reader.validate_qualification(path, save(), "reference")


if __name__ == "__main__":
    unittest.main()
