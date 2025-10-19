#!/usr/bin/env bash
set -euo pipefail

# Script to: add common venv names to .gitignore, untrack them from git index, and create a commit.
# Review the changes before pushing.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

IGNOREFILE=".gitignore"
BACKUP_IGNOREFILE=".gitignore.pre-venv-clean.bak"

# Make a conservative list of patterns to ignore
read -r -d '' IGNORE_PATTERNS <<'PAT'
# virtualenvs and local envs
.venv/
venv/
.venv-pypi/
env/
ENV/
.pytest_cache/
__pycache__/
# ipynb checkpoints (optional)
.ipynb_checkpoints/
# common build artifacts
dist/
build/
*.egg-info/
PAT

# backup existing .gitignore
if [ -f "$IGNOREFILE" ]; then
  cp "$IGNOREFILE" "$BACKUP_IGNOREFILE"
  echo "Backup of existing .gitignore saved to $BACKUP_IGNOREFILE"
fi

# append patterns if not present
echo "Appending venv patterns to $IGNOREFILE (duplicates ignored)..."
for p in $(echo "$IGNORE_PATTERNS"); do
  grep -Fxq "$p" "$IGNOREFILE" 2>/dev/null || echo "$p" >> "$IGNOREFILE"
done

# detect tracked directories that look like virtualenvs or site-packages
echo "Detecting tracked virtualenv-like paths..."
TRACKED_VENVS=$(git ls-files -z | xargs -0 -n1 | grep -E '(^|/)(\.venv|venv|\.venv-pypi|env|ENV)/' || true)

if [ -z "$TRACKED_VENVS" ]; then
  echo "No tracked venv-like paths found in git index."
  exit 0
fi

echo "Tracked venv-like paths (sample):"
echo "$TRACKED_VENVS" | sed -n '1,20p'

# Create a file listing what we'll untrack
OUT_LIST=".ci-out/scan/tracked_venvs_to_untrack.txt"
mkdir -p "$(dirname "$OUT_LIST")"
echo "$TRACKED_VENVS" | sort -u > "$OUT_LIST"
echo "Saved tracked venv paths to $OUT_LIST"

# Untrack them but keep files locally
echo "Running git rm --cached for those paths (safe: files will remain locally)..."
git rm --cached -r $(cat "$OUT_LIST") || true

# stage .gitignore and create commit
git add "$IGNOREFILE"
git commit -m "ci: untrack local virtualenvs; add common venv patterns to .gitignore" || echo "No commit created (maybe no staged changes)."

echo "Done. Review commit with 'git show --stat HEAD' and 'git status'."
