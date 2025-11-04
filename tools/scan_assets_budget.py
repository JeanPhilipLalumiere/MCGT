#!/usr/bin/env python3
"""
Stub de compatibilité pour le hook pre-commit 'assets-budgets'.
- Si l'outil réel n'est pas présent, on ne bloque pas les commits par défaut.
- Mode strict (échec) activé uniquement si MCGT_ASSETS_BUDGET_STRICT ∈ {1,true,yes,y,on}.
- Valide optionnellement un assets_budget.json s'il est présent (sans imposer de règles).
"""
from __future__ import annotations
import os, sys, json, pathlib

STRICT_TRUE = {"1","true","yes","y","on"}

def wants_strict() -> bool:
    val = str(os.environ.get("MCGT_ASSETS_BUDGET_STRICT","")).strip().lower()
    return val in STRICT_TRUE

def main(argv) -> int:
    repo = pathlib.Path(__file__).resolve().parents[1]
    cfg_candidates = [
        repo / "tools" / "assets_budget.json",
        repo / "zz-manifests" / "assets_budget.json",
        repo / ".github" / "assets_budget.json",
    ]
    # Valide JSON si présent (non bloquant sauf strict + JSON invalide)
    for cfg in cfg_candidates:
        if cfg.exists():
            try:
                json.loads(cfg.read_text(encoding="utf-8"))
            except Exception as e:
                msg = f"[assets-budgets] WARNING: config malformée: {cfg} → {e}"
                print(msg, file=sys.stderr)
                return 1 if wants_strict() else 0
            break
    print("[assets-budgets] stub OK — outil réel absent, aucune contrainte appliquée.")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
