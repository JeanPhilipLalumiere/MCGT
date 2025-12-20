#!/usr/bin/env bash
# cleanup_no_backups.sh — purge des fichiers de backup SUIVIS (index-only),
# garde global .gitignore, workflow no-backups réécrit intégralement, PR auto.
# Usage:
#   bash cleanup_no_backups.sh                 # par défaut sur release/zz-tools-0.3.1
#   BASE=main bash cleanup_no_backups.sh       # pour agir sur main

set -Eeuo pipefail

BASE="${BASE:-release/zz-tools-0.3.1}"
BR="cleanup/no-backups-$(date -u +%Y%m%dT%H%M%SZ)"
WF_PATH=".github/workflows/no-backups.yml"
OUTDIR=".ci-out/no-backups"
mkdir -p "$OUTDIR"

# ---------- Traps sûrs ----------
stashed_ref=""
on_err() {
  code=$?
  echo
  echo "[ERREUR] code=$code"
  [[ -n "$stashed_ref" ]] && { echo "[INFO] Restauration du stash local: $stashed_ref"; git stash pop -q || true; }
  exit "$code"
}
on_exit() {
  code=$?
  if [[ "$code" -eq 0 ]]; then
    echo
    echo "[OK] Fin normale."
  fi
}
trap on_err ERR
trap on_exit EXIT

echo "[INFO] Base ciblée: $BASE"

# ---------- Stash si modifs locales ----------
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[INFO] Changements locaux détectés → stash temporaire"
  stashed_ref="$(git stash push -u -m "temp/no-backups-$(date -u +%Y%m%dT%H%M%SZ)")" || true
fi

# ---------- Checkout depuis un ref non ambigu ----------
git fetch origin --quiet || true
UPSTREAM="refs/remotes/origin/$BASE"
git switch -c "$BR" "$UPSTREAM"

# ---------- Regex commune (workflow & garde) ----------
RGX='(\.bak([_.-].*)?$|~$|\.old$|\.orig$|\.tmp$|\.swp$|\.swo$|(^|/)#.*#$|(^|/)\..*~$)'

# ---------- 1) Inventaire des fichiers SUIVIS à purger ----------
mapfile -t FILES < <(git ls-files | egrep -E "$RGX" || true)
COUNT="${#FILES[@]}"
echo "[INFO] Fichiers suivis à purger: $COUNT"

# === Sortie propre si rien à faire (exigence utilisateur) ===
if [[ "$COUNT" -eq 0 ]]; then
  echo "[OK] Rien à faire sur $BASE"
  # >>> désarme les traps pour éviter le faux message à la fermeture
  trap - ERR EXIT
  # >>> en interactif: ne pas quitter la session; en script: terminer proprement
  if [[ -n "${PS1-}" ]]; then
    return 0 2>/dev/null || exit 0
  else
    exit 0
  fi
fi

# ---------- 2) .gitignore — garde idempotent (réécrit proprement) ----------
GI_BLOCK_START="# >>> no-backups guard"
GI_BLOCK_END="# <<< no-backups guard"
GI_BLOCK=$(cat <<'EOF'
# >>> no-backups guard
# Ignorer backups/parasites partout (non destructif pour le working tree)
*.bak
*.bak_*
*.old
*.orig
*.tmp
*~
# Emacs autosave/locks
#*#
.*~
# Vim swaps
*.swp
*.swo
# <<< no-backups guard
EOF
)

if [[ -f .gitignore ]]; then
  # Retire l'ancien bloc s'il existe, puis ajoute le bloc canonique
  sed -i -e "/$GI_BLOCK_START/,/$GI_BLOCK_END/d" .gitignore
  printf "%s\n" "$GI_BLOCK" >> .gitignore
  echo "[OK] .gitignore mis à jour (bloc guard propre)."
else
  printf "%s\n" "$GI_BLOCK" > .gitignore
  echo "[OK] .gitignore créé avec garde."
fi

# ---------- 3) Workflow réécrit intégralement ----------
mkdir -p "$(dirname "$WF_PATH")"
cat > "$WF_PATH" <<'YAML'
name: no-backups
on:
  workflow_dispatch: {}
  push:
    branches: [ "main", "release/**" ]
  pull_request:
    branches: [ "main", "release/**" ]

permissions:
  contents: read

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Scan for backup/parasite files tracked by Git
        shell: bash
        run: |
          set -euo pipefail
          # Aligné sur le garde .gitignore (inclut Emacs #*# et dotfiles *~)
          RGX='(\.bak([_.-].*)?$|~$|\.old$|\.orig$|\.tmp$|\.swp$|\.swo$|(^|/)#.*#$|(^|/)\..*~$)'
          git ls-files | egrep -E "$RGX" > matches.txt || true
          if [[ -s matches.txt ]]; then
            printf "### no-backups: fichiers parasites détectés\n\n" >> "$GITHUB_STEP_SUMMARY"
            printf '```text\n' >> "$GITHUB_STEP_SUMMARY"
            cat matches.txt >> "$GITHUB_STEP_SUMMARY"
            printf '\n```\n' >> "$GITHUB_STEP_SUMMARY"
            echo "::error::Found backup/parasite files tracked by Git. See matches.txt artifact."
            exit 1
          else
            echo "### no-backups: OK — aucun fichier parasite suivi" >> "$GITHUB_STEP_SUMMARY"
          fi

      - name: Upload matches.txt
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: no-backups-${{ github.run_id }}
          path: matches.txt
          if-no-files-found: warn
          retention-days: 7
YAML
echo "[OK] Workflow réécrit: $WF_PATH"

# ---------- 4) Purge index-only des fichiers suivis détectés ----------
# Utilise NUL separator pour couvrir tout caractère exotique
printf "%s\0" "${FILES[@]}" | xargs -0 -r git rm --cached --ignore-unmatch --
echo "[INFO] Retiré de l'index: $COUNT entrées"

# ---------- 5) Commit + pre-commit (tolérant) ----------
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run -a || true
fi
git add -A
git commit -m "ci(no-backups): rewrite workflow & add repo-wide guard; purge tracked backups (index-only)"

# ---------- 6) Push + PR ----------
git push -u origin "$BR"
echo "[OK] Branch poussée: $BR"

gh pr create --base "$BASE" --head "$BR" \
  --title "ci(no-backups): align workflow + repo-wide guard; purge index" \
  --body "Réécriture intégrale du workflow **no-backups**, garde global **.gitignore**, purge des fichiers de backup *suivis* (index-only)."
echo "[OK] PR ouverte."

# ---------- 7) Lancer le workflow sur BASE (historisation) ----------
gh workflow run no-backups.yml --ref "$BASE" || {
  echo "[WARN] Impossible de lancer le workflow no-backups.yml (nom/trigger ?)."
  :
}

# ---------- 8) Télécharger l’artefact le plus récent (best-effort) ----------
RID="$(gh run list --workflow no-backups.yml --branch "$BASE" --json databaseId,createdAt \
       -q 'sort_by(.createdAt) | last | .databaseId // empty')"
if [[ -n "${RID:-}" ]]; then
  gh run watch "$RID" --exit-status || true
  gh run download "$RID" -D "$OUTDIR" || true
  find "$OUTDIR" -maxdepth 2 -name matches.txt -exec sh -c 'echo "---"; nl -ba "$1"' _ {} \; || true
fi

# ---------- 9) Restaurer le stash local s'il existait ----------
if [[ -n "$stashed_ref" ]]; then
  echo "[INFO] Restauration du stash local: $stashed_ref"
  git stash pop -q || true
fi
