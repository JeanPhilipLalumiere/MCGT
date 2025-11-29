#!/usr/bin/env bash
# Fichier : tools/mcgt_probe_packages_v1.sh
# Objectif : cartographier le packaging Python (mcgt, zz_tools, zz-tools, pyproject, versions).
# Mode : lecture seule, pas de modification.

set -Eeuo pipefail

trap 'code=$?;
echo;
echo "[ERREUR] Le script s est arrêté avec le code $code.";
echo "[ASTUCE] Lecture seule : rien n a été modifié.";
read -rp "Appuie sur Entrée pour fermer ce script... ";
exit "$code"' ERR

cd "$(dirname "${BASH_SOURCE[0]}")/.." || {
  echo "[ERREUR] Impossible de remonter à la racine du dépôt."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
}

echo "=== MCGT: probe packages v1 ==="
echo "Dossier courant: $(pwd)"
echo

echo "### (1) pyproject.toml / setup.cfg / setup.py (profondeur 3)"
find . -maxdepth 3 \( -name "pyproject.toml" -o -name "setup.cfg" -o -name "setup.py" \) -print | sort
echo

echo "### (2) Arborescence des répertoires de package (profondeur 2)"
for d in mcgt zz_tools zz-tools zz_tools.egg-info; do
  if [ -d "$d" ]; then
    echo "---- $d (profondeur 2) ----"
    find "$d" -maxdepth 2 -mindepth 1 -print | sort
    echo
  else
    echo "---- $d : [absent] ----"
    echo
  fi
done

echo "### (3) Versions déclarées dans mcgt/__init__.py et zz_tools/__init__.py (si présents)"
if [ -f "mcgt/__init__.py" ]; then
  echo "-- mcgt/__init__.py (lignes contenant '__version__')"
  grep -n "__version__" mcgt/__init__.py || echo "[aucune __version__ dans mcgt/__init__.py]"
  echo
fi

if [ -f "zz_tools/__init__.py" ]; then
  echo "-- zz_tools/__init__.py (lignes contenant '__version__')"
  grep -n "__version__" zz_tools/__init__.py || echo "[aucune __version__ dans zz_tools/__init__.py]"
  echo
fi

echo "### (4) Petit check runtime (import mcgt / zz_tools) - sans obligation de succès"
python - << 'EOF' || echo "[INFO] Import Python a échoué (ce n est pas grave, juste informatif)."
print(">>> Import runtime check")
try:
    import mcgt
    print("mcgt.__version__ =", getattr(mcgt, "__version__", "<no __version__>"))
except Exception as e:
    print("Erreur import mcgt:", e)

try:
    import zz_tools
    print("zz_tools.__version__ =", getattr(zz_tools, "__version__", "<no __version__>"))
except Exception as e:
    print("Erreur import zz_tools:", e)
EOF

echo
echo "[INFO] mcgt_probe_packages_v1: extraction terminée (lecture seule)."
read -rp "Appuie sur Entrée pour fermer ce script... "
exit 0
