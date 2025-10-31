# repo_round3_quarantine_safe_runners_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round3_quarantine_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "branche=${BR}"
# On travaille sur chore/round3-cli-homog (policy CI already there)
if [ "$BR" != "chore/round3-cli-homog" ]; then
  git switch chore/round3-cli-homog
fi

echo "== SCAN RUNNERS *_safe.py hors attic/ =="
mapfile -t SAFE < <(git ls-files | grep -E '^.*run_.*_safe\.py$' | grep -v '^attic/')
if [ "${#SAFE[@]}" -eq 0 ]; then
  echo "[OK] Aucun runner *_safe.py hors attic/."
else
  echo "[FOUND] ${#SAFE[@]} fichier(s) à déplacer:"
  printf ' - %s\n' "${SAFE[@]}"
  echo "== QUARANTAINE =="
  mkdir -p attic/safe_runners
  for f in "${SAFE[@]}"; do
    tgt="attic/safe_runners/${f//\//__}"
    git mv "$f" "$tgt"
    echo "[mv] $f -> $tgt"
  done
  git add -A
  git commit -m "chore(round3): quarantine *_safe runners under attic/safe_runners/ (CI policy compliance)"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
fi

echo "== REGEN TODO CLI =="
python tools/check_cli_common.py || true
python tools/check_cli_policy.py || true
python tools/check_no_safe_runners.py || true

echo "== CONSEIL =="
echo "• Laisse la CI tourner; elle signalera encore les producteurs sans les 6 flags."
echo "• Prochaine étape: patch minimal CLI (chapitre 09) pour passer la policy."

# Fin guardé
