#!/usr/bin/env bash
# repo_probe_safe.sh — inventaire non destructif du dépôt MCGT
# Objectif: NE JAMAIS fermer la fenêtre, même en cas d'erreur.

# ---- Garde-fous généraux -----------------------------------------------
set -u          # variables non définies = erreur (mais on n'abort pas)
set -o pipefail # propage les codes d'erreur dans les pipes, sans quitter

ERRS=0
WARN() { printf "\n[WARN] %s\n" "$*" >&2; }
INFO() { printf "\n[INFO] %s\n" "$*"; }
ERR()  { printf "\n[ERR ] %s\n" "$*" >&2; ERRS=$((ERRS+1)); }

# Intercepter TOUTE erreur d'exécution d'une commande, logguer, et CONTINUER
trap 'code=$?; cmd=${BASH_COMMAND:-?}; ERR "Commande échouée: \"$cmd\" (status=$code) — on continue"; ' ERR

# Ne JAMAIS fermer la fenêtre : toujours exécuter ce bloc à la fin
finish() {
  echo
  INFO "Résumé: $ERRS erreur(s) interceptée(s)."
  echo "[SAFE EXIT] Le script NE fermera pas cette fenêtre."

  # Tenter de récupérer un TTY pour l'invite, même si stdout/stderr sont pipés
  if exec 3</dev/tty 2>/dev/null; then
    echo
    echo -n "Appuie sur Entrée pour revenir à l’invite… " >&3
    # shellcheck disable=SC2162
    read -r _ <&3
    exec 3<&-
  else
    # Pas de TTY (ex: lancé depuis un lanceur graphique) — on temporise
    echo
    INFO "Aucun TTY dispo pour l'invite; pause 30s pour garantir la visibilité…"
    sleep 30
  fi
}
trap finish EXIT

# ------------------------------------------------------------------------
LC_ALL=C
umask 022

echo "== [0] Racine du dépôt =="
pwd || ERR "pwd a échoué"
echo

echo "== [1] Dossiers candidats présents (sensible à la casse) =="
cands=(zz-data zz-figures zz-scripts tools scripts zz-manifests chapters config zz-configuration zz-schemas tests)
for d in "${cands[@]}"; do
  if [ -d "$d" ]; then printf "OK  %s/\n" "$d"; else printf "--  %s/ (absent)\n" "$d"; fi
done
# variantes chapitres à la racine
found_any=0
for pat in "chapter*" "chapitre*"; do
  while IFS= read -r d; do
    [ "$d" = "." ] && continue
    printf "OK  %s/\n" "$(basename "$d")"
    found_any=1
  done < <(find . -maxdepth 1 -mindepth 1 -type d -name "$pat" 2>/dev/null | sort)
done
[ $found_any -eq 0 ] && WARN "Aucun dossier chapter*/chapitre* trouvé à la racine (c’est ok si tout est sous chapters/)"

echo
echo "== [2] Chapitres (FR/EN, zero-padding) =="
find . -maxdepth 1 -type d \
  \( -regex './chapter[0-9]+' -o -regex './chapter[0-9][0-9]+' -o -regex './chapitre[0-9]+' -o -regex './chapitre[0-9][0-9]+' -o -name 'chapters' \) \
  -printf '%f\n' 2>/dev/null | sort | nl -ba | sed -n '1,12p' || WARN "Scan chapitres: nada"
echo

echo "== [3] Scripts principaux par chapitre (run.py / tracer_* etc.) =="
find chapters chapter* chapitre* -maxdepth 2 -type f \
  \( -name 'run.py' -o -name 'tracer_*.py' -o -name 'trace_*.py' -o -regex '.*fig.*[0-9].*\.py' \) \
  2>/dev/null | sort | sed -n '1,20p' || WARN "Aucun script détecté (chemins par défaut inexistants ?)"
echo

