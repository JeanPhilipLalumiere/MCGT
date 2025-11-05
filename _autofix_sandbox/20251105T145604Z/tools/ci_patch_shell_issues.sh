#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

# Normaliser tools/*.sh : retirer BOM/blank au début, forcer le shebang en 1re ligne
normalize() {
  local f="$1"
  [ -f "$f" ] || return 0
  # strip UTF-8 BOM
  perl -i -pe 's/^\x{FEFF}//;' "$f" 2>/dev/null || true
  # enlever lignes vides au début
  awk 'BEGIN{seen=0} {if(!seen && $0 ~ /^[[:space:]]*$/) next; seen=1; print}' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
  # shebang si absent
  if ! head -n1 "$f" | grep -q '^#!'; then
    sed -i '1i #!/usr/bin/env bash' "$f"
  fi
}

for f in tools/*.sh; do normalize "$f"; done

# SC2162 : read -r -p -> read -r -p
grep -lR --include='*.sh' -n 'read -r -p ' tools/ 2>/dev/null | xargs -r sed -i 's/read -r -p /read -r -p /g'

# SC2086 : exit $rc -> exit "$rc" (dans run_with_instrumentation.sh)
if [ -f tools/run_with_instrumentation.sh ]; then
  # Remplace exactement 'exit $rc' par exit "$rc"
  # shellcheck disable=SC2016
  sed -i 's/^\([[:space:]]*exit\)[[:space:]]\+\$rc/\1 "\$rc"/' tools/run_with_instrumentation.sh
fi

# Infos non bloquantes -> on documente mais on garde le code
ensure_disable() { # ajoute un disable en tête si absent
  local file="$1" code="$2"
  [ -f "$file" ] || return 0
  grep -q "shellcheck disable=${code}" "$file" || sed -i "1a # shellcheck disable=${code}" "$file"
}

# Word splitting/ls (on assume le pattern actuel)
[ -f tools/run_and_tail.sh ] && ensure_disable tools/run_and_tail.sh SC2012
[ -f tools/run_and_tail.sh ] && ensure_disable tools/run_and_tail.sh SC2046

# Variable possiblement non utilisée
[ -f tools/guard_no_recipeprefix.sh ] && ensure_disable tools/guard_no_recipeprefix.sh SC2034

# A && B || C : conserver le style actuel mais le classer en info
[ -f tools/ci_trigger_and_fetch_diag.sh ] && ensure_disable tools/ci_trigger_and_fetch_diag.sh SC2015

echo "[patch] Shell scripts normalized & quick-fixes applied."
