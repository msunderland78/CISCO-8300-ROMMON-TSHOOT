"""Offline tests; serial access is mocked, never opened on the test host."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).resolve().parents[1] / "scripts/c8300_console_capture.py"


def load_module():
    spec = importlib.util.spec_from_file_location("c8300_capture", SOURCE)
    module = importlib.util.module_from_spec(spec)
    with patch("os.open", side_effect=AssertionError("Import accessed hardware")):
        spec.loader.exec_module(module)
    return module


class ConsoleCaptureTests(unittest.TestCase):
    def test_import_and_baud_validation_without_hardware(self):
        module = load_module()
        for invalid in (1200, "9600", True, None):
            with self.assertRaises(ValueError):
                module.rate_value(invalid)
        self.assertEqual(module.aliases("/dev/cu.usbserial-test"),
                         ["/dev/cu.usbserial-test", "/dev/tty.usbserial-test"])

    def test_occupied_port_is_not_opened(self):
        module = load_module()
        argv = [str(SOURCE), "--live", "--port", "/dev/cu.usbserial-test",
                "--confirmed-pid", "C8300-1N1S-4T2X"]
        with patch.object(sys, "argv", argv), patch.object(module.subprocess, "run") as run, \
                patch.object(module.os, "open") as opened:
            run.return_value = subprocess.CompletedProcess([], 0, b"123\n", b"")
            with self.assertRaises(RuntimeError):
                module.main()
            opened.assert_not_called()

    def test_capture_preserves_bytes_without_transmitting_or_printing_them(self):
        module = load_module()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            stdin = io.StringIO('{"baud":115200}\n{"close":true}\n')
            stdout = io.StringIO()
            argv = [str(SOURCE), "--live", "--port", "/dev/cu.usbserial-test",
                    "--confirmed-pid", "C8300-1N1S-4T2X"]
            attrs = [0, 0, 0, 0, 0, 0, [0] * 32]
            owners = [subprocess.CompletedProcess([], 1, b"", b""),
                      subprocess.CompletedProcess([], 0, str(os.getpid()).encode() + b"\n", b"")]
            payload = b"boot-test\x00\xff\r\n"
            with contextlib.ExitStack() as stack:
                stack.enter_context(patch.object(module, "__file__", str(root / "scripts/capture.py")))
                stack.enter_context(patch.object(sys, "argv", argv))
                stack.enter_context(patch.object(sys, "stdin", stdin))
                stack.enter_context(contextlib.redirect_stdout(stdout))
                run = stack.enter_context(patch.object(module.subprocess, "run", side_effect=owners))
                stack.enter_context(patch.object(module.os, "open", return_value=123))
                closed = stack.enter_context(patch.object(module.os, "close"))
                stack.enter_context(patch.object(module.os, "umask"))
                stack.enter_context(patch.object(module.os, "read", return_value=payload))
                written = stack.enter_context(patch.object(module.os, "write"))
                stack.enter_context(patch.object(module.fcntl, "ioctl"))
                stack.enter_context(patch.object(module.termios, "tcgetattr", return_value=attrs))
                stack.enter_context(patch.object(module.termios, "tcsetattr"))
                stack.enter_context(patch.object(module.select, "select", side_effect=[
                    ([123], [], []), ([stdin], [], []), ([stdin], [], [])]))
                module.main()
                written.assert_not_called()
                closed.assert_called_once_with(123)
                self.assertEqual(run.call_args_list[1].args[0],
                                 ["lsof", "-t", "/dev/cu.usbserial-test"])
            logs = list(root.rglob("console.log"))
            self.assertEqual(len(logs), 1)
            self.assertEqual(logs[0].read_bytes(), payload)
            self.assertNotIn("boot-test", stdout.getvalue())
            status = json.loads(logs[0].with_name("status.json").read_text())
            self.assertEqual(status["received_bytes"], len(payload))
            self.assertEqual(status["baud"], 115200)
            self.assertEqual(status["phase_bytes"], 0)
            self.assertEqual(status["event"], "capture_closed")


if __name__ == "__main__":
    unittest.main()
