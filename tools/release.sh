#!/usr/bin/env bash
# tools/release.sh — Release E2E idempotente pour zz-tools / MCGT
# - Bump version (tolérant si déjà à jour)
# - Pré-check PyPI (skip build/upload si la version existe déjà)
# - Build sdist+wheel
# - Sanitizer METADATA (strip PEP639/Dynamic) + RECORD/PKG-INFO
# - twine check + upload
# - Sondes JSON & /simple (sans pipe dans if)
# - Smoke install (venv jetable, pip no-cache + retries)
# - Pause anti-fermeture en fin, même en cas d’erreur
set -euo pipefail

VER_NEXT="${1:-}"
if [[ -z "${VER_NEXT}" ]]; then
  echo "Usage: $0 <new-version>"
  exit 2
fi

: "${TWINE_USERNAME:=__token__}"
: "${TWINE_PASSWORD:?TWINE_PASSWORD (token PyPI) manquant}"

: "${RELEASE_SANITIZE:=1}"      # 1=ON
: "${RELEASE_TAG:=0}"           # 1=crée/pousse le tag vX.Y.Z
: "${RELEASE_GH:=0}"            # 1=crée la release GitHub (si 'gh' configuré)
: "${RELEASE_NO_PAUSE:=0}"      # 1=désactive la pause finale
: "${RELEASE_TIMEOUT_JSON:=180}"
: "${RELEASE_TIMEOUT_SIMPLE:=180}"
: "${RELEASE_SMOKE_RETRIES:=30}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ---------- Journalisation & pause ----------
ts() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
LOG="release_${VER_NEXT}_$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$LOG") 2>&1

_pause() {
  local rc="$?"
  [[ "${RELEASE_NO_PAUSE}" == "1" ]] && { echo -e "\nFin (rc=${rc}). Log: $LOG"; return 0; }
  echo -e "\n══════════════════════════════════════════════════════"
  echo "Fin du script (rc=${rc}). Log: $LOG"
  read -r -p "Appuie sur Entrée pour fermer cette fenêtre (ou Ctrl+C) " _ || true
}
trap _pause EXIT

_run() {
  local title="$1"; shift
  echo -e "\n[RUN] ${title}\n>>> $*"
  "$@"
  echo "OK."
}

echo "[release] target -> ${VER_NEXT}"
echo "[cwd] $PWD"
echo "[log] $LOG"

# ---------- Git upstream ----------
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  echo "[git] upstream déjà configuré pour '$(git rev-parse --abbrev-ref HEAD)'"
else
  _run "Set upstream" git push --set-upstream origin "$(git rev-parse --abbrev-ref HEAD)"
fi

# ---------- Version actuelle ----------
CURRENT_IN_PYPROJECT="$(grep -m1 -E '^[[:space:]]*version[[:space:]]*=' pyproject.toml | sed -E 's/.*\"([^\"]+)\".*/\1/')"
echo "pyproject.toml: version actuelle = ${CURRENT_IN_PYPROJECT:-?}"

# ---------- Pré-check PyPI (JSON) ----------
is_on_pypi_json() {
  local ver="$1" body status
  body="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 "https://pypi.org/pypi/zz-tools/json?ts=$(date +%s)" || true)"
  status="$(python - "$ver" <<'PY' 2>/dev/null <<<"$body"
import sys, json
ver = sys.argv[1]
try:
    d = json.loads(sys.stdin.read())
    print("1" if ver in d.get("releases", {}) else "0")
except Exception:
    print("0")
PY
)"
  [[ "$status" == "1" ]] && return 0 || return 1
}

DO_BUILD_UPLOAD=1
if is_on_pypi_json "${VER_NEXT}"; then
  echo "[preflight] PyPI a déjà ${VER_NEXT} — skip build/upload."
  DO_BUILD_UPLOAD=0
fi

# ---------- Bump version (tolérant) ----------
bump_pyproject() {
  python - "$VER_NEXT" <<'PY' || true
import sys, re, pathlib
ver = sys.argv[1]
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")
m = re.search(r'(?m)^\s*version\s*=\s*"([^"]+)"\s*$', s)
if m and m.group(1) == ver:
    print(f"pyproject.toml: version déjà à {ver}")
else:
    s2 = re.sub(r'(?m)^(\s*version\s*=\s*)".*?"(\s*)$', rf'\1"{ver}"\2', s)
    if s2 == s:
        print("pyproject.toml: pattern version introuvable — je continue (à vérifier).")
    else:
        p.write_text(s2, encoding="utf-8")
        print(f"pyproject.toml -> version mise à jour vers {ver}")
PY
}

