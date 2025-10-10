#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP12] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP12] 1) Cibler 'invalid syntax' et 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: invalid syntax/ || r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step12_targets.lst || true
wc -l zz-out/_step12_targets.lst

echo "[STEP12] 2) Correctifs prudents: ':' manquants sur lignes de contrôle + décimaux/underscores"
python3 - <<'PY'
from pathlib import Path
import re, unicodedata

targets = Path("zz-out/_step12_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

CTRL_HEAD = re.compile(
    r'^\s*(if|elif|else|for|while|try|except(?:\s+[^:]+)?|finally|def\s+\w+\s*\(.*\)|class\s+\w+(?:\s*\(.*\))?)\s*(#.*)?$'
)

def needs_colon(lines, i):
    line = lines[i]
    # ignorer si ':' déjà avant le '#'
    code = line.split('#',1)[0]
    if ':' in code: return False
    # vérifier que la ligne suivante existe et est plus indentée
    if i+1 >= len(lines): return False
    cur = len(line) - len(line.lstrip(' '))
    nxt = len(lines[i+1]) - len(lines[i+1].lstrip(' '))
    return nxt > cur

def fix_numbers(text: str) -> str:
    s = unicodedata.normalize("NFKC", text)
    # 1) normalisation unicode ponctuation décimale
    s = (s
         .replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
         .replace("\u00A0","").replace("\u202F","").replace("\u2009","")
         .replace("\u066B",".").replace("\u066C","")
         .replace("\uFF0E",".").replace("\uFF0C","")
         .replace("\u00B7",".")
    )
    # 2) double point 1..2 -> 1.2
    s = re.sub(r'(\d)\s*\.\s*\.(\d)', r'\1.\2', s)
    # 3) underscores : 1__2 -> 1_2
    s = re.sub(r'(?<=\d)_{2,}(?=\d)', '_', s)
    # 4) 1_.2 -> 1.2 ; 1._2 -> 1.2
    s = re.sub(r'(?<=\d)_(?=\.)', '', s)
    s = re.sub(r'(?<=\.)_(?=\d)', '', s)
    # 5) nombres « collés » à des lettres grecques communes (π, µ) : insérer * explicite
    s = re.sub(r'(\d)([πµ])', r'\1*\2', s)
    return s

def fix_file(p: Path) -> bool:
    raw = p.read_text(encoding='utf-8', errors='ignore')
    text = fix_numbers(raw)
    lines = text.splitlines(True)
    changed = False

    # Ajouter ':' sur têtes de blocs si la prochaine ligne est indentée
    for i in range(len(lines)):
        line = lines[i]
        if CTRL_HEAD.match(line) and needs_colon(lines, i):
            # ajouter ':' juste avant un éventuel commentaire
            if '#' in line:
                code, comment = line.split('#',1)
                code = code.rstrip() + ':\t'
                lines[i] = code + '#' + comment
            else:
                lines[i] = line.rstrip() + ':\n'
            changed = True

    new_text = ''.join(lines)
    if new_text != raw:
        p.write_text(new_text, encoding='utf-8')
        return True
    return False

changed_any = False
for t in targets:
    try:
        if fix_file(Path(t)):
            print(f"[FIX*] {t}")
            changed_any = True
    except Exception as e:
        print(f"[WARN] {t}: {e}")

print(f"[RESULT] step12_changed={changed_any}")
PY

echo "[STEP12] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