echo "== [4] Figures & tables (PNG/SVG/PDF/CSV récents sous outputs/ ou zz-figures/) =="
find . -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' -o -iname '*.csv' \) \
  \( -path '*/outputs/*' -o -path './zz-figures/*' \) -printf '%TY-%Tm-%Td %TH:%TM  %p\n' \
  2>/dev/null | sort | tail -n 15 || WARN "Aucune figure/table trouvée"
echo

echo "== [5] Noms de fichiers de figures (patron réel) =="
find . -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) \
  \( -path '*/outputs/*' -o -path './zz-figures/*' \) -printf '%f\n' \
  2>/dev/null | sort -u | sed -n '1,12p' || WARN "Pas de figures trouvées"
echo

echo "== [6] Datasets effectivement lus (grep read_* / np.load) =="
grep -RIn --line-number --include='*.py' \
  -e 'read_csv' -e 'read_json' -e 'read_parquet' -e 'np\.load' -e 'pd\.read_' \
  chapters chapter* chapitre* zz-scripts scripts tools 2>/dev/null | sed -n '1,30p' || WARN "Aucune lecture détectée"
echo

echo "== [7] Dictionnaire de données (dictionary/schemas) =="
ls -1 2>/dev/null \
  data/dictionary.* data/data_dictionary.* zz-data/*dictionary* zz-schemas/* \
  || echo "(aucun fichier dictionary/schemas trouvé)"
echo

echo "== [8] Paramètres globaux (project_params/config/settings) =="
ls -1 config/project_params.* zz-configuration/* config.* settings.* 2>/dev/null || echo "(aucun trouvé)"
echo "Extraits YAML (si présents):"
for f in config/project_params.yml config.yml; do
  if [ -f "$f" ]; then
    echo "--- $f"
    awk 'NR<=50{print} NR==50{print "... (tronqué)"}' "$f" || true
  fi
done
echo

echo "== [9] Overrides locaux (params.yml/json par chapitre) =="
find chapters chapter* chapitre* -maxdepth 2 -type f \
  \( -name 'params.yml' -o -name 'params.yaml' -o -name 'params.json' \) \
  2>/dev/null | sort || echo "(aucun params.* local trouvé)"
echo

echo "== [10] Manifeste d'E/S existant =="
ls -1 zz-manifests/* manifest.* index_outputs.* 2>/dev/null || echo "(aucun manifeste trouvé)"
echo

echo "== [11] Workflows CI & job publish =="
ls -1 .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || echo "(aucun workflow trouvé)"
echo
echo "Titres de jobs (clé name: au niveau job):"
awk '/^jobs:/{J=1;next} J&&/^[^ ]/{J=0} J&&/name:/{print FILENAME":",$0}' .github/workflows/*.y* 2>/dev/null || true
echo

echo "== [12] Tests présents =="
find tests -maxdepth 2 -type f -name 'test_*.py' 2>/dev/null | sort || echo "(aucun test trouvé)"
echo

echo "== [13] Paquets Python =="
[ -d zz_tools ] && echo "OK  package zz_tools/" || echo "--  zz_tools/ absent"
find . -maxdepth 2 -type d -name 'mcgt' -o -name 'mcgt_*' 2>/dev/null | sort || true
echo

echo "== [14] Fichiers LaTeX (.tex) =="
find . -type f -name '*.tex' 2>/dev/null | sort | sed -n '1,20p' || echo "(aucun .tex)"
echo

echo "== [15] Fichiers d'autorité (présence) =="
for f in pyproject.toml setup.cfg MANIFEST.in CITATION.cff codemeta.json zenodo.json README.md LICENSE; do
  [ -e "$f" ] && echo "OK  $f"
done
echo

echo "== [16] Logs existants =="
find . -type f -name '*.log' 2>/dev/null | sort | sed -n '1,20p' || echo "(aucun .log)"
echo

echo "== [17] Orchestrateurs possibles =="
ls -1 zz-scripts/build_all.py scripts/build_all.py tools/run_all.sh tools/build_all.sh 2>/dev/null || echo "(aucun orchestrateur standard trouvé)"
echo

echo "== [18] Dépendances réseau (URLs ou libs HTTP) =="
grep -RIn --include='*.py' -E 'requests|urllib|http://|https://' \
  chapters chapter* chapitre* scripts zz-scripts tools 2>/dev/null | sed -n '1,20p' || echo "(aucune référence réseau trouvée)"
echo

echo "== [19] .gitignore (extraits) =="
if [ -f .gitignore ]; then
  awk 'NR<=200{print} NR==200{print "...(tronqué)"}' .gitignore
else
  echo "(pas de .gitignore)"
fi
echo

echo "== [20] Résumé identités =="
echo "Repo root: $(basename "$(pwd)")"
echo "Voisins immédiats:"
ls -1d ../*/ 2>/dev/null | sed 's@.*/@@' | sed -n '1,20p' || true

# Fin — la fenêtre reste ouverte grâce au trap EXIT -> finish()
