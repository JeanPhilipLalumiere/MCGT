#!/usr/bin/env bash
set -Eeuo pipefail

latest_raw="$(ls -1t zz-out/diag_env_noise_*.raw.log 2>/dev/null | head -1 || true)"
[[ -n "$latest_raw" ]] || { echo "Aucun raw log de diag trouvé."; exit 1; }
latest_x="${latest_raw%.raw.log}.log"
[[ -f "$latest_x" ]] || { echo "Trace xtrace introuvable: $latest_x"; exit 2; }

echo "RAW : $latest_raw"
echo "XTR : $latest_x"
echo

# Trouve la dernière occurrence et son numéro de ligne
pattern='^environment: line 4: .*: division by 0 \(error token is '
last_line="$(grep -nE "$pattern" "$latest_raw" | tail -1 || true)"
if [[ -z "$last_line" ]]; then
  echo "Aucune occurrence ‘environment: line 4 …’ dans $latest_raw"
  exit 0
fi

lnum="${last_line%%:*}"
echo "Dernière occurrence dans le RAW: ligne $lnum"
echo

# Contexte brut +/- 30 lignes
start=$(( lnum>30 ? lnum-30 : 1 ))
end=$(( lnum+30 ))
echo "===== CONTEXTE RAW (lignes $start..$end) ====="
nl -ba "$latest_raw" | sed -n "${start},${end}p"
echo

# Pour l’xtrace: on affiche les 200 dernières lignes avant la fin,
# ça suffit généralement pour voir la commande fautive juste avant le bruit.
echo "===== CONTEXTE XTRACE (200 dernières lignes) ====="
tail -n 200 "$latest_x"

# Heuristique: extraire le 'error token' (chemin script) pour chercher dans l'xtrace
token="$(echo "$last_line" | sed -n 's/.*error token is \"\([^\"]\+\)\".*/\1/p')"
if [[ -n "$token" ]]; then
  echo
  echo "===== RECHERCHE DU TOKEN DANS XTRACE: $token ====="
  grep -n -- "$token" "$latest_x" || true
fi

echo
echo "👉 Inspecte la ou les commandes juste AVANT le bruit dans l'xtrace."
echo "   Cherche une arithmétique shell (( ... )) ou une expansion mal quotée."
