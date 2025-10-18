#!/usr/bin/env python3
"""
_postparse_: centralise les valeurs par défaut et les petites vérifications
après argparse.parse_args() pour homogénéiser tous les scripts.

Usage recommandé :
    from _common.postparse import ensure_std_args
args = parser.parse_args()
    args = ensure_std_args(args)
"""
from __future__ import annotations

from pathlib import Path

DEFAULTS = {
    "dpi": 150,          # rendu rapide par défaut ; scripts peuvent forcer 300
    "fmt": "png",        # alias de "format" si un script l'utilise
    "outdir": ".",       # répertoire de sortie
    "transparent": False # figures opaques par défaut
}

def _coalesce_attr(args, key: str, *aliases, default=None) -> None:
    """args.<key> = première valeur non vide trouvée parmi (key, *aliases), sinon 'default'."""
    # 1) si key existe et est définie
    if hasattr(args, key):
        val = getattr(args, key)
        if val not in (None, ""):
            return
    # 2) sinon, chercher dans les alias
    for al in aliases:
        if hasattr(args, al):
            val = getattr(args, al)
            if val not in (None, ""):
                setattr(args, key, val)
                return
    # 3) défaut
    if default is not None and not hasattr(args, key):
        setattr(args, key, default)

def ensure_std_args(args):
    """Injecte les défauts, harmonise fmt/format, garantit outdir existant."""
    _coalesce_attr(args, "dpi", default=DEFAULTS["dpi"])
    _coalesce_attr(args, "fmt", "format", default=DEFAULTS["fmt"])
    _coalesce_attr(args, "outdir", "out_dir", default=DEFAULTS["outdir"])
    _coalesce_attr(args, "transparent", default=DEFAULTS["transparent"])

    # Création du dossier de sortie si nécessaire
    outdir = Path(getattr(args, "outdir", DEFAULTS["outdir"]))
    try:
        outdir.mkdir(parents=True, exist_ok=True)
    except Exception:
        setattr(args, "outdir", ".")
        Path(".").mkdir(exist_ok=True)
    return args

# Compat descendante si certains scripts appellent 'postparse'
def postparse(args):
    return ensure_std_args(args)
