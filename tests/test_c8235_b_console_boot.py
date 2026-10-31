"""Offline safety/transport checks. No router access or serial-port opening."""
import contextlib
import io
from pathlib import Path
import re
import sys
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import c8235_b_console_boot as boot


BANNER = ("Board Identifier: mirabile-arata, Revision: r2, Serial Number: unknown\r\n"
          "System Bootstrap, Version SDK112312-SoC1-SB-v12.1.22, DEVELOPMENT SOFTWARE\r\n"
          "Soc UUID: " + boot.UUID + " \r\nUUID Len: 0xC\r\nrommon 1 > ").encode()
PREPARED = ("C8235_BOUND16_BOOTSTRAP_READY\r\nPREPARE_STATUS=0\r\n"
            + boot.PATCH_HASH + "  /usr/binos/bin/launch_net.sh\r\n"
            + boot.HOOK_HASH + "  /c8235-bound16-hook.sh\r\n").encode()


class BootTests(unittest.TestCase):
    def test_plan_never_opens_console(self):
        with patch.object(boot, "Console") as console, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(boot.main(["--plan"]), 0)
            self.assertEqual(boot.main([]), 0)
            console.assert_not_called()

    def test_live_mode_requires_physical_confirmation(self):
        with patch.object(boot, "Console") as console:
            with self.assertRaises(boot.Refused):
                boot.main(["--wait-reset", "--port", "/not-a-port"])
            console.assert_not_called()

    def test_real_profile_banner_and_wrong_uuid(self):
        boot.check_banner(BANNER)
        for invalid in (BANNER.replace(b"81 A7", b"81 A8"),
                        BANNER.replace(b"Revision: r2", b"Revision: r3"),
                        BANNER.replace(b"SoC1", b"SoC2")):
            with self.assertRaises(boot.Refused):
                boot.check_banner(invalid)

    def test_echo_does_not_count_as_success(self):
        self.assertFalse(boot.exact_line(b"sh# echo PREPARE_STATUS=0\r\n", "PREPARE_STATUS=0"))
        boot.check_prepare(PREPARED)
        for invalid in (PREPARED.replace(b"STATUS=0", b"STATUS=1"),
                        PREPARED.replace(boot.HOOK_HASH.encode(), b"0" * 64),
                        b"echo C8235_BOUND16_BOOTSTRAP_READY\n" + PREPARED.replace(b"C8235_BOUND16_BOOTSTRAP_READY", b"FAILED")):
            with self.assertRaises(boot.Refused):
                boot.check_prepare(invalid)

    def test_both_observed_ios_welcome_punctuations(self):
        for line in (b"Press RETURN to get started!\r\n", b"Press RETURN to get started.\r\n"):
            self.assertIsNotNone(re.search(boot.WELCOME, line))

    def test_prompt_or_booting_subslot_is_not_platform_ready(self):
        data = b" 0/0      8M-2xSFP+           ok                    00:01:00\nR0        C8230X-8M2X         ok, active            00:01:46\nF0        C8230X-8M2X         ok, active            00:01:46\nRouter#"
        self.assertTrue(boot.platform_ready(data))
        self.assertFalse(boot.platform_ready(b"Router#"))
        self.assertFalse(boot.platform_ready(data.replace(b"ok                    ", b"booting               ")))
        self.assertFalse(boot.platform_ready(data.replace(b"F0", b"F1")))

    def test_transfer_is_bounded_and_exact(self):
        payload = boot.SOURCE.read_bytes()
        chunks = boot.payload_chunks(payload)
        self.assertEqual(b"".join(chunks), payload)
        self.assertTrue(all(len(c) <= 400 for c in chunks))
        self.assertTrue(payload.endswith(b"\n"))
        with self.assertRaises(boot.Refused):
            boot.payload_chunks(payload + b"\n")

    def test_wrong_boot_banner_never_sets_parameters(self):
        console = Mock()
        console.expect.return_value = BANNER.replace(b"81 A7", b"81 A8")
        with self.assertRaises(boot.Refused):
            boot.boot_once(console, boot.SOURCE.read_bytes())
        console.command.assert_not_called()
        console.send.assert_not_called()

    def test_image_mismatch_never_reloads(self):
        console = Mock()
        def command(value, *args):
            if value == "show inventory":
                return b"PID: C8230X-8M2X, VID: V00, SN: FGL2835LBHU\n"
            if value == "show version":
                return b"Version 26.02.01\nConfiguration register is 0x3922\n"
            return b"Router#"
        console.command.side_effect = command
        with self.assertRaises(boot.Refused):
            boot.reload_from_ios(console)
        self.assertFalse(any(c.args[0] == "reload" for c in console.command.call_args_list))

    def test_fragmented_prompt_and_timeout(self):
        console = boot.Console.__new__(boot.Console)
        console.buffer = b""
        fragments = iter([b"\r\nsh-", b"5.0# "])
        def receive(_):
            console.buffer += next(fragments)
        console.receive = receive
        self.assertEqual(console.expect(boot.SHELL, 1), b"\r\nsh-5.0# ")
        self.assertEqual(console.buffer, b"")
        console.receive = lambda _: None
        with self.assertRaises(boot.Refused):
            console.expect(boot.SHELL, 0)

    def test_stale_rommon_prompts_drained_before_command(self):
        console = boot.Console.__new__(boot.Console)
        console.buffer = b"rommon 1 > "
        events = []
        extra = iter([b"\r\nrommon 1 > ", b"\r\nrommon 1 > ", b""])
        def receive(_):
            data = next(extra)
            console.buffer += data
            events.append(("receive", data))
            return data
        console.receive = receive
        console.send = lambda data: events.append(("send", data))
        console.expect = lambda *args: events.append(("expect", console.buffer))
        console.command("set", boot.ROMMON)
        self.assertEqual(events[-2:], [("send", b"set\r"), ("expect", b"")])
        self.assertEqual(len(events), 5)

    def test_unexpected_reset_does_not_match_shell(self):
        console = boot.Console.__new__(boot.Console)
        console.buffer = b"UUID Len: 0xC\nsh-5.0# "
        with self.assertRaises(boot.Refused):
            console.expect(boot.SHELL, 1)

    def test_reset_during_drain_blocks_next_command(self):
        console = boot.Console.__new__(boot.Console)
        console.buffer = b"UUID Len: 0xC\nrommon 1 > "
        console.receive = lambda _: b""
        console.send = Mock()
        with self.assertRaises(boot.Refused):
            console.command("exit")
        console.send.assert_not_called()

    def test_existing_owner_refused_before_open(self):
        with patch.object(boot.subprocess, "run", return_value=Mock(returncode=0, stdout=b"123\n")), patch.object(boot.os, "open") as opened:
            with self.assertRaises(boot.Refused):
                boot.Console("/not-a-port", Path("/not-a-directory"))
            opened.assert_not_called()

    def test_prepare_failure_never_starts_init(self):
        console = Mock()
        console.expect.side_effect = [BANNER, b"EFI stub: Exiting boot services...", b"> ", b"sh-5.0# "]
        def command(value, *args):
            if value == "set":
                return ("USER_BOOT_PARAM=" + boot.PARAM + "\n").encode()
            if "cmdline" in value:
                return ("/bin/sh -c " + boot.PARAM.split(" -c ", 1)[1] + " \n").encode()
            if value.startswith("busybox sha256sum /verify-usb/"):
                return (boot.IMAGE_HASH + "  /verify-usb/" + boot.IMAGE + "\n").encode()
            if value.startswith("umount"):
                return b"UNMOUNT_STATUS=0\n"
            if value.startswith("bash -n"):
                return (boot.SOURCE_HASH + "  /prepare-bound16.sh\n").encode()
            if value.startswith("bash /prepare-bound16"):
                return PREPARED.replace(b"STATUS=0", b"STATUS=1")
            return b"sh-5.0# "
        console.command.side_effect = command
        with patch.object(boot.time, "monotonic", side_effect=[0, 9, 10, 11]), patch.object(boot.termios, "tcdrain") as drain:
            with self.assertRaises(boot.Refused):
                boot.boot_once(console, boot.SOURCE.read_bytes())
        drain.assert_called_once_with(console.fd)
        self.assertEqual([c.args[0] for c in console.baud.call_args_list], [9600, 115200])
        self.assertNotIn(b"exit\r", [c.args[0] for c in console.send.call_args_list])


if __name__ == "__main__":
    unittest.main()
