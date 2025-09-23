#!/usr/bin/env bash
# pas de `set -e` pour éviter toute fermeture brutale ; on journalise et on continue.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"
mkdir -p "${REPORTS}"

log(){ printf "%s\n" "$*" | tee -a "${REPORTS}/finalize.log" ; }

log "==[1] Forcer la désindexation de MCGT-clean/ (subrepo accidentel) =="
git rm -r --cached -f MCGT-clean 2>&1 | tee -a "${REPORTS}/git_rm_mcgt_clean.txt" || true
# s'assurer qu'il est ignoré
grep -qxF "MCGT-clean/" .gitignore 2>/dev/null || echo "MCGT-clean/" >> .gitignore

log "==[2] pre-commit: exclure backups/rapports pour ne plus parser zz-trash/* =="
python - <<'PY' 2>>"_reports/${TS}/py_errors.log" || true
from pathlib import Path
from yaml import safe_load, safe_dump

p = Path(".pre-commit-config.yaml")
cfg = safe_load(p.read_text(encoding="utf-8")) if p.exists() else {"repos": []}

# Top-level exclude (regex) — ignorer *zz-trash*, *_reports*, *_snapshots*, *MCGT-clean*
exclude = cfg.get("exclude", "")
wanted = r"^(zz-trash/|_reports/|_snapshots/|MCGT-clean/)"
if exclude:
    if wanted not in exclude:
        cfg["exclude"] = f"{wanted}|({exclude})"
else:
    cfg["exclude"] = wanted

# Pour sécurité, appliquer aussi l'exclude sur chaque repo/hook
for repo in cfg.get("repos", []):
    hooks = repo.get("hooks", [])
    for h in hooks:
        ex = h.get("exclude", "")
        if wanted not in ex:
            h["exclude"] = f"{wanted}|({ex})" if ex else wanted

p.write_text(safe_dump(cfg, sort_keys=False), encoding="utf-8")
print("[OK] pre-commit exclude mis à jour.")
PY

log "==[3] Nettoyage CSV: suppression des colonnes entièrement vides (ex: error_code) =="
python - <<'PY' 2>>"_reports/${TS}/py_errors.log" || true
from pathlib import Path
import pandas as pd

targets = [
    Path("zz-data/chapter10/10_mc_results.csv"),
    Path("zz-data/chapter10/10_mc_results.circ.csv"),
]
changed = []
for t in targets:
    if not t.exists():
        print(f"[SKIP] {t} absent"); continue
    df = pd.read_csv(t)
    # colonnes vides = tout NaN ou chaîne vide/whitespace
    empty_cols = []
    for c in df.columns:
        s = df[c]
        is_empty = False
        if s.isna().all():
            is_empty = True
        else:
            # traiter les valeurs string type '' ou '  '
            try:
                if s.astype(str).str.strip().eq("").all():
                    is_empty = True
            except Exception:
                pass
        if is_empty: empty_cols.append(c)
    if empty_cols:
        df = df.drop(columns=empty_cols)
        df.to_csv(t, index=False)
        changed.append((t.as_posix(), empty_cols))
        print(f"[FIX] {t}: dropped empty columns {empty_cols}")
    else:
        print(f"[OK] {t}: no empty columns")
print("CHANGED=", changed)
PY

log "==[4] pre-commit (2 passes, non bloquant) =="
pre-commit install -f >/dev/null 2>&1 || true
pre-commit run --all-files 2>&1 | tee "${REPORTS}/precommit_pass1.txt" || true
pre-commit run --all-files 2>&1 | tee "${REPORTS}/precommit_pass2.txt" || true

log "==[5] Validation JSON/CSV (rapporté) =="
if [ -x zz-schemas/validate_all.sh ]; then
  ./zz-schemas/validate_all.sh 2>&1 | tee "${REPORTS}/validate_all.txt" || true
fi

log "==[6] Commit & push (tolérant) =="
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore(phase0): ignore backups in pre-commit, drop empty CSV cols, unstage MCGT-clean"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || log "[WARN] push a échoué (ok)."
else
  log "(rien à committer)"
fi

log ">>> Done. Rapports: ${REPORTS}"
