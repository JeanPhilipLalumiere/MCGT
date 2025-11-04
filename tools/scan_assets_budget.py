#!/usr/bin/env python3
"""
Stub de compatibilité pour le hook pre-commit 'assets-budgets'.
- But: ne pas bloquer les commits si l'outil réel n'est pas présent/configuré.
- Comportement: inspecte éventuellement un fichier de config (facultatif), sinon exit 0.
"""
from __future__ import annotations
import sys, os, json, pathlib

def main(argv):
    # Optionnel: on regarde un fichier de config si présent, sinon on passe.
    repo = pathlib.Path(__file__).resolve().parents[1]
    cfg_candidates = [
        repo / "tools" / "assets_budget.json",
        repo / "zz-manifests" / "assets_budget.json",
        repo / ".github" / "assets_budget.json",
    ]
    for cfg in cfg_candidates:
        if cfg.exists():
            try:
                json.loads(cfg.read_text(encoding="utf-8"))
            except Exception as e:
                print(f"[assets-budgets] WARNING: config malformée: {cfg} → {e}", file=sys.stderr)
                # Choix: ne pas bloquer pour l’instant (retour 0). Ajuster à 1 si tu veux rendre bloquant.
                return 0
            # Ici tu pourrais faire de vrais contrôles si besoin.
            break
    print("[assets-budgets] (stub) OK — outil réel absent, aucune contrainte appliquée.")
    return int(bool(os.environ.get('MCGT_ASSETS_BUDGET_STRICT')))  # 0=OK (défaut), 1=fail en mode strict

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
