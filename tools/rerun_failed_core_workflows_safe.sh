# tools/rerun_failed_core_workflows_safe.sh
#!/usr/bin/env bash
# NE FERME PAS — relance les 2 derniers runs en échec pour build-publish & ci-accel
set -u -o pipefail; set +e
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m[OK  ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

BR="${1:-main}"
wfs=( ".github/workflows/build-publish.yml" ".github/workflows/ci-accel.yml" )

if ! gh auth status >/dev/null 2>&1; then
  warn "gh non authentifié — je fais un simple workflow_dispatch@${BR}"
  for wf in "${wfs[@]}"; do
    gh workflow run "$wf" -r "$BR" >/dev/null 2>&1 && ok "dispatch $wf@$BR" || warn "dispatch KO $wf"
  done
  exit 0
fi

for wf in "${wfs[@]}"; do
  info "Recherche des 2 derniers runs en échec pour ${wf##*/}@$BR"
  rows="$(gh run list --workflow "$wf" --branch "$BR" --limit 10 2>/dev/null \
         | awk '$1=="completed" && $2=="failure"{print $(NF-2)}' | head -n 2)"
  if [ -z "$rows" ]; then
    warn "Pas d'échec récent pour ${wf##*/} — je fais un dispatch."
    gh workflow run "$wf" -r "$BR" >/dev/null 2>&1 && ok "dispatch $wf@$BR" || warn "dispatch KO $wf"
    continue
  fi
  while IFS= read -r rid; do
    [ -n "$rid" ] || continue
    gh run rerun "$rid" --failed >/dev/null 2>&1 && ok "rerun (failed) run=$rid" || {
      warn "rerun --failed impossible (permissions ?). Je tente un dispatch."
      gh workflow run "$wf" -r "$BR" >/dev/null 2>&1 && ok "dispatch $wf@$BR" || warn "dispatch KO $wf"
    }
  done <<< "$rows"
done

ok "Relances envoyées. Ouvre Actions → Runs pour suivre (fenêtre laissée OUVERTE)."
