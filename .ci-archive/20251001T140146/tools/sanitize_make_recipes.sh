#!/usr/bin/env bash
set -euo pipefail

PAUSE="${PAUSE:-1}"
_pause(){
  if [[ "${PAUSE}" != "0" && -t 0 ]]; then
    echo
    read -r -p "✓ Terminé. Appuie sur Entrée pour fermer ce script..." _
  fi
}
trap _pause EXIT

echo "== Sanitize Makefile (tabs ASCII + suppression espaces Unicode invisibles) =="

[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }
bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

python - <<'PY'
import re, pathlib

# Tous les "espaces bizarres" et invisibles à retirer
BAD_CHARS = {
    "\u00A0": " ",   # NBSP
    "\u1680": " ",   # OGHAM SPACE
    "\u180E": "",    # MONGOLIAN VOWEL SEPARATOR (obsolete)
    "\u2000": " ", "\u2001": " ", "\u2002": " ", "\u2003": " ",
    "\u2004": " ", "\u2005": " ", "\u2006": " ", "\u2007": " ",
    "\u2008": " ", "\u2009": " ", "\u200A": " ", # EN/EM/THIN etc.
    "\u200B": "",    # ZERO WIDTH SPACE
    "\u200C": "",    # ZERO WIDTH NON-JOINER
    "\u200D": "",    # ZERO WIDTH JOINER
    "\u202F": " ",   # NARROW NBSP
    "\u205F": " ",   # MEDIUM MATHEMATICAL SPACE
    "\u2060": "",    # WORD JOINER
    "\uFEFF": "",    # BOM/ZWNBSP
}
TRANS = str.maketrans(BAD_CHARS)

p = pathlib.Path("Makefile")
txt = p.read_text(encoding="utf-8", errors="replace")
# normalise CRLF/CR
txt = txt.replace("\r\n", "\n").replace("\r", "\n")
lines = txt.split("\n")

re_rule   = re.compile(r'^[A-Za-z0-9_.%/\-]+(?:\s*\([^)]*\))?\s*:')  # target[:]
in_recipe = False
fixed_lines = []

def sanitize_recipe_line(s: str) -> str:
    # supprime BOM/zero-width/espaces spéciaux partout
    s = s.translate(TRANS)
    # s'il s'agit d'une ligne de recette: doit commencer par exactement \t sans rien avant
    # on supprime tout le *whitespace* de tête puis on préfixe \t
    s = s.lstrip()
    s = "\t" + s if not s.startswith("\t") else ("\t" + s.lstrip("\t"))
    # nettoie continuation: pas d'espace après le backslash de fin
    if s.rstrip().endswith("\\") and not s.endswith("\\"):
        # cas rare déjà ok
        pass
    else:
        # en général: on rstrip les espaces en fin, puis remet un \ si déjà présent
        if s.rstrip().endswith("\\"):
            s = s.rstrip()  # enlève les spaces après \
        else:
            # rien
            s = s.rstrip()
    return s

for i, line in enumerate(lines):
    # purge globalement les caractères invisibles dans *toutes* les lignes (même hors recette)
    clean = line.translate(TRANS)

    if re_rule.match(clean) and not clean.lstrip().startswith("#"):
        in_recipe = True
        fixed_lines.append(clean)
        continue

    # nouvelle règle / ligne vide -> sort de recette
    if in_recipe and (clean.strip() == "" or re_rule.match(clean)):
        in_recipe = False

    if in_recipe:
        # transforme *toute* ligne du bloc recette en véritable ligne de recette:
        #  - supprime les espaces/char invisibles en tête
        #  - force un TAB ASCII comme premier char
        #  - nettoie backslash de fin
        fixed_lines.append(sanitize_recipe_line(clean))
    else:
        fixed_lines.append(clean)

# réassemble
out = "\n".join(fixed_lines)
# garantis une fin de fichier LF
if not out.endswith("\n"):
    out += "\n"
p.write_text(out, encoding="utf-8")
print("OK: Makefile nettoyé (chars invisibles purgés, recettes = TAB ASCII, LF).")
PY

echo "✅ Makefile patché (backup: $bak)"

# Affiche un hexdump lisible autour des lignes 70..82
echo "— Hexdump context 70..82 —"
nl -ba -w3 -s': ' Makefile | sed -n '70,82p' | awk '{print $0}' | while IFS= read -r L; do
  num="${L%%:*}"
  line="${L#*: }"
  printf "%3s: " "$num"
  # hexdump/od sur la chaîne via printf
  printf "%s" "$line" | od -An -t x1 -c | sed 's/^/    /'
done

# Visualise TAB comme ^I
echo "— Visualise TAB (^I) 70..82 —"
nl -ba -w3 -s': ' Makefile | sed -n '70,82p' | sed -e 's/\t/^I/g' -e 's/$/$/'

# Vérifie la cible
echo "— make -n fix-manifest —"
if make -n fix-manifest >/dev/null; then
  echo "✅ make -n fix-manifest : OK"
else
  echo "⚠️  make -n fix-manifest a échoué. Contexte brut :"
  make -n || true
  exit 2
fi

# (Optionnel) pousse si disponible
if [ -x tools/push_all.sh ]; then
  echo "— push_all.sh —"
  tools/push_all.sh
else
  echo "ℹ️  tools/push_all.sh non trouvé — push ignoré."
fi
