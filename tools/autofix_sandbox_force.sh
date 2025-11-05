#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Usage: tools/autofix_sandbox_force.sh "message de commit" [--push]
MSG="${1:-autofix(sandbox): ascii + future placement}"
PUSH="${2:-}"

# 0) Garantir l'unignore au .gitignore racine (idempotent)
if ! grep -q '^!release_zenodo_codeonly/' "$ROOT/.gitignore"; then
  {
    echo
    echo "# Allow code-only snapshot for Zenodo (re-include, even if parent ignored)"
    echo "!release_zenodo_codeonly/"
    echo "!release_zenodo_codeonly/v0.3.x/"
    echo "!release_zenodo_codeonly/v0.3.x/mcgt/**"
  } >> "$ROOT/.gitignore"
  git -C "$ROOT" add .gitignore
  MCGT_UNSEAL=1 git -C "$ROOT" commit -m "gitignore: re-include release_zenodo_codeonly/v0.3.x/mcgt/**" || true
fi

# 1) Lancer l'autofix (tolérant aux échecs d'add/commit internes)
python3 "$ROOT/tools/autofix_sandbox.py" --apply --commit "$MSG" --no-verify || true

# 2) (Re)stager le snapshot code-only, forçant si Git le considère ignoré
if git -C "$ROOT" add -n release_zenodo_codeonly/v0.3.x/mcgt/mcgt/__init__.py 2>&1 | grep -qi 'ignored'; then
  git -C "$ROOT" add -f -- release_zenodo_codeonly/v0.3.x/mcgt/**
else
  git -C "$ROOT" add -- release_zenodo_codeonly/v0.3.x/mcgt/**
fi

# 3) Durcir l'ignore du snapshot (idempotent)
SNAP_IGN="$ROOT/release_zenodo_codeonly/.gitignore"
mkdir -p "$(dirname "$SNAP_IGN")"
cat > "$SNAP_IGN" <<'EOF'
# Ignore all by default
*
!.gitignore
!v0.3.x/
!v0.3.x/mcgt/**

# Re-ignore build/backup artifacts inside mcgt/**
v0.3.x/mcgt/**/__pycache__/
v0.3.x/mcgt/**/*.pyc
v0.3.x/mcgt/**/*.pyo
v0.3.x/mcgt/**/*.bak
v0.3.x/mcgt/**/*RoundFUT*.pre.*
v0.3.x/mcgt/**/*autofix.*.bak
EOF
git -C "$ROOT" add release_zenodo_codeonly/.gitignore

# 4) Purger l'index des artefacts déjà trackés
mapfile -d '' -t GARBAGE < <(
  git -C "$ROOT" ls-files -z -- release_zenodo_codeonly/v0.3.x/mcgt \
  | grep -zE '/__pycache__/|\.pyc$|\.pyo$|\.bak$|RoundFUT.*\.pre\.|autofix\..*\.bak$' || true
)
((${#GARBAGE[@]})) && git -C "$ROOT" rm -r --cached -- "${GARBAGE[@]}"

# 5) Commit si l'index contient quelque chose
if [[ -n "$(git -C "$ROOT" diff --cached --name-only)" ]]; then
  MCGT_UNSEAL=1 git -C "$ROOT" commit -m "$MSG" --no-verify
  echo "[OK] Commit forcé: $MSG"
else
  echo "[SKIP] Rien à committer."
fi

# 6) Push optionnel
if [[ "$PUSH" == "--push" ]]; then
  git -C "$ROOT" push
fi
