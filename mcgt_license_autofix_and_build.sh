#!/usr/bin/env bash
# mcgt_license_autofix_and_build.sh
# Corrige pyproject (license SPDX + license-files), nettoie setup.*,
# reconstruit sdist+wheel, twine check, et déclenche (optionnel) les guards.
set -Eeuo pipefail

echo "== mcgt license autofix & build =="
[ -f pyproject.toml ] || { echo "ERREUR: exécute ce script à la racine du repo (pyproject.toml manquant)."; exit 1; }

ts="$(date -u +%Y%m%dT%H%M%SZ)"
bkp_dir=".bkp_pkgmeta_${ts}"
mkdir -p "${bkp_dir}"
cp -a pyproject.toml "${bkp_dir}/pyproject.toml.bak"
[ -f setup.cfg ] && cp -a setup.cfg "${bkp_dir}/setup.cfg.bak" || true
[ -f setup.py ] && cp -a setup.py "${bkp_dir}/setup.py.bak" || true
echo "Backups -> ${bkp_dir}/"

# 1) [project] : forcer `license = "MIT"` et retirer "license" de dynamic=[]
tmp1="$(mktemp)"
awk '
  BEGIN{ in_proj=0; added=0; skip_block=0; depth=0 }
  function count(s,c,  n,i){ n=0; for(i=1;i<=length(s);i++) if(substr(s,i,1)==c) n++; return n }
  /^\[project\]\s*$/ { in_proj=1; print; next }
  /^\[/ {
    if (in_proj && !added) { print "license = \"MIT\""; added=1 }
    in_proj=0; skip_block=0; depth=0
    print; next
  }
  {
    if (in_proj) {
      if (skip_block==1) {
        depth += count($0,"{") - count($0,"}")
        if (depth<=0) { skip_block=0 }
        next
      }
      if ($0 ~ /^[[:space:]]*license[[:space:]]*=/ && $0 ~ /{/) {
        depth = count($0,"{") - count($0,"}")
        skip_block=1
        next
      }
      if ($0 ~ /^[[:space:]]*license[[:space:]]*=/ && $0 !~ /{/) { next }
      if ($0 ~ /^[[:space:]]*dynamic[[:space:]]*=/ && $0 ~ /\[/ && $0 ~ /\]/) {
        line=$0
        gsub(/"license"[[:space:]]*,[[:space:]]*/,"",line)
        gsub(/[[:space:]]*,"license"[[:space:]]*/,"",line)
        gsub(/,[[:space:]]*\]/,"]",line)
        sub(/\[[[:space:]]*\]/,"[]", line)
        print line
        next
      }
      print
      next
    }
    print
  }
  END{ if (in_proj && !added) { print "license = \"MIT\"" } }
' pyproject.toml > "${tmp1}" && mv "${tmp1}" pyproject.toml

# 2) [tool.setuptools].license-files
if ! grep -qE '^\[tool\.setuptools\]' pyproject.toml; then
  cat >> pyproject.toml <<'TOML'

[tool.setuptools]
license-files = ["LICENSE", "LICENSE-data"]
TOML
else
  if ! grep -qE '^\s*license-files\s*=' pyproject.toml; then
    tmp2="$(mktemp)"
    awk '
      BEGIN{in_block=0}
      /^\[tool\.setuptools\]\s*$/ { print; print "license-files = [\"LICENSE\", \"LICENSE-data\"]"; in_block=1; next }
      /^\[/ { in_block=0; print; next }
      { print }
    ' pyproject.toml > "${tmp2}" && mv "${tmp2}" pyproject.toml
  else
    tmp3="$(mktemp)"
    awk '
      BEGIN{in_block=0}
      /^\[tool\.setuptools\]\s*$/ { in_block=1; print; next }
      /^\[/ { in_block=0; print; next }
      {
        if (in_block==1 && $0 ~ /^[[:space:]]*license-files[[:space:]]*=/) {
          line=$0
          if (line !~ /"LICENSE"/)      sub(/\]/,", \"LICENSE\"]", line)
          if (line !~ /"LICENSE-data"/) sub(/\]/,", \"LICENSE-data\"]", line)
          gsub(/,\s*,/,",", line)
          print line
          next
        }
        print
      }
    ' pyproject.toml > "${tmp3}" && mv "${tmp3}" pyproject.toml
  fi
fi

# 3) Nettoyage legacy license= dans setup.py / setup.cfg (si présents)
if [ -f setup.py ]; then
  sed -i.bak -E 's/^\s*license\s*=\s*["'\''"][^"'\''"]*["'\''"]\s*,\s*$//g' setup.py || true
  sed -i -E    's/,\s*license\s*=\s*["'\''"][^"'\''"]*["'\''"]//g' setup.py || true
fi
if [ -f setup.cfg ]; then
  awk '
    BEGIN{in_meta=0}
    /^\[metadata\]\s*$/ { in_meta=1; print; next }
    /^\[/ { in_meta=0; print; next }
    { if (in_meta==1 && $0 ~ /^[[:space:]]*license[[:space:]]*=/) next; print }
  ' setup.cfg > "${bkp_dir}/setup.cfg.cleaned" && mv "${bkp_dir}/setup.cfg.cleaned" setup.cfg
fi

# 4) Build + twine check
echo "== build (sdist+wheel) =="
python3 -V || true
python3 -m pip show build twine setuptools || true
python3 -m build --sdist --wheel
sdist="$(ls -1t dist/*.tar.gz | head -n1)"
wheel="$(ls -1t dist/*.whl | head -n1)"
echo "sdist: ${sdist}"
echo "wheel: ${wheel}"
echo "== twine check =="
twine check "${wheel}" "${sdist}"

# 5) (Optionnel) déclenchement guards si gh présent
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
if command -v gh >/dev/null 2>&1; then
  for wf in readme-guard.yml manifest-guard.yml guard-ignore-and-sdist.yml; do
    if [ -f ".github/workflows/${wf}" ]; then
      echo "↳ trigger: ${wf} on ${branch}"
      gh workflow run "${wf}" -r "${branch}" || true
    fi
  done
fi

echo "== DONE =="
echo "Backups: ${bkp_dir}"
echo "Artifacts: ${sdist} , ${wheel}"
echo "twine check: PASSED"
