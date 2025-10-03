#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

OUT_DIR=".ci-out"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/naming_guard_report.txt"
: >"$REPORT"

err() { echo "ERROR: $*" | tee -a "$REPORT"; }
info() { echo "INFO:  $*" | tee -a "$REPORT"; }

# Exclure binaires/artefacts/baks/sha256sum/gitignore
EXC=(
  ':!*.png' ':!*.jpg' ':!*.jpeg' ':!*.svg'
  ':!.ci-out/**' ':!.ci-logs/**' ':!.ci-archive/**'
  ':!*/*.bak*' ':!*~' ':!.gitignore'
  ':!zz-manifests/manifest_publication.sha256sum'
)

info "==> Naming guard: scan des références non canoniques"

declare -a checks=(
  "bad_prefix|zz-figures/chapter[0-9]{2}/fig_|Remplacer 'chapterNN/fig_' par 'chapterNN/NN_fig_'"
  "bad_03b|zz-figures/chapter10/10_fig_03b_|Renommer '03b' -> '03_b'"
  "bad_iso_map|fig_01_iso_(map_p95|p95_map)|Utiliser '10_fig_01_iso_p95_maps'"
  "bad_spectre|zz-figures/chapter02/fig_00_spectre|Utiliser '02_fig_00_spectrum'"
  "bad_p95_check|zz-figures/chapter09/09_fig_p95_check_control|Utiliser '09_fig_00_p95_check_control'"
  "bad_milestones|zz-figures/chapter09/fig_04_milestones_absdphi_vs_f|Utiliser '09_fig_04_absdphi_milestones_vs_f'"
)

fail=0
for spec in "${checks[@]}"; do
  name="${spec%%|*}"
  rest="${spec#*|}"
  regex="${rest%%|*}"
  help="${rest#*|}"
  info "--> Vérif: ${name} (${regex})"
  hits="$(git grep -n -E "${regex}" -- "${EXC[@]}" -- . || true)"
  if [[ -n "$hits" ]]; then
    echo "$hits" | tee -a "$REPORT"
    err "Nom non canonique détecté: ${name} — ${help}"
    fail=1
  fi
done

if ((fail == 0)); then
  info "✅ Naming guard: OK (aucune référence non canonique détectée)"
else
  err "❌ Naming guard: échecs détectés. Voir $REPORT"
fi

exit "$fail"
