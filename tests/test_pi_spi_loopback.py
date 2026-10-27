"""Offline tests only; never open GPIO/SPI."""
import contextlib
import io
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_spi_loopback as loopback


class LoopbackTests(unittest.TestCase):
    def test_pattern_coverage_and_determinism(self):
        self.assertEqual(loopback.pattern_bytes("ones", 17), bytes([255]) * 17)
        self.assertEqual(set(loopback.pattern_bytes("ramp", 517)), set(range(256)))
        self.assertEqual(loopback.pattern_bytes("pseudorandom", 517),
                         loopback.pattern_bytes("pseudorandom", 517))
        with self.assertRaises(ValueError):
            loopback.pattern_bytes("unknown", 4)

    def test_comparison_detects_direction_and_incomplete_data(self):
        result = loopback.compare(bytes([255, 0, 85]), bytes([127, 1, 85]))
        self.assertEqual(result["different_bytes"], 2)
        self.assertEqual(result["different_bits"], 2)
        self.assertEqual(result["lost_one_bits"], 1)
        self.assertEqual(result["added_one_bits"], 1)
        self.assertEqual(result["first_difference_offset"], 0)
        self.assertEqual(result["last_difference_offset"], 1)
        with self.assertRaises(ValueError):
            loopback.compare(b"12", b"1")

    def test_matrix_compares_all_bytes_and_both_passes(self):
        report = {"tests": []}
        with contextlib.redirect_stdout(io.StringIO()):
            loopback.run_matrix(lambda data, speed: data, report, lambda: None)
        self.assertEqual(len(report["tests"]), 144)
        self.assertEqual(sum(t["bytes"] for t in report["tests"]), 166644)
        self.assertTrue(all(t["different_bits"] == 0 for t in report["tests"]))

    def test_default_and_help_do_not_open_device(self):
        with patch.object(loopback.os, "open", side_effect=AssertionError("device opened")):
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(loopback.main([]), 0)
                with self.assertRaises(SystemExit) as stopped:
                    loopback.main(["--help"])
                self.assertEqual(stopped.exception.code, 0)

    def test_explicit_modes_are_exclusive_and_report_correct_setup(self):
        with patch.object(loopback, "acquire", return_value=0) as acquire:
            self.assertEqual(loopback.main(["--adapter-loopback"]), 0)
            acquire.assert_called_once_with("adapter-only")
            acquire.reset_mock()
            self.assertEqual(loopback.main(["--isolated-loopback"]), 0)
            acquire.assert_called_once_with("pi-only")
            with contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    loopback.main(["--isolated-loopback", "--adapter-loopback"])


if __name__ == "__main__":
    unittest.main()
