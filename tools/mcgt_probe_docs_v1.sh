#!/usr/bin/env bash
# Fichier: tools/mcgt_probe_docs_v1.sh
# Objectif : sonder MCGT en lecture seule (docs, métadonnées, config, paquets)
#            en affichant les contenus clés directement dans le log.

set -Eeuo pipefail

trap 'code=$?;
echo;
echo "[ERREUR] Le script s est arrêté avec le code $code.";
echo "[ASTUCE] Ce script ne modifie aucun fichier; tu peux inspecter le log ci-dessus en toute sécurité.";
read -rp "Appuie sur Entrée pour fermer ce script... ";
exit "$code"' ERR

# Se placer à la racine du dépôt (dossier parent de tools/)
cd "$(dirname "${BASH_SOURCE[0]}")/.." || {
  echo "[ERREUR] Impossible de remonter à la racine du dépôt."
  read -rp "Appuie sur Entrée pour fermer ce script... "
  exit 1
}

echo "=== MCGT: probe docs v1 (lecture seule) ==="
echo "Dossier courant: $(pwd)"
echo

echo "### (1) Contexte Git rapide (branche + dernier commit)"
git branch --show-current || true
git log -1 --oneline || true
echo

echo "### (2) README.md (lignes 1–80)"
if [ -f README.md ]; then
  sed -n '1,80p' README.md
else
  echo "README.md absent."
fi
echo

echo "### (3) README-REPRO.md (lignes 1–80)"
if [ -f README-REPRO.md ]; then
  sed -n '1,80p' README-REPRO.md
else
  echo "README-REPRO.md absent."
fi
echo

echo "### (4) docs/README-REPRO.md (lignes 1–80)"
if [ -f docs/README-REPRO.md ]; then
  sed -n '1,80p' docs/README-REPRO.md
else
  echo "docs/README-REPRO.md absent."
fi
echo

echo "### (5) RUNBOOK.md (lignes 1–80)"
if [ -f RUNBOOK.md ]; then
  sed -n '1,80p' RUNBOOK.md
else
  echo "RUNBOOK.md absent."
fi
echo

echo "### (6) CITATION.cff (lignes 1–80)"
if [ -f CITATION.cff ]; then
  sed -n '1,80p' CITATION.cff
else
  echo "CITATION.cff absent."
fi
echo

echo "### (7) .zenodo.json (lignes 1–60)"
if [ -f .zenodo.json ]; then
  sed -n '1,60p' .zenodo.json
else
  echo ".zenodo.json absent."
fi
echo

echo "### (8) Arborescence du paquet mcgt/ (profondeur 2, fichiers .py/.md/.txt)"
if [ -d mcgt ]; then
  find mcgt -maxdepth 2 -mindepth 1 -type f \( -name '*.py' -o -name '*.md' -o -name '*.txt' \) | sort
else
  echo "Répertoire mcgt/ absent."
fi
echo

echo "### (9) mcgt/__init__.py (lignes 1–80)"
if [ -f mcgt/__init__.py ]; then
  sed -n '1,80p' mcgt/__init__.py
else
  echo "mcgt/__init__.py absent."
fi
echo

echo "### (10) zz_tools/__init__.py (lignes 1–80)"
if [ -f zz_tools/__init__.py ]; then
  sed -n '1,80p' zz_tools/__init__.py
else
  echo "zz_tools/__init__.py absent."
fi
echo

echo "### (11) Liste des modules zz_tools/* (niveau 1, *.py)"
if [ -d zz_tools ]; then
  find zz_tools -maxdepth 1 -type f -name '*.py' | sort
else
  echo "Répertoire zz_tools/ absent."
fi
echo

echo "### (12) zz-configuration/README.md (lignes 1–80)"
if [ -f zz-configuration/README.md ]; then
  sed -n '1,80p' zz-configuration/README.md
else
  echo "zz-configuration/README.md absent."
fi
echo

echo "### (13) zz-config/ (fichiers au niveau 1)"
if [ -d zz-config ]; then
  find zz-config -maxdepth 1 -type f | sort
else
  echo "Répertoire zz-config/ absent."
fi
echo

echo "### (14) zz-schemas/README_SCHEMAS.md (lignes 1–80)"
if [ -f zz-schemas/README_SCHEMAS.md ]; then
  sed -n '1,80p' zz-schemas/README_SCHEMAS.md
else
  echo "zz-schemas/README_SCHEMAS.md absent."
fi
echo

echo "### (15) Liste des schémas JSON dans zz-schemas/ (profondeur 1)"
if [ -d zz-schemas ]; then
  find zz-schemas -maxdepth 1 -type f -name '*.json' | sort
else
  echo "Répertoire zz-schemas/ absent."
fi
echo

echo "### (16) main.tex (lignes 1–80)"
if [ -f main.tex ]; then
  sed -n '1,80p' main.tex
else
  echo "main.tex absent."
fi
echo

echo
echo "[INFO] mcgt_probe_docs_v1: extraction terminée (lecture seule)."
read -rp "Appuie sur Entrée pour fermer ce script... "
exit 0
