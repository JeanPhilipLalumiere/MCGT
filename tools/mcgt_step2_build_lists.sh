#!/usr/bin/env bash
# mcgt_step2_build_lists.sh — Lecture seule : synthèse IGNORE / ADD / REVIEW.
# Aucun rm/mv. Anti-fermeture si double-clic. Idempotent.

set -u
IFS=$'\n\t'
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="_tmp"
INV_DIR="_tmp/inventaires"
SUMMARY_MD="TODO_CLEANUP.md"

trap 'echo "[WARN] Une commande a échoué (code=$?) — consulte _tmp/step2_${RUN_ID}.log"; read -rp "Appuyez sur Entrée pour fermer..."; exit 0' ERR

mkdir -p "$LOG_DIR"
exec > >(tee -a "${LOG_DIR}/step2_${RUN_ID}.log") 2>&1

# 1) Collecte sources (tolérant à l’absence)
f_safe() { [ -f "$1" ] && cat "$1" || true; }

LOGS=$(f_safe "${INV_DIR}/logs_"*".txt")
CACHES=$(f_safe "${INV_DIR}/caches_"*".txt")
TMPBAK=$(f_safe "${INV_DIR}/tmp_bak_"*".txt")
NONOBL_DIRS=$(f_safe "${INV_DIR}/dossiers_non_obligatoires_"*".txt")
BIGS=$(f_safe "${INV_DIR}/gros_fichiers_"*".txt" | awk '{print $2}')
ARCHS=$(f_safe "${INV_DIR}/archives_"*".txt")
MULTI=$(f_safe "${INV_DIR}/figures_multi_format_"*".txt")

# 2) IGNORE candidates (règle conservative)
#    - répertoires non obligatoires
#    - caches/build/egg-info/dist
#    - logs/err/out/diag ids
#    - backups/.bak*
#    - archives zip/tar.gz
#    - sorties zz-out (runs), dist
#    - traces temporaires diverses
IGNORE_PATTERNS=$(
  {
    echo ".ci-out/"
    echo "_tmp/"
    echo "_tmp-figs/"
    echo "zz-out/"
    echo "dist/"
    echo "tools.egg-info/"
    echo "tools*.egg-info/"
    echo "**/__pycache__/"
    echo "**/.pytest_cache/"
    echo "**/.mypy_cache/"
    echo "**/.ipynb_checkpoints/"
    echo "**/*.log"
    echo "**/*.out"
    echo "**/*.err"
    echo ".diag_last_failed.json"
    echo ".last_run_id"
    echo "**/*.bak*"
    echo "backups/"
    echo "_snapshots/"
    echo "_attic_untracked/"
    echo "**/*.zip"
    echo "**/*.tar.gz"
  } | sed '/^$/d'
)

# 3) ADD (références d’autorité) — étendable selon ton repo
ADD_LIST=$(
  {
    [ -f "assets/zz-manifests/manifest_master.json" ] && echo "assets/zz-manifests/manifest_master.json"
    [ -f "assets/zz-manifests/manifest_publication.json" ] && echo "assets/zz-manifests/manifest_publication.json"
    [ -f "assets/zz-manifests/manifest_report.json" ] && echo "assets/zz-manifests/manifest_report.json"
    # Conserver temporairement les backfilled tant qu’utiles à l’état courant
    [ -f "assets/zz-manifests/manifest_master.backfilled.json" ] && echo "assets/zz-manifests/manifest_master.backfilled.json"
    [ -f "assets/zz-manifests/manifest_master.backfilled.force.json" ] && echo "assets/zz-manifests/manifest_master.backfilled.force.json"
    [ -f "CITATION.cff" ] && echo "CITATION.cff"
    [ -f ".zenodo.json" ] && echo ".zenodo.json"
    [ -f "LICENSE" ] && echo "LICENSE"
    [ -f "README.md" ] && echo "README.md"
    [ -d "assets/zz-schemas" ] && echo "assets/zz-schemas/**"
    [ -d "policies" ] && echo "policies/**"
    [ -d "tests" ] && echo "tests/**"
  }
)

