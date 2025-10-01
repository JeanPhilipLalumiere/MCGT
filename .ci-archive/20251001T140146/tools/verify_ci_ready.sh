#!/usr/bin/env bash
set -euo pipefail

GREEN=$'\e[32m'; YEL=$'\e[33m'; RED=$'\e[31m'; DIM=$'\e[2m'; NC=$'\e[0m'
pass(){ printf "%s✔%s %s\n" "$GREEN" "$NC" "$1"; }
warn(){ printf "%s•%s %s\n" "$YEL" "$NC" "$1"; }
fail(){ printf "%s✘%s %s\n" "$RED" "$NC" "$1"; exit 1; }

[ -d .git ] || fail "Lance le script à la racine du dépôt (.git/)."
branch="$(git rev-parse --abbrev-ref HEAD)"
echo "${DIM}Branche: ${branch}${NC}"

# 1) Fichier workflow présent
test -f .github/workflows/sanity.yml && pass "sanity.yml présent"

# 2) Parse YAML (PyYAML si dispo)
if python - <<'PY' >/dev/null 2>&1
import yaml, pathlib
p = pathlib.Path(".github/workflows/sanity.yml")
yaml.safe_load(p.read_text(encoding="utf-8"))
PY
then
  pass "YAML parsé (PyYAML)"
else
  warn "PyYAML non installé — pre-commit/CI vérifieront le YAML."
fi

# 3) Garde-fou: pas de .RECIPEPREFIX
if grep -n '^[[:space:]]*\.RECIPEPREFIX' Makefile >/dev/null 2>&1; then
  fail ".RECIPEPREFIX détecté dans Makefile (interdit)."
else
  pass "Aucun .RECIPEPREFIX actif"
fi

# 4) Dry-run make ciblé
make -n fix-manifest >/dev/null && pass "make -n fix-manifest OK"

# 5) Diag manifeste strict rapide
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal \
  --content-check --fail-on errors >/dev/null && pass "diag_consistency (strict) OK"

# 6) Tests unitaires
python -m pytest -q >/dev/null && pass "pytest OK"

# 7) Optionnel: affichage/trigger CI si gh dispo
if command -v gh >/dev/null 2>&1; then
  warn "gh détecté — derniers runs:"
  gh run list --workflow sanity.yml -b "$branch" -L 5 || warn "Pas encore de run visible."
  echo
  echo "Pour suivre le dernier run:"
  echo "  gh run watch --exit-status \$(gh run list --workflow sanity.yml -b \"$branch\" -L1 --json databaseId -q '.[0].databaseId')"
else
  warn "gh non détecté. Pour déclencher la CI :"
  echo "  git commit --allow-empty -m 'ci: sanity ping' && git push"
fi

pass "Vérification CI locale terminée."
