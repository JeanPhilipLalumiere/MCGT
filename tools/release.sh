#!/usr/bin/env bash
set -euo pipefail

VER_NEXT="${1:?Usage: tools/release.sh <new-version>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 0) prérequis TWINE (token project/org)
: "${TWINE_USERNAME:=__token__}"
: "${TWINE_PASSWORD:?TWINE_PASSWORD (token PyPI) manquant}"

echo "[release] bump -> ${VER_NEXT}"

# 1) bump version (pyproject + __init__)
sed -i -E "s/^version = \".*\"/version = \"${VER_NEXT}\"/" pyproject.toml
sed -i -E "s/__version__ = \".*\"/__version__ = \"${VER_NEXT}\"/" zz_tools/__init__.py
git add -A
git commit -m "chore(version): ${VER_NEXT}"
git push origin main

# 2) build propre
rm -rf dist build *.egg-info
python -m build

# 3) sanitizer PEP639 (wheel + sdist)
python - <<'PY'
import re, zipfile, tarfile, tempfile, pathlib, hashlib, base64, csv, io, shutil
DIST = pathlib.Path("dist")
PAT  = re.compile(r"^(?:License-Expression|License-File|Dynamic\s*:).*$", re.I|re.M)
def strip_meta(t): o="\n".join(ln for ln in t.splitlines() if not PAT.match(ln)); return o if o.endswith("\n") else o+"\n"
def fix_wheel(p: pathlib.Path):
    with zipfile.ZipFile(p,"r") as zin:
        names=zin.namelist()
        meta=[n for n in names if n.endswith(".dist-info/METADATA")][0]
        rec = meta.rsplit(".dist-info/",1)[0]+".dist-info/RECORD"
        rows=[]; cleaned=strip_meta(zin.read(meta).decode("utf-8","replace")).encode()
        for n in names: rows.append((n, cleaned if n==meta else zin.read(n)))
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
            if m.name.endswith("/PKG-INFO"): pkginfo=m.name; break
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

# 4) vérification + upload
twine check dist/*
twine upload dist/*

# 5) sonde /simple (pip)
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

echo "[release] terminé: ${VER_NEXT}"
echo "Astuce: tag -> git tag -a v${VER_NEXT} -m 'Release ${VER_NEXT}' && git push origin v${VER_NEXT}"
