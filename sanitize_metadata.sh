#!/usr/bin/env bash
set -Eeuo pipefail

echo "== MCGT / zz_tools — sanitize core metadata for Twine =="

ROOT="${1:-.}"
cd "$ROOT"

PYPROJ="pyproject.toml"
SETCFG="setup.cfg"

[[ -f "$PYPROJ" ]] || { echo "!! $PYPROJ introuvable"; exit 2; }
[[ -f "$SETCFG" ]] || { echo "!! $SETCFG introuvable"; exit 2; }

ts="$(date +%Y%m%dT%H%M%SZ)"
cp -a "$PYPROJ" "${PYPROJ}.bak.${ts}"
cp -a "$SETCFG" "${SETCFG}.bak.${ts}"

echo "-- Patch pyproject.toml : retire license-expression / license-file + dynamic entries correspondantes"
# 1) Supprime champs problématiques explicites
perl -0777 -i -pe '
  s/^\s*license[-_]?expression\s*=\s*.*\n//gmi;
  s/^\s*license[-_]?file[s]?\s*=\s*.*\n//gmi;
' "$PYPROJ"

# 2) Dans les lignes \"dynamic = [ ... ]\", retirer les tokens \"license\" et \"license-file\"
perl -0777 -i -pe '
  sub strip_tokens {
    my ($s) = @_;
    $s =~ s/\s*\"license(-file)?\"\s*,\s*//g;
    $s =~ s/,\s*\"license(-file)?\"\s*//g;
    $s =~ s/\[\s*,\s*/[/g;
    $s =~ s/,\s*\]/]/g;
    return $s;
  }
  s/^( \s* dynamic \s* = \s* \[ [^\n]* \] )/
    strip_tokens($1)
  /gexmi;
' "$PYPROJ"

# 3) S'assurer que [project] possède \"license = \\\"MIT\\\"\"
awk '
  BEGIN{in=0; have=0}
  /^\s*\[project\]\s*$/ {in=1; print; next}
  in==1 && /^\s*license\s*=/ {have=1}
  in==1 && /^\s*\[/ { if(!have){print "license = \"MIT\""}; in=0 }
  {print}
  END{ if(in==1 && !have){ print "license = \"MIT\"" } }
' "$PYPROJ" > "${PYPROJ}.tmp" && mv "${PYPROJ}.tmp" "$PYPROJ"

echo "-- Patch setup.cfg : impose license = MIT et supprime license_files"
awk '
  BEGIN{in=0; have=0}
  /^\s*\[metadata\]\s*$/ {in=1; print; next}
  in==1 && /^\s*license\s*=/ {have=1}
  in==1 && /^\s*\[/ { if(!have){print "license = MIT"}; in=0 }
  {print}
  END{ if(in==1 && !have){ print "license = MIT" } }
' "$SETCFG" > "${SETCFG}.tmp" && mv "${SETCFG}.tmp" "$SETCFG"
sed -ri '/^\s*license_files\s*=/d' "$SETCFG"

echo "-- Clean & rebuild sdist"
rm -rf dist build *.egg-info || true
python -m build --sdist

SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
echo "sdist: $SDIST"

echo
echo "=== Inspect PKG-INFO (head) ==="
tar -xOf "$SDIST" */PKG-INFO | sed -n '1,60p' || { echo "!! PKG-INFO introuvable dans l’archive"; }

echo
echo "=== Validation rapide — absence des champs litigieux ==="
if tar -xOf "$SDIST" */PKG-INFO | grep -qiE '^(License-Expression:|Dynamic: .*license)'; then
  echo "!! Des champs non supportés subsistent (License-Expression ou Dynamic: license) — à corriger."
  echo "   Indices:"
  tar -xOf "$SDIST" */PKG-INFO | grep -niE 'License-Expression|Dynamic: .*license' || true
  echo "   Essaye : grep -R \"license-?expression\\|license[-_]file\" pyproject.toml setup.cfg setup.py"
  exit 3
else
  echo "OK: ni License-Expression, ni Dynamic: license* dans PKG-INFO"
fi

echo
echo "=== Run twine check ==="
python - <<'PY'
import sys, subprocess, glob
dist = sorted(glob.glob("dist/*.tar.gz"))[-1]
print("Checking", dist, "with twine ...")
try:
    subprocess.check_call(["twine", "check", dist])
except subprocess.CalledProcessError as e:
    print("Twine check failed with exit code", e.returncode, file=sys.stderr)
    sys.exit(e.returncode)
PY

echo
echo "Done."
