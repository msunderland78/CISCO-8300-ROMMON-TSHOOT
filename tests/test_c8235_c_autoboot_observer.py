"""Console guard checks using local pipes only; no router/serial access."""
import importlib.util
import io
import os
from pathlib import Path
import unittest

SOURCE = Path(__file__).resolve().parents[1] / (
    "experimental-recovery/c8235-c-bootflash-20261101/observe-one-autoboot.py")
SPEC = importlib.util.spec_from_file_location("c8235_c_observer", SOURCE)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
BANNER = (b"mirabile-arata, Revision: r2\nSDK112312-SoC1-SB-v12.1.22\n"
          b"Soc UUID: 13 FF FF 87 79 AD FB 83 CA 80 82 43 \nUUID Len: 0xC\n")


class ObserverTests(unittest.TestCase):
    def setUp(self):
        self.reader, self.writer = os.pipe()
        self.addCleanup(os.close, self.reader)
        self.addCleanup(os.close, self.writer)
        self.console = object.__new__(MODULE.OneAutobootConsole)
        self.console.fd = self.reader
        self.console.log = io.BytesIO()
        self.console.buffer = b""
        self.console.reset_tail = b""
        self.console.reset_count = 0
        self.sent = []
        self.events = []
        self.console.send = self.sent.append
        self.console.event = lambda state, **details: self.events.append((state, details))

    def feed(self, data):
        os.write(self.writer, data)
        self.assertEqual(self.console.receive(0), data)

    def test_fragmented_first_matching_boot_is_passive_then_next_is_stopped(self):
        self.feed(BANNER[:-4])
        self.assertEqual(self.sent, [])
        self.feed(BANNER[-4:])
        self.assertEqual(self.sent, [])
        self.assertEqual(self.console.reset_count, 1)
        self.feed(BANNER)
        self.assertEqual(self.sent, [b"\x03\x03\x03"])
        self.assertEqual(self.console.log.getvalue(), BANNER + BANNER)

    def test_wrong_identity_is_stopped_on_first_boot(self):
        self.feed(BANNER.replace(b"13 FF FF", b"14 FF FF"))
        self.assertEqual(self.sent, [b"\x03\x03\x03"])
        self.assertFalse(self.events[-1][1]["identity_matched"])

    def test_B_identity_is_stopped_on_first_boot(self):
        self.feed(BANNER.replace(b"83 CA 80 82 43", b"7C 6D E0 81 A7"))
        self.assertEqual(self.sent, [b"\x03\x03\x03"])

    def test_wrong_firmware_is_stopped_on_first_boot(self):
        self.feed(BANNER.replace(b"v12.1.22", b"v12.1.23"))
        self.assertEqual(self.sent, [b"\x03\x03\x03"])


if __name__ == "__main__":
    unittest.main()
