"""Offline tests for C8235-A write scope, fail-closed gates and full readback."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_c8235_a_u2900_restore as worker


class Transfer:
    def __init__(self, data, bad_id=False, corrupt=False, short=False):
        self.data, self.bad_id, self.corrupt, self.short = data, bad_id, corrupt, short
        self.calls = []

    def __call__(self, packet, speed):
        self.calls.append(packet)
        if packet[0] == 0x9F:
            return b"\0\0\0\0" if self.bad_id else b"\0\x20\xbb\x19"
        if packet[0] == 0x05:
            return b"\0\0"
        if packet[0] == 0x70:
            return b"\0\x80"
        if packet[0] != 0x13:
            raise AssertionError("Readback must not write or change flash mode")
        address = int.from_bytes(packet[1:5], "big")
        data = bytearray(self.data[address:address + len(packet) - 5])
        if self.corrupt and address == 512:
            data[-1] ^= 1
        result = bytes(5) + data
        return result[:-1] if self.short else result


class RestoreTests(unittest.TestCase):
    def test_hash_size_preservation_and_sector_plan_gates(self):
        before = bytes(3 * 4096)
        changed = b"\1" + before[1:]
        with patch.multiple(worker, SIZE=len(before), BOUNDARY=4096,
                            BEFORE_HASH=worker.sha(before), CANDIDATE_HASH=worker.sha(changed),
                            EXPECTED_SECTORS=1, EXPECTED_RUNS=1):
            self.assertEqual(worker.validate_inputs(before, changed), [[0, 4096]])
            with self.assertRaisesRegex(ValueError, "backup hash"):
                worker.validate_inputs(changed, changed)
            with self.assertRaisesRegex(ValueError, "Candidate hash"):
                worker.validate_inputs(before, before)
            with self.assertRaisesRegex(ValueError, "size"):
                worker.validate_inputs(before, changed[:-1])
            bad = changed[:-1] + b"\1"
            with patch.object(worker, "CANDIDATE_HASH", worker.sha(bad)):
                with self.assertRaisesRegex(ValueError, "preserved suffix"):
                    worker.validate_inputs(before, bad)
            with patch.object(worker, "EXPECTED_SECTORS", 2):
                with self.assertRaisesRegex(ValueError, "sector plan"):
                    worker.validate_inputs(before, changed)

    def test_layout_is_inclusive_and_command_keeps_verification(self):
        self.assertEqual(worker.layout_text([[0x10000, 0x12000], [0x20000, 0x21000]]),
                         "00010000:00011fff fw00\n00020000:00020fff fw01\n")
        command = worker.write_command(Path("/private-run"), 27)
        self.assertEqual(command.count("-i"), 27)
        self.assertIn("fw26", command)
        self.assertIn("--sacrifice-ratio", command)
        self.assertIn("/private-run/candidate.bin", command)
        for forbidden in ("-n", "-N", "-f", "-E", "--wp-disable", "--noverify"):
            self.assertNotIn(forbidden, command)

    def test_id_status_rejects_errors_protection_and_bad_identity(self):
        self.assertEqual(worker.id_status(Transfer(b""))["fsr"], 128)
        with self.assertRaisesRegex(ValueError, "ID"):
            worker.id_status(Transfer(b"", bad_id=True))
        for sr, fsr in ((1, 128), (4, 128), (128, 128), (0, 0), (0, 160), (0, 144), (0, 130)):
            def transfer(packet, speed):
                return {0x9F: b"\0\x20\xbb\x19", 0x05: bytes([0, sr]), 0x70: bytes([0, fsr])}[packet[0]]
            with self.assertRaises(ValueError):
                worker.id_status(transfer)

    def capture(self, directory, transfer, data, report):
        with patch.object(worker, "SIZE", len(data)), contextlib.redirect_stdout(io.StringIO()):
            worker.capture_readback(transfer, Path(directory), data, report, lambda: None)

    def test_full_readback_matches_and_never_issues_write_opcode(self):
        data = bytes(range(256)) * 4
        with tempfile.TemporaryDirectory() as directory:
            transfer, report = Transfer(data), {}
            self.capture(directory, transfer, data, report)
            self.assertEqual(report["readback"]["sha256"], worker.sha(data))
            self.assertEqual(report["readback"]["differing_bytes"], 0)
            self.assertEqual(Path(directory, report["readback"]["file"]).read_bytes(), data)
            self.assertEqual([int.from_bytes(p[1:5], "big") for p in transfer.calls if p[0] == 0x13], [0, 512])
            self.assertEqual({p[0] for p in transfer.calls}, {0x9F, 0x05, 0x70, 0x13})

    def test_readback_mismatch_preserves_complete_original_and_fails(self):
        data = bytes(1024)
        with tempfile.TemporaryDirectory() as directory:
            report = {}
            with self.assertRaisesRegex(ValueError, "mismatch"):
                self.capture(directory, Transfer(data, corrupt=True), data, report)
            self.assertTrue(report["readback"]["complete"])
            self.assertEqual(report["readback"]["first_difference"], "0x3ff")
            self.assertEqual(report["readback"]["differing_bytes"], 1)
            self.assertEqual(Path(directory, report["readback"]["file"]).stat().st_size, 1024)

    def test_short_read_keeps_partial_and_bad_id_prevents_array_read(self):
        for arguments in ({"short": True}, {"bad_id": True}):
            with tempfile.TemporaryDirectory() as directory:
                transfer, report = Transfer(bytes(1024), **arguments), {}
                with self.assertRaises(ValueError):
                    self.capture(directory, transfer, bytes(1024), report)
                self.assertFalse(report["readback"]["complete"])
                self.assertTrue(Path(directory, report["readback"]["file"]).exists())
                if arguments.get("bad_id"):
                    self.assertNotIn(0x13, [p[0] for p in transfer.calls])

    def test_write_process_has_no_kill_timeout_and_nonzero_is_not_retried(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []
            def runner(command, **kwargs):
                calls.append(kwargs)
                return subprocess.CompletedProcess(command, 1)
            with self.assertRaisesRegex(ValueError, "no automatic write retry"):
                worker.run_phase(Path(directory), "write", ["mock-only"], {}, lambda: None, runner)
            self.assertEqual(len(calls), 1)
            self.assertIsNone(calls[0]["timeout"])

    def test_fresh_pre_read_mismatch_never_reaches_write(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "before.bin").write_bytes(b"before")
            (root / "candidate.bin").write_bytes(b"candidate")
            phases = []
            def phase(directory, name, command, report, save):
                phases.append(name)
                (directory / "U2900-prewrite-full-read.bin").write_bytes(b"mismatch")
            with patch.object(worker, "validate_inputs", return_value=[[0, 4096]]), \
                    patch.object(worker, "environment_gate"), patch.object(worker, "physical_gate", return_value={}), \
                    patch.object(worker, "run_phase", side_effect=phase), \
                    patch.object(worker.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, stdout="flashrom v1.6.0 mock")), \
                    contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(worker.execute(root, "mock-boot"), 1)
            self.assertEqual(phases, ["pre-read"])
            report = json.loads((root / "completion.json").read_text())
            self.assertIn("NO WRITE", report["failure"])
            self.assertFalse(report["complete"])

    def test_exclusive_outputs_preserve_existing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "write-once.lock"
            worker.exclusive(path, b"original")
            with self.assertRaises(FileExistsError):
                worker.exclusive(path, b"changed")
            self.assertEqual(path.read_bytes(), b"original")
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_help_has_no_hardware_effects(self):
        with patch.object(worker, "execute") as execute, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(worker.main([]), 0)
            execute.assert_not_called()


if __name__ == "__main__":
    unittest.main()
