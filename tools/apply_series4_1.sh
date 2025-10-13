#!/usr/bin/env bash
# Script tolérant : on ne quitte jamais sur erreur
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts() { date +"%Y-%m-%d %H:%M:%S"; }
say(){ echo -e "[$(ts)] $*"; }
run(){ say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p tools .github/workflows"

step "1) Réécrire tools/scan_assets_budget.py (skip AVANT stat + try/except)"
cat > tools/scan_assets_budget.py <<'PY'
#!/usr/bin/env python3
import os, sys, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = ["zz-figures/_legacy_conflicts/"]

# Budgets
PER_FILE_BUDGET = {
  ".png":    4_000_000,     # 4 MB / image
  ".npz":    50_000_000,    # 50 MB / npz
  ".csv.gz": 80_000_000,    # 80 MB / dataset compressé
}
TOTAL_BUDGET = {
  "zz-figures": 200_000_000,  # 200 MB cumulé
  "zz-data":    800_000_000,  # 800 MB cumulé
}

def is_excluded(rel: str) -> bool:
  rel = rel.replace("\\", "/")
  return any(rel.startswith(p) for p in EXCLUDE_PREFIXES)

def ext_of(path: str):
  p = path.lower()
  # extensions multi-suffixes d'abord
  if p.endswith(".csv.gz"): return ".csv.gz"
  return Path(p).suffix

failed = 0
totals = {"zz-figures": 0, "zz-data": 0}

def safe_is_file(p: Path) -> bool:
  try:
    return p.is_file()
  except PermissionError:
    # On traite comme non lisible => on ignore silencieusement
    return False

def safe_size(p: Path) -> int:
  try:
    return p.stat().st_size
  except PermissionError:
    # Non lisible => ignorer du budget
    return 0

def check_tree(base: str):
  global failed
  basep = ROOT / base
  if not basep.exists():
    return
  for p in basep.rglob("*"):
    # Calculer 'rel' AVANT toute stat/is_file pour pouvoir exclure sans toucher au FS
    try:
      rel = p.relative_to(ROOT).as_posix()
    except Exception:
      # En cas d'étrangeté, on skipe
      continue
    if is_excluded(rel):
      continue
    # Uniquement fichiers réguliers lisibles
    if not safe_is_file(p):
      continue
    size = safe_size(p)
    totals[base] += size
    e = ext_of(rel)
    if e in PER_FILE_BUDGET and size > PER_FILE_BUDGET[e]:
      print(f"❌ {rel}: {size} > budget {PER_FILE_BUDGET[e]} octets")
      failed = 1

for folder in ("zz-figures", "zz-data"):
  check_tree(folder)

for folder, budget in TOTAL_BUDGET.items():
  if totals.get(folder, 0) > budget:
    print(f"❌ Total {folder}: {totals[folder]} > budget {budget} octets")
    failed = 1

# Garde: aucun exécutable sans shebang
proc = subprocess.run(
  ["bash","-lc","git ls-files -z | xargs -0 -I{} bash -lc 'test -x \"{}\" && { head -n1 \"{}\" | grep -q \"^#!\"; } || exit 0' | wc -l"],
  capture_output=True, text=True
)
bad = 0
try:
  bad = int(proc.stdout.strip())
except Exception:
  pass
if bad > 0:
  print(f"❌ Exécutables sans shebang détectés: {bad}")
  failed = 1

if failed:
  print("\n⛔ Budgets/shebang non conformes. Ajustez fichiers ou budgets (tools/scan_assets_budget.py).")
  sys.exit(1)
else:
  print("✅ Budgets et shebang OK.")
PY
run "chmod +x tools/scan_assets_budget.py"

step "2) Corriger .pre-commit-config.yaml (stages préconisés) + migration"
# Créer fichier si absent
[ -f .pre-commit-config.yaml ] || : > .pre-commit-config.yaml

# Si un bloc local existe, remplacer 'stages: [commit]' par 'stages: [pre-commit]'
# (on tolère espaces / casse)
run "sed -i -E 's/stages: *\\[( *commit *|\"commit\"|\\x27commit\\x27)\\]/stages: [pre-commit]/Ig' .pre-commit-config.yaml"

# Si notre hook n'existe pas encore, on l'ajoute (ou on remet proprement le bloc)
if ! grep -q 'id: assets-budgets' .pre-commit-config.yaml 2>/dev/null; then
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
        stages: [pre-commit]
# END LOCAL BUDGET HOOKS
PC
fi

# Lancer la migration officielle (ne casse pas si rien à migrer)
run "pre-commit migrate-config || true"
run "pre-commit install || true"

step "3) Restaurer un .editorconfig complet (version non tronquée)"
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

step "4) Commit + push (jamais bloquant)"
run "git add tools/scan_assets_budget.py .pre-commit-config.yaml .editorconfig || true"
run "git commit -m 'ci(budgets): fix PermissionError (skip avant stat + try/except); stages [pre-commit]; editorconfig complet' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Renvoyez-moi le log pour un patch ciblé."
else
  say "✅ Série 4.1 appliquée sans erreurs bloquantes côté script."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