# 4) Matérialiser les fichiers
printf "%s\n" ${IGNORE_PATTERNS} | awk 'NF' | sort -u > ignore_list_round2.txt
printf "%s\n" ${ADD_LIST} | awk 'NF' | sort -u > add_list_round2.txt

# 5) REVIEW = Inventaire (logs+caches+tmpbak+nonobl+archs+multi+bigs) – IGNORE + ADD (priorité ADD)
#    NB: on part de l’union des INVENTAIRES explicites; on filtre ce qui matche IGNORE_PATTERNS.
tmp_all="${LOG_DIR}/_all_inventory_${RUN_ID}.txt"
{
  printf "%s\n" "$LOGS"
  printf "%s\n" "$CACHES"
  printf "%s\n" "$TMPBAK"
  printf "%s\n" "$NONOBL_DIRS"
  printf "%s\n" "$ARCHS"
  printf "%s\n" "$MULTI"
  printf "%s\n" "$BIGS"
} | sed -E 's#^\./##' | awk 'NF' | sort -u > "$tmp_all"

# Construire grep pattern pour IGNORE
ignore_regex_file="${LOG_DIR}/_ignore_regex_${RUN_ID}.txt"
# Convertit patterns style .gitignore en regex simples (approx. conservative)
# (on se contente de rejeter si le chemin contient une sous-chaîne clé)
sed -E 's#\*#.#g' ignore_list_round2.txt \
  | sed -E 's#/\$?$#/#' \
  | awk 'NF' > "$ignore_regex_file"

review_file="review_list_round2.txt"
: > "$review_file"

while IFS= read -r path; do
  keep=1
  # Priorité ADD
  if grep -qxF "$path" add_list_round2.txt 2>/dev/null; then
    keep=0
  else
    # Filtrage IGNORE (substring conservative)
    if [ -s "$ignore_regex_file" ]; then
      if grep -qF "/" <<<"$path"; then
        # chemin avec /
        while IFS= read -r pat; do
          if [[ "$path" =~ $(echo "$pat" | sed 's#/#\/#g') ]]; then keep=0; break; fi
        done < "$ignore_regex_file"
      else
        # élément seul
        while IFS= read -r pat; do
          if [[ "$path" =~ $(echo "$pat" | sed 's#/#\/#g') ]]; then keep=0; break; fi
        done < "$ignore_regex_file"
      fi
    fi
  fi
  [ $keep -eq 1 ] && echo "$path" >> "$review_file"
done < "$tmp_all"

# 6) Résumé chiffré dans TODO_CLEANUP.md
count_lines () { [ -f "$1" ] && wc -l < "$1" || echo 0; }
IGN_N=$(count_lines ignore_list_round2.txt)
ADD_N=$(count_lines add_list_round2.txt)
REV_N=$(count_lines review_list_round2.txt)

{
  echo
  echo "## Step 2 — Listes Round2 (${RUN_ID})"
  echo "- **IGNORE** : ${IGN_N} motifs/chemins"
  echo "- **ADD**    : ${ADD_N} chemins d'autorité"
  echo "- **REVIEW** : ${REV_N} éléments à inspection manuelle"
  echo
  echo "### Règle rappel"
  echo "\`REVIEW = (INVENTAIRE – IGNORE) ∪ ADD\` avec priorité **ADD > IGNORE**."
  echo
  echo "### Prochaines actions"
  echo "1) Parcourir *review_list_round2.txt* et soit déplacer vers **IGNORE**, soit vers **ADD**."
  echo "2) Après tri, geler les patterns IGNORE dans *.gitignore* et documenter les exceptions."
  echo "3) Lancer Step 3 (dé-dup Makefiles + profil QUIET) — je te fournirai le script."
} >> "$SUMMARY_MD"

# Pause (anti-fermeture si lancé par double-clic)
if [ -t 1 ]; then
  echo
  read -rp "Synthèse des listes terminée. Appuyez sur Entrée pour quitter..."
fi

exit 0
