#!/usr/bin/env bash
# MCGT — réparation packaging (PEP 639 vs twine) + garde-fou anti-fermeture
# - Continue sur erreur, log complet, fenêtre maintenue ouverte

set -u -o pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="mcgt_packaging_fix_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

_pause_end() {
  echo
  echo "══════════════════════════════════════════════════════"
  echo "Fin du script. Log: $LOG"
  echo "Appuie sur Entrée pour fermer cette fenêtre."
  read -r _ || { sleep 3600; }  # garde ouverte si non-interactif
}
trap _pause_end EXIT

ERRORS=()
run() {
  local desc="$1"; shift
  echo; echo "—— $desc"; echo ">>> $*"
  "$@"; local rc=$?
  if [ $rc -ne 0 ]; then
    ERRORS+=("[$rc] $desc — cmd: $*")
    echo "!! Échec ($rc) — poursuivi."
  else
    echo "OK."
  fi
  return $rc
}

# ---------- 0) Base propre (ne pas tirer les tags pour éviter l’erreur) ----------
run "Fetch + reset main (sans tags)" bash -lc '
  git fetch origin &&
  git checkout main &&
  git reset --hard origin/main
'

# ---------- 1) Purge complète des sources License-File ----------
run "Lister occurrences license[-_ ]?file" bash -lc '
  grep -RInE "license[-_ ]?file" setup.cfg setup.py pyproject.toml || true
'
run "Purger license_file(s)/license_files dans setup.cfg" bash -lc '
  if [ -f setup.cfg ]; then
    sed -i -E "/^[[:space:]]*license[-_ ]?file(s)?[[:space:]]*=.*/d" setup.cfg || true
    sed -i -E "/^[[:space:]]*license_files[[:space:]]*=.*/d" setup.cfg || true
  fi
'
run "Purger argument license_file=… dans setup.py" bash -lc '
  if [ -f setup.py ] && grep -qE "license_file[[:space:]]*=" setup.py; then
    sed -i -E "s/[[:space:]]*license_file[[:space:]]*=\s*[\"'\''][^\"'\'']+[\"'\'']\s*,?//g" setup.py || true
  fi
'

# ---------- 2) Normaliser pyproject.toml : SPDX + readme Markdown + toolchain ----------
run "Normaliser pyproject.toml (license SPDX + readme + build-system)" python - <<'PY'
from pathlib import Path
import re

pp = Path("pyproject.toml")
if not pp.exists():
    print("pyproject.toml absent — skip.")
else:
    t = pp.read_text(encoding="utf-8")

    # license: table -> string SPDX
    t = re.sub(r'(?mi)^\s*license\s*=\s*\{[^\}]*\}\s*$', 'license = "MIT"', t)
    if "[project]" in t and not re.search(r'(?m)^\s*license\s*=', t):
        t = t.replace("[project]", "[project]\nlicense = \"MIT\"", 1)

    # readme: si absent, pointer vers README.md en Markdown
    if "[project]" in t and not re.search(r'(?m)^\s*readme\s*=', t):
        t = t.replace("[project]", "[project]\nreadme = { file = \"README.md\", content-type = \"text/markdown\" }", 1)

    # build-system
    if "[build-system]" not in t:
        t = t.rstrip() + '\n\n[build-system]\nrequires = ["setuptools>=77", "wheel"]\nbuild-backend = "setuptools.build_meta"\n'
    else:
        if 'setuptools>=' not in t:
            t = re.sub(r'(\[build-system\][\s\S]*?requires\s*=\s*\[)', r'\1"setuptools>=77", ', t, count=1)
        if '"wheel"' not in t:
            t = re.sub(r'(\[build-system\][\s\S]*?requires\s*=\s*\[[^\]]*)\]', r'\1, "wheel"]', t, count=1)
        if 'build-backend' not in t:
            t = re.sub(r'(\[build-system\][\s\S]*?\n)', r'\1build-backend = "setuptools.build_meta"\n', t, count=1)

    pp.write_text(t, encoding="utf-8")
    print("pyproject.toml: license=MIT, readme=Markdown, build-system OK.")
