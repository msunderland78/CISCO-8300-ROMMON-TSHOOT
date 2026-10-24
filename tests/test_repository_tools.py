"""Regression checks for public evidence redaction and the upload size guard."""

import importlib.util
import contextlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock


SPEC = importlib.util.spec_from_file_location(
    "repository_tools", Path(__file__).resolve().parents[1] / "scripts/repository_tools.py"
)
TOOLS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOLS)


class PublicationTests(unittest.TestCase):
    def test_sync_refuses_a_different_branch_before_mutation(self):
        with mock.patch.object(TOOLS, "git", return_value=mock.Mock(stdout=b"other\n")) as command:
            with self.assertRaises(RuntimeError):
                TOOLS.sync("Test")
        command.assert_called_once_with("branch", "--show-current")

    def test_sync_refuses_an_unexpected_remote_before_mutation(self):
        responses = [mock.Mock(stdout=b"main\n"),
                     mock.Mock(stdout=b"https://example.invalid/repository.git\n")]
        with mock.patch.object(TOOLS, "git", side_effect=responses) as command:
            with self.assertRaises(RuntimeError):
                TOOLS.sync("Test")
        self.assertEqual(2, command.call_count)

    def test_recovery_prose_is_not_mistaken_for_a_configured_password(self):
        prose = "enable " + "secret was entered during setup, but not saved.\n"
        self.assertEqual([], TOOLS.findings(prose.encode()))

    def test_configured_plaintext_and_hashes_are_removed(self):
        plain = "example-" + "test-credential"
        hashed = "$" + "9$" + "X" * 58
        content = ("enable " + "secret 9 " + hashed + "\n"
                   + "username operator privilege 15 " + "password 0 " + plain + "\n")
        result = TOOLS.sanitize(content.encode(), {plain, hashed})
        self.assertNotIn(plain.encode(), result)
        self.assertNotIn(hashed.encode(), result)
        self.assertEqual([], TOOLS.findings(result, {plain, hashed}))
        self.assertEqual(2, result.count(TOOLS.MARKER.encode()))

    def test_setup_password_redacted_in_tx_echo_and_config(self):
        value = "example-" + "setup-credential"
        content = ("Enter enable " + "secret:\n"
                   + "[TX 2026-10-24T12:00:00] " + repr((value + "\r").encode())
                   + "\n" + value + "\n")
        self.assertEqual([value], list(TOOLS.prompt_replies(content)))
        result = TOOLS.sanitize(content.encode(), {value})
        self.assertNotIn(value.encode(), result)
        self.assertEqual([], TOOLS.findings(result, {value}))

    def test_weak_attempted_default_redacted_only_in_password_reply(self):
        value = "ci" + "sco"
        content = ("manufacturer=" + value + "\nPassword:\n"
                   + "[TX 2026-10-24T12:00:00] " + repr((value + "\r").encode()) + "\n")
        result = TOOLS.sanitize(content.encode(), {value})
        self.assertIn(("manufacturer=" + value).encode(), result)
        self.assertIn(TOOLS.MARKER.encode(), result)
        self.assertEqual([], TOOLS.findings(result, {value}))

    def test_tokens_private_keys_and_unknown_hashes_are_removed(self):
        token = "ghp_" + "Q" * 36
        key = "-----BEGIN " + "PRIVATE KEY-----\nTESTDATA\n-----END " + "PRIVATE KEY-----"
        hashed = "$" + "9$" + "Z" * 58
        content = "\n".join([token, key, hashed]).encode()
        self.assertTrue(TOOLS.findings(content))
        result = TOOLS.sanitize(content, set())
        self.assertEqual([], TOOLS.findings(result))
        self.assertNotIn(token.encode(), result)
        self.assertNotIn(b"TESTDATA", result)
        self.assertNotIn(hashed.encode(), result)

    def test_known_password_is_detected_inside_binary_image(self):
        value = "example-" + "binary-credential"
        data = b"\0\xffFIRMWARE" + value.encode() + b"\0TAIL"
        self.assertIn("known-password-or-hash", TOOLS.findings(data, {value}))

    def test_original_sources_and_sanitized_counterparts_are_distinct(self):
        original = "c8375-recovery/original-staged-firmware/pre-rommon-startup-20261023.txt"
        self.assertTrue(TOOLS.is_raw_source(original))
        self.assertTrue(TOOLS.is_raw_source("router-console-logs/example-console.log"))
        self.assertFalse(TOOLS.is_raw_source("sanitized-evidence/" + original))
        self.assertFalse(TOOLS.is_raw_source("C8235-G2-RECOVERY-CONTEXT.txt"))

    def test_at_limit_blob_blocked_before_reading_content(self):
        result = mock.Mock(stdout=str(TOOLS.LIMIT).encode())
        with mock.patch.object(TOOLS, "git", return_value=result) as command, \
                contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(RuntimeError):
                TOOLS.audit_blobs([("example-oid", "oversized.bin")], secrets=set())
        command.assert_called_once_with("cat-file", "-s", "example-oid")

    def test_preparation_preserves_original_log(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "router-console-logs/example.log"
            source.parent.mkdir()
            value = "example-" + "preserved-credential"
            raw = ("enable " + "secret 0 " + value + "\n").encode()
            source.write_bytes(raw)
            private = root / ".git/recovery-private"
            private.mkdir(parents=True)
            with mock.patch.object(TOOLS, "ROOT", root), \
                    mock.patch.object(TOOLS, "MANIFEST", root / "REPOSITORY-MANIFEST.json"), \
                    mock.patch.object(TOOLS, "private_dir", return_value=private), \
                    mock.patch.object(TOOLS, "ignored_paths", return_value={"router-console-logs/example.log"}), \
                    contextlib.redirect_stdout(io.StringIO()):
                TOOLS.prepare()
            self.assertEqual(raw, source.read_bytes())
            published = root / "sanitized-evidence/router-console-logs/example.log"
            self.assertNotIn(value.encode(), published.read_bytes())
            self.assertTrue((private / "known-secrets.json").exists())


if __name__ == "__main__":
    unittest.main()
