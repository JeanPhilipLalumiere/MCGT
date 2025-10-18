#!/usr/bin/env python3
from __future__ import annotations
from contextlib import contextmanager
import matplotlib as mpl

_PRESETS = {
    "paper": {"figure.dpi": 300, "savefig.dpi": 300, "axes.grid": False, "font.size": 9.0},
    "talk":  {"figure.dpi": 150, "savefig.dpi": 150, "axes.grid": False, "font.size": 12.0},
    "mono":  {"text.kerning_factor": 0, "axes.prop_cycle": mpl.cycler(color=["0.0","0.3","0.6","0.9"])},
}

@contextmanager
def apply_style(name: str | None):
    """
    N'applique rien si name in (None, 'none'); restaure toujours les rcParams.

    Usage:
        from _common.style import apply_style
        with apply_style(getattr(args, "style", "none")):
            ...
    """
    if not name or name == "none":
        yield
        return
    old = mpl.rcParams.copy()
    try:
        for k, v in _PRESETS.get(name, {}).items():
            mpl.rcParams[k] = v
        yield
    finally:
        mpl.rcParams.update(old)
