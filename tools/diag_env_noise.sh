#!/usr/bin/env bash
set -Eeuo pipefail

ts="$(date +%Y%m%dT%H%M%S)"
diag_log="zz-out/diag_env_noise_${ts}.log"
raw_log="zz-out/diag_env_noise_${ts}.raw.log"

# Même commande que le runner PASS14
cmd='tools/pass14_smoke_with_mapping.sh'

# Xtrace très verbeux, horodaté, avec source:ligne
export PS4='+[${EPOCHREALTIME}] ${BASH_SOURCE##*/}:${LINENO}: ${FUNCNAME[0]:-main}: '
# canal séparé pour la trace xtrace
exec {xtracefd}> "$diag_log"
export BASH_XTRACEFD=$xtracefd
set -o xtrace

# Snapshot de l'environnement utile
{
  echo '===== DIAG SNAPSHOT ====='
  echo "shell: $SHELL"; bash --version 2>/dev/null | head -1 || true
  echo "pwd:    $(pwd)"
  echo "whoami: $(whoami)"
  echo '--- env (tri) ---'
  env | sort
  echo '--- bash options ---'
  shopt -p || true
  echo '===== RUN ====='
} >>"$diag_log" 2>&1

# Exécution en dupliquant aussi le flux brut pour corrélation
# (raw -> tout le stderr/stdout, diag_log -> la trace xtrace)
{
  set +o pipefail
  { "$SHELL" -lc "$cmd"; } > >(tee -a "$raw_log") 2>&1
} || true

# Post-traitement minimal : extraire le bruit et le contexte proche
{
  echo '===== NOISE CANDIDATES (raw) ====='
  grep -nE '^environment: line 4: .*: division by 0 \(error token is ' "$raw_log" || true
  echo '===== CONTEXT AROUND (xtrace) ====='
  # Cherche les 20 lignes de contexte autour des appels proches de "environment"
  grep -nE 'environment|pass14_smoke_with_mapping|exec|env -u BASH_ENV -u ENV bash --noprofile --norc -lc' "$diag_log" | sed -n '1,200p' || true
} >>"$diag_log" 2>&1

echo "Diagnostic terminé.
 - Trace xtrace : $diag_log
 - Flux brut    : $raw_log
Astuce : ouvre $diag_log et repère la dernière commande exécutée juste AVANT les lignes “environment: line 4 …” du $raw_log."
