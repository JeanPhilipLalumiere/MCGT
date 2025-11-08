#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

FILE=".github/workflows/sanity-main.yml"
test -f "$FILE" || {
  echo "[ERREUR] Fichier introuvable: $FILE" >&2
  exit 1
}

TS="$(date +%Y%m%dT%H%M%S)"
BACKUP="${FILE}.bak.${TS}"
cp -v -- "$FILE" "$BACKUP"

# Crée le programme AWK qui transforme le YAML uniquement à l'intérieur des blocs "run: |"
AWK_PROG="$(mktemp)"
cat >"$AWK_PROG" <<'AWK'
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s){ return rtrim(ltrim(s)) }
function flush_echo_group(    i) {
    if (echo_count==0) return
    if (echo_count==1) {
        print echo_orig_line
    } else {
        print echo_indent "{"
        for (i=1; i<=echo_count; i++) {
            print echo_indent "  " echo_lines[i]
        }
        print echo_indent "} >> \"$GITHUB_OUTPUT\""
    }
    echo_count=0; echo_orig_line=""
    for (i in echo_lines) delete echo_lines[i]
}
BEGIN{
    in_run=0; indent_code=-1
    echo_count=0; echo_indent=""
}
{
    line=$0

    if (!in_run) {
        print line
        if (match(line, /^[[:space:]]*run:[[:space:]]*\|[[:space:]]*$/)) {
            in_run=1; indent_code=-1
        }
        next
    }

    # Dans un bloc run: |
    # Indentation de la ligne courante
    indlen = match(line, /^[[:space:]]*/)
    indstr = substr(line, 1, RLENGTH)

    # Détecte le début d'indentation du code (première ligne non vide après run: |)
    if (indent_code < 0 && line !~ /^[[:space:]]*$/) {
        indent_code = RLENGTH
    }

    # Fin du bloc run si on remonte l'indentation (hors lignes vides)
    if (!(line ~ /^[[:space:]]*$/) && indent_code >= 0 && RLENGTH < indent_code) {
        flush_echo_group()
        in_run=0; indent_code=-1
        print line
        next
    }

    # Lignes vides -> imprimer telles quelles après flush éventuel
    if (line ~ /^[[:space:]]*$/) {
        flush_echo_group()
        print line
        next
    }

    # SC2129 : accumulation de "echo ... >> \"$GITHUB_OUTPUT\"" consécutifs
    if (match(line, /^([[:space:]]*)echo (.*) >> "\$GITHUB_OUTPUT"[[:space:]]*$/, m)) {
        if (echo_count==0) echo_indent=m[1]
        echo_count++
        echo_lines[echo_count] = "echo " m[2]
        echo_orig_line = line
        next
    } else {
        flush_echo_group()
    }

    # SC2015 : transformer "A && B || C" -> if A; then B; else C; fi
    # Capture grossière (hors commentaires fin de ligne)
    if (match(line, /^([[:space:]]+)([^&|#][^&|]*?)\s*&&\s*([^|#]+?)\s*\|\|\s*([^#]+)$/, m)) {
        ind=m[1]; A=trim(m[2]); B=trim(m[3]); C=trim(m[4])
        sub(/[;[:space:]]+$/, "", A)
        sub(/^[;[:space:]]+/, "", B); sub(/[;[:space:]]+$/, "", B)
        sub(/^[;[:space:]]+/, "", C); sub(/[;[:space:]]+$/, "", C)
        print ind "if " A "; then"
        print ind "  " B
        print ind "else"
        print ind "  " C
        print ind "fi"
        next
    }

    # Défaut : imprimer tel quel
    print line
}
END{
    flush_echo_group()
}
AWK

TMP="${FILE}.tmp.${TS}"
awk -f "$AWK_PROG" -- "$FILE" >"$TMP"
mv -v -- "$TMP" "$FILE"
rm -f -- "$AWK_PROG"

echo
echo "=== DIFF ==="
git --no-pager diff -- "$FILE" || true

# Si pas de changement, on s'arrête gentiment
if git diff --quiet -- "$FILE"; then
  echo "[INFO] Aucun changement nécessaire dans $FILE"
  exit 0
fi

# Commit local
git add -- "$FILE"
git commit -m "ci: actionlint fixes (SC2015 if/else; SC2129 group GITHUB_OUTPUT)"

# Optionnel : test rapide si pre-commit est dispo
if command -v pre-commit >/dev/null 2>&1; then
  echo "[INFO] pre-commit présent — exécution locale (all files)…"
  pre-commit run --all-files || true
fi

echo "[OK] Correctifs appliqués et commit local créé."
