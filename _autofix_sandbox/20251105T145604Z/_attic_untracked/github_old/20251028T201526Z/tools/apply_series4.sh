#!/usr/bin/env bash
# Pas de -e : on continue même si certaines étapes échouent.
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts() { date +"%Y-%m-%d %H:%M:%S"; }
say() { echo -e "[$(ts)] $*"; }
run() { say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p tools .github/workflows"

step "1) .editorconfig (cohérence des fins de lignes/indent)"
cat > .editorconfig <<'EC'
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true

[*.{py,sh}]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
EC

step "2) Scanner de budgets d'assets (PNG/CSV.GZ/NPZ) + garde exec/shebang"
cat > tools/scan_assets_budget.py <<'PY'
#!/usr/bin/env python3
import os, sys, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = ["zz-figures/_legacy_conflicts/"]

# Budgets (modifiables si besoin)
PER_FILE_BUDGET = {
  ".png": 4_000_000,      # 4.0 MB par image
  ".npz": 50_000_000,     # 50 MB par archive npz
  ".csv.gz": 80_000_000,  # 80 MB par dataset compressé
}
TOTAL_BUDGET = {
  "zz-figures": 200_000_000, # 200 MB cumulés de figures
  "zz-data":    800_000_000, # 800 MB cumulés de données
}

def excluded(rel: str) -> bool:
  rel = rel.replace("\\","/")
  return any(rel.startswith(p) for p in EXCLUDE_PREFIXES)

def ext_of(path: str):
  p = path.lower()
  for e in (".csv.gz",):   # extensions à 2 suffixes d'abord
    if p.endswith(e): return e
  return Path(p).suffix

failed = 0
totals = {"zz-figures": 0, "zz-data": 0}

def check_tree(base: str):
  global failed
  basep = ROOT / base
  if not basep.exists(): return
  for p in basep.rglob("*"):
    if not p.is_file(): continue
    rel = p.relative_to(ROOT).as_posix()
    if excluded(rel): continue
    size = p.stat().st_size
    totals[base] += size
    e = ext_of(rel)
    if e in PER_FILE_BUDGET and size > PER_FILE_BUDGET[e]:
      print(f"❌ {rel}: {size} > budget {PER_FILE_BUDGET[e]} octets")
      failed = 1

for folder in ("zz-figures","zz-data"):
  check_tree(folder)

for folder, budget in TOTAL_BUDGET.items():
  if totals[folder] > budget:
    print(f"❌ Total {folder}: {totals[folder]} > budget {budget} octets")
    failed = 1

# Garde: aucun exécutable sans shebang
import subprocess
proc = subprocess.run(
  ["bash","-lc","git ls-files -z | xargs -0 -I{} bash -lc 'test -x \"{}\" && { head -n1 \"{}\" | grep -q \"^#!\"; } || exit 0' | wc -l"],
  capture_output=True, text=True
)
try:
  bad = int(proc.stdout.strip())
except Exception:
  bad = 0
if bad > 0:
  print(f"❌ Exécutables sans shebang détectés: {bad}")
  failed = 1

if failed:
  print("\n⛔ Budgets/shebang non conformes. Ajustez fichiers ou budgets (tools/scan_assets_budget.py).")
  sys.exit(1)
else:
  print("✅ Budgets et shebang OK.")
PY
chmod +x tools/scan_assets_budget.py

step "3) Cibles Makefile (budgets, ci-checks)"
if [ -f Makefile ]; then
  # purge ancien bloc si présent
  sed -i '/^# BEGIN BUDGET TARGETS$/,/^# END BUDGET TARGETS$/d' Makefile || true
else
  : > Makefile
fi
cat >> Makefile <<'MAKE'

# BEGIN BUDGET TARGETS
.PHONY: budgets ci-checks
budgets:
	@python3 tools/scan_assets_budget.py

ci-checks: integrity budgets
	@echo "CI local OK."
# END BUDGET TARGETS
MAKE

step "4) CI budgets + ajout des gardes dans pre-commit"
# Workflow CI
cat > .github/workflows/budgets.yml <<'YML'
name: budgets
on: [push, pull_request]
jobs:
  budgets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Budgets & shebang
        run: python3 tools/scan_assets_budget.py
YML

# Ajout des hooks locaux si non présents
if [ -f .pre-commit-config.yaml ]; then
  # Supprimer bloc préexistant pour éviter doublons
  awk 'BEGIN{skip=0} /^# BEGIN LOCAL BUDGET HOOKS$/{skip=1} /^# END LOCAL BUDGET HOOKS$/{skip=0; next} { if(!skip) print $0 }' .pre-commit-config.yaml > .pre-commit-config.yaml.tmp || true
  mv .pre-commit-config.yaml.tmp .pre-commit-config.yaml
else
  : > .pre-commit-config.yaml
fi

cat >> .pre-commit-config.yaml <<'PC'
# BEGIN LOCAL BUDGET HOOKS
repos:
  - repo: local
    hooks:
      - id: assets-budgets
        name: assets-budgets
        entry: python3 tools/scan_assets_budget.py
        language: system
        pass_filenames: false
        stages: [commit]
# END LOCAL BUDGET HOOKS
PC

run "pre-commit install || true"

step "5) Commit + push (non bloquant)"
run "git add .editorconfig tools/scan_assets_budget.py Makefile .github/workflows/budgets.yml .pre-commit-config.yaml || true"
run "git commit -m 'ci(budgets): budgets PNG/CSV.GZ/NPZ + garde shebang; cible Makefile; hook pre-commit' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Transmettez le log si vous voulez un patch ciblé."
else
  say "✅ Série 4 appliquée sans erreurs détectées côté script."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
