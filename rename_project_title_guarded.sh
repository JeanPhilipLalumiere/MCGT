#!/usr/bin/env bash
# rename_project_title_guarded.sh — Renomme proprement le TITRE du projet dans docs/métadonnées
#  - Cible: "Le Modèle de la Courbure Gravitationnelle du Temps"
#  - Remplace les formulations textuelles, sans toucher le code/identifiants.
#  - Montre un DRY-RUN, puis applique; ouvre PR dédiée.

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/rename_title_${TS}.log"

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

TARGET="Le Modèle de la Courbure Gravitationnelle du Temps"

# Expressions sources (insensibles à la casse/accents via perl Unicode)
# - Variante longue francisée "temporelle"
# - MCGT en titre (ligne #, =, etc.) → on remplacera seulement dans en-têtes README/chapitres
PAT_LONG='mod[èe]le\s+de\s+la\s+courbure\s+gravitationnelle\s+temporelle'

# Fichiers ciblés (docs & meta)
GLOB='(md|rst|tex|yml|yaml|toml|cff|json)'

# Branche
git fetch origin >/dev/null 2>&1 || true
git switch -c chore/rename-title || git checkout -b chore/rename-title

say "[DRY-RUN] Occurrences potentielles:"
# Liste des lignes candidates
rg -n --pcre2 -i -g "*.{${GLOB}}" "(MCGT|${PAT_LONG})" \
  | sed 's/^/  > /' | tee -a "$LOG" || true

# Appliquer remplacements limités aux docs/meta:
# 1) Remplacer la formulation longue (temporelle) → Titre cible
# 2) Ajuster titres README/chapitres contenant "MCGT" seul en titre de page
#    Heuristique simple: si une ligne de titre est exactement "MCGT" (ou '# MCGT', '\section{MCGT}', etc.)
perl -0777 -pe "
  use utf8;
  s/${PAT_LONG}/$TARGET/ig;
" -i $(git ls-files '*.'{md,rst,tex,yml,yaml,toml,cff,json} | tr '\n' ' ') || true

# Heuristiques de titres:
# Markdown: lignes '# MCGT' → '# Le Modèle ...'
# RST: lignes 'MCGT' suivies d'une ligne '====' → remplacer le texte
# LaTeX: \title{MCGT} ou \section{MCGT} → remplacer le contenu
# (on reste conservateurs)
perl -0777 -pe "
  use utf8;
  s/^(\\s*#\\s*)MCGT\\s*\$/\${1}$TARGET/mg;
  s/(^MCGT\\n[=]{3,}\\n)/$TARGET\\n==============================\\n/mg;
  s/\\\\title\\{\\s*MCGT\\s*\\}/\\\\title{$TARGET}/mg;
  s/\\\\section\\{\\s*MCGT\\s*\\}/\\\\section{$TARGET}/mg;
" -i $(git ls-files '*.'{md,rst,tex} | tr '\n' ' ') || true

# CITATION.cff: title: ... → remplace si existant
if [[ -f CITATION.cff ]]; then
  awk -v tgt="$TARGET" '
    BEGIN{done=0}
    /^title:/ && done==0 { print "title: " tgt; done=1; next }
    { print }
  ' CITATION.cff > _tmp/CITATION.cff.$TS || true
  if ! cmp -s CITATION.cff "_tmp/CITATION.cff.$TS"; then
    mv "_tmp/CITATION.cff.$TS" CITATION.cff
  else
    rm -f "_tmp/CITATION.cff.$TS"
  fi
fi

# pyproject.toml: on NE CHANGE PAS project.name (package), mais on peut enrichir description si présente
if [[ -f pyproject.toml ]]; then
  awk -v tgt="$TARGET" '
    BEGIN{inproj=0; changed=0}
    /^\[project\]/ {inproj=1}
    inproj && /^description\s*=/ && changed==0 {
      # Conserve la ligne mais si elle contient "MCGT" nu, on ajoute le titre complet
      if ($0 ~ /MCGT\W*$/) { print "description = \"" tgt " (MCGT)\"" ; changed=1; next }
    }
    { print }
  ' pyproject.toml > _tmp/pyproject.toml.$TS || true
  if ! cmp -s pyproject.toml "_tmp/pyproject.toml.$TS"; then
    mv "_tmp/pyproject.toml.$TS" pyproject.toml
  else
    rm -f "_tmp/pyproject.toml.$TS"
  fi
fi

# Staging & commit seulement s'il y a des diffs
if ! git diff --quiet; then
  git add -A
  git commit -m "docs: titre officiel — « Le Modèle de la Courbure Gravitationnelle du Temps » (sans toucher le package/code)"
  git push -u origin chore/rename-title
  gh pr create --fill --title "docs: titre officiel du projet" --body "Remplace la formulation « modèle de la courbure gravitationnelle temporelle » et les titres *MCGT* par « **Le Modèle de la Courbure Gravitationnelle du Temps** ». Aucun changement de package/module."
  echo "[NEXT] Ouvre la PR et vérifie le rendu des titres dans README/CITATION/chapitres."
else
  echo "[OK] Aucun changement détecté (déjà conforme)."
fi
