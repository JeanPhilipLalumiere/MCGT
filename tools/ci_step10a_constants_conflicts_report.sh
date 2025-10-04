#!/usr/bin/env bash
set -euo pipefail

REPORT=".ci-out/py_constants_conflicts_report.txt"
TSV=".ci-out/py_constants_conflicts.tsv"
SNIPS_DIR=".ci-out/py_constants_snippets"
REG="zz-configuration/python_constants_registry.json"
STRICT="${STRICT:-0}" # mettre STRICT=1 pour faire échouer si conflits

: >"$REPORT"
: >"$TSV"
mkdir -p "$SNIPS_DIR"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

[[ -f "$REG" ]] || {
  err "Registre introuvable: $REG — lance d'abord ci_step10_python_constants_guard."
  exit 2
}

log "Analyse des conflits dans $REG"
python - <<'PY' >"$TSV"
import json, pathlib, sys, textwrap, os

REG = pathlib.Path("zz-configuration/python_constants_registry.json")
data = json.loads(REG.read_text(encoding="utf-8"))

conflicts = data.get("issues",{}).get("conflicts",[])
print("name\tvalue_type\tvalue_repr\tmodule\tpath\tlineno")

for c in conflicts:
    name = c["name"]
    # map occurrence -> printable row
    for occ in c["occurrences"]:
        vt = occ.get("value_type","unknown")
        if occ.get("is_literal"):
            val = occ.get("value")
        else:
            val = occ.get("expr")
        # compact repr (single-line)
        if isinstance(val, (list, dict)):
            import json as _json
            val_repr = _json.dumps(val, ensure_ascii=False, sort_keys=True)
        else:
            val_repr = repr(val) if not isinstance(val, (int,float,bool,str)) and val is not None else str(val)
        print("\t".join([
            name,
            vt,
            val_repr.replace("\n","⏎"),
            occ.get("module",""),
            occ.get("path",""),
            str(occ.get("lineno","")),
        ]))
PY

CONFLICTS_COUNT=$(awk 'END{print NR-1}' "$TSV")
log "Conflits détectés: $CONFLICTS_COUNT (détails TSV: $TSV)"

# Génère un rapport lisible + extraits de code autour des lignes concernées
{
  echo "==== PY CONSTANTS CONFLICTS REPORT ===="
  echo "TSV: $TSV"
  echo
  if [[ $CONFLICTS_COUNT -le 0 ]]; then
    echo "AUCUN CONFLIT."
  else
    echo "Conflits trouvés:"
    echo
    # Regroupe par nom de constante
    cut -f1 "$TSV" | tail -n +2 | sort | uniq | while read -r const; do
      echo "---- CONST: ${const} ----"
      # variantes uniques
      awk -v c="$const" -F'\t' 'NR>1 && $1==c {print $3}' "$TSV" | sort | uniq -c | sed 's/^/    /'
      echo "  Occurrences:"
      awk -v c="$const" -F'\t' 'NR>1 && $1==c {printf "    - %s (%s:%s)\n", $4, $5, $6}' "$TSV"
      echo

      # extrait de code pour chaque occurrence (3 lignes de contexte)
      awk -v c="$const" -F'\t' 'NR>1 && $1==c {print $5"\t"$6}' "$TSV" |
        while IFS=$'\t' read -r path lineno; do
          [[ -f "$path" ]] || continue
          start=$((lineno > 1 ? lineno - 1 : 1))
          end=$((lineno + 1))
          snip="$SNIPS_DIR/${const}__$(echo "$path" | tr '/.' '__')__${lineno}.txt"
          nl -ba -w3 -s'  ' "$path" | sed -n "${start},${end}p" >"$snip"
          echo "    >>> $snip"
        done
      echo
    done
    echo
    echo "NOTE: utilise STRICT=1 pour échouer le job si des conflits persistent."
  fi
} | tee -a "$REPORT"

if [[ $STRICT -eq 1 && $CONFLICTS_COUNT -gt 0 ]]; then
  err "Conflits présents et STRICT=1 — échec."
  exit 1
fi

log "OK — Rapport: $REPORT ; extraits: $SNIPS_DIR/"
