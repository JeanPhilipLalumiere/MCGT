"""Centralized Matplotlib style helpers for manuscript-grade figures."""

from __future__ import annotations

import os
import shutil
import errno
import pathlib as pathlib_module
import tempfile
import subprocess
from pathlib import Path

import matplotlib
import matplotlib.texmanager as texmanager_module

_THEMES = {
    "paper": dict(figure_dpi=150, font_size=9, axes_linewidth=0.8, grid=True),
    "talk": dict(figure_dpi=150, font_size=12, axes_linewidth=1.0, grid=True),
    "mono": dict(figure_dpi=150, font_size=9, axes_linewidth=0.8, grid=True),
}

ROOT = Path(__file__).resolve().parents[2]
LOCAL_TEXMF = ROOT / "texmf" / "tex" / "latex" / "local"
LOCAL_MPLCONFIG = ROOT / ".mplconfig"
_ORIGINAL_OS_REPLACE = os.replace
_OS_REPLACE_PATCHED = False
_ORIGINAL_MAKE_PNG = texmanager_module.TexManager.make_png.__func__
_MAKE_PNG_PATCHED = False


def _latex_available() -> bool:
    return shutil.which("latex") is not None


def _prepare_local_tex_environment() -> None:
    LOCAL_TEXMF.mkdir(parents=True, exist_ok=True)
    LOCAL_MPLCONFIG.mkdir(parents=True, exist_ok=True)
    texinputs = os.environ.get("TEXINPUTS", "")
    local_tex = str(LOCAL_TEXMF)
    if local_tex not in texinputs.split(":"):
        os.environ["TEXINPUTS"] = f"{local_tex}:{texinputs}" if texinputs else f"{local_tex}:"
    os.environ.setdefault("MPLCONFIGDIR", str(LOCAL_MPLCONFIG))
    os.environ.setdefault("XDG_CACHE_HOME", str(LOCAL_MPLCONFIG))
    os.environ.setdefault("TMPDIR", str(LOCAL_MPLCONFIG))
    system_bins = ["/usr/bin", "/bin"]
    if Path("/usr/bin/latex").exists():
        path_parts = os.environ.get("PATH", "").split(":")
        new_parts = system_bins + [p for p in path_parts if p and p not in system_bins]
        os.environ["PATH"] = ":".join(new_parts)


def _patch_os_replace_for_exdev() -> None:
    global _OS_REPLACE_PATCHED
    if _OS_REPLACE_PATCHED:
        return

    def safe_replace(src: str | bytes, dst: str | bytes) -> None:
        try:
            _ORIGINAL_OS_REPLACE(src, dst)
        except OSError as exc:
            if exc.errno != errno.EXDEV:
                raise
            dst_path = Path(dst)
            if dst_path.exists():
                dst_path.unlink()
            shutil.move(str(src), str(dst))

    os.replace = safe_replace
    pathlib_module.os.replace = safe_replace
    _OS_REPLACE_PATCHED = True


def _patch_make_png_fallback() -> None:
    global _MAKE_PNG_PATCHED
    if _MAKE_PNG_PATCHED:
        return

    @classmethod
    def make_png(cls, tex, fontsize, dpi):
        if shutil.which("dvipng") is not None:
            return _ORIGINAL_MAKE_PNG(cls, tex, fontsize, dpi)

        basefile = cls.get_basefile(tex, fontsize, dpi)
        pngfile = f"{basefile}.png"
        if os.path.exists(pngfile):
            return pngfile

        dvifile = cls.make_dvi(tex, fontsize)
        if shutil.which("dvips") is None or shutil.which("gs") is None:
            raise RuntimeError("usetex=True requires dvipng or the dvips+gs fallback toolchain.")

        with tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR")) as tmpdir:
            psfile = Path(tmpdir) / "matplotlib_tex.ps"
            texmanager_module.TexManager._run_checked_subprocess(
                ["dvips", "-E", "-o", str(psfile), dvifile],
                tex,
            )
            texmanager_module.TexManager._run_checked_subprocess(
                [
                    "gs",
                    "-q",
                    "-dSAFER",
                    "-dBATCH",
                    "-dNOPAUSE",
                    "-sDEVICE=pngalpha",
                    f"-r{dpi}",
                    f"-sOutputFile={pngfile}",
                    str(psfile),
                ],
                tex,
            )
        return pngfile

    texmanager_module.TexManager.make_png = make_png
    _MAKE_PNG_PATCHED = True


def _resolve_usetex(usetex: bool | None = None) -> bool:
    if usetex is not None:
        return bool(usetex and _latex_available())
    env = os.environ.get("MCGT_USE_TEX")
    if env is not None:
        return env.strip().lower() not in {"0", "false", "no", "off"} and _latex_available()
    return _latex_available()


def manuscript_rc(usetex: bool | None = None) -> dict[str, object]:
    use_tex = _resolve_usetex(usetex)
    rc = {
        "text.usetex": use_tex,
        "font.family": "serif",
        "font.serif": ["Times", "Times New Roman", "DejaVu Serif"],
        "mathtext.fontset": "cm",
        "axes.unicode_minus": False,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    }
    if use_tex:
        rc["text.latex.preamble"] = r"\usepackage{mathptmx}"
    return rc


def apply_manuscript_defaults(usetex: bool | None = None) -> None:
    rc = manuscript_rc(usetex=usetex)
    if rc["text.usetex"]:
        _prepare_local_tex_environment()
        _patch_os_replace_for_exdev()
        _patch_make_png_fallback()
    matplotlib.rcParams.update(rc)


def apply(theme: str | None, usetex: bool | None = None) -> None:
    apply_manuscript_defaults(usetex=usetex)
    if not theme or theme == "none":
        return
    t = _THEMES.get(theme, _THEMES["paper"])
    rc = matplotlib.rcParams
    rc["font.size"] = t["font_size"]
    rc["axes.linewidth"] = t["axes_linewidth"]
    rc["xtick.major.width"] = t["axes_linewidth"]
    rc["ytick.major.width"] = t["axes_linewidth"]
    rc["figure.dpi"] = t["figure_dpi"]
    rc["axes.grid"] = bool(t["grid"])
    rc["grid.linestyle"] = ":"
    rc["grid.linewidth"] = 0.6
