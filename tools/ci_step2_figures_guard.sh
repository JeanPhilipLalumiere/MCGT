#!/usr/bin/env bash
set -euo pipefail

echo ">> Guard: figures integrity & manifest consistency"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FIGDIR="${FIGDIR:-zz-figures}"
MANIFEST="${MANIFEST:-zz-manifests/manifest_figures.sha256sum}"

# --- Helpers ---------------------------------------------------------------

# Recalcule un manifest "stable" **relatif** à $ROOT, en excluant:
#  - le dossier de quarantaine: $FIGDIR/_legacy_conflicts/**
#  - les liens symboliques (on les accepte comme alias legacy → canonique)
#  - fichiers non {png,svg,pdf}
compute_manifest_rel() {
  local out="$1"
  local figdir_rel
  figdir_rel="$(realpath --relative-to="$ROOT" "$FIGDIR")"
  # find en relatif, tri stable, hash, et on nettoie les "./"
  LC_ALL=C \
  find "$figdir_rel" \
      \( -path "$figdir_rel/_legacy_conflicts" -o -path "$figdir_rel/_legacy_conflicts/*" -o -type l \) -prune -o \
      -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 sha256sum \
  | sed 's#  ./#  #g' > "$out"
}

# Liste les symlinks cassés (info)
scan_broken_symlinks() {
  local figdir_rel; figdir_rel="$(realpath --relative-to="$ROOT" "$FIGDIR")"
  # find retourne 0 même si -printf imprime rien; on compte côté shell
  local n
  n="$(LC_ALL=C find "$figdir_rel" -xtype l -print | wc -l | tr -d ' ')"
  echo ">> Scan symlinks cassés…"
  echo "symlinks cassés: $n"
}

# Détection des doublons **réels** (fichiers distincts) en ignorant:
#  - la quarantaine
#  - les symlinks
#  - le préfixe chapitre "NN_" (on compare "clé logique" sans préfixe)
check_real_duplicates() {
python3 - <<'PY'
import os, sys
root = os.getcwd()
figdir = os.environ.get("FIGDIR","zz-figures")
fq = os.path.join(root, figdir)
dups = {}
for dirpath, dirnames, filenames in os.walk(fq):
    if os.path.normpath(dirpath).startswith(os.path.join(fq, "_legacy_conflicts")):
        continue
    for fn in filenames:
        if not fn.lower().endswith((".png",".svg",".pdf")):
            continue
        full = os.path.join(dirpath, fn)
        if os.path.islink(full):
            continue  # alias legacy accepté
        key = fn
        parts = fn.split("_", 1)
        if len(parts)==2 and parts[0].isdigit() and len(parts[0])==2:
            key = parts[1]  # retire "NN_"
        dups.setdefault(key, []).append(full)

bad = {k:v for k,v in dups.items() if len(v) > 1}
if bad:
    print("::error::doublons potentiels legacy/canonique détectés:")
    for k in sorted(bad):
        print(f"  - {k}:")
        for p in sorted(bad[k]):
            print(f"      {p}")
    sys.exit(1)

print("Aucun doublon logique résiduel (hors quarantaine; symlinks acceptés).")
PY
}

# --- Exécution -------------------------------------------------------------

echo "ROOT=$ROOT"
echo "FIGDIR=$ROOT/$FIGDIR"
echo "MANIFEST=$ROOT/$MANIFEST"
echo

scan_broken_symlinks
echo

echo ">> Inventaire des figures (png/svg/pdf)…"
# Compte en **ignorant** la quarantaine et les symlinks
tmp_list="$(mktemp)"
compute_manifest_rel "$tmp_list"
# On compte le nombre de lignes du manifest temporaire (chaque ligne = un fichier)
files_count="$(wc -l < "$tmp_list" | tr -d ' ')"
echo "fichiers: $files_count"
echo

echo ">> Rebuild manifest temporaire et diff…"
if ! diff -u "$MANIFEST" "$tmp_list" >/dev/null 2>&1 ; then
  echo "::error::Manifest drift détecté (recrée le manifest)."
  diff -u "$MANIFEST" "$tmp_list" || true
  exit 1
else
  echo "Manifest OK (aucun drift)."
fi
echo

echo ">> Vérification de doublons legacy/canonique…"
if ! check_real_duplicates ; then
  exit 1
fi
