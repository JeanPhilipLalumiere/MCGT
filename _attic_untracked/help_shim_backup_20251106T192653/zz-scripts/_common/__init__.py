"""Lightweight _common package init for MCGT (safe)."""
from . import cli, postparse
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging
__all__ = ["cli", "postparse"]
