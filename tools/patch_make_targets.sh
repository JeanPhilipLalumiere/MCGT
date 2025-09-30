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

echo "== Patch Makefile : fix-manifest & fix-manifest-strict =="

[ -f Makefile ] || { echo "❌ Makefile introuvable."; exit 1; }

bak="Makefile.bak.$(date -u +%Y%m%dT%H%M%SZ)"
cp -f Makefile "$bak"

python - <<'PY'
import re, pathlib

mf = pathlib.Path("Makefile")
txt = mf.read_text(encoding="utf-8", errors="replace")
# normalise les fins de ligne
txt = txt.replace("\r\n","\n").replace("\r","\n")

# Contenu canonique (TAB = \t)
block_fix = (
    "fix-manifest:\n"
    "\t@python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \\\n"
    "\t  --report json --normalize-paths --apply-aliases --strip-internal \\\n"
    "\t  --content-check --write-hashes --write-sizes || true\n"
    "\t@echo \"Done: fix-manifest (hashes/sizes écrits si applicable).\"\n"
)

block_fix_strict = (
    "fix-manifest-strict:\n"
    "\t@python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \\\n"
    "\t  --report json --normalize-paths --apply-aliases --strip-internal \\\n"
    "\t  --content-check --fail-on errors\n"
)

# Remplace chaque règle par sa version saine, qu'elle existe déjà ou pas.
def replace_rule(text, rule_name, new_block):
    # capture du bloc: début de ligne 'rule_name:' puis tout jusqu'à
    # la ligne vide suivante OU la prochaine règle/référence évidente.
    pat = re.compile(
        rf"(?m)^{re.escape(rule_name)}\s*:\s*\n(?:\t.*\n|\s*#.*\n|\s*\n|[^\n\t#].*\n)*",
    )
    if pat.search(text):
        text = pat.sub(new_block, text, count=1)
    else:
        # Injecte le bloc à la fin avec une ligne vide avant si besoin
        if not text.endswith("\n"):
            text += "\n"
        if not text.endswith("\n\n"):
            text += "\n"
        text += new_block
    return text

txt = replace_rule(txt, "fix-manifest", block_fix)
txt = replace_rule(txt, "fix-manifest-strict", block_fix_strict)

# Sauvegarde
pathlib.Path("Makefile").write_text(txt, encoding="utf-8")
print("OK: règles réécrites proprement (tabs + LF).")
PY

echo "✅ Makefile patché (backup: $bak)"

# Montre le contexte autour des règles (visualise les TAB par ^I)
echo "— Contexte autour de fix-manifest —"
awk 'BEGIN{show=0}
     /^fix-manifest:/{show=1}
     /^fix-manifest-strict:/{if(show){exit} }
     { if(show) print NR": "$0 }' Makefile | sed -e 's/\t/^I/g' -e 's/$/$/'

echo "— Contexte autour de fix-manifest-strict —"
awk 'BEGIN{show=0}
     /^fix-manifest-strict:/{show=1}
     /^[A-Za-z0-9_.%\/-]+\s*:/{if(NR>1 && $0 !~ /^fix-manifest-strict:/ && show){exit}}
     { if(show) print NR": "$0 }' Makefile | sed -e 's/\t/^I/g' -e 's/$/$/'

# Vérification make (dry-run) sur la cible sensible
echo "— make -n fix-manifest —"
if make -n fix-manifest >/dev/null; then
  echo "✅ make -n fix-manifest : OK"
else
  echo "⚠️  make -n fix-manifest a échoué. Affichage de make -n complet :"
  make -n || true
  exit 2
fi

# (Optionnel) Pousser si ton script push_all existe
if [ -x tools/push_all.sh ]; then
  echo "— push_all.sh —"
  tools/push_all.sh
else
  echo "ℹ️  tools/push_all.sh non trouvé — étape push ignorée."
fi
