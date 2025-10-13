#!/usr/bin/env bash
set -euo pipefail

VER_NEXT="${1:?Usage: tools/release.sh <new-version>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 0) Pré-requis TWINE (token project/org)
: "${TWINE_USERNAME:=__token__}"
: "${TWINE_PASSWORD:?TWINE_PASSWORD (token PyPI) manquant}"

echo "[release] target -> ${VER_NEXT}"

# 1) Bump de version (robuste)
# pyproject.toml: remplace la ligne version = "..."
python - "$VER_NEXT" <<'PY'
import sys, re, pathlib
ver = sys.argv[1]
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")
s2 = re.sub(r'(?m)^(\\s*version\\s*=\\s*)".*?"(\\s*)$', rf'\\1"{ver}"\\2', s)
if s == s2:
    raise SystemExit("pyproject.toml: version non mise à jour (pattern non trouvé)")
p.write_text(s2, encoding="utf-8")
PY

# zz_tools/__init__.py: remplace __version__ = "..."
python - "$VER_NEXT" <<'PY'
import sys, re, pathlib
ver = sys.argv[1]
p = pathlib.Path("zz_tools/__init__.py")
s = p.read_text(encoding="utf-8")
if "__version__" not in s:
    s = s.rstrip() + f'\n__version__ = "{ver}"\n'
else:
    s = re.sub(r'(?m)^(__version__\\s*=\\s*)".*?"(\\s*)$', rf'\\1"{ver}"\\2', s)
p.write_text(s, encoding="utf-8")
PY

git add -A
git commit -m "chore(version): ${VER_NEXT}" || echo "[release] rien à committer (déjà à ${VER_NEXT}?)"
git push origin main || true

# 2) Build propre
rm -rf dist build *.egg-info
python -m build

# 3) Sanitizer PEP639 (strip License-Expression / License-File / Dynamic:*)
python - <<'PY'
import re, zipfile, tarfile, tempfile, pathlib, hashlib, base64, csv, io, shutil
DIST = pathlib.Path("dist")
PAT  = re.compile(r"^(?:License-Expression|License-File|Dynamic\\s*:).*$", re.I|re.M)
def strip_meta(t): 
    o = "\n".join(ln for ln in t.splitlines() if not PAT.match(ln))
    return o if o.endswith("\n") else o+"\n"
def fix_wheel(p: pathlib.Path):
    with zipfile.ZipFile(p,"r") as zin:
        names = zin.namelist()
        meta  = [n for n in names if n.endswith(".dist-info/METADATA")][0]
        rec   = meta.rsplit(".dist-info/",1)[0]+".dist-info/RECORD"
        rows  = []
        cleaned = strip_meta(zin.read(meta).decode("utf-8","replace")).encode()
        for n in names:
            rows.append((n, cleaned if n==meta else zin.read(n)))
    with zipfile.ZipFile(p,"w",compression=zipfile.ZIP_DEFLATED) as zout:
        for n,b in rows:
            if n==rec: continue
            zout.writestr(n,b)
        out=io.StringIO(); w=csv.writer(out)
        for n,b in rows:
            if n==rec: continue
            h=hashlib.sha256(b).digest()
            algo="sha256="+base64.urlsafe_b64encode(h).rstrip(b"=").decode()
            w.writerow([n,algo,str(len(b))])
        w.writerow([rec,"",""])
        zout.writestr(rec,out.getvalue())
def fix_sdist(p: pathlib.Path):
    tmp = pathlib.Path(tempfile.mkstemp(suffix=".tar.gz")[1])
    with tarfile.open(p,"r:gz") as tin, tarfile.open(tmp,"w:gz") as tout:
        pkginfo=None
        for m in tin.getmembers():
            if m.name.endswith("/PKG-INFO"):
                pkginfo=m.name; break
        for m in tin.getmembers():
            data = tin.extractfile(m).read() if m.isfile() else None
            if m.name==pkginfo and data is not None:
                data=strip_meta(data.decode("utf-8","replace")).encode()
                m.size=len(data)
            tout.addfile(m, io.BytesIO(data) if data is not None else None)
    shutil.move(tmp, p)
for whl in DIST.glob("*.whl"):    fix_wheel(whl)
for sd  in DIST.glob("*.tar.gz"): fix_sdist(sd)
print("Sanitizer: OK")
PY

# 4) Vérification + Upload
twine check dist/*
twine upload dist/*

# 5) Sondes de propagation côté /simple
VER="${VER_NEXT}"
deadline=$(( $(date +%s) + 300 ))
while :; do
  html="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 \
         "https://pypi.org/simple/zz-tools/?ts=$(date +%s)" || true)"
  echo "$html" | grep -q "$VER" && { echo "[release] visible dans /simple: $VER"; break; }
  [ "$(date +%s)" -ge "$deadline" ] && { echo "[release] Timeout /simple"; break; }
  echo "[release] en attente /simple..."
  sleep 5
done

echo "[release] terminé -> ${VER_NEXT}"
echo "Astuce: tag -> git tag -a v${VER_NEXT} -m 'Release ${VER_NEXT}' && git push origin v${VER_NEXT}"
