cd "$(git rev-parse --show-toplevel)"

cat > scripts/guard_ignore_and_sdist.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== GUARD: tracked files ignored check ==="
ignored=0

# Robust: support filenames with spaces/special chars (NUL-delimited)
while IFS= read -r -d '' f; do
  if git check-ignore -q -- "$f"; then
    ignored=$((ignored + 1))
    echo "::warning file=$f::tracked & ignored"
  fi
done < <(git ls-files -z)

echo "[tracked & ignored count] $ignored"
if [[ "$ignored" -ne 0 ]]; then
  echo "::error::Des fichiers SUIVIS seraient ignorés par .gitignore"
  exit 1
fi

echo
echo "=== GUARD: build sdist (python -m build --sdist) ==="
python -m pip -q install --upgrade pip >/dev/null
python -m pip -q install build >/dev/null
python -m build --sdist

SDIST="$(ls -1t dist/*.tar.gz 2>/dev/null | head -1 || true)"
[[ -n "${SDIST:-}" ]] || { echo "::error::Aucun sdist produit"; exit 1; }
echo "[sdist] $SDIST"
export SDIST

echo
echo "=== Inspect sdist content ==="
python - <<'PY'
import os, re, sys, tarfile

sdist = os.environ.get("SDIST")
if not sdist:
    print("::error::SDIST env manquant (bug du script).")
    sys.exit(1)

deny = [
    r'(^|/)\.venv(/|$)', r'(^|/)\.venv[^/]*(/|$)',
    r'(^|/)venv(/|$)', r'(^|/)venv[^/]*(/|$)',
    r'(^|/)_tmp(/|$)', r'(^|/)assets/zz-figures(/|$)',
    r'(^|/)legacy-tex(/|$)',
    r'(^|/)\.pytest_cache(/|$)', r'(^|/)\.ruff_cache(/|$)', r'(^|/)\.mypy_cache(/|$)',
    r'(^|/)\.ipynb_checkpoints(/|$)',
    r'(^|/)_logs(/|$)',
    r'(^|/)dist(/|$)', r'(^|/)build(/|$)',
    r'\.(log|tmp|bak)(\.|$)',
    r'\.tar\.gz$', r'\.whl$',
]
deny_re = [re.compile(p, re.I) for p in deny]

bad = []
with tarfile.open(sdist, "r:gz") as tf:
    members = tf.getnames()
    for m in members:
        path = m.lower()
        if any(rx.search(path) for rx in deny_re):
            bad.append(m)

    print(f"[members] {len(members)} entries")
    print("sample:")
    for s in members[:15]:
        print("  -", s)

if bad:
    print("::error::Chemins indésirables détectés dans le sdist:")
    for b in bad[:80]:
        print("  -", b)
    if len(bad) > 80:
        print(f"  ... ({len(bad) - 80} autres)")
    sys.exit(1)

print("[OK] Aucun chemin indésirable dans le sdist.")
PY
EOF

chmod +x scripts/guard_ignore_and_sdist.sh
