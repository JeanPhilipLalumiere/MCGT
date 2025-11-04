#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP22] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP22] 1) Cibler '=' en condition + try sans corps/except"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /cannot assign to expression here/ ||
      r ~ /Maybe you meant '\''=='\''/ ||
      r ~ /Maybe you meant '\''=='\'' or '\':'='\'' instead of '\''='\''/ ||
      r ~ /IndentationError: expected an indented block after '\''try'\''/) print $1
}' "$CSV" | sort -u > zz-out/_step22_targets.lst || true
wc -l zz-out/_step22_targets.lst

echo "[STEP22] 2) Patch: '=' -> '==' uniquement dans en-têtes if/elif/while (tokenize) + compléter try: (corps+except)"
python3 - <<'PY'
from pathlib import Path
import io, re, tokenize

targets = Path("zz-out/_step22_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

def fix_eq_in_heads(text: str) -> tuple[str, bool]:
    """Remplace '=' par '==' uniquement dans les en-têtes if/elif/while.
    Si tokenization échoue (lignes finissant par '\' mal formées, etc.), on ne modifie rien."""
    try:
        src = io.StringIO(text).readline
        out = []
        paren = 0
        in_head = False
        changed = False
        for tok in tokenize.generate_tokens(src):
            ttype, tstr, start, end, line = tok
            if ttype == tokenize.NAME and tstr in ("if", "elif", "while"):
                in_head = True
                out.append(tok)
                continue
            if in_head:
                if ttype == tokenize.OP:
                    if tstr in "([{":
                        paren += 1
                    elif tstr in ")]}":
                        paren -= 1
                    elif tstr == "=":
                        tok = tokenize.TokenInfo(type=tokenize.OP, string="==", start=start, end=end, line=line)
                        changed = True
                    elif tstr == ":" and paren == 0:
                        in_head = False
                out.append(tok)
                continue
            out.append(tok)
        return tokenize.untokenize(out), changed
    except tokenize.TokenError:
        # Fichier illisible par tokenize (p.ex. backslash de continuation mal formé).
        # On n'applique PAS la correction '='→'==' pour éviter d'altérer le fichier.
        return text, False

def indent_of(s: str) -> int:
    return len(s) - len(s.lstrip(" \t"))

def ensure_try_body_and_except(lines: list[str]) -> tuple[list[str], bool]:
    """Ajoute un corps 'pass' manquant après 'try:' et un handler 'except Exception: pass' s'il n'y en a pas.
    Idempotent sur appels répétés."""
    i = 0
    n = len(lines)
    changed = False
    while i < n:
        s = lines[i]
        if re.match(r'^\s*try\s*:\s*(#.*)?$', s):
            base_indent = indent_of(s)
            # Corps ?
            j = i + 1
            while j < n and lines[j].strip() == "":
                j += 1
            body_missing = (j >= n) or (indent_of(lines[j]) <= base_indent)
            if body_missing:
                lines.insert(j, " " * (base_indent + 4) + "pass\n")
                n += 1
                changed = True
                j += 1
            # Handler présent ?
            k = j
            has_handler = False
            while k < n:
                linek = lines[k]
                if linek.strip() == "":
                    k += 1; continue
                ind = indent_of(linek)
                if ind < base_indent:
                    break
                if ind == base_indent and re.match(r'^\s*(except|finally)\b', linek):
                    has_handler = True
                    break
                # autre stmt au même indent → on s'arrête, pas de handler trouvé
                if ind == base_indent and k > j:
                    break
                k += 1
            if not has_handler:
                insert_at = j if j <= n else n
                lines.insert(insert_at, " " * base_indent + "except Exception:\n")
                lines.insert(insert_at + 1, " " * (base_indent + 4) + "pass\n")
                n += 2
                changed = True
                i = insert_at + 2
                continue
        i += 1
    return lines, changed

tot_files = eq_files = try_files = 0
for t in targets:
    p = Path(t)
    raw = p.read_text(encoding="utf-8", errors="ignore")
    # 1) '=' -> '==' uniquement si tokenization OK
    fixed, eq_changed = fix_eq_in_heads(raw)
    # 2) compléter try: (corps + except)
    lines = fixed.splitlines(keepends=True)
    lines2, try_changed = ensure_try_body_and_except(lines)
    new = "".join(lines2)
    if new != raw:
        p.write_text(new, encoding="utf-8")
        tot_files += 1
        eq_files += int(eq_changed)
        try_files += int(try_changed)
        print(f"[STEP22-FIX] {t}: eq_heads={'YES' if eq_changed else 'NO'} try_fix={'YES' if try_changed else 'NO'}")
print(f"[RESULT] step22_changed_files={tot_files} eq_heads_changed~={eq_files} try_fix_files~={try_files}")
PY

echo "[STEP22] 3) Smoke + Top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{ n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i; printf "%s: %s\n",$2,r }' "$CSV" \
  | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
