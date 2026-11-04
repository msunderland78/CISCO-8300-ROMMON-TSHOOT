"""Offline read bounds, early stops and preservation; no hardware access."""
import contextlib
import copy
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_gpio_c8235_a_u2900_samples as reader


class FakeSpi:
    def __init__(self, bad_id_at=None, short_read=False, change=False, uniform=False):
        self.calls, self.ids, self.reads = [], 0, 0
        self.bad_id_at, self.short_read = bad_id_at, short_read
        self.change, self.uniform = change, uniform

    def transfer(self, packet):
        self.calls.append(packet)
        if packet[0] == 0x9f:
            self.ids += 1
            return b"\0\0\0\0" if self.ids == self.bad_id_at else b"\0\x20\xbb\x19"
        if packet[0] != 0x13:
            raise AssertionError("Unexpected opcode")
        self.reads += 1
        address = int.from_bytes(packet[1:5], "big")
        data = bytearray((address // 512 + i) % 256 for i in range(512))
        if self.uniform:
            data[:] = b"\xff" * 512
        if self.change and self.reads == 5:
            data[7] ^= 0x05
        response = bytes(5) + data
        return response[:-1] if self.short_read else response


class SampleTests(unittest.TestCase):
    def run_capture(self, spi, directory, report):
        saved = []
        with patch.object(reader.os, "chown"), contextlib.redirect_stdout(io.StringIO()):
            result = reader.capture(spi, report, directory,
                                    lambda: saved.append(copy.deepcopy(report)))
        return result, saved

    def test_fixed_reads_both_halves_three_passes_only_read_opcodes(self):
        with tempfile.TemporaryDirectory() as temp:
            spi, report = FakeSpi(), {}
            result, saved = self.run_capture(spi, Path(temp), report)
            self.assertTrue(result)
            self.assertEqual(len(spi.calls), 25)
            self.assertEqual(spi.ids, 13)
            reads = [p for p in spi.calls if p[0] == 0x13]
            self.assertEqual([int.from_bytes(p[1:5], "big") for p in reads],
                             [0, 0x1f2000, 0x1000000, 0x1fffe00] * 3)
            self.assertTrue(all(len(p) == 517 and not any(p[5:]) for p in reads))
            self.assertEqual(report["array_bytes_received"], 6144)
            self.assertEqual(len(report["comparisons"]), 8)
            self.assertTrue(all(c["different_bytes"] == 0 for c in report["comparisons"]))
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 24)
            for sample in report["samples"]:
                p = Path(temp) / sample["file"]
                self.assertEqual(p.stat().st_mode & 0o777, 0o600)
                self.assertEqual(p.stat().st_size, 512)
            self.assertEqual(saved[-1]["array_bytes_received"], 6144)

    def test_initial_bad_id_prevents_any_array_read(self):
        with tempfile.TemporaryDirectory() as temp:
            spi, report = FakeSpi(bad_id_at=1), {}
            with self.assertRaisesRegex(ValueError, "chip ID"):
                self.run_capture(spi, Path(temp), report)
            self.assertEqual(len(spi.calls), 1)
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_later_bad_id_stops_and_keeps_prior_sample(self):
        with tempfile.TemporaryDirectory() as temp:
            spi, report = FakeSpi(bad_id_at=2), {}
            with self.assertRaises(ValueError):
                self.run_capture(spi, Path(temp), report)
            self.assertEqual(spi.reads, 1)
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 2)
            self.assertEqual(report["identities"][-1]["id"], "000000")

    def test_incomplete_read_retains_exact_raw_response_and_stops(self):
        with tempfile.TemporaryDirectory() as temp:
            spi, report = FakeSpi(short_read=True), {}
            with self.assertRaisesRegex(ValueError, "Incomplete SPI read"):
                self.run_capture(spi, Path(temp), report)
            self.assertEqual(len(spi.calls), 2)
            self.assertFalse(report["samples"][0]["complete"])
            files = list(Path(temp).iterdir())
            self.assertEqual(len(files), 1)
            self.assertEqual(files[0].stat().st_size, 516)

    def test_first_mismatch_stops_before_next_region_and_preserves_both(self):
        with tempfile.TemporaryDirectory() as temp:
            spi, report = FakeSpi(change=True), {}
            with self.assertRaisesRegex(ValueError, "Sample mismatch"):
                self.run_capture(spi, Path(temp), report)
            self.assertEqual(spi.reads, 5)
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 10)
            comparison = report["comparisons"][-1]
            self.assertEqual(comparison["different_bytes"], 1)
            self.assertEqual(comparison["different_bits"], 2)
            self.assertEqual(comparison["first_difference_address"], "0x7")

    def test_uniform_results_not_accepted_as_read_path_qualification(self):
        with tempfile.TemporaryDirectory() as temp:
            report = {}
            with self.assertRaisesRegex(ValueError, "uniform"):
                self.run_capture(FakeSpi(uniform=True), Path(temp), report)
            self.assertEqual(report["nonuniform_regions"], [])
            self.assertEqual(len(report["samples"]), 12)

    def test_original_file_never_overwritten(self):
        with tempfile.TemporaryDirectory() as temp, patch.object(reader.os, "chown"):
            path = Path(temp) / "sample.bin"
            reader.preserve(path, b"original")
            with self.assertRaises(FileExistsError):
                reader.preserve(path, b"replacement")
            self.assertEqual(path.read_bytes(), b"original")

    def test_default_help_and_explicit_entry(self):
        with patch.object(reader, "acquire", return_value=0) as acquire:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit):
                    reader.main(["--help"])
            acquire.assert_not_called()
            self.assertEqual(reader.main(["--read"]), 0)
            acquire.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