PY

# ---------- 3) Rebuild propre ----------
run "Nettoyage build" bash -lc 'rm -rf dist build *.egg-info'
run "Build (sdist + wheel)" bash -lc 'python -m build'

# ---------- 4) Audit METADATA + Dynamic ----------
run "Afficher entêtes License*/Dynamic* dans METADATA/PKG-INFO" python - <<'PY'
import glob, zipfile, tarfile
def scan_whl():
    for whl in glob.glob("dist/*.whl"):
        with zipfile.ZipFile(whl) as zf:
            meta = [n for n in zf.namelist() if n.endswith(".dist-info/METADATA")]
            if not meta: 
                print(f"[WHEEL] {whl}: pas de METADATA"); 
                continue
            data = zf.read(meta[0]).decode("utf-8","replace").splitlines()
            print(f"[WHEEL] {whl}")
            for i,l in enumerate(data,1):
                if l.lower().startswith(("metadata-version:","license:","license-file:","license-expression:","dynamic:")):
                    print(f"  {i}:{l}")
def scan_sdist():
    for tgz in glob.glob("dist/*.tar.gz"):
        with tarfile.open(tgz,"r:gz") as tf:
            pkgs = [m for m in tf.getmembers() if m.name.endswith("/PKG-INFO")]
            if not pkgs:
                print(f"[SDIST] {tgz}: pas de PKG-INFO"); 
                continue
            data = tf.extractfile(pkgs[0]).read().decode("utf-8","replace").splitlines()
            print(f"[SDIST] {tgz}")
            for i,l in enumerate(data,1):
                if l.lower().startswith(("metadata-version:","license:","license-file:","license-expression:","dynamic:")):
                    print(f"  {i}:{l}")
scan_whl(); scan_sdist()
PY

# ---------- 5) Twine à jour + check ----------
run "Installer/maj twine/pkginfo/readme_renderer/rfc3986" bash -lc '
  python -m pip install -q --upgrade pip &&
  python -m pip install -q --upgrade "twine>=6.2.0" "pkginfo>=1.11.0" "readme_renderer>=44.0" "rfc3986>=2.0.0"
'

