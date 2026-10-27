"""Offline protocol and cleanup checks; no GPIO access or gpiod import."""
import contextlib
import io
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import pi_gpio_loopback as gpio


class GpioLoopbackTests(unittest.TestCase):
    def test_mode0_msb_order_and_settling_before_each_sample(self):
        state = {}
        events = []

        def write(line, value):
            state[line] = value
            events.append(("write", line, value))

        def read(line):
            self.assertEqual(line, gpio.MISO)
            self.assertEqual(state[gpio.CS], 0)
            self.assertEqual(state[gpio.CLK], 1)
            self.assertEqual(events[-1], ("wait",))
            events.append(("read",))
            return state[gpio.MOSI]

        spi = gpio.BitBang(write, read, lambda: events.append(("wait",)))
        self.assertEqual(spi.transfer(bytes([0xA5, 0x12])), bytes([0xA5, 0x12]))
        self.assertEqual([e[2] for e in events if e[:2] == ("write", gpio.MOSI)],
                         [int(b) for b in "1010010100010010"])
        self.assertEqual(state[gpio.CS], 1)
        self.assertEqual(state[gpio.CLK], 0)

    def test_transfer_failure_still_deselects(self):
        state = {}
        def broken_read(line):
            raise OSError("synthetic read failure")
        spi = gpio.BitBang(lambda line, value: state.update({line: value}), broken_read, lambda: None)
        with self.assertRaises(OSError):
            spi.transfer(b"1")
        self.assertEqual(state[gpio.CS], 1)
        self.assertEqual(state[gpio.CLK], 0)

    def test_default_help_and_explicit_entry(self):
        with patch.object(gpio, "acquire", return_value=0) as acquire:
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(gpio.main([]), 0)
                with self.assertRaises(SystemExit):
                    gpio.main(["--help"])
            acquire.assert_not_called()
            self.assertEqual(gpio.main(["--adapter-loopback"]), 0)
            acquire.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
