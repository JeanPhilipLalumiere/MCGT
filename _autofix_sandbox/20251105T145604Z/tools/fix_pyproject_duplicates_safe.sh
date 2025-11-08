#!/usr/bin/env bash
# tools/fix_pyproject_duplicates_safe.sh
# Neutralise prudemment les *clés dupliquées dans une même table* TOML en les commentant.
# Idempotent, avec sauvegarde. N'altère pas la 1ʳᵉ occurrence d'une clé, seulement les suivantes.

set -Eeuo pipefail
i(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
w(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
e(){ printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" 1>&2; }

[[ -f pyproject.toml ]] || { e "pyproject.toml introuvable"; exit 1; }

mkdir -p backups _tmp
bk="backups/pyproject.toml.$(date +%Y%m%dT%H%M%S).bak"
cp -f pyproject.toml "$bk"
i "Backup: $bk"

# AWK: suit la table courante; commente les lignes où une clé réapparaît dans la *même* table.
# - Table = ligne du type [project] ou [tool.setuptools], etc.
# - Clé = texte avant le premier '=' hors commentaires.
awk '
BEGIN {
  table = "";
}
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s){ return rtrim(ltrim(s)) }

{
  orig = $0;

  # Conserve les commentaires vides/pleins tels quels
  if (match(orig, /^[ \t]*#/)) { print orig; next }

  # Détection table: [xxx] ou [[xxx]]
  if (match(orig, /^[ \t]*\[[^\]]+\][ \t]*$/)) {
    table = trim(orig);
    # Normalise pour la map (supprime espaces)
    gsub(/[ \t]+/, "", table);
    print orig;
    next;
  }

  # Lignes type "key = ..."
  # On ignore les lignes sans '=' ou commençant par un ident non valide
  if (index(orig, "=") == 0) { print orig; next }

  # Extraire la clé avant le 1er '=' (sans espaces)
  split(orig, arr, "=");
  key = trim(arr[1]);

  # clé invalide (vide, commence par [ ou {, etc.) -> garder tel quel
  if (key == "" || match(key, /^[\[\{]/)) { print orig; next }

  # On travaille *par table* ; s il n y a pas encore de table, on utilise "" (racine)
  mapkey = table "|" key;
  if (seen[mapkey] == 1) {
    # Dupliqué → commenter prudemment
    print "# DUPLICATE_DISABLED: " orig;
  } else {
    seen[mapkey] = 1;
    print orig;
  }
}
' pyproject.toml > _tmp/pyproject.toml.dedup

# Remplace si différent
if ! cmp -s pyproject.toml _tmp/pyproject.toml.dedup; then
  mv _tmp/pyproject.toml.dedup pyproject.toml
  i "Doublons neutralisés (les occurrences suivantes sont commentées)."
  changed=1
else
  i "Aucun doublon détecté (ou déjà neutralisé)."
  changed=0
  rm -f _tmp/pyproject.toml.dedup
fi

# Essai build sdist (non bloquant)
i "Test build sdist (sanity)…"
python - <<'PY' || true
import subprocess, sys, pathlib, shutil, tarfile
root = pathlib.Path(".")
dist = root/"dist"
if dist.exists():
    shutil.rmtree(dist)
subprocess.run([sys.executable, "-m", "build", "--sdist"], check=False)
sd = sorted(dist.glob("*.tar.gz"))
print("SDISTs:", [p.name for p in sd])
if sd:
    with tarfile.open(sd[0], "r:gz") as t:
        names = t.getnames()
    (root/"_tmp"/"sdist_contents_after_fix.txt").parent.mkdir(parents=True, exist_ok=True)
    (root/"_tmp"/"sdist_contents_after_fix.txt").write_text("\n".join(names))
PY

# Commit/push si modifié
if [[ "$changed" -eq 1 ]]; then
  git add pyproject.toml || true
  git commit -m "chore(build): neutralize duplicate keys in pyproject.toml (safe auto-fix)"
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  git push -u origin "$current_branch" || w "Push non effectué (droits/remote?)"
  i "Modifs poussées sur $current_branch"
else
  i "Rien à pousser."
fi

# Relance Actions si dispo
if command -v gh >/dev/null 2>&1; then
  br="$(git rev-parse --abbrev-ref HEAD)"
  gh workflow run .github/workflows/build-publish.yml -r "$br" >/dev/null 2>&1 || true
  gh workflow run .github/workflows/ci-accel.yml -r "$br" >/dev/null 2>&1 || true
  i "Workflows relancés sur $br (si triggers actifs)."
fi

i "Terminé. Backup: $bk"
