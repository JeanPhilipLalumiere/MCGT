#!/usr/bin/env bash
set -euo pipefail
[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }

out="$(mktemp)"
if make -n >"$out" 2>&1; then
  echo "✅ make -n: OK"
  rm -f "$out"
  exit 0
fi

echo "⚠️  make -n a signalé des erreurs. Contexte:"
grep -n "Makefile:[0-9]\+:" "$out" | sed 's/^/  /' || true

# Affiche 5 lignes de contexte autour de chaque ligne rapportée
while read -r ln; do
  num="${ln#Makefile:}"; num="${num%%:*}"
  echo "----- contexte autour de la ligne $num -----"
  nl -ba -w2 -s': ' Makefile | sed -n "$((num-4)),$((num+4))p"
done < <(grep -o "Makefile:[0-9]\+:" "$out" | sort -u)

echo "Journal complet: $out"
exit 1