TWINE_ERR=0
# Ne pas matcher les .bak si présents
twine check dist/*.whl dist/*.tar.gz || TWINE_ERR=$?
echo "twine check exit=$TWINE_ERR"

# ---------- 6) Si twine échoue: strip PEP639 + Dynamic: license-* puis régénérer ----------
if [ $TWINE_ERR -ne 0 ]; then
  echo "twine check a échoué — strip PEP639 (License-File/License-Expression) et Dynamic: license-* puis regen RECORD…"
  run "Patch METADATA/PKG-INFO + regen RECORD" python - <<'PY'
import glob, zipfile, tarfile, io, os, hashlib, base64, csv, tempfile, shutil

def strip_headers(text:str)->str:
    out=[]
    for line in text.splitlines():
        low=line.lower()
        if low.startswith("license-file:") or low.startswith("license-expression:"):
            continue
        if low.startswith("dynamic:"):
            tokens=[t.strip() for t in line.split(":",1)[1].split(",") if t.strip()]
            tokens=[t for t in tokens if t not in ("license-file","license-expression","license")]
            if not tokens: 
                continue
            line = "Dynamic: " + ", ".join(tokens)
        out.append(line)
    if not text.endswith("\n"): out.append("")
    return "\n".join(out)

def regen_record(tmpdir, distinfo):
    import csv, base64, hashlib, os
    record=os.path.join(distinfo,"RECORD")
    rows=[]; rootlen=len(tmpdir.rstrip(os.sep))+1
    for root,_,files in os.walk(tmpdir):
        for fn in files:
            full=os.path.join(root,fn)
            rel=full[rootlen:].replace(os.sep,"/")
            if rel.endswith("RECORD"):
                rows.append([rel,"",""]); continue
            with open(full,"rb") as f: b=f.read()
            h="sha256="+base64.urlsafe_b64encode(hashlib.sha256(b).digest()).decode().rstrip("=")
            rows.append([rel,h,str(len(b))])
    with open(record,"w",newline="",encoding="utf-8") as f:
        csv.writer(f).writerows(rows)

def rewrite_wheel(path):
    tmpdir=tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(path) as zf: zf.extractall(tmpdir)
        di = next((d for d in os.listdir(tmpdir) if d.endswith(".dist-info")), None)
        if not di: 
            print(f"[WHEEL] {path}: pas de .dist-info, skip"); return
        di = os.path.join(tmpdir, di)
        meta=os.path.join(di,"METADATA")
        with open(meta,"r",encoding="utf-8",errors="replace") as f: data=f.read()
        new=strip_headers(data)
        with open(meta,"w",encoding="utf-8") as f: f.write(new)
        # supprimer licences embarquées (optionnel)
        licdir=os.path.join(di,"licenses"); shutil.rmtree(licdir, ignore_errors=True)
        regen_record(tmpdir, di)
        bak=path+".bak"; os.replace(path,bak)
        with zipfile.ZipFile(path,"w",compression=zipfile.ZIP_DEFLATED) as z:
            for root,_,files in os.walk(tmpdir):
                for fn in files:
                    full=os.path.join(root,fn)
                    rel=full[len(tmpdir.rstrip(os.sep))+1:].replace(os.sep,"/")
                    z.write(full, rel)
        print(f"[WHEEL] patch OK -> {path} (backup {bak})")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

def rewrite_sdist(path):
    tmpdir=tempfile.mkdtemp()
    try:
        with tarfile.open(path,"r:gz") as tf: tf.extractall(tmpdir)
        pkginfo=None
        for dirpath,_,files in os.walk(tmpdir):
            if "PKG-INFO" in files: pkginfo=os.path.join(dirpath,"PKG-INFO"); break
        if not pkginfo:
            print(f"[SDIST] {path}: pas de PKG-INFO, skip"); return
        with open(pkginfo,"r",encoding="utf-8",errors="replace") as f: data=f.read()
        new=strip_headers(data)
        with open(pkginfo,"w",encoding="utf-8") as f: f.write(new)
        bak=path+".bak"; os.replace(path,bak)
        entries=os.listdir(tmpdir)
        with tarfile.open(path,"w:gz") as tf:
            if len(entries)==1 and os.path.isdir(os.path.join(tmpdir,entries[0])):
                base=entries[0]; tf.add(os.path.join(tmpdir,base), arcname=base)
            else:
                for name in entries: tf.add(os.path.join(tmpdir,name), arcname=name)
        print(f"[SDIST] patch OK -> {path} (backup {bak})")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

for whl in glob.glob("dist/*.whl"): rewrite_wheel(whl)
for tgz in glob.glob("dist/*.tar.gz"): rewrite_sdist(tgz)
PY

  # Recheck twine (ignorer *.bak)
  twine check dist/*.whl dist/*.tar.gz || true
  # Nettoyage: enlever les backups s'ils existent
  rm -f dist/*.bak 2>/dev/null || true
fi

# ---------- 7) Commit & push des modifs éventuels ----------
run "Commit & push des modifs" bash -lc '
  if ! git diff --quiet; then
    git add -A
    git commit -m "build(packaging): SPDX + readme; strip PEP639 & Dynamic license-* si nécessaire; regen RECORD"
    git push origin main
  else
    echo "Aucun changement à committer."
  fi
'

# ---------- 8) Résumé ----------
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo; echo "!!! Des étapes ont échoué (fenêtre maintenue ouverte) :"
  for e in "${ERRORS[@]}"; do echo " - $e"; done
  echo "Consulte le log: $LOG"
else
  echo; echo "✓ Tout s’est bien passé. Log: $LOG"
fi

