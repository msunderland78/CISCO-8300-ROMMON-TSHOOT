"""Offline bounded read/stop/preservation checks; no GPIO access."""
import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_gpio_u1_read as reader


class FakeSpi:
    def __init__(self, identity=b"\x20\xbb\x19", change=False):
        self.identity, self.change, self.passes, self.calls = identity, change, 0, []

    def transfer(self, packet):
        self.calls.append(packet)
        if packet[0] == 0x9f:
            self.passes += 1
            return b"\0" + self.identity
        if packet[0] != 0x13:
            raise AssertionError("Unexpected flash opcode")
        address = int.from_bytes(packet[1:5], "big")
        data = bytearray((address + i) % 256 for i in range(len(packet) - 5))
        if self.change and self.passes == 2 and address == reader.START:
            data[0] ^= 1
        return bytes(5) + data


class GpioU1Tests(unittest.TestCase):
    def capture(self, spi, directory):
        report = {}
        with patch.object(reader.os, "chown"):
            with contextlib.redirect_stdout(io.StringIO()):
                result = reader.capture(spi, report, directory, lambda: None)
        return result, report

    def test_expected_identity_and_two_exact_native_address_passes(self):
        with tempfile.TemporaryDirectory() as temp:
            spi = FakeSpi()
            result, report = self.capture(spi, Path(temp))
            self.assertTrue(result)
            self.assertEqual(len(report["samples"]), 2)
            self.assertEqual(report["comparison"]["different_bytes"], 0)
            reads = [p for p in spi.calls if p[0] == 0x13]
            self.assertEqual(len(reads), 16)
            self.assertEqual([int.from_bytes(p[1:5], "big") for p in reads[:8]],
                             list(range(reader.START, reader.START + 4096, 512)))
            path = Path(temp) / report["samples"][0]["file"]
            self.assertEqual(path.stat().st_size, 4096)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            with self.assertRaises(FileExistsError):
                self.capture(FakeSpi(), Path(temp))

    def test_bad_id_stops_before_any_array_read(self):
        with tempfile.TemporaryDirectory() as temp:
            spi = FakeSpi(identity=b"\0\0\0")
            with self.assertRaises(ValueError):
                self.capture(spi, Path(temp))
            self.assertEqual([p[0] for p in spi.calls], [0x9f])
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_mismatch_reports_absolute_address_and_retains_both(self):
        with tempfile.TemporaryDirectory() as temp:
            result, report = self.capture(FakeSpi(change=True), Path(temp))
            self.assertFalse(result)
            self.assertEqual(report["comparison"]["different_bytes"], 1)
            self.assertEqual(report["comparison"]["first_difference_address"], hex(reader.START))
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 2)

    def test_no_default_or_help_action(self):
        with patch.object(reader, "acquire", side_effect=AssertionError("hardware action")):
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit):
                    reader.main(["--help"])


if __name__ == "__main__":
    unittest.main()
