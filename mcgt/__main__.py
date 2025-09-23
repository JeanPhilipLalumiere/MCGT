# mcgt.__main__ — minimal CLI
from __future__ import annotations

import argparse


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="mcgt", description="MCGT CLI")
    parser.add_argument("--version", action="store_true", help="print version and exit")
    parser.add_argument("--summary", action="store_true", help="print debug summary")
    args = parser.parse_args(argv)
    if args.version:
        try:
            from . import __version__

            print(__version__)
        except Exception:
            print("unknown")
        return 0
    if args.summary:
        try:
            from . import print_summary

            print_summary()
        except Exception as e:
            print(f"summary unavailable: {e}")
        return 0
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
