#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP02] 0) (Re)lancer le smoke pour partir d'un état frais"
tools/pass14_smoke_with_mapping.sh

echo "[STEP02] 1) Extraire les fichiers encore en SyntaxError/IndentationError"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  if (r ~ /SyntaxError|IndentationError/) print $1
}' "$CSV" | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP02] 2) Correction robuste des virgules dans add_argument(...)"
$PYTHON - <<'PY'
import io, tokenize, pathlib

paths = pathlib.Path("zz-out/_parse_fail.lst").read_text(encoding="utf-8").splitlines()
targets = [p for p in sorted(set(paths)) if p and pathlib.Path(p).exists()]

def fix_file(p: pathlib.Path) -> bool:
    src = p.read_text(encoding="utf-8")
    lines = src.splitlines(True)
    text = "".join(lines)
    changed = False

    # Travail par fenêtre: on retrouve chaque "add_argument(" via tokens, on balance le compteur de ()
    # et on ajoute une virgule aux lignes "kw=..." qui n'en ont pas avant la fermeture ).
    off0 = 0
    while True:
        idx = text.find("add_argument(", off0)
        if idx < 0:
            break
        # repositionnement en coordonnées ligne/colonne via tokenize
        toks = list(tokenize.generate_tokens(io.StringIO(text[idx:]).readline))
        depth = 0
        opened = False
        # borne absolue dans le fichier (ligne d'origine)
        # convertit offset local->global en recalculant depuis début
        pre = text[:idx]
        base_line = pre.count("\n") + 1  # 1-indexed
        # trouver le bloc (...) correspondant
        close_line = None
        for tok in toks:
            t, v, (r, c), _, _ = tok
            if t == tokenize.OP and v == "(":
                depth += 1; opened = True
            elif t == tokenize.OP and v == ")":
                depth -= 1
                if opened and depth == 0:
                    close_line = base_line + r - 1
                    break
        if close_line is None:
            off0 = idx + 12
            continue

        open_line = None
        # retrouver la ligne d'ouverture exacte (première '(' après add_argument)
        depth = 0; opened = False
        for tok in toks:
            t, v, (r, c), _, _ = tok
            if t == tokenize.OP and v == "(":
                open_line = base_line + r - 1
                break

        if open_line is None:
            off0 = idx + 12
            continue

        # Parcourt des lignes internes (open_line..close_line inclus)
        for L in range(open_line+1, close_line+1):
            raw = lines[L-1]
            s = raw.rstrip("\n")
            st = s.strip()
            if not st or st.startswith("#"):
                continue
            # ignorer les lignes de fermeture ou déjà terminées par séparateur évident
            if st in (")", "])", "}),", "),") or st.endswith((",", ")", "}", "],")):
                continue
            # heuristique sûre: présence de '=' hors opérateurs de comparaison usuels
            # (les kwargs sont du type kw=expr, rarement '==' dans add_argument)
            if "=" in st and not any(op in st for op in ("==", ">=", "<=", "!=")):
                # éviter d’ajouter une virgule après un commentaire de fin de ligne
                if "#" in s:
                    code, _comment = s.split("#", 1)
                    code = code.rstrip()
                    if not code.endswith((",", ")", "}", "],")):
                        lines[L-1] = code + ",  #" + _comment.strip() + "\n"
                        changed = True
                else:
                    lines[L-1] = s + ",\n"
                    changed = True

        text = "".join(lines)
        off0 = idx + 12

    if changed:
        p.write_text("".join(lines), encoding="utf-8")
    return changed

changed_any = False
for path in targets:
    p = pathlib.Path(path)
    try:
        if fix_file(p):
            print(f"[FIX] add_argument commas -> {p}")
            changed_any = True
    except Exception as e:
        print(f"[WARN] skip {p}: {e}")

print(f"[RESULT] changed_any={changed_any}")
PY

echo "[STEP02] 3) Recompile ciblé"
while read -r f; do
  [ -f "$f" ] || continue
  python3 -m py_compile "$f" 2>/dev/null || echo "[PYCOMPILE] still failing: $f"
done < zz-out/_parse_fail.lst

echo "[STEP02] 4) Smoke + top erreurs"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
