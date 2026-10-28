"""Offline physical-chip label/entry/protocol checks for reverse controls."""
import contextlib
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_gpio_u1_read as shared_reader
import pi_gpio_u2_read as u2_reader
import pi_u1_cs_hold as shared_hold
import pi_u2_cs_hold as u2_hold


class U2ControlTests(unittest.TestCase):
    def test_reverse_control_metadata_and_callback_label(self):
        with patch.object(u2_hold, "run_hardware", return_value=0) as run:
            self.assertEqual(u2_hold.acquire(120), 0)
            args = run.call_args.args
            self.assertEqual(args[3]["physical_chip_controlled"], "U2")
            self.assertEqual(args[3]["physical_chip_measured"], "U1")
            with patch.object(u2_hold, "hold_control", return_value=True) as callback:
                args[2](None, {}, None, lambda: None)
                self.assertEqual(callback.call_args.kwargs["target_chip"], "U2")

    def test_u2_read_samples_use_u2_names_and_only_read_opcodes(self):
        class Spi:
            def transfer(self, packet):
                if packet[0] == 0x9f:
                    return b"\0\x20\xbb\x19"
                if packet[0] != 0x13:
                    raise AssertionError("Unexpected flash command")
                return bytes(len(packet))
        with tempfile.TemporaryDirectory() as temp:
            report = {}
            with patch.object(shared_reader.os, "chown"):
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertTrue(shared_reader.capture(Spi(), report, Path(temp), lambda: None, "U2"))
            self.assertEqual(len(list(Path(temp).glob("U2-*.bin"))), 2)
            self.assertEqual(len(list(Path(temp).glob("U1-*.bin"))), 0)
            self.assertEqual(report["comparison"]["different_bytes"], 0)

    def test_both_defaults_are_inert_and_explicit_entries_select_u2(self):
        for module in (u2_hold, u2_reader):
            with patch.object(module, "acquire", side_effect=AssertionError("hardware action")):
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(module.main([]), 0)
                    with self.assertRaises(SystemExit):
                        module.main(["--help"])
        with patch.object(u2_reader, "acquire", return_value=0) as acquire:
            self.assertEqual(u2_reader.main(["--read"]), 0)
            acquire.assert_called_once_with("U2")
        with patch.object(u2_hold, "acquire", return_value=0) as acquire:
            self.assertEqual(u2_hold.main(["--hold-u2-cs-low"]), 0)
            acquire.assert_called_once_with(120)

    def test_unknown_chip_rejected_before_io(self):
        with self.assertRaises(ValueError):
            shared_reader.capture(None, {}, None, lambda: None, "unknown")
        with self.assertRaises(ValueError):
            shared_reader.acquire("unknown")
        with self.assertRaises(ValueError):
            shared_hold.hold_control(None, {}, None, lambda: None, 120, target_chip="unknown")


if __name__ == "__main__":
    unittest.main()
