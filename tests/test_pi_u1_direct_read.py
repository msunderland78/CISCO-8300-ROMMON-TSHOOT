"""Offline packet/response checks; no SPI or sudo access."""
import contextlib
import ctypes
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch

PATH = Path(__file__).resolve().parents[1] / 'scripts/pi_u1_direct_read.py'
SPEC = importlib.util.spec_from_file_location('pi_u1_direct_read', PATH)
reader = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reader)


class DirectReadTests(unittest.TestCase):
    def test_packet_is_native_read_and_explicit_big_endian_address(self):
        packet = reader.read_packet(0x001F2000, 512)
        self.assertEqual(packet[:5], bytes([0x13, 0, 0x1F, 0x20, 0]))
        self.assertEqual(len(packet), 517)
        self.assertEqual(packet[5:], bytes(512))
        for address, count in [(-1, 512), (33554431, 2), (0, 513), (0, 0)]:
            with self.assertRaises(ValueError):
                reader.read_packet(address, count)

    def test_reads_eight_exact_chunks_and_discards_command_phase_response(self):
        calls = []
        expected = bytes(range(256)) * 16

        def transfer(packet, speed):
            address = int.from_bytes(packet[1:5], 'big')
            offset = address - reader.START
            calls.append((address, speed, len(packet)))
            return bytes([0xAA]) * 5 + expected[offset:offset + 512]

        self.assertEqual(reader.read_block(transfer, 100000), expected)
        self.assertEqual([c[0] for c in calls], list(range(reader.START, reader.START + 4096, 512)))
        self.assertTrue(all(c[1:] == (100000, 517) for c in calls))
        with self.assertRaises(ValueError):
            reader.read_block(lambda packet, speed: b'', 100000)

    def test_default_and_help_never_open_spi(self):
        with patch.object(reader.os, 'open', side_effect=AssertionError('SPI opened')):
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(reader.main([]), 0)
                with self.assertRaises(SystemExit) as stopped:
                    reader.main(['--help'])
                self.assertEqual(stopped.exception.code, 0)

    def test_linux_fixed_width_structure_layout(self):
        self.assertEqual(ctypes.sizeof(reader.SpiTransfer), 32)
        self.assertEqual(reader.SpiTransfer.tx_buf.offset, 0)
        self.assertEqual(reader.SpiTransfer.rx_buf.offset, 8)
        self.assertEqual(reader.SpiTransfer.len.offset, 16)
        self.assertEqual(reader.SpiTransfer.speed_hz.offset, 20)
        self.assertEqual(reader.SpiTransfer.bits_per_word.offset, 26)


if __name__ == '__main__':
    unittest.main()
