#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP11] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP11] 1) Cibler les fichiers avec 'unmatched' ou 'invalid decimal literal'"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError: unmatched/ || r ~ /invalid decimal literal/) print $1
}' "$CSV" | sort -u > zz-out/_step11_targets.lst || true
wc -l zz-out/_step11_targets.lst

echo "[STEP11] 2) Prune global des closers )]} (partout dans la ligne, hors chaînes/commentaires) + normalisation décimaux"
python3 - <<'PY'
from pathlib import Path
import unicodedata, re

targets = Path("zz-out/_step11_targets.lst").read_text(encoding="utf-8").splitlines()
targets = [t for t in sorted(set(targets)) if t and Path(t).exists()]

def fix_text(txt: str) -> tuple[str,bool]:
    orig = txt
    # --- Normalisation Unicode (décimaux & ponctuation) ---
    txt = unicodedata.normalize("NFKC", txt)
    txt = (txt
        .replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")  # minus / tirets
        .replace("\u00A0","").replace("\u202F","").replace("\u2009","")    # espaces fines/insécables
        .replace("\u066B",".").replace("\u066C","")                        # décimale/arabe millier
        .replace("\uFF0E",".").replace("\uFF0C","")                        # fullwidth . ,
        .replace("\u00B7",".")                                             # middle dot
    )

    # --- Prune des closers unmatched partout (en ignorant chaînes/commentaires) ---
    out_lines = []
    par, brk, brc = 0, 0, 0  # () [] {}
    for line in txt.splitlines(True):
        i, n = 0, len(line)
        out = []
        in_str = False
        q = ""           # quote char: ' or "
        triple = False
        while i < n:
            ch = line[i]

            # Début commentaire (hors chaîne) -> recopier le reste tel quel
            if not in_str and ch == "#":
                out.append(line[i:]); i = n; break

            # Gestion chaînes
            if in_str:
                out.append(ch)
                # échappement
                if ch == "\\":
                    if i+1 < n:
                        out.append(line[i+1]); i += 2; continue
                # fin chaîne
                if triple:
                    if i+2 < n and line[i:i+3] == q*3:
                        out[-1] = q  # remplace dernier ch par q pour garder les 3 q ci-dessous
                        out.append(q); out.append(q)
                        i += 3; in_str=False; triple=False; q=""
                        continue
                else:
                    if ch == q:
                        in_str=False; q=""
                        i += 1; continue
                i += 1; continue

            # Pas en chaîne : détecter ouverture chaîne
            if ch in ("'", '"'):
                if i+2 < n and line[i:i+3] == ch*3:
                    in_str=True; q=ch; triple=True
                    out.append(ch); out.append(ch); out.append(ch); i += 3; continue
                else:
                    in_str=True; q=ch; triple=False
                    out.append(ch); i += 1; continue

            # Compteurs de structure
            if ch == "(":
                par += 1; out.append(ch); i += 1; continue
            if ch == "[":
                brk += 1; out.append(ch); i += 1; continue
            if ch == "{":
                brc += 1; out.append(ch); i += 1; continue

            if ch == ")":
                if par > 0:
                    par -= 1; out.append(ch)
                # sinon: drop
                i += 1; continue
            if ch == "]":
                if brk > 0:
                    brk -= 1; out.append(ch)
                i += 1; continue
            if ch == "}":
                if brc > 0:
                    brc -= 1; out.append(ch)
                i += 1; continue

            # Autres caractères
            out.append(ch); i += 1

        out_lines.append("".join(out))

    txt = "".join(out_lines)

    # --- Décimaux: motif chiffre .. chiffre -> chiffre . chiffre ---
    txt = re.sub(r'(\d)\s*\.\s*\.(\d)', r'\1.\2', txt)

    # (Optionnel, prudent) motif  . .  autour d’un chiffre/exp -> une seule .
    txt = re.sub(r'(\d)\s*\.\s*\.(?!\.)', r'\1.', txt)

    return txt, (txt != orig)

changed_any = False
for t in targets:
    p = Path(t)
    try:
        raw = p.read_text(encoding="utf-8", errors="ignore")
        fixed, changed = fix_text(raw)
        if changed:
            p.write_text(fixed, encoding="utf-8")
            print(f"[PRUNE*] {t}")
            changed_any = True
    except Exception as e:
        print(f"[WARN] {t}: {e}")

print(f"[RESULT] step11_changed={changed_any}")
PY

echo "[STEP11] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
