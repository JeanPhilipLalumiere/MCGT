#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}:$PWD"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP09] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP09] 1) Cibler uniquement les SyntaxError/IndentationError"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP09] 2) Closer générique des appels ouverts + normalisation décimaux (prudente)"
python3 - <<'PY'
from pathlib import Path
import io, tokenize, re

fail_paths = Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(fail_paths)) if p and Path(p).exists()]

def indent(s:str)->int:
    return len(s) - len(s.lstrip(' \t'))

def normalize_decimals(txt:str)->str:
    # Hyphens/espaces étranges -> ASCII
    txt2 = (txt
        .replace("\u2212","-").replace("\u2013","-").replace("\u2014","-")
        .replace("\uFE63","-").replace("\uFF0D","-")
        .replace("\u00A0","").replace("\u202F","")
    )
    return txt2

def closer_once(text:str)->tuple[str,bool,int]:
    """
    Ferme les appels NAME '(' ou '.' NAME '(' restés ouverts jusqu'à une dé-dente.
    - Ignore strings/commentaires via tokenize
    - Stratégie: insérer ')' au début de la première ligne dont l'indentation
      redevient <= indent de la ligne d'ouverture (ou EOF).
    Retour: (new_text, changed?, nb_insertions)
    """
    lines = text.splitlines(True)
    src = "".join(lines)

    try:
        toks = list(tokenize.generate_tokens(io.StringIO(src).readline))
    except tokenize.TokenError:
        # Même si le tokenizing échoue (EOF prématurée), on tente quand même avec une passe heuristique
        toks = []

    # Pile d'ouvertures "(" localisées au contexte "appel"
    # Élément: (open_line_idx0, base_indent)
    call_opens = []

    # On détecte motif: [NAME| (DOT NAME)] + '('  => ouverture d'appel
    prev = None
    prev2 = None
    for tok in toks:
        ttype, tval, (r,c), _, _ = tok
        if ttype == tokenize.OP and tval == "(":
            # est-ce un appel ? (juste après NAME ou après DOT NAME)
            is_call = False
            if prev and prev.type == tokenize.NAME:
                is_call = True
            elif prev and prev.type == tokenize.OP and prev.string == ")" and prev2 and prev2.type==tokenize.NAME:
                # cas style fonction retournée (...)(
                is_call = True
            elif prev and prev.type == tokenize.NAME and prev2 and prev2.type == tokenize.OP and prev2.string==".":
                # obj . method (
                is_call = True

            if is_call:
                base_ind = indent(lines[r-1])
                call_opens.append( (r-1, base_ind) )
        elif ttype in (tokenize.NEWLINE, tokenize.NL):
            pass
        prev2, prev = prev, tok

    # Fermer chaque ouverture qui n'a pas de fermeture correspondante avant dé-dente
    # Pour ça, on recompte localement les paires () ligne par ligne à partir de open_line.
    inserted = 0
    changed = False
    for (open_idx0, base_ind) in call_opens:
        # Recompte naive des () à partir de open jusqu'à fin pour savoir si non fermé
        depth = 0
        still_open = False
        for i in range(open_idx0, len(lines)):
            line = lines[i]
            # Compter "(" et ")" hors chaînes/commentaires -> on fait simple: retire strings/comm via regex light
            # (ok ici car on ne s'en sert que pour savoir si on ferme du call)
            s = line
            s = re.sub(r"#.*$", "", s)
            s = re.sub(r"(?s)'''[^']*'''|\"\"\"[^\"]*\"\"\"|'[^'\\]*(?:\\.[^'\\]*)*'|\"[^\"\\]*(?:\\.[^\"\\]*)*\"", "", s)
            for ch in s:
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    if depth>0: depth -= 1
            if i > open_idx0 and indent(line) <= base_ind:
                # On a dé-denté à un niveau <= base: si depth>0 alors l'appel est resté ouvert.
                if depth > 0:
                    lines[i] = ")" * depth + line
                    inserted += depth
                    changed = True
                break
        else:
            # Pas de dé-dente: fermer en fin de fichier si encore ouvert
            if depth > 0:
                lines.append(")" * depth + "\n")
                inserted += depth
                changed = True

    new_text = "".join(lines)
    return new_text, changed, inserted

total_changed = 0
total_inserted = 0
for p in targets:
    path = Path(p)
    try:
        txt = path.read_text(encoding="utf-8")
    except Exception:
        continue
    orig = txt
    txt = normalize_decimals(txt)
    new, ch, ins = closer_once(txt)
    if ch or txt != orig:
        path.write_text(new, encoding="utf-8")
        total_changed += 1
        total_inserted += ins
        print(f"[CLOSE+] {path} (inserted={ins}{', +dec' if txt!=orig else ''})")

print(f"[RESULT] files_changed={total_changed} total_parens_inserted={total_inserted}")
PY

echo "[STEP09] 3) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
