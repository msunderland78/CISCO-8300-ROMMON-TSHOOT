"""Offline acquisition guards; never open a programmer or SPI device."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "scripts" / "pi_u1_short_reads.py"
SPEC = importlib.util.spec_from_file_location("pi_u1_short_reads", SOURCE)
reader = importlib.util.module_from_spec(SPEC)
with patch.object(subprocess, "run", side_effect=AssertionError("subprocess on import")):
    SPEC.loader.exec_module(reader)


class PiU1ReadsTests(unittest.TestCase):
    def test_without_read_or_with_help_has_no_hardware_access(self):
        with patch.object(reader.subprocess, "run", side_effect=AssertionError("hardware access")):
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit) as stopped:
                    reader.main(["--help"])
                self.assertEqual(stopped.exception.code, 0)

    def test_compare_reports_absolute_offsets_and_rejects_incomplete_data(self):
        first = bytes(range(256)) * 256
        self.assertEqual(reader.compare_region(first, first, 0x1F0000)["different_bytes"], 0)
        changed = bytearray(first)
        changed[0] ^= 1
        changed[-1] ^= 1
        self.assertEqual(reader.compare_region(first, changed, 0x1F30000), {
            "different_bytes": 2,
            "first_difference": "0x01F30000",
            "last_difference": "0x01F3FFFF",
        })
        with self.assertRaises(ValueError):
            reader.compare_region(first, b"", 0)

    def test_active_flashrom_stops_before_creating_capture_directory(self):
        with patch.object(reader.subprocess, "run", return_value=subprocess.CompletedProcess([], 0)):
            with patch.object(reader.tempfile, "mkdtemp", side_effect=AssertionError("created capture")):
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(reader.main(["--read"]), 1)

    def run_fake_acquisition(self, mode):
        calls = []
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            old = home / "original.bin"
            old.write_bytes(b"preserved original")

            def fake_run(argv, **kwargs):
                if argv[0] == "pgrep":
                    return subprocess.CompletedProcess(argv, 1)
                calls.append(argv)
                self.assertEqual(argv[:2], ["sudo", "flashrom"])
                self.assertEqual(argv[argv.index("-c") + 1], "MT25QU256")
                self.assertEqual(argv[argv.index("-p") + 1], reader.PROGRAMMER)
                self.assertIn("-r", argv)
                self.assertFalse({"-w", "-E", "-f", "--wp-disable"} & set(argv))
                if mode == "failure":
                    return subprocess.CompletedProcess(argv, 1)
                for index, value in enumerate(argv):
                    if value != "-i":
                        continue
                    region, filename = argv[index + 1].split(":", 1)
                    payload = bytearray(bytes(range(256)) * 256)
                    if mode == "short":
                        payload = payload[:-1]
                    if mode == "different" and len(calls) == 2 and region == "upper":
                        payload[-1] ^= 1
                    Path(filename).write_bytes(payload)
                return subprocess.CompletedProcess(argv, 0)

            with patch.object(reader.Path, "home", return_value=home):
                with patch.object(reader.subprocess, "run", side_effect=fake_run):
                    with contextlib.redirect_stdout(io.StringIO()):
                        code = reader.main(["--read"])
            self.assertEqual(old.read_bytes(), b"preserved original")
            captures = list(home.glob("C8375-U1-Pi100kHz-*"))
            self.assertEqual(len(captures), 1)
            directory = captures[0]
            self.assertEqual(directory.stat().st_mode & 0o777, 0o700)
            report = json.loads((directory / "comparison.json").read_text())
            for path in directory.iterdir():
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            return code, report, len(calls)

    def test_success_preserves_original_and_private_modes(self):
        code, report, calls = self.run_fake_acquisition("equal")
        self.assertEqual(code, 0)
        self.assertEqual(calls, 2)
        self.assertTrue(report["repeatable"])
        self.assertEqual(len(report["reads"]), 2)
        self.assertTrue(all(sample["bytes"] == 65536
                            for record in report["reads"]
                            for sample in record["samples"].values()))

    def test_failed_read_is_preserved_and_not_retried(self):
        code, report, calls = self.run_fake_acquisition("failure")
        self.assertEqual(code, 1)
        self.assertEqual(calls, 1)
        self.assertEqual(report["status"], "failed/interrupted")
        self.assertIn("placeholders", report["reads"][0]["status"])

    def test_wrong_size_stops_before_second_pass(self):
        code, report, calls = self.run_fake_acquisition("short")
        self.assertEqual(code, 1)
        self.assertEqual(calls, 1)
        self.assertIn("expected 65536", report["failure"])

    def test_different_samples_return_nonzero_with_absolute_difference(self):
        code, report, calls = self.run_fake_acquisition("different")
        self.assertEqual(code, 2)
        self.assertEqual(calls, 2)
        self.assertFalse(report["repeatable"])
        self.assertEqual(report["comparisons"]["upper"]["last_difference"], "0x01F3FFFF")


if __name__ == "__main__":
    unittest.main()
