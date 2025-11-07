#!/usr/bin/env bash
set -euo pipefail

PYTHON="${PYTHON:-python3}"
CSV="zz-out/homog_smoke_pass14.csv"
LOG="zz-out/homog_smoke_pass14.log"

echo "[STEP01] 1) Patch V3 (idempotent)"
$PYTHON tools/patch_pass14_known_issues.py --csv "$CSV" || true

echo "[STEP01] 2) Smoke"
tools/pass14_smoke_with_mapping.sh

echo "[STEP01] 3) Extraire les fichiers en SyntaxError/IndentationError"
# Reconstruire 'reason' (3e col jusqu'à l'avant-avant-dernière, car il y a des virgules dans les messages)
awk -F, 'NR>1{
  n=NF; reason=$3; for(i=4;i<=n-3;i++) reason=reason","$i;
  if (reason ~ /SyntaxError|IndentationError/) print $1"|"reason
}' "$CSV" > zz-out/_parse_fail_full.lst || true

cut -d'|' -f1 zz-out/_parse_fail_full.lst | sort -u > zz-out/_parse_fail.lst || true
wc -l zz-out/_parse_fail.lst

echo "[STEP01] 4) Fix auto des virgules manquantes dans add_argument(...) (si détecté par Python)"
$PYTHON - <<'PY'
import io, re, sys, tokenize, pathlib

fails = pathlib.Path("zz-out/_parse_fail_full.lst").read_text(encoding="utf-8").splitlines()
targets = []
for row in fails:
    try:
        path, reason = row.split("|", 1)
    except ValueError:
        continue
    if "Perhaps you forgot a comma?" in reason and "add_argument" in reason:
        targets.append(path)

targets = sorted(set(t for t in targets if t))
print(f"[AUTO-FIX] Candidats add_argument (perhaps you forgot a comma?): {len(targets)}")
for p in targets:
    P = pathlib.Path(p)
    if not P.exists():
        continue
    src = P.read_text(encoding="utf-8")
    lines = src.splitlines(True)

    # Cherche des blocs add_argument( ... ) et vérifie les lignes de kwargs
    out = lines[:]
    changed = False

    i = 0
    while i < len(out):
        line = out[i]
        if "add_argument(" not in line:
            i += 1
            continue
        # position de l'appel
        open_line_idx = i
        base_indent = len(out[i]) - len(out[i].lstrip(" \t"))
        # balayer jusqu'à fermeture en tenant un compteur de parenthèses (en ignorant les chaînes/commentaires)
        text = "".join(out[open_line_idx:])
        try:
            toks = list(tokenize.generate_tokens(io.StringIO(text).readline))
        except tokenize.TokenError:
            # fichier globalement cassé — on laisse à la passe suivante
            i += 1
            continue
        depth = 0
        start_abs = open_line_idx
        end_abs = None
        hit_open = False
        # retrouver la première '(' après 'add_argument'
        after_add = False
        for tok in toks:
            typ, val, (r, c), _, _ = tok
            abs_r = start_abs + r - 1
            if abs_r == open_line_idx and "add_argument" in out[open_line_idx]:
                after_add = True
            if not after_add:
                continue
            if typ == tokenize.OP and val == "(":
                depth += 1; hit_open = True
            elif typ == tokenize.OP and val == ")":
                depth -= 1
                if hit_open and depth == 0:
                    end_abs = abs_r
                    break
        if end_abs is None:
            # pas de fermeture claire — laisser à la passe patch V3
            i += 1
            continue

        # Dans (open_line_idx .. end_abs), si une ligne ressemble à "kw=val" et ne finit pas par "," ou ")" ou "}" → ajouter une virgule
        for j in range(open_line_idx+1, end_abs+1):
            L = out[j].rstrip("\n")
            stripped = L.strip()
            if not stripped or stripped.startswith("#"):
                continue
            # ignorer lignes de fermeture
            if stripped in (")", "])", "}),", "),"):
                continue
            # heuristique "kw = expr" pas terminé par virgule
            if "=" in stripped and not stripped.endswith(",") and not stripped.endswith(")") and not stripped.endswith("}") and not stripped.endswith("],"):
                out[j] = L + ",\n"
                changed = True

        if changed:
            P.write_text("".join(out), encoding="utf-8")
        i = end_abs + 1

    if changed:
        print(f"[AUTO-FIX] Virgules ajoutées : {p}")
PY

echo "[STEP01] 5) Recompile ciblé pour visualiser les restes"
while read -r f; do
  [ -f "$f" ] || continue
  echo "----- $f"
  python3 -m py_compile "$f" 2>&1 | sed 's/^/    /' || true
done < zz-out/_parse_fail.lst

echo "[STEP01] 6) Smoke (post-fix) + résumé"
tools/pass14_smoke_with_mapping.sh
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25
