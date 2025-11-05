#!/usr/bin/env bash
# reclean_restored_bak_guarded.sh
# Remet de l'ordre après restauration .bak → fichiers "vivants".
# - Dry-run lisible
# - Application sûre (branche dédiée + PR)
# - Garde-fou: fenêtre ne se ferme pas

set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"; cd "$REPO"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/reclean_bak_${TS}.log"
DRY="_tmp/reclean_bak_dry_${TS}.txt"

echo "[INFO] Repo: $(basename "$REPO")" | tee "$LOG"

# 1) Cibles identifiées
echo "[SCAN] inventaire des réintroductions indésirables" | tee -a "$LOG"
: > "$DRY"

# a) Tout _tmp/** suivi par Git (ne devrait pas l’être)
git ls-files -z _tmp | xargs -0 -I{} bash -lc 'echo "[TMP] {}"' | tee -a "$DRY" || true

# b) Contenu du dossier backups/ (workflows archivés redevenus 'actifs' à tort)
if [ -d backups ]; then
  git ls-files -z backups | xargs -0 -I{} bash -lc 'echo "[BACKUPS] {}"' | tee -a "$DRY" || true
fi

# c) Fichiers restaurés dans attic/.../tools/ sans suffixe .bak (nous re-bak-ons)
mapfile -t ATTIC_TOOLS < <(git ls-files 'attic/**/tools/*' 2>/dev/null || true)
for f in "${ATTIC_TOOLS[@]:-}"; do
  base="$(basename "$f")"
  case "$base" in
    *.bak|*.bak.*) : ;;                      # déjà bak
    *) echo "[ATTIC-TOOLS-REB AK] $f" | tee -a "$DRY" ;;
  esac
done

echo
echo "Aperçu des actions proposées :" | tee -a "$LOG"
cat "$DRY" | sed -n '1,200p' | tee -a "$LOG" || true
echo "(…voir $DRY pour l’intégralité)" | tee -a "$LOG"

read -r -p $'OK pour appliquer ? [o/N] ' ans </dev/tty || true
[[ "${ans:-N}" =~ ^[oOyY]$ ]] || { echo "Abandon (dry-run seulement)."; exit 0; }

# 2) Application
BR="chore/reclean-bak-${TS}"
git switch -c "$BR" >/dev/null

# a) retirer _tmp/** du suivi Git (sans effacer tes fichiers locaux)
if git ls-files -z _tmp | grep -q . ; then
  git rm -r --cached _tmp || true
fi

# b) déplacer backups/** → attic/ci_backups_<TS>/
if [ -d backups ] && git ls-files -z backups | grep -q . ; then
  DEST="attic/ci_backups_${TS}"
  mkdir -p "$DEST"
  # on déplace uniquement ce qui est tracké
  while IFS= read -r -d '' f; do
    mkdir -p "$DEST/$(dirname "$f" | sed 's#^backups/?##')"
    git mv "$f" "$DEST/$(echo "$f" | sed 's#^backups/##')" || true
  done < <(git ls-files -z backups)
fi

# c) re-suffixer .bak dans attic/.../tools/ pour laisser clair que c’est archivé
for f in "${ATTIC_TOOLS[@]:-}"; do
  base="$(basename "$f")"
  case "$base" in
    *.bak|*.bak.*) : ;;
    *) git mv "$f" "${f}.bak" || true ;;
  esac
done

# d) .gitignore (durcissement)
#    - ignorer _tmp/ et backups/ globalement (on garde la liberté de mettre un README)
if ! grep -qE '(^|/)_tmp/?$' .gitignore 2>/dev/null; then
  echo "_tmp/" >> .gitignore
fi
if ! grep -qE '(^|/)backups/?$' .gitignore 2>/dev/null; then
  echo "backups/" >> .gitignore
  mkdir -p backups
  : > backups/README.md
  git add backups/README.md || true
fi

git add -A
git commit -m "chore(clean): re-attic backups & tmp; re-suffix .bak in attic tools; harden .gitignore"

# 3) PR
git push -u origin HEAD
gh pr create --fill || true
URL="$(gh pr view --json url -q .url 2>/dev/null || echo '')"
echo "[DONE] PR: ${URL:-<ouvrir manuellement>}" | tee -a "$LOG"

# 4) Sanity courte CI (best-effort)
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in {1..6}; do
  gh run list --branch main --limit 5 2>/dev/null | head -n 3 | sed "s/^/[POLL $i] /" || true
  sleep 5
done

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true
