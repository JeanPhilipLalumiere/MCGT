#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Le log complet est visible ci-dessus.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== MCGT – Vue d'ensemble de l'arborescence (maxdepth 4, sans attic / out / logs) =="
echo

echo "-- Dossiers de premier niveau (racine) --"
find . -maxdepth 1 -mindepth 1 -type d ! -path "./.git" | sort
echo

echo "-- Dossiers jusqu'à profondeur 2 (sans attic/_attic_untracked) --"
find . -maxdepth 2 -type d \
  ! -path "./.git*" \
  ! -path "./attic*" \
  ! -path "./_attic_untracked*" \
  | sort
echo

echo "-- Arborescence détaillée jusqu'à profondeur 4 (sans attic / _logs / _snapshots / zz-out) --"
find . -maxdepth 4 -type d \
  ! -path "./.git*" \
  ! -path "./attic*" \
  ! -path "./_attic_untracked*" \
  ! -path "./_logs*" \
  ! -path "./_snapshots*" \
  ! -path "./zz-out*" \
  | sort
echo

read -rp "Terminé (extract_01_tree). Appuie sur Entrée pour revenir au shell..." _
