#!/usr/bin/env bash
# mcgt_probe_round3.sh — lecture seule, diagnostics d'homogénéité
# Garde-fou : ne ferme PAS le terminal en cas d'erreur, n'appelle pas exit.
set -Eeuo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="/tmp/mcgt_probe_round3_${TS}"
mkdir -p "${OUT}"
LOG="${OUT}/probe.log"

# Tee sans fermer le shell en cas d'erreur
exec > >(tee -a "${LOG}") 2>&1

echo ">>> START mcgt_probe_round3 @ ${TS}"
echo "pwd: $(pwd)"
command -v python && python --version || true

# Trap doux : on logge l'erreur mais on continue
trap 'echo "[WARN] Une commande a échoué (code=$?) — on continue";' ERR

echo ">>> 0) Sanity .gitignore et artefacts"
grep -nE '(^|/)\.ci-out/?$' .gitignore || echo "[HINT] Ajouter .ci-out/ dans .gitignore"
grep -nE '(^|/)release_zenodo_codeonly(/|$)' .gitignore || echo "[HINT] Ignorer release_zenodo_codeonly/ (artefact CI)"

echo ">>> 1) Packaging — pyproject vs __init__"
PYPROJ="pyproject.toml"
if [[ -f "${PYPROJ}" ]]; then
  awk 'NR>=1 && NR<=200{print NR ":" $0}' "${PYPROJ}" > "${OUT}/pyproject.head.txt"
  grep -E '^(name|version|requires-python)' -n "${PYPROJ}" || true
else
  echo "[WARN] pyproject.toml introuvable"
fi

echo "---- mcgt/__init__.py version ----"
grep -nE '__version__\s*=' mcgt/__init__.py || echo "[WARN] mcgt/__init__.py sans __version__"
echo "---- zz_tools/__init__.py version ----"
grep -nE '__version__\s*=' zz_tools/__init__.py || echo "[WARN] zz_tools/__init__.py sans __version__"

echo ">>> 2) Détection d'incohérences de versions (Python)"
python - <<'PY'
import re, pathlib, sys, json
root = pathlib.Path(".")
res = {"pyproject":{}, "mcgt":None, "zz_tools":None}
pp = root/"pyproject.toml"
if pp.exists():
    txt = pp.read_text(encoding="utf-8", errors="ignore")
    for key in ("name","version","requires-python"):
        m = re.search(rf'^{key}\s*=\s*["\']([^"\']+)["\']', txt, re.M)
        if m: res["pyproject"][key] = m.group(1)
mi = root/"mcgt/__init__.py"
if mi.exists():
    m = re.search(r'__version__\s*=\s*["\']([^"\']+)["\']', mi.read_text(encoding="utf-8", errors="ignore"))
    if m: res["mcgt"] = m.group(1)
zi = root/"zz_tools/__init__.py"
if zi.exists():
    m = re.search(r'__version__\s*=\s*["\']([^"\']+)["\']', zi.read_text(encoding="utf-8", errors="ignore"))
    if m: res["zz_tools"] = m.group(1)
print(json.dumps(res, indent=2))
# Flags d'écart simples
ppv = res["pyproject"].get("version")
if ppv and res["zz_tools"] and ppv != res["zz_tools"]:
    print(f"[MISMATCH] pyproject.version({ppv}) != zz_tools.__version__({res['zz_tools']})")
if ppv and res["mcgt"] and ppv != res["mcgt"]:
    print(f"[MISMATCH] pyproject.version({ppv}) != mcgt.__version__({res['mcgt']})")
PY

echo ">>> 3) Inventaire des scripts CLI & normalisation attendue"
# Recensement des add_argument fréquents
grep -Rsn --include='*.py' -E 'add_argument\(|--format|--fmt|--dpi|--outdir|--transparent|--style|--verbose' zz-scripts/ > "${OUT}/cli_scan.txt" || true
sed -n '1,200p' "${OUT}/cli_scan.txt"

echo ">>> 4) Figures — motifs divergents"
find zz-figures -type f -name '*.png' | sed 's#.*/##' | sort | head -n 40
# Signatures de noms hétérogènes
grep -Rsn --include='*.png' -E '(^|/)0?[0-9]{2}_fig_|(^|/)fig_0?[0-9]_' zz-figures | sed -n '1,60p' || true

echo ">>> 5) Manifeste — compte & pollution .bak"
for f in zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
  if [[ -f "$f" ]]; then
    echo "-- $f"
    python - "$f" <<'PY'
import json,sys,re
p=sys.argv[1]
j=json.load(open(p))
paths=[e.get("path","") for e in j.get("entries", j if isinstance(j,list) else []) if isinstance(e,dict) or isinstance(j,list)]
n=len(paths)
bak=sum(1 for x in paths if ".bak_" in x or x.endswith(".bak"))
print(f"entries={n}  bak_entries={bak}")
PY
  else
    echo "[WARN] $f introuvable"
  fi
done

echo ">>> 6) Données volumineuses (top 20)"
du -h zz-data | tail -n 1 || true
# Top fichiers
( set +e; LC_ALL=C ls -lS $(find zz-data -type f -printf '%p\n') 2>/dev/null | head -n 25 ) || true

echo ">>> 7) Tests — skip & configs"
grep -Rsn 'pytest\.skip' zz-scripts zz-tests | sed -n '1,80p' || true
ls -1 zz-tests/pytest.ini pyproject-local-pytest.toml 2>/dev/null || true
ls -1 .github/workflows/*.yml* 2>/dev/null || true

echo ">>> 8) Dossiers redondants"
for d in zz-config zz-configuration attic _attic_untracked release_zenodo_codeonly; do
  if [[ -d "$d" ]]; then echo "OK - $d"; fi
done

echo ">>> 9) Conseils immédiats (auto-checks)"
# Alerte find -maxdepth usage
echo "[CHECK] Vérifier l'ordre des options 'find' (-maxdepth AVANT -type)."

echo ">>> END. Logs: ${LOG}"
echo "Dossier de sortie: ${OUT}"
# Pause douce pour éviter fermeture brutale sous certains terminaux
sleep 0.1
