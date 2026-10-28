#!/usr/bin/env python3
"""AI-assisted bounded GPIO read-only entry for C8375-A/FDO2742M0FK/U2.

Explicit --read only after fresh physical U2 mapping/isolation/voltage checks.
Uses shared guarded acquisition: expected RDID before each of two fixed4KiB
reads; only0x9fRDID/0x13nativeREAD. Samples and reports explicitly labelU2.
"""
import argparse

from pi_gpio_u1_read import acquire


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--read", action="store_true")
    args = parser.parse_args(argv)
    if not args.read:
        parser.print_help()
        return 0
    return acquire("U2")


if __name__ == "__main__":
    raise SystemExit(main())