bump_init() {
  python - "$VER_NEXT" <<'PY' || true
import sys, re, pathlib
ver = sys.argv[1]
p = pathlib.Path("zz_tools/__init__.py")
s = p.read_text(encoding="utf-8")
m = re.search(r'(?m)^\s*__version__\s*=\s*"([^"]+)"\s*$', s)
if m and m.group(1) == ver:
    print(f"__init__.py: __version__ déjà {ver}")
else:
    s2 = re.sub(r'(?m)^(\s*__version__\s*=\s*)".*?"(\s*)$', rf'\1"{ver}"\2', s)
    if s2 == s:
        s2 = s.rstrip() + f'\n__version__ = "{ver}"\n'
    p.write_text(s2, encoding="utf-8")
    print(f"__init__.py -> version mise à jour vers {ver}")
PY
}

if [[ "${DO_BUILD_UPLOAD}" == "1" ]]; then
  bump_pyproject
  bump_init

  # Commit/push si changements
  if ! git diff --quiet --staged || ! git diff --quiet; then
    echo -e "\n[RUN] Commit bump ${VER_NEXT}"
    git add -A && echo "OK."
    echo -e "\n[RUN] Git commit"
    git commit -m "chore(version): ${VER_NEXT}" && echo "OK."
    echo -e "\n[RUN] Git push"
    git push origin "$(git rev-parse --abbrev-ref HEAD)" && echo "OK."
  else
    echo "[git] rien à committer"
    git push || true
  fi

  # ✅ FIX: appeler rm directement (pas via `bash -lc`), robuste même si rien n’existe
  _run "Nettoyage build" rm -rf dist build *.egg-info

  _run "Build (sdist + wheel)" python -m build

  if [[ "${RELEASE_SANITIZE}" == "1" ]]; then
    python - <<'PY'
import re, zipfile, tarfile, tempfile, pathlib, hashlib, base64, csv, io, shutil, os

DIST = pathlib.Path("dist")
PAT  = re.compile(r"^(?:License-Expression|License-File|Dynamic\s*:).*$", re.I|re.M)

def strip_meta(txt: str) -> str:
    out = "\n".join(ln for ln in txt.splitlines() if not PAT.match(ln))
    return out if out.endswith("\n") else out + "\n"

def fix_wheel(p: pathlib.Path):
    with zipfile.ZipFile(p, "r") as zin:
        names = zin.namelist()
        meta  = [n for n in names if n.endswith(".dist-info/METADATA")][0]
        rec   = meta.rsplit(".dist-info/", 1)[0] + ".dist-info/RECORD"
        rows  = []
        cleaned = strip_meta(zin.read(meta).decode("utf-8","replace")).encode()
        for n in names:
            rows.append((n, cleaned if n == meta else zin.read(n)))
    with zipfile.ZipFile(p, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for n, b in rows:
            if n == rec: continue
            zout.writestr(n, b)
        out = io.StringIO(); w = csv.writer(out)
        for n, b in rows:
            if n == rec: continue
            h = hashlib.sha256(b).digest()
            algo = "sha256=" + base64.urlsafe_b64encode(h).rstrip(b"=").decode()
            w.writerow([n, algo, str(len(b))])
        w.writerow([rec, "", ""])
        zout.writestr(rec, out.getvalue())

def fix_sdist(p: pathlib.Path):
    tmpdir = pathlib.Path(tempfile.mkdtemp())
    try:
        with tarfile.open(p, "r:gz") as tin:
            tin.extractall(tmpdir)
        meta = list(tmpdir.rglob("PKG-INFO"))
        if meta:
            m = meta[0]
            txt  = m.read_bytes().decode("utf-8","replace")
            txt2 = strip_meta(txt)
            if txt2 != txt:
                m.write_text(txt2, encoding="utf-8")
        # Écrire dans un fichier temporaire, puis remplacement atomique
        tmp_out = p.with_suffix(".sanitized.tar.gz")
        with tarfile.open(tmp_out, "w:gz") as tout:
# -> colle le bloc "Probe /simple (critère pip). Ne bloque pas la fin de script" juste après l’upload PyPI for q 
# in sorted(tmpdir.rglob("*")):
#   sauvegarde et quitte tout.add(q, arcname=q.relative_to(tmpdir))
        os.replace(tmp_out, p) finally:
# 3) Commit/push shutil.rmtree(tmpdir, ignore_errors=True)
git add tools/release.sh for whl in DIST.glob("*.whl"): git commit -m "release.sh: probe /simple non bloquant 
(préserve la fenêtre & les logs)" fix_wheel(whl) for sd in DIST.glob("*.tar.gz"): git push -u origin 
fix/release-probe-softfail fix_sdist(sd) print("Sanitizer: OK") PY
  else
    echo "Sanitizer: OFF (skipped)"
  fi

  _run "twine check" twine check "dist/zz_tools-${VER_NEXT}-py3-none-any.whl" "dist/zz_tools-${VER_NEXT}.tar.gz"
  _run "Upload PyPI (twine)" twine upload "dist/zz_tools-${VER_NEXT}-py3-none-any.whl" "dist/zz_tools-${VER_NEXT}.tar.gz"
else
  echo "[preflight] Skip bump/build/upload : version déjà présente sur PyPI."
fi

# ---------- Sondes PyPI ----------
probe_json() {
  local ver="$1" deadline=$(( $(date +%s) + ${RELEASE_TIMEOUT_JSON} )) body status
  while :; do
    body="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 \
             "https://pypi.org/pypi/zz-tools/json?ts=$(date +%s)" || true)"
    status="$(python - "$ver" <<'PY' 2>/dev/null <<<"$body"
import sys, json
ver=sys.argv[1]
try:
    d=json.loads(sys.stdin.read())
    print("FOUND" if ver in d.get("releases",{}) else "MISS")
except Exception:
    print("MISS")
PY
)"
    if [[ "$status" == "FOUND" ]]; then
      echo "PyPI JSON: ${ver} visible."
      break
    fi
    [[ "$(date +%s)" -ge "$deadline" ]] && { echo "Timeout PyPI JSON"; return 1; }
    echo "PyPI JSON: pas encore visible; retry…"; sleep 5
  done
}

