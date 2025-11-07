#!/usr/bin/env bash
set -Eeuo pipefail

ts="$(date +%Y%m%dT%H%M%S)"
xlog="zz-out/trace_source_${ts}.xtrace.log"

echo "=== Contexte shell court ==="
echo "whoami: $(whoami)"
echo "pwd:    $(pwd)"
echo "SHELL:  ${SHELL:-<unset>}"
echo

echo "=== Inventaire de 'environment' dans ce shell ==="
type -a environment 2>/dev/null || echo "<introuvable dans 'type -a'>"
command -v environment 2>/dev/null || true
declare -f environment 2>/dev/null || echo "<pas une fonction bash>"
echo

echo "=== Run instrumenté (xtrace) SANS profils/rc ==="
# ouvre un descripteur dédié pour la trace
exec {xtracefd}> "$xlog"
export BASH_XTRACEFD=$xtracefd
# PS4 horodaté + localisation
export PS4='+[${EPOCHREALTIME}] ${BASH_SOURCE##*/}:${LINENO}: ${FUNCNAME[0]:-main}: '

# On purge BASH_ENV/ENV et on interdit le chargement de profils/rc
# On injecte dans le -lc une mini-prologue qui refait l'inventaire 'environment' côté shell enfant
set -x
env -u BASH_ENV -u ENV bash --noprofile --norc -lc '
  echo "---(enfant) Inventaire environment ---"
  type -a environment 2>/dev/null || echo "<child: introuvable>"
  command -v environment 2>/dev/null || true
  declare -f environment 2>/dev/null || echo "<child: pas une fonction>"
  echo
  # PATH minimal pour éviter collisions éventuelles
  export PATH="/usr/bin:/bin"
  # Lancement PASS14 (non filtré) pour observer le bruit
  tools/pass14_smoke_with_mapping.sh
' || true
set +x

echo "xtrace -> $xlog"
echo

echo "=== Heuristique: erreurs 'environment: line' dans la sortie précédente ==="
grep -nE '^environment: line [0-9]+' "$xlog" || echo "<rien dans xtrace (si bruit persiste à l'écran, il vient d'un sous-shell non tracé)>"
echo

echo "=== Grep des inclusions/source dans xtrace ==="
grep -nE '\b(source|\. ) .*(environment|/etc/profile|bashrc|profile\.d)' "$xlog" || echo "<rien d'évident>"
echo

echo "=== Fin. Si le bruit a disparu avec --noprofile/--norc, patcher tous les runners en ce sens. ==="
