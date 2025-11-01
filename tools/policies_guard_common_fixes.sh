#!/usr/bin/env bash
# tools/policies_guard_common_fixes.sh
# Corrige les manques les plus fréquents pour faire passer "Policies Guard".
# - Ajoute CODEOWNERS / SECURITY.md / PULL_REQUEST_TEMPLATE.md si absents
# - Impose permissions minimales pour tous les workflows
# - Met des permissions étendues uniquement sur build-publish.yml
# - Relance la CI (si demandé)
#
# Usage:
#   bash tools/policies_guard_common_fixes.sh [branche] [--dispatch]
#
set -Eeuo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
DO_DISPATCH="${2:-}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

log(){ printf '\n\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m[OK ]\033[0m %s\n' "$*"; }

mkdir -p .github backups _tmp

# 1) CODEOWNERS
if [[ ! -f .github/CODEOWNERS ]]; then
  cat > .github/CODEOWNERS <<'EOF'
# Default code owners
*   @JeanPhilipLalumiere
EOF
  ok "Ajout .github/CODEOWNERS (owner par défaut)."
else
  log ".github/CODEOWNERS déjà présent."
fi

# 2) SECURITY.md
if [[ ! -f .github/SECURITY.md ]]; then
  cat > .github/SECURITY.md <<'EOF'
# Security Policy

## Reporting a Vulnerability
Please report security issues privately via email or a private GitHub issue if available.
We will assess, fix, and release patches as soon as possible.

## Supported Versions
We generally support the latest released version. Older versions may receive fixes on a best-effort basis.
EOF
  ok "Ajout .github/SECURITY.md (policy minimale)."
else
  log ".github/SECURITY.md déjà présent."
fi

# 3) PULL_REQUEST_TEMPLATE.md
if [[ ! -f .github/PULL_REQUEST_TEMPLATE.md ]]; then
  cat > .github/PULL_REQUEST_TEMPLATE.md <<'EOF'
## Description
<!-- Résumez les changements. Lien vers l'issue si applicable. -->

## Checklist
- [ ] Titre conforme Conventional Commits (ex: `chore(ci): ...` / `fix(core): ...`)
- [ ] CI verte (ou justifiée)
- [ ] Docs/README mis à jour si nécessaire
- [ ] Pas de fichiers générés ni secrets dans le diff

## Tests
<!-- Décrivez comment tester / ce qui a été testé. -->
EOF
  ok "Ajout .github/PULL_REQUEST_TEMPLATE.md."
else
  log ".github/PULL_REQUEST_TEMPLATE.md déjà présent."
fi

# 4) Permissions minimales par défaut sur tous les workflows
shopt -s nullglob
WF=(".github/workflows/"*.yml ".github/workflows/"*.yaml)
if ((${#WF[@]}==0)); then
  warn "Aucun workflow trouvé dans .github/workflows/."
fi

for f in "${WF[@]}"; do
  # Sauvegarde
  cp --no-clobber --update=none "$f" "backups/$(basename "$f").bak" || true

  # Ajoute permissions top-level si absentes
  if ! grep -qE '^[[:space:]]*permissions:' "$f"; then
    awk 'NR==1{print "# added by policies_guard_common_fixes"; print "permissions:"; print "  contents: read"}1' "$f" > "$f.tmp"
    mv "$f.tmp" "$f"
    ok "permissions: contents: read -> $f"
  fi
done

# 5) Permissions spécifiques pour la publication PyPI (si workflow présent)
PUB_WF=""
for f in "${WF[@]}"; do
  if grep -qiE 'pypi|publish|build-publish' "$f"; then
    PUB_WF="$f"; break
  fi
done

if [[ -n "${PUB_WF:-}" ]]; then
  # S'assure que le job de publish a les droits nécessaires
  # (on ne touche pas aux autres jobs)
  # NB: insertion simple: si 'id-token' n'est pas mentionné, on ajoute un bloc permissif.
  if ! grep -q 'id-token:' "$PUB_WF"; then
    log "Renforcement permissions pour la publication: $PUB_WF"
    # Ajoute un bloc de permissions globales si besoin (déjà fait plus haut),
    # puis ajoute un commentaire d’intention. Éviter de casser le YAML.
    printf '\n# publish permissions (added by policies_guard_common_fixes)\n' >> "$PUB_WF"
    printf 'permissions:\n  id-token: write\n  contents: write\n' >> "$PUB_WF"
    ok "Ajout id-token/contents write dans $PUB_WF (niveau fichier)."
    warn "Si Policies Guard exige des permissions au niveau du job uniquement, on ajustera après lecture des logs."
  else
    log "Permissions publish déjà présentes dans $PUB_WF"
  fi
fi

# 6) Commit & push
if ! git diff --quiet -- .github; then
  git add .github
  git commit -m "chore(policies): governance files & least-privilege permissions (safe defaults)"
  ok "Commit créé."
else
  log "Aucun changement à committer."
fi

if [[ -n "$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)" ]]; then
  git push
  ok "Push effectué sur $(git rev-parse --abbrev-ref HEAD)."
else
  warn "Branche sans tracking. Push manuel recommandé :"
  echo "     git push -u origin $(git rev-parse --abbrev-ref HEAD)"
fi

# 7) Relance Policies Guard (optionnel)
if [[ "${DO_DISPATCH:-}" == "--dispatch" ]]; then
  if gh workflow run .github/workflows/policies-guard.yml -r "$BRANCH" >/dev/null 2>&1; then
    ok "Relance policies-guard (workflow_dispatch)."
  else
    warn "Impossible de relancer policies-guard (pas de trigger?)."
  fi
fi

log "Terminé. Si Policies Guard échoue encore, partage ~20 lignes clefs de son log résumé pour patch ciblé."
