#!/usr/bin/env bash
set -euo pipefail

echo "[PATCH] Purge des appels plt.tight_layout(...) au profit de fig.subplots_adjust(...)"

# Fichiers à traiter (repérés par ton smoke précédent)
FILES=(
  "zz-scripts/chapter10/plot_fig01_iso_p95_maps.py"
  "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
  "zz-scripts/chapter10/regen_fig05_using_circp95.py"
  "zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py"
)

# Fonction utilitaire: pour chaque fichier, on traite 3 cas:
#  A) séquence "...; plt.tight_layout(...); fig.savefig(...)"  -> subplots_adjust ; fig.savefig
#  B) bloc "warnings.catch_warnings(); warnings.simplefilter(...); plt.tight_layout()" -> ...; fig=plt.gcf(); fig.subplots_adjust(...)
#  C) tout "plt.tight_layout(...)" résiduel -> fig=plt.gcf(); fig.subplots_adjust(...)
patch_file () {
  local F="$1"
  [[ -f "$F" ]] || { echo "[SKIP] $F (absent)"; return 0; }

  echo "  - traite $F"

  # A) tight_layout + savefig enchaînés (multilignes autorisés)
  perl -0777 -pe '
    s/plt\.tight_layout\([^)]*\)\s*;\s*fig\.savefig\(([^)]+)\)/fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12);\nfig.savefig(\1)/sg
  ' -i "$F"

  # B) séquence dans un bloc warnings
  perl -0777 -pe '
    s/(warnings\.simplefilter\([^)]*\)\s*;\s*)plt\.tight_layout\(\)/\1fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg
  ' -i "$F"

  # C) toute autre occurrence résiduelle
  perl -0777 -pe '
    s/plt\.tight_layout\([^)]*\)/fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg
  ' -i "$F"
}

for f in "${FILES[@]}"; do
  patch_file "$f"
done

echo "[OK] Remplacements effectués."

echo "[CHECK] Affiche les lignes contenant encore tight_layout (hors commentaires)"
viol=$(awk '/tight_layout/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find zz-scripts/chapter10 -maxdepth 1 -name "*.py"))
if [[ -n "${viol}" ]]; then
  echo "[FAIL] Il reste des appels actifs à tight_layout :"
  echo "${viol}"
  exit 1
else
  echo "[OK] Aucun appel actif à tight_layout détecté."
fi
