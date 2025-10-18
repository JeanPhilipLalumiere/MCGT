#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path

def ensure_dir(p: Path | str) -> Path:
    p = Path(p)
    p.parent.mkdir(parents=True, exist_ok=True)
    return p

def savefig_safe(fig, out: str | Path, dpi=None, transparent=None, fmt=None, tight=True):
    """
    Sauvegarde robuste (crée répertoires, adapte suffixe si fmt fourni).
    N'altère pas la figure; retourne le chemin final.
    """
    out = Path(out)
    if fmt:
        suf = "." + fmt.lower().lstrip(".")
        if out.suffix.lower() != suf:
            out = out.with_suffix(suf)
    ensure_dir(out)
    kw = {}
    if dpi is not None:
        kw["dpi"] = dpi
    if transparent is not None:
        kw["transparent"] = transparent
    try:
        if tight:
            fig.savefig(out, bbox_inches="tight", **kw)
        else:
            fig.savefig(out, **kw)
    except Exception:
        # dernier recours : sans bbox_inches
        fig.savefig(out, **kw)
    return out
