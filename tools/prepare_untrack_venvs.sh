#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"

OUT_DIR=".ci-out/scan"
mkdir -p "$OUT_DIR"

IGNOREFILE=".gitignore"
BACKUP="$IGNOREFILE.pre-venv-clean.bak"
cp -n "$IGNOREFILE" "$BACKUP" 2>/dev/null || true
echo "Backup saved to $BACKUP (if it existed)."

# conservative patterns
PATTERNS=$'.venv/\nvenv/\n.venv-pypi/\nenv/\nENV/\n.pytest_cache/\n__pycache__/\n.ipynb_checkpoints/\ndist/\nbuild/\n*.egg-info/\n'

# append missing patterns
echo "Ensuring venv patterns are present in $IGNOREFILE"
python3 - <<'PY'
import sys
f = ".gitignore"
pats = """$PATTERNS"""
try:
    exist = open(f, "r", encoding="utf-8").read().splitlines()
except FileNotFoundError:
    exist = []
out = open(f, "a", encoding="utf-8")
for line in pats.splitlines():
    if line.strip() and line not in exist:
        out.write(line + "\n")
out.close()
print("Appended missing patterns to", f)
PY

# detect tracked venv-like paths
echo "Detecting tracked virtualenv-like paths..."
git ls-files -z | xargs -0 -n1 | grep -E '(^|/)(\.venv|venv|\.venv-pypi|env|ENV)/' | sort -u > "$OUT_DIR/tracked_venvs_to_untrack.txt" || true

if [ ! -s "$OUT_DIR/tracked_venvs_to_untrack.txt" ]; then
  echo "No tracked venv-like paths found. Nothing to untrack."
  exit 0
fi

echo "Wrote list to $OUT_DIR/tracked_venvs_to_untrack.txt"
echo "Creating a safe apply script: tools/apply_untrack_venvs.sh (NOT executed automatically)."
cat > tools/apply_untrack_venvs.sh <<'APPLY'
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT"
LIST=".ci-out/scan/tracked_venvs_to_untrack.txt"
if [ ! -s "$LIST" ]; then
  echo "No venvs listed in $LIST"
  exit 0
fi
echo "This script will run: git rm --cached -r <each path in $LIST>"
echo "Preview (dry-run):"
while IFS= read -r p; do
  echo "would untrack: $p"
done < "$LIST"

echo
echo "To actually untrack, run this script again with 'apply' as argument: ./tools/apply_untrack_venvs.sh apply"
if [ "${1-}" = "apply" ]; then
  while IFS= read -r p; do
    echo "Untracking: $p"
    git rm --cached -r -- "$p" || true
  done < "$LIST"
  git add .gitignore
  echo "Staged .gitignore and untrack changes. Run 'git status' then commit when ready."
fi
APPLY
chmod +x tools/apply_untrack_venvs.sh

echo "Done. Inspect $OUT_DIR/tracked_venvs_to_untrack.txt and tools/apply_untrack_venvs.sh. Run the apply script with 'apply' when you're ready."
