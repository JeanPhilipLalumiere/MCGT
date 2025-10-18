#!/usr/bin/env python3
from __future__ import annotations

import argparse


def add_common_cli(parser: argparse.ArgumentParser) -> None:
    parser.add_argument('--fmt','--format', dest='fmt', choices=['png','pdf','svg'], default=None)
    parser.add_argument('--dpi', type=int, default=None)
    parser.add_argument('--outdir', type=str, default=None)
    parser.add_argument('--transparent', action='store_true')
    parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none')

def ensure_std_args(args):
    """Hook de normalisation ; no-op pour l’instant (garde-place pour futur)."""
    return args
