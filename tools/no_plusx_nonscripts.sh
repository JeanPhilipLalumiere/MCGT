#!/usr/bin/env bash
set -Eeuo pipefail
# Refuse +x sur fichiers non scripts (YAML/MD/TXT/JSON/TOML/etc.) et workflows

NON_SCRIPT_EXTS='(ya?ml|md|txt|json|toml|ini|lock|csv|svg|png|jpe?g|gif|pdf)'

# Tous les fichiers marqués exécutables dans l'index
mapfile -t execs < <(git ls-files -s | awk '$1 ~ /^100755/ {print $4}')

bad=()
for p in "${execs[@]}"; do
  # 1) extensions non-script → interdit
  if [[ "$p" =~ \.($NON_SCRIPT_EXTS)$ ]]; then
    bad+=("$p")
    continue
  fi
  # 2) workflows → jamais +x
  if [[ "$p" == .github/workflows/* ]]; then
    bad+=("$p")
    continue
  fi
  # 3) pas de shebang → suspect
  if [[ -f "$p" ]] && ! head -n1 -- "$p" | grep -qE '^#!'; then
    bad+=("$p")
  fi
done

if ((${#bad[@]})); then
  echo "[ERROR] Ces fichiers sont exécutables (+x) mais ne devraient pas l'être :"
  printf ' - %s\n' "${bad[@]}"
  echo
  echo "Corrigez avec : git update-index --chmod=-x <fichier>"
  exit 1
fi
echo "[OK] Aucun non-script exécutable détecté."
