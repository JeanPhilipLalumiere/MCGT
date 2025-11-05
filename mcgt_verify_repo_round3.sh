#!/usr/bin/env bash
# Vérification repo-wide (Python byte-compile + bash -n + check __future__ placement)
# Sécurisé : n’abat jamais le terminal ; toujours exit 0 avec un résumé.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || true

TMP="$(mktemp -d -t mcgt_verify_repo_XXXXXX)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

printf ">>> VERIFY repo-wide (py byte-compile, sh syntax, future placement)\n"
printf "root: %s\n\n" "$ROOT"

# —---------------------------
# 1) Inventaires de fichiers
# —---------------------------
# Python (tracked + untracked), avec exclusions usuelles
PY_LIST="$TMP/py_files.txt"
{
  git ls-files '**/*.py'
  # Untracked raisonnables :
  find . -type f -name '*.py' \
    -not -path './.git/*' \
    -not -path './.ci-out/*' \
    -not -path './__pycache__/*' \
    -not -path './.tox/*' \
    -not -path './.mypy_cache/*' \
    -not -path './_attic_untracked/*' \
    -not -path './release_zenodo_codeonly/*' \
    -not -name '*.py.broken.*' \
    -not -name '*.bak' 2>/dev/null
} | sed 's#^\./##' | sort -u > "$PY_LIST"

# Shell scripts (tracked + untracked), avec exclusions similaires
SH_LIST="$TMP/sh_files.txt"
{
  git ls-files '**/*.sh'
  find . -type f -name '*.sh' \
    -not -path './.git/*' \
    -not -path './.ci-out/*' \
    -not -path './_attic_untracked/*' \
    -not -path './release_zenodo_codeonly/*' 2>/dev/null
} | sed 's#^\./##' | sort -u > "$SH_LIST"

# —---------------------------
# 2) Compile Python
# —---------------------------
PY_OK=0; PY_BAD=0
PY_ERRS="$TMP/py_errs.txt"
: > "$PY_ERRS"

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if python3 -m py_compile "$f" 2>>"$PY_ERRS"; then
    ((PY_OK++))
  else
    ((PY_BAD++))
    printf "[PY-ERR] %s\n" "$f"
  fi
done < "$PY_LIST"

# —---------------------------
# 3) Vérif bash -n
# —---------------------------
SH_OK=0; SH_BAD=0
SH_ERRS="$TMP/sh_errs.txt"
: > "$SH_ERRS"

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if bash -n "$f" 2>>"$SH_ERRS"; then
    ((SH_OK++))
  else
    ((SH_BAD++))
    printf "[SH-ERR] %s\n" "$f"
  fi
done < "$SH_LIST"

# —---------------------------
# 4) Check placement __future__
#    (aucun code/importe « normal » avant from __future__)
# —---------------------------
FUT_OK=0; FUT_BAD=0
FUT_REPORT="$TMP/future_report.txt"
python3 - "$PY_LIST" "$FUT_REPORT" <<'PY'
import sys, ast, io, tokenize, token
from pathlib import Path

def first_significant_offset(src:str):
    # Skip BOM, shebang, encoding, blank, comments, module docstring
    # Return index of first significant stmt (in lines index)
    g = tokenize.generate_tokens(io.StringIO(src).readline)
    encoding_seen = False
    first_tok = None
    for tok in g:
        if tok.type == token.NL or tok.type == token.NEWLINE:
            continue
        if tok.type == token.ENCODING:
            encoding_seen = True
            continue
        if tok.type == token.COMMENT:
            continue
        first_tok = tok
        break
    # Special-case: module docstring (first stmt is a STRING)
    try:
        mod = ast.parse(src)
    except SyntaxError:
        return 0  # parse fail handled elsewhere by py_compile
    if mod.body and isinstance(mod.body[0], ast.Expr) and isinstance(getattr(mod.body[0], 'value', None), ast.Str):
        # position right after docstring node
        return mod.body[0].lineno
    return first_tok.start[0]-1 if first_tok else 0

def has_future_violation(src:str) -> bool:
    # True if there's a from __future__ import * that appears AFTER a significant stmt/import
    lines = src.splitlines()
    sig_line = first_significant_offset(src)  # 0-based approx
    seen_future = False
    past_future_zone = False
    for i, line in enumerate(lines):
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        if s.startswith('"""') or s.startswith("'''"):
            # naive skip of block docstring (we accept parse-based check above already)
            pass
        if s.startswith('from __future__ import '):
            seen_future = True
            if past_future_zone:
                # future found after normal code/imports → violation
                return True
            continue
        # If we met any non-future, non-comment, non-empty BEFORE any future → violation
        if not seen_future and i > sig_line:
            # allow encoding/shebang/docstring up to sig_line
            if not s.startswith('from __future__ import '):
                return True
        # If we already saw future and this line is "normal", future zone ends
        if seen_future and not s.startswith('from __future__ import '):
            past_future_zone = True
    return False

py_list = Path(sys.argv[1]).read_text(encoding='utf-8').splitlines()
report = Path(sys.argv[2])
bad = []
for rel in py_list:
    p = Path(rel)
    try:
        src = p.read_text(encoding='utf-8')
    except Exception:
        # unreadable; rely on py_compile failure
        continue
    if 'from __future__ import ' in src and has_future_violation(src):
        bad.append(rel)

report.write_text('\n'.join(bad), encoding='utf-8')
print(f"[future-check] bad={len(bad)}")
PY

FUT_BAD=$(wc -l < "$FUT_REPORT" | awk '{print $1}')
if [[ "$FUT_BAD" =~ ^[0-9]+$ ]]; then :; else FUT_BAD=0; fi
FUT_OK=$(( $(wc -l < "$PY_LIST") - FUT_BAD ))

# —---------------------------
# 5) Résumé
# —---------------------------
echo
echo "=== SUMMARY ==="
printf "PY OK=%d  BAD=%d\n" "$PY_OK" "$PY_BAD"
printf "SH OK=%d  BAD=%d\n" "$SH_OK" "$SH_BAD"
printf "__future__ placement: OK=%d  BAD=%d\n" "$FUT_OK" "$FUT_BAD"

if (( PY_BAD > 0 )); then
  echo
  echo "--- Python compile errors (tail) ---"
  tail -n 50 "$PY_ERRS"
fi

if (( SH_BAD > 0 )); then
  echo
  echo "--- Shell syntax errors (tail) ---"
  tail -n 50 "$SH_ERRS"
fi

if (( FUT_BAD > 0 )); then
  echo
  echo "--- Files with suspicious __future__ placement ---"
  cat "$FUT_REPORT"
fi

echo
echo "✅ Script terminé (sans fermer la session). Code de sortie forcé à 0."
exit 0
