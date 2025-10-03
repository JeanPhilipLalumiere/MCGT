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

# Exclusions (binaires/artefacts/baks/sha256sum/gitignore + ce script/workflow)
EXC=(
  ':!*.png' ':!*.jpg' ':!*.jpeg' ':!*.svg'
  ':!.ci-out/**' ':!.ci-logs/**' ':!.ci-archive/**'
  ':!*/*.bak*' ':!*~' ':!.gitignore'
  ':!zz-manifests/manifest_publication.sha256sum'
  ':!tools/ci_step4_guard_naming.sh'
  ':!.github/workflows/naming-guard.yml'
)

info "==> Naming guard: scan des références non canoniques"

# Délimiteur: TAB — name<TAB>regex<TAB>help
checks=(
  $'bad_prefix\tzz-figures/chapter[0-9]{2}/fig_\tRemplacer '\''chapterNN/fig_'\'' par '\''chapterNN/NN_fig_'\'''
  $'bad_03b\tzz-figures/chapter10/10_fig_03b_\tRenommer '\''03b'\'' -> '\''03_b'\'''
  # cible uniquement les variantes erronées (jamais ...p95_maps)
  $'bad_iso_map\t(zz-figures/chapter10/10_fig_01_iso_(map_p95|p95_map)\\.png|(^|[^A-Za-z0-9_])fig_01_iso_(map_p95|p95_map)\\.png($|[^A-Za-z0-9_]))\tUtiliser '\''10_fig_01_iso_p95_maps'\'''
  $'bad_spectre\tzz-figures/chapter02/fig_00_spectre\tUtiliser '\''02_fig_00_spectrum'\'''
  $'bad_p95_check\tzz-figures/chapter09/09_fig_p95_check_control\tUtiliser '\''09_fig_00_p95_check_control'\'''
  $'bad_milestones\tzz-figures/chapter09/fig_04_milestones_absdphi_vs_f\tUtiliser '\''09_fig_04_absdphi_milestones_vs_f'\'''
)

fail=0
for spec in "${checks[@]}"; do
  IFS=$'\t' read -r name regex help <<<"$spec"
  info "--> Vérif: ${name} (${regex})"
  hits="$(git grep -n -E "$regex" -- "${EXC[@]}" -- . 2>/dev/null || true)"
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
