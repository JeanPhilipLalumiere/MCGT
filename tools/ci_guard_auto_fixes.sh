#!/usr/bin/env bash
# tools/ci_guard_auto_fixes.sh
# Corrige les gardes CI courants de façon sûre et idempotente.

set -Eeuo pipefail
BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
PRNUM="${2:-19}"

i(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
w(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
e(){ printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" 1>&2; }

git rev-parse --is-inside-work-tree >/dev/null || { e "Pas un repo git."; exit 0; }
git fetch --all -q || true
git checkout "$BRANCH" >/dev/null 2>&1 || true

_changed=0
mark(){ _changed=1; }

mkdir -p _tmp ci-artifacts .ci-archive

# 1) MANIFEST.in — durcissement (sans doublons)
i "Vérification/renforcement MANIFEST.in…"
touch MANIFEST.in
# Ajouts utiles (uniques)
ensure_line() {
  local patt="$1"
  grep -Fqx "$patt" MANIFEST.in || { echo "$patt" >> MANIFEST.in; mark; }
}
ensure_line "include README.md"
ensure_line "include LICENSE*"
ensure_line "include pyproject.toml"
ensure_line "global-exclude *.log *.bak *.bak.* *.tmp *.swp *.save"
ensure_line "prune .ci-archive"
ensure_line "prune backups"
ensure_line "prune _tmp"
# éviter de shipper de gros artefacts
ensure_line "prune dist"
ensure_line "prune build"
ensure_line "prune docs/_build"
git add MANIFEST.in || true

# 2) README présent et câblé (pyproject lit déjà README.md d’après tes logs)
if [[ ! -f README.md ]]; then
  i "README.md manquant -> création minimale (non destructive)…"
  cat > README.md <<'MD'
# MCGT

Ce dépôt fait l'objet d'une homogénéisation multi-chapitres. Cette notice minimale permet au packaging et aux gardes CI de passer. Voir la documentation du projet pour les détails.
MD
  mark
  git add README.md
fi

# 3) Normalisation permissions exec & shebangs
i "Normalisation permissions (exec) et shebangs…"
# a) fichiers avec shebang -> s'assurer que +x est présent
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  # Ajoute +x si shebang détecté
  grep -qE '^\s*#!' "$f" && chmod +x "$f" && git add "$f" && mark || true
done < <(git ls-files | grep -E '(^|/)(tools/|scripts/|bin/|\.github/).*' || true)

# b) exécutables SANS shebang -> retirer +x
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  # retire +x uniquement si pas de shebang
  if ! head -n1 "$f" | grep -qE '^\s*#!'; then
    chmod a-x "$f" && git add "$f" && mark || true
  fi
done < <(git ls-files --stage | awk '$1~/100755/{print $4}')

# 4) Fichiers générés suivis par Git -> déversionner proprement
i "Déversionne les artefacts générés (sauvegarde dans .ci-archive/)…"
GEN_PATTERNS=(
  "*.pdf"
  "docs/_build/**"
  "dist/**"
  "build/**"
)
# Détecte par glob depuis l’index
mapfile -t tracked < <(git ls-files)
for g in "${GEN_PATTERNS[@]}"; do
  for f in ${tracked[@]+"${tracked[@]}"}; do
    if [[ "$f" == $g ]]; then
      mkdir -p ".ci-archive/$(dirname "$f")"
      if [[ -f "$f" ]]; then cp -n "$f" ".ci-archive/$f" 2>/dev/null || true; fi
      git rm -q --cached "$f" 2>/dev/null || true
      mark
    fi
  done
done
# S’assurer que .ci-archive est ignoré
grep -Fqx ".ci-archive/" .gitignore || { echo ".ci-archive/" >> .gitignore; git add .gitignore; mark; }

# 5) Build sdist (sanity) — sans échouer le script
i "Construction sdist (sanity)…"
python - <<'PY' || true
import subprocess, sys, pathlib, shutil, json, tarfile
root = pathlib.Path(".")
path = root / "dist"
if path.exists():
    shutil.rmtree(path)
subprocess.run([sys.executable, "-m", "build", "--sdist"], check=False)
sdists = sorted((root/"dist").glob("*.tar.gz"))
print("SDISTs:", [p.name for p in sdists])
# Lister le contenu pour les gardes manifest
if sdists:
    t = tarfile.open(sdists[0], "r:gz")
    names = t.getnames()
    (root/"_tmp"/"sdist_contents.txt").parent.mkdir(parents=True, exist_ok=True)
    (root/"_tmp"/"sdist_contents.txt").write_text("\n".join(names))
PY

# 6) Commit/push si changements
if (( _changed == 1 )); then
  git commit -m "chore(ci): guards auto-fixes — MANIFEST/README, perms & generated artifacts (safe)"
  git push -u origin "$BRANCH"
  i "Changements poussés sur $BRANCH."
else
  i "Aucun changement requis (déjà conforme)."
fi

# 7) Relance CI (si gh présent)
if command -v gh >/dev/null 2>&1; then
  i "Dispatch workflows…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" >/dev/null 2>&1 || true
  gh workflow run .github/workflows/ci-accel.yml -r "$BRANCH" >/dev/null 2>&1 || true
  i "Surveille: gh pr checks $PRNUM"
else
  w "gh indisponible: relance via l’onglet Actions."
fi

i "Fini (mode safe). Artefacts: _tmp/sdist_contents.txt"
