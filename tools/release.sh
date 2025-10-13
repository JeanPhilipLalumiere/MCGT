#!/usr/bin/env bash
# MCGT — release helper (bump → build → sanitize → check → upload → probe → smoke)
# - Garde-fou: la fenêtre reste ouverte à la fin, même en cas d’erreur
# - Logs complets (tee vers un fichier horodaté)
# - Bump robuste (pyproject + __init__)
# - Sanitize PEP 639 (strip License-Expression/License-File/Dynamic:*)
# - Probes PyPI JSON & /simple avec contournement cache
# - Smoke install robuste (boucle retries + --no-cache-dir)

set -euo pipefail

# ─── LOGGING / GUARDED EXIT ────────────────────────────────────────────────────
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="release_${1:-UNKNOWN}_${TS}.log"

exec > >(tee -a "$LOG") 2>&1

_pause_end() {
  rc=$?
  echo
  echo "══════════════════════════════════════════════════════"
  echo "Fin du script (rc=$rc). Log: $LOG"
  # Pause toujours, même en non-interactif (sleep fallback)
  read -r -p "Appuie sur Entrée pour fermer cette fenêtre (ou Ctrl+C) " _ || sleep 3600
}
trap _pause_end EXIT

# ─── HELPERS ───────────────────────────────────────────────────────────────────
die() { echo "ERROR: $*" >&2; exit 1; }

req() {
  local name="$1"
  command -v "$name" >/dev/null 2>&1 || die "Commande requise manquante: $name"
}

# Petite exécution “verbeuse” qui échoue dur
run() {
  local desc="$1"; shift
  echo; echo "[RUN] $desc"
  echo ">>> $*"
  "$@"
  echo "OK."
}

# ─── PRECHECKS ─────────────────────────────────────────────────────────────────
VER_NEXT="${1:?Usage: tools/release.sh <new-version>}"
: "${TWINE_USERNAME:=__token__}"
: "${TWINE_PASSWORD:?TWINE_PASSWORD (token PyPI) manquant}"

for bin in python git twine curl; do req "$bin"; done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
echo "[release] target -> ${VER_NEXT}"
echo "[cwd] $ROOT"
echo "[log] $LOG"

# S’assurer que 'main' a un upstream pour push
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "[git] configure upstream -> origin/main"
  git branch --set-upstream-to=origin/main main || true
else
  echo "[git] upstream déjà configuré pour 'main'"
fi

# ─── 1) BUMP VERSION (pyproject + __init__) ────────────────────────────────────
# pyproject.toml
python - "$VER_NEXT" <<'PY'
import sys, re, pathlib
ver = sys.argv[1]
p   = pathlib.Path("pyproject.toml")
s   = p.read_text(encoding="utf-8")
s2  = re.sub(r'(?m)^(\s*version\s*=\s*)".*?"(\s*)$', rf'\1"{ver}"\2', s)
if s == s2:
    print("pyproject.toml: version non mise à jour (pattern non trouvé)")
    sys.exit(1)
p.write_text(s2, encoding="utf-8")
print("pyproject.toml -> version mise à jour")
PY

# zz_tools/__init__.py
python - "$VER_NEXT" <<'PY'
import sys, re, pathlib
ver = sys.argv[1]
p   = pathlib.Path("zz_tools/__init__.py")
s   = p.read_text(encoding="utf-8")
s2  = re.sub(r'(?m)^(__version__\s*=\s*)".*?"(\s*)$', rf'\1"{ver}"\2', s)
if s == s2:
    # Si le champ n’existe pas, on l’ajoute en fin de fichier.
    if "__version__" not in s:
        s2 = s.rstrip() + f'\n__version__ = "{ver}"\n'
    else:
        print("__init__.py: version non mise à jour (pattern non trouvé)")
        sys.exit(1)
p.write_text(s2, encoding="utf-8")
print("__init__.py -> version mise à jour")
PY

# Commit/push si modifs
if ! git diff --quiet --cached || ! git diff --quiet; then
  run "Commit bump ${VER_NEXT}" git add -A
  run "Git commit" git commit -m "chore(version): ${VER_NEXT}"
  run "Git push"   git push origin main
else
  echo "[git] rien à committer"
  git push || true
fi

# ─── 2) BUILD PROPRE ───────────────────────────────────────────────────────────
run "Nettoyage build" bash -lc 'rm -rf dist build *.egg-info'
run "Build (sdist + wheel)" python -m build

# ─── 3) SANITIZER (strip PEP639 + Dynamic) ─────────────────────────────────────
python - <<'PY'
import re, zipfile, tarfile, tempfile, pathlib, hashlib, base64, csv, io, shutil, sys
DIST = pathlib.Path("dist")
PAT  = re.compile(r"^(?:License-Expression|License-File|Dynamic\s*:).*$", re.I|re.M)

def strip_meta(txt: str) -> str:
    out = "\n".join(ln for ln in txt.splitlines() if not PAT.match(ln))
    return out if out.endswith("\n") else out + "\n"

