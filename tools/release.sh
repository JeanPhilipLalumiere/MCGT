#!/usr/bin/env bash
# Release MCGT zz-tools — bump/build/sanitize/check/upload/probe
# Garde-fou: la fenêtre reste ouverte en fin, même en cas d’échec.
set -euo pipefail

VER_NEXT="${1:?Usage: tools/release.sh <new-version>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="release_${VER_NEXT}_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

_pause_end() {
  local rc=$?
  echo
  echo "══════════════════════════════════════════════════════"
  echo "Fin du script (rc=$rc). Log: $LOG"
  echo "Appuie sur Entrée pour fermer cette fenêtre (ou Ctrl+C)."
  read -r _ || sleep 3600
}
trap _pause_end EXIT INT

: "${TWINE_USERNAME:=__token__}"
: "${TWINE_PASSWORD:?TWINE_PASSWORD (token PyPI) manquant}"

echo "[release] target -> ${VER_NEXT}"
echo "[cwd] $PWD"
echo "[log] $LOG"

# -------------------------------------------------------------------
# 0) S'assurer que la branche courante est poussable (upstream auto)
branch="$(git rev-parse --abbrev-ref HEAD)"
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  echo "[git] upstream manquant pour '$branch' — configuration…"
  git push -u origin "$branch"
else
  echo "[git] upstream déjà configuré pour '$branch'"
fi

# -------------------------------------------------------------------
# 1) Bump version — robuste sur la section [project] de pyproject.toml
python - "$VER_NEXT" <<'PY'
import sys, re, pathlib
ver = sys.argv[1]
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")

# On isole la section [project]
m = re.search(r'(?ms)^\[project\]\s*(.*?)^(?=\[|\Z)', s)
if not m:
    raise SystemExit("[project] introuvable dans pyproject.toml")

block = m.group(1)
# Remplacer la 1ère occurrence de version = '...' / "..." (tolère espaces & commentaires)
new_block, n = re.subn(
    r'(?m)^(?P<pre>\s*version\s*=\s*)(?P<q>["\'])(?P<val>.*?)(?P=q)(?P<post>\s*(#.*)?)$',
    rf'\g<pre>"{ver}"\g<post>',
    block,
    count=1
)
if n == 0:
    raise SystemExit('pyproject.toml: ligne version = "..." non trouvée dans [project]')

s2 = s[:m.start(1)] + new_block + s[m.end(1):]
p.write_text(s2, encoding="utf-8")
print("pyproject.toml -> version mise à jour")

# __init__.py
pi = pathlib.Path("zz_tools/__init__.py")
si = pi.read_text(encoding="utf-8")
si2, n2 = re.subn(
    r'(?m)^(?P<pre>\s*__version__\s*=\s*)(?P<q>["\'])(?P<val>.*?)(?P=q)(?P<post>\s*(#.*)?)$',
    rf'\g<pre>"{ver}"\g<post>',
    si,
    count=1
)
if n2 == 0:
    raise SystemExit('__init__.py: __version__ = "..." non trouvé')

pi.write_text(si2, encoding="utf-8")
print("__init__.py -> version mise à jour")
PY

git add -A
git commit -m "chore(version): ${VER_NEXT}" || echo "[git] rien à committer"
git push

# -------------------------------------------------------------------
# 2) Build propre
rm -rf dist build *.egg-info
python -m build

# -------------------------------------------------------------------
# 3) Sanitizer post-build (strip PEP639 + Dynamic: ; regen RECORD)
python - <<'PY'
import re, zipfile, tarfile, tempfile, pathlib, hashlib, base64, csv, io, shutil
DIST=pathlib.Path("dist")
PAT=re.compile(r"^(?:License-Expression|License-File|Dynamic\s*:).*$", re.I|re.M)

def strip_meta(t:str)->str:
    o="\n".join(ln for ln in t.splitlines() if not PAT.match(ln))
    return o if o.endswith("\n") else o+"\n"

def fix_wheel(p: pathlib.Path):
    with zipfile.ZipFile(p,"r") as z:
        ns=z.namelist()
        m=[n for n in ns if n.endswith(".dist-info/METADATA")][0]
        r=m.rsplit(".dist-info/",1)[0]+".dist-info/RECORD"
        rows=[]; cleaned=strip_meta(z.read(m).decode("utf-8","replace")).encode()
        for n in ns:
            rows.append((n, cleaned if n==m else z.read(n)))
    with zipfile.ZipFile(p,"w",compression=zipfile.ZIP_DEFLATED) as z:
        for n,b in rows:
            if n==r: continue
            z.writestr(n,b)
        out=io.StringIO(); w=csv.writer(out)
        for n,b in rows:
            if n==r: continue
            h=hashlib.sha256(b).digest()
            w.writerow([n, "sha256="+base64.urlsafe_b64encode(h).rstrip(b"=").decode(), str(len(b))])
        w.writerow([r,"",""])
        z.writestr(r, out.getvalue())

def fix_sdist(p: pathlib.Path):
    tmp=tempfile.mkdtemp(); tmp_out=tempfile.mkdtemp()
    try:
        with tarfile.open(p,"r:gz") as tin:
            tin.extractall(tmp)
        root = next(pathlib.Path(tmp).iterdir())
        meta_p = root/"PKG-INFO"
        meta = meta_p.read_bytes().decode("utf-8","replace")
        meta_p.write_text(strip_meta(meta), encoding="utf-8")
        out = pathlib.Path(tmp_out)/p.name
        with tarfile.open(out,"w:gz") as tout:
            tout.add(root, arcname=root.name)
        shutil.copy2(out, p)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        shutil.rmtree(tmp_out, ignore_errors=True)

for whl in DIST.glob("*.whl"): fix_wheel(whl)
for sd  in DIST.glob("*.tar.gz"): fix_sdist(sd)
print("Sanitizer: OK")
PY

# -------------------------------------------------------------------
# 4) Vérif & upload PyPI
twine check dist/*.whl dist/*.tar.gz
twine upload dist/*.whl dist/*.tar.gz

# -------------------------------------------------------------------
# 5) Sonde l’index /simple jusqu’à visibilité
python - "$VER_NEXT" <<'PY'
import sys, time, urllib.request
ver=sys.argv[1]
url="https://pypi.org/simple/zz-tools/"
deadline=time.time()+300
while True:
    try:
        with urllib.request.urlopen(url) as r:
            html=r.read().decode()
        if ver in html:
            print(f"Visible in /simple: {ver}")
            break
    except Exception:
        pass
    if time.time()>deadline:
        raise SystemExit("Timeout index /simple")
    time.sleep(5)
PY

# -------------------------------------------------------------------
# 6) Smoke test (hors repo)
tmpdir="$(mktemp -d)"
python -m venv "$tmpdir/.venv-smoke"
source "$tmpdir/.venv-smoke/bin/activate"
python -m pip install -U pip >/dev/null
python -m pip install --no-cache-dir "zz-tools==${VER_NEXT}"
python - <<'PY'
import zz_tools, importlib.util, sys
print("__version__ =", getattr(zz_tools, "__version__", "unknown"))
print("module path =", zz_tools.__file__)
print("find_spec ok  =", bool(importlib.util.find_spec("zz_tools")))
print("loaded from current venv:", zz_tools.__file__.startswith(sys.prefix))
PY
deactivate

# -------------------------------------------------------------------
# 7) Tag
git tag -a "v${VER_NEXT}" -m "Release ${VER_NEXT}"
git push origin "v${VER_NEXT}"

echo "[release] done."
