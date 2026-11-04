"""Offline SPI reference comparison and early-stop tests; no device access."""
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
import pi_spi_c8235_a_u2900_read as reader


def data_at(address, length):
    return bytes((address + i) % 251 for i in range(length))


class Transfer:
    def __init__(self, bad_id=False, mismatch=False, short=False):
        self.calls = []
        self.bad_id, self.mismatch, self.short = bad_id, mismatch, short

    def __call__(self, packet, speed):
        self.calls.append((packet, speed))
        if packet[0] == 0x9f:
            return bytes(4) if self.bad_id else b"\0\x20\xbb\x19"
        if packet[0] != 0x13:
            raise AssertionError("Unexpected opcode")
        data = bytearray(data_at(int.from_bytes(packet[1:5], "big"), len(packet) - 5))
        if self.mismatch:
            data[0] ^= 1
        response = bytes(5) + data
        return response[:-1] if self.short else response


class HardwareSampleTests(unittest.TestCase):
    def capture(self, transfer, directory, report):
        references = {a: data_at(a, 512) for a in reader.ADDRESSES}
        with patch("pi_gpio_c8235_a_u2900_samples.os.chown"), contextlib.redirect_stdout(io.StringIO()):
            return reader.capture(transfer, directory, report, lambda: None, references)

    def test_all_rates_shapes_match_reference_with_bounded_read_opcodes(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(), {}
            self.assertTrue(self.capture(transfer, Path(temp), report))
            self.assertEqual(len(report["samples"]), 48)
            self.assertEqual(len(report["identities"]), 51)
            self.assertEqual(report["array_bytes_received"], 24576)
            self.assertTrue(all(s["different_bytes_from_GPIO"] == 0 for s in report["samples"]))
            self.assertEqual({speed for _, speed in transfer.calls}, {100000, 500000, 1000000})
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 96)
            for packet, _ in transfer.calls:
                self.assertIn(packet[0], (0x9f, 0x13))
                if packet[0] == 0x13:
                    self.assertIn(len(packet), (69, 517))
                    self.assertLessEqual(int.from_bytes(packet[1:5], "big") + len(packet) - 5, 33554432)

    def test_bad_id_prevents_array_read(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(bad_id=True), {}
            with self.assertRaisesRegex(ValueError, "ID"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(len(transfer.calls), 1)
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_first_sample_mismatch_stops_before_second_sample(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(mismatch=True), {}
            with self.assertRaisesRegex(ValueError, "differs"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(len(report["samples"]), 1)
            self.assertEqual(len(transfer.calls), 9)
            self.assertEqual(report["samples"][0]["different_bytes_from_GPIO"], 8)
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 2)

    def test_incomplete_frame_preserved_and_stops_immediately(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer, report = Transfer(short=True), {}
            with self.assertRaisesRegex(ValueError, "Incomplete"):
                self.capture(transfer, Path(temp), report)
            self.assertEqual(len(transfer.calls), 2)
            self.assertFalse(report["samples"][0]["complete"])
            self.assertEqual(next(Path(temp).glob("*.bin")).stat().st_size, 68)

    def test_reference_identity_hash_and_sample_validation(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            report = {"status": "passed", "chassis": "C8235-A/FGL2835L42B",
                      "board": "FOC28292GUQ", "physical_chip": "U2900", "samples": []}
            for address in reader.ADDRESSES:
                for number in (1, 2, 3):
                    name = f"{address:08x}-{number}.bin"
                    data = data_at(address, 512)
                    (directory / name).write_bytes(data)
                    report["samples"].append({"address": hex(address), "pass": number,
                                              "file": name, "sha256": hashlib.sha256(data).hexdigest()})
            raw = json.dumps(report).encode()
            (directory / "report.json").write_bytes(raw)
            digest = hashlib.sha256(raw).hexdigest()
            self.assertEqual(set(reader.load_references(directory, digest)), set(reader.ADDRESSES))
            with self.assertRaisesRegex(ValueError, "report hash"):
                reader.load_references(directory, "0" * 64)
            (directory / report["samples"][0]["file"]).write_bytes(b"changed")
            with self.assertRaisesRegex(ValueError, "sample size/hash"):
                reader.load_references(directory, digest)

    def test_help_default_and_missing_reference_do_not_open_hardware(self):
        with patch.object(reader, "acquire") as acquire:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit):
                    reader.main(["--help"])
                with self.assertRaises(SystemExit):
                    reader.main(["--samples"])
            acquire.assert_not_called()


if __name__ == "__main__":
    unittest.main()
