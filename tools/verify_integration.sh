#!/usr/bin/env bash
set -euo pipefail

GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; DIM=$'\e[2m'; NC=$'\e[0m'

pass(){ printf "%s✔%s %s\n" "$GREEN" "$NC" "$1"; }
fail(){ printf "%s✘%s %s\n" "$RED" "$NC" "$1"; }
warn(){ printf "%s•%s %s\n" "$YELLOW" "$NC" "$1"; }

ok_core=true

# 0) Garde-fou: racine de dépôt
if [ ! -d .git ]; then
  fail "Lance ce script à la racine du dépôt (où .git/ existe)."
  exit 2
fi
echo "${DIM}Branche: $(git rev-parse --abbrev-ref HEAD)${NC}"

# 1) Fichiers attendus
req_files=(
  ".github/workflows/publish.yml"
  "tools/archive/archive_safe.sh"
  "tools/manifest/check_strict.sh"
  "Makefile"
)
for f in "${req_files[@]}"; do
  if [ -e "$f" ]; then pass "Présent: $f"; else fail "Manquant: $f"; ok_core=false; fi
done

# 2) publish.yml est du YAML valide
if command -v python >/dev/null 2>&1; then
  if python - <<'PY' 2>/dev/null
import sys, yaml
p=".github/workflows/publish.yml"
yaml.safe_load(open(p, encoding="utf-8"))
print("OK")
PY
  then pass "YAML valide: .github/workflows/publish.yml"
  else fail "YAML invalide: .github/workflows/publish.yml"; ok_core=false
  fi
else
  warn "Python introuvable — saut de la validation YAML."
fi

# 3) Cibles Make présentes
if grep -qE '^[[:space:]]*fix-manifest:' Makefile; then
  pass "Makefile contient la cible: fix-manifest"
else
  fail "Makefile: cible fix-manifest absente"; ok_core=false
fi
if grep -qE '^[[:space:]]*fix-manifest-strict:' Makefile; then
  pass "Makefile contient la cible: fix-manifest-strict"
else
  fail "Makefile: cible fix-manifest-strict absente"; ok_core=false
fi

# 4) Scripts marqués exécutables
for x in tools/archive/archive_safe.sh tools/manifest/check_strict.sh; do
  if [ -x "$x" ]; then pass "Exécutable: $x"; else fail "Non exécutable: $x (chmod +x)"; ok_core=false; fi
done

# 5) Archiver: test d’exécution (force un fichier existant dans l’archive)
pick=""
for cand in README.md pyproject.toml .gitignore; do
  [ -e "$cand" ] && { pick="$cand"; break; }
done
if [ -n "$pick" ]; then
  if tools/archive/archive_safe.sh archive "$pick"; then
    latest=$(ls -1t archive/cleanup_*.tar.gz 2>/dev/null | head -n1 || true)
    if [ -n "$latest" ]; then
      pass "Archive créée: ${latest}"
      if tar -tzf "$latest" | grep -q "$(basename "$pick")"; then
        pass "Contenu vérifié dans l’archive: $(basename "$pick")"
      else
        warn "Impossible de confirmer la présence de $(basename "$pick") dans ${latest}"
      fi
    else
      warn "Aucune archive trouvée après exécution."
    fi
  else
    fail "Échec d'exécution de tools/archive/archive_safe.sh"; ok_core=false
  fi
else
  warn "Aucun fichier témoin (README.md/pyproject.toml/.gitignore) — saut du test d’archive."
fi

# 6) Manifeste: exécution tolérante
if grep -q 'diag_consistency.py' zz-manifests/diag_consistency.py 2>/dev/null; then
  if make -s fix-manifest >/dev/null 2>&1; then
    pass "make fix-manifest a tourné"
  else
    warn "make fix-manifest a retourné une erreur (non bloquant pour l’intégration)."
  fi
  # Strict (diagnostic informatif)
  if tools/manifest/check_strict.sh >/tmp/verify_manifest_strict.log 2>&1; then
    pass "check_strict: manifeste OK (strict)"
  else
    warn "check_strict: avertissements/erreurs — vois /tmp/verify_manifest_strict.log"
  fi
else
  warn "diag_consistency.py non trouvé — tests manifeste sautés."
fi

# 7) Vérifications Git: fichiers suivis & commit récent qui les touche
for f in "${req_files[@]}"; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    pass "Suivi par Git: $f"
  else
    fail "Non suivi par Git: $f (git add)"; ok_core=false
  fi
done

# commit récent sur publish.yml
if git log -n 1 --pretty=format:%h -- .github/workflows/publish.yml >/dev/null 2>&1; then
  last_touch=$(git log -n 1 --pretty=format:'%h %ad — %s' --date=short -- .github/workflows/publish.yml)
  pass "Dernière modif publish.yml: ${last_touch}"
else
  warn "Impossible d’identifier un commit pour publish.yml"
fi

# 8) Résultat final
echo
if $ok_core; then
  echo "${GREEN}✅ Intégration confirmée — cœur fonctionnel en place.${NC}"
  rc=0
else
  echo "${RED}❌ Intégration INCOMPLÈTE — vois les ✘ ci-dessus.${NC}"
  rc=1
fi

# Option pour éviter la fermeture si lancé par double-clic
if [ "${PAUSE:-1}" = "1" ]; then
  read -rp "Appuie sur Entrée pour fermer… " _ || true
fi

exit $rc
