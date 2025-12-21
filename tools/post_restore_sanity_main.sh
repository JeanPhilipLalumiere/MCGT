#!/usr/bin/env bash
# post_restore_sanity_main.sh — déclenche pypi-build & secret-scan sur main et attend SUCCESS
# - AUCUNE écriture dans le repo
# - Journalisation + garde-fou pour garder la fenêtre ouverte
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _logs _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/sanity_main_${TS}.log"

say(){ echo -e "$*" | tee -a "$LOG" ; }

say "[STEP] 1/5 — Vérifie protection de main"
PROT="$(gh api repos/:owner/:repo/branches/main/protection)"
strict=$(echo "$PROT" | jq -r '.required_status_checks.strict')
conv=$(echo "$PROT" | jq -r '.required_conversation_resolution.enabled')
revn=$(echo "$PROT" | jq -r '.required_pull_request_reviews.required_approving_review_count')
checks=$(echo "$PROT" | jq -r '[.required_status_checks.checks[].context] | join(",")')
say "[INFO] strict=$strict ; conv_resolve=$conv ; reviews=$revn ; checks=$checks"
if [[ "$strict" != "true" || "$conv" != "true" || "$revn" != "1" ]] \
   || ! grep -q "pypi-build/build" <<<"$checks" \
   || ! grep -q "secret-scan/gitleaks" <<<"$checks"; then
  say "[WARN] Protection non conforme aux attentes strictes — tu viens de la restaurer, re-lance ce script après correction si besoin."
fi

say "[STEP] 2/5 — Déclenche workflows sur ref=main (workflow_dispatch)"
# Ces noms doivent correspondre aux fichiers présents en CI
# (tu les as déjà : pypi-build.yml et secret-scan.yml)
( gh workflow run pypi-build.yml  --ref main && say "[OK] dispatch pypi-build" ) || say "[WARN] dispatch pypi-build a échoué (vérifie triggers)"
( gh workflow run secret-scan.yml  --ref main && say "[OK] dispatch secret-scan" ) || say "[WARN] dispatch secret-scan a échoué (vérifie triggers)"

say "[STEP] 3/5 — Attente que les runs soient pris en compte (petit délai)"
sleep 8

say "[STEP] 4/5 — Boucle de poll (max 60 x 5s ≈ 5 min)"
ok_build=""; ok_scan=""
for i in $(seq 1 60); do
  # Récupère les DERNIERS runs par workflow sur main
  rb=$(gh run list --workflow pypi-build.yml  --branch main --limit 1 --json conclusion,status 2>/dev/null | jq -r '.[0].conclusion // ""')
  rs=$(gh run list --workflow secret-scan.yml --branch main --limit 1 --json conclusion,status 2>/dev/null | jq -r '.[0].conclusion // ""')

  [[ "$rb" == "success" ]] && ok_build="yes" || ok_build=""
  [[ "$rs" == "success" ]] && ok_scan="yes"  || ok_scan=""

  say "[POLL $i] pypi-build=$rb ; secret-scan=$rs"
  if [[ "$ok_build" == "yes" && "$ok_scan" == "yes" ]]; then
    say "[OK] Les deux workflows sur main ont conclu SUCCESS."
    break
  fi
  sleep 5
done

if [[ "$ok_build" != "yes" || "$ok_scan" != "yes" ]]; then
  say "[FAIL] Timeout: au moins un des deux workflows n'a pas conclu SUCCESS."
  say "       Consulte 'gh run view' pour les logs détaillés."
  read -r -p $'Fin (échec). ENTER pour fermer…\n' _ </dev/tty || true
  exit 1
fi

say "[STEP] 5/5 — Sanity CI sur main: OK (protections + 2 checks verts)."
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