def fix_wheel(p: pathlib.Path):
    with zipfile.ZipFile(p, "r") as zin:
        names   = zin.namelist()
        meta    = [n for n in names if n.endswith(".dist-info/METADATA")][0]
        rec     = meta.rsplit(".dist-info/", 1)[0] + ".dist-info/RECORD"
        rows    = []
        cleaned = strip_meta(zin.read(meta).decode("utf-8", "replace")).encode()
        for n in names:
            rows.append((n, cleaned if n == meta else zin.read(n)))
    with zipfile.ZipFile(p, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for n, b in rows:
            if n == rec:  # on écrit RECORD à la fin
                continue
            zout.writestr(n, b)
        # RECORD régénéré
        out = io.StringIO(); w = csv.writer(out)
        for n, b in rows:
            if n == rec: continue
            h = hashlib.sha256(b).digest()
            algo = "sha256=" + base64.urlsafe_b64encode(h).rstrip(b"=").decode()
            w.writerow([n, algo, str(len(b))])
        w.writerow([rec, "", ""])
        zout.writestr(rec, out.getvalue().encode("utf-8"))

def fix_sdist(p: pathlib.Path):
    # Retire champs PEP639 du PKG-INFO (sdist)
    tmp = pathlib.Path(tempfile.mkdtemp())
    try:
        with tarfile.open(p, "r:gz") as tf:
            tf.extractall(tmp)
        # Trouver PKG-INFO
        pkg_info = None
        for q in tmp.rglob("PKG-INFO"):
            if q.is_file():
                pkg_info = q; break
        if not pkg_info:
            return
        txt = pkg_info.read_bytes().decode("utf-8","replace")
        cleaned = strip_meta(txt)
        pkg_info.write_text(cleaned, encoding="utf-8")
        # Recréer tar.gz
        newp = p.with_suffix(".tar.gz.tmp")
        with tarfile.open(newp, "w:gz") as out:
            root = next(tmp.iterdir())  # dossier racine
            out.add(root, arcname=root.name, recursive=True)
        shutil.move(str(newp), str(p))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

wheels = list(DIST.glob("*.whl"))
sdists = list(DIST.glob("*.tar.gz"))

for whl in wheels: fix_wheel(whl)
for sd in sdists:  fix_sdist(sd)

print("Sanitizer: OK")
PY

# ─── 4) TWINE CHECK ────────────────────────────────────────────────────────────
run "twine check" twine check dist/*.whl dist/*.tar.gz

# ─── 5) UPLOAD PyPI ────────────────────────────────────────────────────────────
run "Upload PyPI (twine)" twine upload dist/*.whl dist/*.tar.gz

# ─── 6) PROBE PyPI: JSON puis /simple (cache-busting) ─────────────────────────
VER="${VER_NEXT}"
deadline_json=$(( $(date +%s) + 180 ))
while :; do
  body="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 \
          "https://pypi.org/pypi/zz-tools/json?ts=$(date +%s)" || true)"
  status="$(
    BODY="$body" python - "$VER" <<'PY'
import os, sys, json
ver = sys.argv[1]
try:
    data = json.loads(os.environ.get("BODY") or "{}")
    print("FOUND" if ver in data.get("releases", {}) else "MISS")
except Exception:
    print("MISS")
PY
  )"
  [ "$status" = "FOUND" ] && { echo "PyPI JSON: ${VER} visible."; break; }
  [ "$(date +%s)" -ge "$deadline_json" ] && { echo "Timeout PyPI JSON"; break; }
  echo "PyPI JSON: pas encore visible; retry…"; sleep 5
done

deadline_simple=$(( $(date +%s) + 300 ))
while :; do
  html="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 \
         "https://pypi.org/simple/zz-tools/?ts=$(date +%s)" || true)"
  echo "$html" | grep -q "$VER" && { echo "PyPI /simple: ${VER} visible."; break; }
  [ "$(date +%s)" -ge "$deadline_simple" ] && { echo "Timeout index /simple"; break; }
  echo "PyPI /simple: pas encore visible; retry…"; sleep 5
done

# ─── 7) SMOKE INSTALL (venv jetable, retries, no-cache) ───────────────────────
echo "# -- SMOKE INSTALL --"
tmpdir="$(mktemp -d)"; echo "TMP = $tmpdir"
python -m venv "$tmpdir/.venv-smoke"
# shellcheck disable=SC1090
source "$tmpdir/.venv-smoke/bin/activate"
python -m pip cache purge || true
python -m pip install -U pip

OK=0
for i in $(seq 1 30); do
  echo "[try $i/30] pip install zz-tools==${VER} (no-cache)…"
  if python -m pip install --no-cache-dir --index-url https://pypi.org/simple "zz-tools==${VER}"; then
    OK=1; break
  fi
  echo "…pas encore propagé; retry dans 5s"
  sleep 5
done

if [ "$OK" -ne 1 ]; then
  echo "Smoke install échouée après retries (latence CDN probable)."
  # On n’échoue pas le script pour te laisser consulter le log; commente la ligne suivante si tu veux hard-fail :
  # exit 1
else
  python - <<'PY'
import zz_tools, importlib.util, sys
print("__version__ =", getattr(zz_tools, "__version__", "unknown"))
print("module path =", zz_tools.__file__)
print("find_spec ok  =", bool(importlib.util.find_spec("zz_tools")))
print("loaded from current venv:", zz_tools.__file__.startswith(sys.prefix))
PY
fi

deactivate || true
echo "Log fin: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
