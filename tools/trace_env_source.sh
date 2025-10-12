safe_cp() { 
  src="$1"; dest="$2"; 
  # si la destination existe déjà, ne rien faire ; sinon copie simple 
  if [ -e "$dest" ]; then 
    return 0; 
  fi; 
  cp "$src" "$dest"; 
}

#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Recherche d'un fichier 'environment' dans le repo ==="
env_files="$(git ls-files -- ':/*environment' ':/*Environment' 2>/dev/null || true)"
if [[ -z "${env_files}" ]]; then
  # fallback: scan FS proche
  env_files="$(find . -maxdepth 2 -type f -name 'environment' -o -name 'Environment' -print 2>/dev/null || true)"
fi
printf '%s\n' "${env_files:-<aucun>}"
echo

echo "=== Recherche des appels de source ==="
git grep -nE '(^|[;[:space:]])(\.|\bsource)\s+([.\/]*environment)\b' -- \
  || echo "<aucune occurrence explicite dans l'index git>"
echo

# Afficher début des fichiers "environment" trouvés
if [[ -n "${env_files}" ]]; then
  echo "=== Aperçu des 10 premières lignes de chaque 'environment' ==="
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    echo "--- $f"
    nl -ba "$f" | sed -n '1,12p' || true
    echo
  done <<< "${env_files}"
fi

# Tracer un run PASS14 pour capter les 'source'
ts="$(date +%Y%m%dT%H%M%S)"
xlog="zz-out/trace_source_${ts}.xtrace.log"

echo "=== Run instrumenté (xtrace) ==="
export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
export BASH_XTRACEFD=9
{
  set -x
  # On veut voir les 'source' → activer extdebug/xtrace
  shopt -s expand_aliases
  # Rejouer le runner en nettoyant BASH_ENV/ENV malgré tout
  env -u BASH_ENV -u ENV bash -lc 'tools/pass14_smoke_with_mapping.sh'
} 9> "$xlog" 2>&1 || true
echo "xtrace → $xlog"
echo

# Heuristique: lignes d'inclusion
echo "=== Lignes suspectes dans le xtrace (source/.) ==="
grep -nE '\+ .* (source|\. ) .*environment' "$xlog" || echo "<rien trouvé, inspecte tout le xtrace>"
echo

# Option de neutralisation soft: renommer temporairement le/les fichiers
if [[ -n "${env_files}" ]]; then
  echo "=== Neutralisation soft (rename -> .disabled) ==="
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ -f "$f" && ! -f "${f}.disabled" ]]; then
      git ls-files --error-unmatch "$f" >/dev/null 2>&1 && tracked=1 || tracked=0
      safe_cp "$f" "${f}.bak"
      mv "$f" "${f}.disabled"
      echo "renamed: $f -> ${f}.disabled (backup: ${f}.bak) [tracked=$tracked]"
    fi
  done <<< "${env_files}"
else
  echo "Aucun fichier 'environment' trouvé à neutraliser."
fi

echo
echo "=== Re-run PASS14 (attendu: plus de bruit) ==="
env -u BASH_ENV -u ENV bash -lc 'tools/pass14_smoke_with_mapping.sh' || true
echo "OK. Vérifie visuellement les lignes 'environment: line 4: …' (elles devraient disparaître)."

