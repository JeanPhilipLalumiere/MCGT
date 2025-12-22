# ch10 — Restauration du générateur officiel (v0.3.3)

## Objectifs
- Remplacer le *stub* minimal par la version corrigée de `scripts/10_global_scan/generate_data_chapter10.py`
- Conserver l'interface CLI actuelle (compat smoke/tests)
- Laisser `tests/test_ch10_smoke.py` vert

## Checklist
- [ ] Corriger l'indentation/l'AST et stabiliser la CLI
- [ ] Vérifier `--config` + `--out-results` (CSV non vide)
- [ ] Smoke ch10 vert (make smoke-ch10)
- [ ] Pytest vert
- [ ] Refresh manifests + diagnostics (0 erreur)
- [ ] README-REPRO (2 commandes) mis à jour
- [ ] Nettoyage `*.bak.*` si présent

## Notes techniques
- Ne pas casser le format CSV attendu par le smoke/tests actuels
- Garder les noms de flags existants pour éviter les régressions
