#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP10] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP10] 1) Cibler les fichiers avec 'unmatched')' ou 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: unmatched \047\)\047/ || r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step10_targets.lst || true
wc -l zz-out/_step10_targets.lst

echo "[STEP10] 2) Prune des ')' surnuméraires (début de ligne) + normalisation Unicode NFKC & séparateurs décimaux"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, unicodedata, re

targets = Path("zz-out/_step10_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

def strip_str_comm(line:str)->str:
    # retire chaînes/commentaires (approx) pour compter les () sans faux positifs
    s = re.sub(r"#.*$", "", line)
    s = re.sub(r'(?s)"""[^"]*"""|\'\'\'[^\']*\'\'\'|"[^"\\]*(?:\\.[^"\\]*)*"|\'[^\'\\]*(?:\\.[^\'\\]*)*\'', "", s)
    return s

def prune_file(p: Path) -> bool:
    raw = p.read_text(encoding="utf-8", errors="ignore")
    # NFKC pour normaliser chiffres/ponctuation pleine largeur, etc.
    txt = unicodedata.normalize("NFKC", raw)
    # Remplacements décimaux/espaces durs/points exotiques
    txt = (txt
        .replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
        .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
        .replace("\u066B",".").replace("\u066C","")   # Arabic decimal/thousand
        .replace("\uFF0E",".").replace("\uFF0C","")   # fullwidth period/comma
        .replace("\u00B7",".")                        # middle dot
    )
    lines = txt.splitlines(True)

    changed = (txt != raw)
    depth = 0
    for i, line in enumerate(lines):
        # détecter run initial de ')'
        m = re.match(r'^([ \t]*)(\)+)(.*)$', line)
        if m:
            lead, run, rest = m.groups()
            keep = min(len(run), depth)  # on ne garde que ce qui clôture des '(' en attente
            if keep < len(run):
                lines[i] = lead + (")"*keep) + rest
                changed = True
        # mettre à jour le depth avec la ligne (sans strings/commentaires)
        s = strip_str_comm(lines[i])
        for ch in s:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth = max(depth-1, 0)

    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

changed_any = False
for t in targets:
    try:
        if prune_file(Path(t)):
            print(f"[PRUNE+] {t}")
            changed_any = True
    except Exception as e:
        print(f"[WARN] {t}: {e}")

print(f"[RESULT] step10_changed={changed_any}")
PY

echo "[STEP10] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
