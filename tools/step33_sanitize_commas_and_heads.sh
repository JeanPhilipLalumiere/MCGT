#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Rafraîchir le CSV + (re)générer la liste si absente
tools/pass14_smoke_with_mapping.sh >/dev/null || true
if [[ ! -f zz-out/_remaining_files.lst ]]; then
  tools/step32_report_remaining.sh >/dev/null || true
fi

python3 - <<'PY'
from pathlib import Path
import io, re, sys, tokenize, token

rem = Path("zz-out/_remaining_files.lst")
if not rem.exists():
    print("[step33] rien à faire (pas de liste)"); sys.exit(0)

files = [p for p in rem.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

# ---------------- Token-based sanitizer ----------------
def sanitize_tokens(src: str) -> str:
    out = []
    stack = []  # items: {'ch': '(', 'just_opened': bool}
    g = tokenize.generate_tokens(io.StringIO(src).readline)
    for tok in g:
        t, s, start, end, line = tok
        if t == token.OP and s in '([{':
            stack.append({'ch': s, 'just_opened': True})
            out.append(tok); continue
        if t == token.OP and s == ',':
            if stack and stack[-1]['just_opened']:
                # skip ',' immediately after an opening bracket
                continue
        if t == token.OP and s in ')]}':
            # drop trailing ',' right before a closer
            if out and out[-1].type == token.OP and out[-1].string == ',' and stack:
                out.pop()
            if stack: stack.pop()
            out.append(tok); continue
        # once we see a substantive token, the "just_opened" state ends
        if stack and t not in (tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT, tokenize.COMMENT):
            stack[-1]['just_opened'] = False
        out.append(tok)
    return tokenize.untokenize(out)

# ---------------- Regex fallback + global safe fixes ----------------
def sanitize_regex(s: str) -> str:
    s2 = s
    # 1) Retirer ',' juste après ouvrantes et juste avant fermantes (robuste)
    s2 = re.sub(r'(\(|\[|\{)\s*,\s*', r'\1', s2)
    s2 = re.sub(r'\s*,\s*(\)|\]|\})', r'\1', s2)

    # 2) Débuts de ligne avec ')' optionnellement '*' avant kwargs / clefs / littéraux → on retire
    s2 = re.sub(
        r'(?m)^(?P<indent>\s*)\)\*?\s*(?=(?:\w+\s*=|["\'].*["\']\s*:|[-+]?(?:\d+(?:\.\d*)?|\.\d+)|[rubfRUBF]?["\']))',
        r'\g<indent>', s2)

    # 3) parents[,N] → parents[N]
    s2 = re.sub(r'\bparents\s*\[\s*,\s*(\d+)\s*\]', r'parents[\1]', s2)

    # 4) __name__ === "__main__" → ==
    s2 = re.sub(r'(__name__\s*)===\s*(["\']__main__["\'])', r'\1== \2', s2)

    # 5) NAME , ()  → NAME()
    s2 = re.sub(r'([\w\.]+)\s*,\s*\(\s*\)', r'\1()', s2)

    # 6) NAME , (  → NAME(     (ex: str,(  → str()
    s2 = re.sub(r'([\w\.]+)\s*,\s*\(', r'\1(', s2)

    # 7) var , [idx] → var[idx] (ex: df_ref,[ "P_ref" ] → df_ref["P_ref"])
    s2 = re.sub(r'([)\]\w\.])\s*,\s*(\[)', r'\1\2', s2)

    return s2

def full_sanitize(src: str) -> str:
    # on tente la passe tokenisée ; si elle échoue, on garde l'original
    try:
        mid = sanitize_tokens(src)
    except tokenize.TokenError:
        mid = src
    # applique toujours les regex globales sûres
    return sanitize_regex(mid)

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    new = full_sanitize(src)
    if new != src:
        fp.write_text(new, encoding="utf-8")
        changed += 1
        print(f"[SANITIZE] {p}")

print(f"[RESULT] files_changed={changed}")
PY

# Petit rapport pour visualiser l'effet sur les premières erreurs restantes
tools/step32_report_remaining.sh | sed -n '1,160p' || true