probe_simple() {
  local ver="$1" deadline=$(( $(date +%s) + ${RELEASE_TIMEOUT_SIMPLE} )) html
  while :; do
    html="$(curl -fsS -H 'Cache-Control: no-cache' --max-time 5 "https://pypi.org/simple/zz-tools/?ts=$(date +%s)" || true)"
    if grep -q "$ver" <<<"$html"; then
      echo "PyPI /simple: ${ver} visible."
      break
    fi
    [[ "$(date +%s)" -ge "$deadline" ]] && { echo "Timeout index /simple"; return 1; }
    echo "PyPI /simple: pas encore visible; retry…"; sleep 5
  done
}

probe_json "${VER_NEXT}" || true
probe_simple "${VER_NEXT}" || true

# ---------- Smoke install ----------
unset PYTHONPATH
echo "# -- SMOKE INSTALL --"
tmpdir="$(mktemp -d)"; echo "TMP = $tmpdir"
python -m venv "$tmpdir/.venv-smoke"
# shellcheck disable=SC1090
source "$tmpdir/.venv-smoke/bin/activate"
python -m pip cache purge || true
python -m pip install -U pip

OK=0
for i in $(seq 1 "${RELEASE_SMOKE_RETRIES}"); do
  echo "[try $i/${RELEASE_SMOKE_RETRIES}] pip install zz-tools==${VER_NEXT} (no-cache)…"
  if python -m pip install --no-cache-dir --index-url https://pypi.org/simple "zz-tools==${VER_NEXT}"; then
    OK=1
    break
  fi
  echo "…pas encore propagé; retry dans 5s"
  sleep 5
done

if [[ "$OK" -eq 1 ]]; then
  ( cd "$tmpdir" && python - <<'PY'
import zz_tools, importlib.util, sys
print("__version__ =", getattr(zz_tools, "__version__", "unknown"))
print("module path =", zz_tools.__file__)
print("find_spec ok  =", bool(importlib.util.find_spec("zz_tools")))
print("loaded from current venv:", zz_tools.__file__.startswith(sys.prefix))
PY
  )
else
  echo "Échec d’installation après ${RELEASE_SMOKE_RETRIES} tentatives — latence CDN probable."
fi
deactivate || true

echo "Log fin: $(ts)"

# ---------- Tag & GitHub (optionnels) ----------
if [[ "${RELEASE_TAG}" == "1" ]]; then
  if git rev-parse "v${VER_NEXT}" >/dev/null 2>&1; then
    echo "[tag] v${VER_NEXT} déjà présent localement."
  else
    _run "git tag v${VER_NEXT}" git tag -a "v${VER_NEXT}" -m "Release ${VER_NEXT}"
  fi
  _run "git push tag" git push origin "v${VER_NEXT}"
fi

if [[ "${RELEASE_GH}" == "1" ]]; then
  if command -v gh >/dev/null 2>&1; then
    gh release create "v${VER_NEXT}" --generate-notes --title "zz-tools ${VER_NEXT}" \
      || echo "[gh] release déjà existante ou gh non configuré."
  else
    echo "[gh] CLI non trouvée — skip."
  fi
fi
