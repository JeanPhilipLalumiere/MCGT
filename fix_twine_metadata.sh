#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Diagnose Twine metadata issue: locating unsupported fields ==="
grep -RinE '^[[:space:]]*(license[-_ ]?expression|license[-_ ]?file)[[:space:]]*=' setup.cfg pyproject.toml 2>/dev/null || true

echo
echo "=== Patch setup.cfg (remove non‑standard keys) ==="
if [[ -f setup.cfg ]]; then
  cp -n setup.cfg setup.cfg.bak || true
  # Drop any 'license-expression' style lines (non-standard for setuptools metadata)
  sed -i -E '/^[[:space:]]*license[-_ ]?expression[[:space:]]*=/Id' setup.cfg || true
  # Normalize 'license-file' (old/invalid) -> remove; setuptools uses 'license_files' and we will rely on pyproject instead
  sed -i -E '/^[[:space:]]*license[-_ ]?file[[:space:]]*=/Id' setup.cfg || true
fi

echo
echo "=== Patch pyproject.toml (PEP 621 license + setuptools license-files) ==="
if [[ -f pyproject.toml ]]; then
  cp -n pyproject.toml pyproject.toml.bak || true
  # Remove any legacy/non-standard keys if present
  sed -i -E '/^[[:space:]]*license[-_ ]?expression[[:space:]]*=/Id' pyproject.toml || true
  sed -i -E '/^[[:space:]]*license[-_ ]?file[[:space:]]*=/Id' pyproject.toml || true

  # Ensure [project].license exists; prefer file reference to keep metadata clean
  if ! awk '
    BEGIN{p=0; ok=0}
    /^\[project\]/{p=1; next}
    /^\[/{if(p==1) p=0}  # leaving [project]
    p==1 && /^[[:space:]]*license[[:space:]]*=/{ok=1}
    END{exit(ok?0:1)}
  ' pyproject.toml; then
    awk '
      BEGIN{done=0}
      /^\[project\]/{print; print "license = { file = \"LICENSE\" }"; done=1; next}
      {print}
      END{if(!done){print "[project]"; print "license = { file = \"LICENSE\" }"}}
    ' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
  fi

  # Ensure setuptools knows which files to package as license files
  if ! grep -qE '^\[tool\.setuptools\]' pyproject.toml; then
    printf '\n[tool.setuptools]\n' >> pyproject.toml
  fi
  if ! grep -qE '^license-files' pyproject.toml; then
    printf 'license-files = ["LICENSE","LICENSE-data"]\n' >> pyproject.toml
  fi
fi

echo
echo "=== Clean & rebuild sdist ==="
rm -rf dist build *.egg-info || true
python -m build --sdist

SDIST=$(ls -1t dist/*.tar.gz | head -n1)
echo "sdist: $SDIST"
echo

echo "=== Inspect PKG-INFO license headers (after patch) ==="
tar -xOf "$SDIST" */PKG-INFO | egrep -i '^(Metadata-Version|Name|Version|License|License-File|Classifier|Summary):' || true
echo

echo "=== Run twine check ==="
twine check "$SDIST" || true

echo
echo "=== (Optional) Trigger guard workflows on current branch if available ==="
if command -v gh >/dev/null 2>&1; then
  BR=$(git rev-parse --abbrev-ref HEAD)
  for wf in readme-guard.yml manifest-guard.yml guard-ignore-and-sdist.yml; do
    if [[ -f ".github/workflows/$wf" ]]; then
      echo "Triggering $wf on $BR..."
      gh workflow run "$wf" -r "$BR" || true
    fi
  done
fi

echo
echo "Done. Review the twine output above. If errors persist, run:"
echo "  tar -xOf \"$SDIST\" */PKG-INFO | sed -n '1,200p'"
