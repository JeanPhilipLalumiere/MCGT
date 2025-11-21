#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: bash twine_fix_v2.sh [/path/to/repo]
REPO="${1:-$(pwd)}"
cd "$REPO"

echo "==> Repo: $REPO"

if [[ ! -f pyproject.toml ]]; then
  echo "Erreur: pyproject.toml introuvable dans $REPO" >&2
  exit 2
fi

# 0) Affiche versions utiles
python3 -V || true
python3 - <<'PY'
import importlib, sys
def ver(pkg):
    try:
        m = importlib.import_module(pkg)
        v = getattr(m, "__version__", "?")
        print(f"{pkg}=={v}")
    except Exception as e:
        print(f"{pkg} (non installé)")
for p in ("build","twine","setuptools","pkginfo","readme_renderer","packaging"):
    ver(p)
PY

# 1) Met à jour twine/pkginfo (tolère absence de réseau)
python3 -m pip install -U --disable-pip-version-check --no-input twine pkginfo readme-renderer packaging >/dev/null 2>&1 || true

# 2) Sauvegarde pyproject.toml
BKP="pyproject.toml.twinetmp.$(date +%s)"
cp -f pyproject.toml "$BKP"
echo "Backup -> $BKP"

# 3) Patch pyproject.toml (license = { text = "MIT" } et nettoyage dynamic)
python3 - "$BKP" <<'PY'
import sys, re, io, os
p="pyproject.toml"
s=open(p,'r',encoding='utf-8').read()

def block_bounds(text, header):
    m = re.search(r'(?m)^\s*\[' + re.escape(header) + r'\]\s*$', text)
    if not m: 
        return None
    start = m.start()
    n = re.search(r'(?m)^\s*\[[^\]]+\]\s*$', text[m.end():])
    end = len(text) if not n else m.end()+n.start()
    return start, end

b = block_bounds(s,'project')
if not b:
    print("! section [project] introuvable, aucun patch appliqué", file=sys.stderr)
else:
    head, body, rest = s[:b[0]], s[b[0]:b[1]], s[b[1]:]
    # 3.1) license = "..."  ->  license = { text = "..." }
    pat = re.compile(r'(?m)^(?P<i>\s*)license\s*=\s*"(?P<v>[^"]+)"\s*$')
    if pat.search(body):
        body = pat.sub(lambda m: f'{m.group("i")}license = {{ text = "{m.group("v")}" }}', body)
    else:
        # si aucune clé license, insère { file = "LICENSE" } après name/version si possible
        if not re.search(r'(?m)^\s*license\s*=', body):
            ins = '\nlicense = { file = "LICENSE" }\n'
            m = re.search(r'(?m)^\s*(name|version)\s*=.*$', body)
            idx = m.end() if m else 0
            body = body[:idx] + ins + body[idx:]
    # 3.2) retire "license" et "license-file" de dynamic (si présents)
    dyn = re.search(r'(?ms)^\s*dynamic\s*=\s*\[(?P<body>.*?)\]\s*$', body)
    if dyn:
        body_content = dyn.group('body')
        # éclate par virgules hors crochets
        parts = [p.strip() for p in re.split(r',(?![^\[]*\])', body_content) if p.strip()]
        cleaned = []
        for p in parts:
            token = re.sub(r'["\']','',p).strip()
            if token not in ('license','license-file'):
                cleaned.append(p)
        new_line = 'dynamic = [' + (', '.join(cleaned)) + ']'
        body = body[:dyn.start()] + re.sub(r'(?ms)^\s*dynamic\s*=\s*\[.*?\]\s*$', new_line, body[dyn.start():dyn.end()]) + body[dyn.end():]
        body = body.replace('dynamic = []', '# dynamic (empty) removed by script')
    s = head + body + rest
    with open(p,'w',encoding='utf-8') as f:
        f.write(s)
    print("pyproject.toml patché.")

PY

# 4) Build sdist propre
python3 -m build --sdist

# 5) Chemin de l’archive
SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
echo "sdist: $SDIST"

# 6) Trouve PKG-INFO dans l’archive
PKGINFO="$(tar -tf "$SDIST" | grep -E '/PKG-INFO$' | head -n1 || true)"
if [[ -z "${PKGINFO:-}" ]]; then
  echo "!! PKG-INFO introuvable dans l’archive (inhabituel)"
else
  echo -e "\n=== Inspect PKG-INFO (head) ==="
  tar -xOf "$SDIST" "$PKGINFO" | sed -n '1,40p'
  # Vérifie l’absence de License-Expression (PEP 639) pour compat Twine anciens
  if tar -xOf "$SDIST" "$PKGINFO" | grep -q '^License-Expression:'; then
    echo "!! Alerte: 'License-Expression' encore présent — Twine ancien peut échouer"
  fi
fi

# 7) twine check (avec chemin correctement quoté)
echo -e "\n=== Run twine check ==="
python3 -m twine check "$SDIST" || {
  echo "Twine check a échoué. Revenir au backup: $BKP"
  # On laisse le backup pour restauration manuelle si besoin
  exit 1
}

echo "OK: twine check passé."
