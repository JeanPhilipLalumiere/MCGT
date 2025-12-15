#!/usr/bin/env bash
set -Eeo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/prepub_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

on_exit() {
  ec=$?
  echo
  echo "== Fin (code: $ec) =="
  echo "Log: $LOG"
  if [ -z "${MCGT_NO_SHELL_DROP:-}" ]; then
    echo
    echo "Ouverture d'un shell interactif (anti-fermeture)."
    echo "Pour quitter: 'exit' ou Ctrl+D."
    if command -v "${SHELL:-bash}" >/dev/null 2>&1; then exec "${SHELL:-bash}" -i
    elif command -v bash >/dev/null 2>&1; then exec bash -i
    else echo "Aucun shell trouvé, maintien de la session (Ctrl+C pour fermer)"; tail -f /dev/null
    fi
  fi
}
trap on_exit EXIT

echo "== Build prépublication bundle =="

FIGDIR="${FIGDIR:-zz-figures}"
MANIFEST_DIR="zz-manifests"
OUTDIR="dist"

# Infos repo
GIT_SHA="$(git rev-parse --short=12 HEAD 2>/dev/null || echo nogit)"
GIT_DESC="$(git describe --tags --always --dirty=+ 2>/dev/null || echo "$GIT_SHA")"
PREFIX="MCGT-prepub_${GIT_DESC}_${TS}"
STAGE="/tmp/${PREFIX}"
mkdir -p "$STAGE" "$OUTDIR"

# README de prépublication
README="${STAGE}/README_PREPUB.md"
FIGCOUNT=$(find "$FIGDIR" -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) \
            -not -path "$FIGDIR/_legacy_conflicts/*" | wc -l | tr -d ' ')
cat > "$README" <<EOF
# MCGT — Prépublication (bundle)
- Commit: \`${GIT_DESC}\` (\`${GIT_SHA}\`)
- Date (UTC): ${TS}
- Figures (hors quarantaine): ${FIGCOUNT}
- Inclus: scripts, données (si présents), figures, manifests (manifest + index), ce README
- Exclus: \`${FIGDIR}/_legacy_conflicts/\` (doublons legacy quarantainés)

## Contenu
- \`tools/\` (outils de build/guard)
- \`scripts/\` et/ou \`zz-scripts/\` (si présents)
- \`data/\` (si présent)
- \`${FIGDIR}/\` (symlinks legacy **déréférencés** → fichiers réels)
- \`${MANIFEST_DIR}/manifest_figures.sha256sum\`
- \`${MANIFEST_DIR}/figures_index.csv\` et \`figures_per_chapter.md\` (si présents)

## Vérifications rapides
\`\`\`bash
make figures-guard
make index-guard
\`\`\`

## Note
Cette prépublication **n’inclut pas** les fichiers .TEX remplis. Ils seront ajoutés ultérieurement.
EOF

copy_if_dir() { local src="$1"; local dst="$2"; [ -d "$src" ] || return 0; echo "→ copie: $src/"; rsync -a "$src"/ "$dst"/"$src"/; }

# Outils & code
copy_if_dir "tools" "$STAGE"
copy_if_dir "scripts" "$STAGE"
copy_if_dir "zz-scripts" "$STAGE"
copy_if_dir "data" "$STAGE"

# Manifests sélectionnés
mkdir -p "$STAGE/$MANIFEST_DIR"
for f in manifest_figures.sha256sum figures_index.csv figures_per_chapter.md fig_symlinks.map.csv; do
  [ -f "$MANIFEST_DIR/$f" ] && cp "$MANIFEST_DIR/$f" "$STAGE/$MANIFEST_DIR/"
done

# Figures: sans quarantaine, et **déréférencer** les symlinks legacy
if [ -d "$FIGDIR" ]; then
  echo "→ copie figures (sans _legacy_conflicts/ ; symlinks déréférencés)"
  rsync -aL --exclude "_legacy_conflicts/" "$FIGDIR"/ "$STAGE/$FIGDIR"/
fi

# Tarball + SHA256
TAR="${OUTDIR}/${PREFIX}.tar.gz"
echo "→ empaquetage: ${TAR}"
tar -C "/tmp" -czf "$TAR" "$PREFIX"

SHA=$(sha256sum "$TAR" | awk '{print $1}')
BYTES=$(stat -c%s "$TAR")
echo "${SHA}  ${TAR}  (${BYTES} bytes)"
echo "${SHA}  ${TAR}  (${BYTES} bytes)" > "zz-manifests/prepub_sha256.txt"
echo "Wrote zz-manifests/prepub_sha256.txt"

echo
echo "== Contenu dist/ =="
ls -lh "$OUTDIR"
