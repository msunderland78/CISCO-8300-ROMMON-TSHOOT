"""Offline C8235-A opcode bounds, failure stop and explicit-entry checks."""
import contextlib
import copy
import io
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_gpio_c8235_a_u2900_id as reader


class FakeSpi:
    def __init__(self, responses):
        self.responses = iter(responses)
        self.calls = []

    def transfer(self, packet):
        self.calls.append(packet)
        return next(self.responses)


class C8235IdentificationTests(unittest.TestCase):
    def run_probe(self, spi, report, saved):
        with contextlib.redirect_stdout(io.StringIO()):
            return reader.identify(spi, report, None,
                                   lambda: saved.append(copy.deepcopy(report)))

    def test_only_three_id_packets_no_array_or_write_commands(self):
        spi = FakeSpi([b"\xff\x20\xbb\x19"] * 3)
        report, saved = {}, []
        self.assertTrue(self.run_probe(spi, report, saved))
        self.assertEqual(spi.calls, [b"\x9f\x00\x00\x00"] * 3)
        self.assertEqual([r["id"] for r in report["identities"]], ["20bb19"] * 3)
        self.assertEqual(len(saved), 3)

    def test_first_bad_identity_is_saved_and_stops(self):
        for wrong in (b"\0\0\0\0", b"\xff\xff\xff\xff", b"\0\x20\xba\x19"):
            with self.subTest(response=wrong.hex()):
                spi = FakeSpi([wrong, b"\0\x20\xbb\x19"])
                report, saved = {}, []
                with self.assertRaisesRegex(ValueError, "Unexpected chip ID"):
                    self.run_probe(spi, report, saved)
                self.assertEqual(len(spi.calls), 1)
                self.assertEqual(saved[0]["identities"][0]["response_hex"], wrong.hex())

    def test_incomplete_or_extra_response_stops_without_retry(self):
        for response in (b"", b"\0\x20\xbb", b"\0\x20\xbb\x19\0"):
            with self.subTest(length=len(response)):
                spi = FakeSpi([response])
                report, saved = {}, []
                with self.assertRaisesRegex(ValueError, "Incomplete chip identification"):
                    self.run_probe(spi, report, saved)
                self.assertEqual(len(spi.calls), 1)
                self.assertEqual(saved[0]["identities"][0]["bytes_received"], len(response))

    def test_changed_second_identity_stops_before_third_transfer(self):
        spi = FakeSpi([b"\0\x20\xbb\x19", b"\0\xff\xff\xff"])
        report, saved = {}, []
        with self.assertRaises(ValueError):
            self.run_probe(spi, report, saved)
        self.assertEqual(len(spi.calls), 2)
        self.assertEqual(len(saved), 2)

    def test_default_help_and_explicit_entry(self):
        with patch.object(reader, "acquire", return_value=0) as acquire:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit):
                    reader.main(["--help"])
            acquire.assert_not_called()
            self.assertEqual(reader.main(["--identify"]), 0)
            acquire.assert_called_once_with()

    def test_hardware_request_has_c8235_target_identity(self):
        with patch.object(reader, "run_hardware", return_value=0) as hardware:
            self.assertEqual(reader.acquire(), 0)
        prefix, setup, diagnostic, metadata = hardware.call_args.args
        self.assertIn("C8235-A-FGL2835L42B-U2900", prefix)
        self.assertIn("FOC28292GUQ", setup)
        self.assertIs(diagnostic, reader.identify)
        self.assertEqual(metadata["physical_chip"], "U2900")
        self.assertEqual(metadata["opcodes"], ["0x9f RDID"])
        self.assertEqual(metadata["array_bytes_read"], 0)


if __name__ == "__main__":
    unittest.main()
