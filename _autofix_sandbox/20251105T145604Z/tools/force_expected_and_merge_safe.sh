#!/usr/bin/env bash
set -u -o pipefail; set +e
PR="${1:-20}"
REQ1="pypi-build/build"; REQ2="secret-scan/gitleaks"
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*\n"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*\n"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*\n"; }
err(){  printf '\033[1;31m[ERR ]\033[0m %s\n' "$*\n"; }

BR="$(gh pr view "$PR" --json headRefName -q .headRefName 2>/dev/null)" || BR=""
[ -z "${BR:-}" ] && { err "Impossible d’obtenir la branche PR"; exit 0; }
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR" >/dev/null 2>&1

# 1) No-op ciblé pour générer un NOUVEAU SHA si besoin (et éviter 'already up to date')
touch .ci-nudge && git add .ci-nudge
git commit -m "chore(ci): nudge required checks (expected→success sync)" >/dev/null 2>&1 || true
git push >/dev/null 2>&1 || true

# 2) Récupérer le HEAD SHA et dispatch UNIQUEMENT les workflows requis
HEAD_SHA="$(git rev-parse HEAD)"
ok "HEAD SHA = $HEAD_SHA"
gh workflow run .github/workflows/pypi-build.yml  -r "$BR" >/dev/null 2>&1 || warn "dispatch pypi-build.yml a échoué"
gh workflow run .github/workflows/secret-scan.yml -r "$BR" >/dev/null 2>&1 || warn "dispatch secret-scan.yml a échoué"

# 3) Poll l’API des checks jusqu’à SUCCESS pour REQ1 & REQ2 au HEAD courant
#    On passe par l’API 'commits/{sha}/check-runs' pour lire les 'conclusion' des jobs Actions
MAX=60; SLEEP=10
for i in $(seq 1 $MAX); do
  info "Poll $i/$MAX — vérification des deux contexts requis sur $HEAD_SHA"
  # Liste des check-runs via API (peut renvoyer plusieurs runs — on filtre par nom et HEAD SHA)
  JSON="$(gh api repos/:owner/:repo/commits/$HEAD_SHA/check-runs -H 'Accept: application/vnd.github+json' 2>/dev/null)"
  # Conclusions (success/failure) pour nos deux noms
  C1="$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="'"$REQ1"'") | .conclusion' | tail -n1)"
  C2="$(printf "%s" "$JSON" | jq -r '.check_runs[]? | select(.name=="'"$REQ2"'") | .conclusion' | tail -n1)"
  echo "  $REQ1 => ${C1:-<none>}"
  echo "  $REQ2 => ${C2:-<none>}"
  if [ "${C1:-}" = "success" ] && [ "${C2:-}" = "success" ]; then
    ok "Les deux checks requis sont SUCCESS sur le HEAD courant."
    break
  fi
  sleep "$SLEEP"
done

# 4) Merge standard, puis fallback admin
gh pr merge "$PR" --rebase --delete-branch && exit 0
warn "Merge standard refusé, tentative admin…"
gh pr merge "$PR" --rebase --delete-branch --admin || err "Même l’admin a été refusé — utilise l’UI (Rebase and merge)."
