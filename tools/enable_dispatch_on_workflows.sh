#!/usr/bin/env bash
# tools/enable_dispatch_on_workflows.sh
# Ajoute 'workflow_dispatch:' et 'pull_request:' dans les workflows cibles si absents.
# Fichiers ciblés : .github/workflows/build-publish.yml, .github/workflows/ci-accel.yml
# Crée *.bak, commit, push sur la branche rewrite.

set -euo pipefail
FILES=(
  ".github/workflows/build-publish.yml"
  ".github/workflows/ci-accel.yml"
)

BRANCH="${1:-rewrite/main-20251026T134200}"

# Assure la branche locale
git fetch origin "$BRANCH" >/dev/null 2>&1 || true
git checkout -B "$BRANCH" "origin/$BRANCH" 2>/dev/null || git checkout "$BRANCH"

changed=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "[INFO] Skip (absent): $f"; continue; }
  cp --no-clobber --update=none "$f" "$f.bak" || true

  # Ajoute 'workflow_dispatch:' si absent
  if ! grep -Eq '^[[:space:]]*workflow_dispatch:' "$f"; then
    echo "[RUN] Ajout workflow_dispatch: -> $f"
    # S’il y a un bloc 'on:' on ajoute dedans, sinon on ajoute un bloc 'on:' minimal
    if grep -Eq '^[[:space:]]*on:' "$f"; then
      awk '
        BEGIN{added=0}
        /^[[:space:]]*on:[[:space:]]*$/ && added==0 {
          print; print "  workflow_dispatch:"; added=1; next
        }
        {print}
        END{if(added==0){print "on:"; print "  workflow_dispatch:"}}
      ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    else
      printf "on:\n  workflow_dispatch:\n\n%s" "$(cat "$f")" > "$f.tmp" && mv "$f.tmp" "$f"
    fi
    changed=1
  fi

  # Ajoute 'pull_request:' si ni pull_request ni push ne sont présents (pour CI PR)
  if ! grep -Eq '^[[:space:]]*(pull_request:|push:)' "$f"; then
    echo "[RUN] Ajout pull_request: -> $f"
    awk '
      BEGIN{added=0}
      /^[[:space:]]*on:[[:space:]]*$/ && added==0 {
        print; print "  pull_request:"; added=1; next
      }
      {print}
      END{if(added==0){print "on:"; print "  pull_request:"}}
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    changed=1
  fi
done

if [[ $changed -eq 1 ]]; then
  echo "[RUN] Commit & push des workflows modifiés…"
  git add .github/workflows/*.yml
  git commit -m "ci: enable workflow_dispatch and pull_request triggers (safe)"
  git push -u origin "$BRANCH"
  echo "[INFO] CI devrait se (re)lancer sur la PR #19."
else
  echo "[INFO] Aucun changement requis dans les workflows."
fi
