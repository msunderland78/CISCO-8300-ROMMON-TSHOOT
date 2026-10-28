"""Offline CS-only ordering, cleanup and duration checks."""
import contextlib
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_u1_cs_hold as hold


class FakePins:
    def __init__(self):
        self.writes = []

    def write(self, line, value):
        self.writes.append((line, value))


class CsHoldTests(unittest.TestCase):
    def test_stop_file_deselects_without_clock_or_byte_transfer(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            (directory / "stop").touch()
            pins, report = FakePins(), {}
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertTrue(hold.hold_control(pins, report, directory, lambda: None,
                                                 120, now=lambda: 0, sleep=lambda _: None))
            self.assertEqual(pins.writes, [(hold.CLK, 0), (hold.CS, 0), (hold.CLK, 0), (hold.CS, 1)])
            self.assertEqual(report["hold"]["end_reason"], "stop file requested")
            self.assertEqual(report["hold"]["flash_bytes_sent"], 0)

    def test_timeout_and_failure_both_restore_inactive_select(self):
        for fails in (False, True):
            with tempfile.TemporaryDirectory() as temp:
                pins, report, clock = FakePins(), {}, [0]
                def sleep(seconds):
                    if fails:
                        raise OSError("synthetic failure")
                    clock[0] += seconds
                with contextlib.redirect_stdout(io.StringIO()):
                    if fails:
                        with self.assertRaises(OSError):
                            hold.hold_control(pins, report, Path(temp), lambda: None,
                                              10, now=lambda: clock[0], sleep=sleep)
                    else:
                        hold.hold_control(pins, report, Path(temp), lambda: None,
                                          10, now=lambda: clock[0], sleep=sleep)
                self.assertEqual(pins.writes[-1], (hold.CS, 1))
                self.assertTrue(all(value == 0 for line, value in pins.writes if line == hold.CLK))

    def test_safe_default_help_and_bounded_explicit_entry(self):
        with patch.object(hold, "acquire", return_value=0) as acquire:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(hold.main([]), 0)
                with self.assertRaises(SystemExit):
                    hold.main(["--help"])
            acquire.assert_not_called()
            with contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    hold.main(["--hold-u1-cs-low", "--seconds", "181"])
            acquire.assert_not_called()
            self.assertEqual(hold.main(["--hold-u1-cs-low", "--seconds", "120"]), 0)
            acquire.assert_called_once_with(120)


if __name__ == "__main__":
    unittest.main()
