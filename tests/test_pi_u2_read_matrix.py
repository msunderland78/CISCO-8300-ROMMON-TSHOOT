"""Offline U2 protocol/stop/preservation tests; no SPI or GPIO access."""
import contextlib
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_u2_read_matrix as reader
import pi_u1_direct_read as direct


class FakeTransfer:
    def __init__(self, identity=b"\x20\xbb\x19", change=False):
        self.identity, self.change, self.identities, self.calls = identity, change, 0, []

    def __call__(self, packet, speed):
        self.calls.append((packet, speed))
        if packet == b"\x9f\0\0\0":
            self.identities += 1
            return b"\0" + self.identity
        if packet[0] != 0x13:
            raise AssertionError("Unexpected flash opcode")
        address = int.from_bytes(packet[1:5], "big")
        data = bytearray((a ^ (a >> 8) ^ (a >> 16) ^ (a >> 24)) & 255
                         for a in range(address, address + len(packet) - 5))
        if self.change and self.identities == 2 and address == 0x00FFFF00:
            data[0] ^= 1
        return bytes(5) + data


class U2MatrixTests(unittest.TestCase):
    def run_capture(self, transfer, directory):
        report = {}
        result = reader.capture(transfer, directory, report, lambda: None,
            addresses=(0x00FFFF00,), speeds=(100000,), chunks=(64, 512), size=512)
        return result, report

    def test_native_boundary_reads_repeat_and_match_across_chunk_shapes(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer = FakeTransfer()
            result, report = self.run_capture(transfer, Path(temp))
            self.assertTrue(result)
            self.assertEqual(len(report["samples"]), 4)
            self.assertEqual(len({s["sha256"] for s in report["samples"]}), 1)
            reads = [p for p, _ in transfer.calls if p[0] == 0x13]
            self.assertTrue(any(int.from_bytes(p[1:5], "big") >= 0x01000000 for p in reads))
            self.assertTrue(all(len(p) <= 517 for p in reads))
            for sample in report["samples"]:
                path = Path(temp) / sample["file"]
                self.assertEqual(path.stat().st_size, 512)
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            first = (Path(temp) / report["samples"][0]["file"]).read_bytes()
            with self.assertRaises(FileExistsError):
                self.run_capture(FakeTransfer(), Path(temp))
            self.assertEqual((Path(temp) / report["samples"][0]["file"]).read_bytes(), first)

    def test_wrong_id_stops_before_any_array_command(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer = FakeTransfer(identity=b"\0\0\0")
            with self.assertRaises(ValueError):
                self.run_capture(transfer, Path(temp))
            self.assertEqual(len(transfer.calls), 1)
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_mismatch_stops_and_preserves_both_originals(self):
        with tempfile.TemporaryDirectory() as temp:
            transfer = FakeTransfer(change=True)
            result, report = self.run_capture(transfer, Path(temp))
            self.assertFalse(result)
            self.assertEqual(len(report["samples"]), 2)
            self.assertEqual(report["comparisons"][0]["pair_different_bytes"], 1)
            self.assertEqual(len(list(Path(temp).glob("*.bin"))), 2)

    def test_short_responses_and_invalid_ranges_are_rejected(self):
        with self.assertRaises(ValueError):
            reader.read_at(lambda p, s: b"", 0, 512, 64, 100000)
        for address, size, chunk in [(33554431, 2, 64), (-1, 1, 64), (0, 1, 513)]:
            with self.assertRaises(ValueError):
                reader.read_at(FakeTransfer(), address, size, chunk, 100000)

    def test_default_help_and_missing_reset_ack_cannot_access_hardware(self):
        with patch.object(reader, "acquire", side_effect=AssertionError("SPI accessed")):
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                self.assertEqual(reader.main(["--u1-reset-low"]), 0)
                for args in (["--help"], ["--read"]):
                    with self.assertRaises(SystemExit):
                        reader.main(args)

    def test_controller_maximum_is_explicit_and_legacy_default_preserved(self):
        for speed in (100000, 1000000):
            fake = MagicMock()
            fake.ioctl.return_value = 0
            with patch.object(direct.ctypes, "CDLL", return_value=fake):
                direct.make_transfer(99, max_speed=speed)
            self.assertEqual(fake.ioctl.call_args_list[2].args[2]._obj.value, speed)
        for invalid in (0, 1000001, True):
            with self.assertRaises(ValueError):
                direct.make_transfer(99, max_speed=invalid)


if __name__ == "__main__":
    unittest.main()
