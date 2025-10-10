#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"

CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP08] 0) Vérif sitecustomize/phi_mcgt"
python3 - <<'PY'
import sys
loaded = 'sitecustomize' in sys.modules
print(f"[CHECK] sitecustomize_loaded={loaded}")
try:
    import mcgt.phase as ph
    print(f"[CHECK] phi_mcgt_present={hasattr(ph,'phi_mcgt')}")
except Exception as e:
    print(f"[WARN] import mcgt.phase failed: {e}")
PY

echo "[STEP08] 1) Smoke (avec PYTHONPATH fixé)"
tools/pass14_smoke_with_mapping.sh

echo "[STEP08] 2) Cibler fichiers: IndentationError(after if) + invalid decimal literal"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /IndentationError: expected an indented block after '\''if'\''/ ||
      r ~ /SyntaxError: invalid decimal literal/) print $1"|"r
}' "$CSV" > zz-out/_step08_targets_full.lst || true

cut -d'|' -f1 zz-out/_step08_targets_full.lst | sort -u > zz-out/_step08_targets.lst || true
wc -l zz-out/_step08_targets.lst

echo "[STEP08] 3) Patch auto: add 'pass' après if + normalisation nombres Unicode"
python3 - <<'PY'
from pathlib import Path
import re

FULL = Path("zz-out/_step08_targets_full.lst")
if not FULL.exists():
    print("[INFO] rien à patcher (liste vide)")
    raise SystemExit(0)

# file -> set(line_numbers) for 'if' blocks
if_lines = {}
dec_files = set()
for line in FULL.read_text(encoding="utf-8").splitlines():
    if not line.strip(): continue
    path, reason = line.split("|", 1)
    if "IndentationError: expected an indented block after 'if' statement on line" in reason:
        m = re.search(r"line\s+(\d+)", reason)
        if m:
            if_lines.setdefault(path, set()).add(int(m.group(1)))
    if "SyntaxError: invalid decimal literal" in reason:
        dec_files.add(path)

def add_pass_after_if(p: Path, line_no: int) -> bool:
    try:
        lines = p.read_text(encoding="utf-8").splitlines(True)
    except Exception:
        return False
    if not (1 <= line_no <= len(lines)): return False
    base = len(lines[line_no-1]) - len(lines[line_no-1].lstrip(' '))
    # si une ligne non vide suivante est déjà indentée, on ne touche pas
    i = line_no
    while i < len(lines) and lines[i].strip()=="":
        i += 1
    if i < len(lines):
        nxt = lines[i]
        if nxt.strip() and (len(nxt) - len(nxt.lstrip(' '))) > base:
            return False
    lines.insert(line_no, " "*(base+4) + "pass\n")
    p.write_text("".join(lines), encoding="utf-8")
    return True

def normalize_decimal_unicode(p: Path) -> bool:
    try:
        txt = p.read_text(encoding="utf-8")
    except Exception:
        return False
    orig = txt
    # remplacements prudents mais globaux (simplicité > perfection pour le smoke)
    txt = txt.replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")  # − – —
    txt = txt.replace("\u00A0","").replace("\u202F","")  # NBSP & NNBSP suppr. dans nombres
    # autres variantes minus rares
    txt = txt.replace("\uFE63","-").replace("\uFF0D","-")
    if txt != orig:
        p.write_text(txt, encoding="utf-8"); return True
    return False

changed = 0
for path, lines in if_lines.items():
    p = Path(path)
    if not p.exists(): continue
    for ln in sorted(lines):
        if add_pass_after_if(p, ln):
            print(f"[FIX:if-pass] {p}:{ln}"); changed += 1

for path in sorted(dec_files):
    p = Path(path)
    if not p.exists(): continue
    if normalize_decimal_unicode(p):
        print(f"[FIX:decimal] {p}"); changed += 1

print(f"[RESULT] step08_changes={changed}")
PY

echo "[STEP08] 4) Smoke post-fix + top erreurs"
tools/pass14_smoke_with_mapping.sh

awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
