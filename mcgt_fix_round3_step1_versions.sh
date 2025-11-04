#!/usr/bin/env bash
# fichier : mcgt_fix_round3_step1_versions.sh
# répertoire : ~/MCGT

set -Eeuo pipefail

_ts="$(date -u +%Y%m%dT%H%M%SZ)"
_log="/tmp/mcgt_fix_round3_step1_${_ts}.log"
exec > >(tee -a "${_log}") 2>&1

trap 'echo; echo "[ERROR] Une erreur est survenue. Voir le log : ${_log}"; echo "La session reste ouverte pour inspection.";' ERR

echo ">>> START fix step1 @ ${_ts}"
echo "pwd: $(pwd)"

# 1) Lire version canonique depuis pyproject.toml
py_ver="$(python3 - <<'PY'
import tomllib,sys
with open("pyproject.toml","rb") as f:
    data=tomllib.load(f)
print(data["project"]["version"])
PY
)"
echo "[INFO] Version canonique (pyproject.project.version) = ${py_ver}"

# 2) Sauvegardes
backup_dir="/tmp/mcgt_backups_${_ts}"
mkdir -p "${backup_dir}"
cp -a zz_tools/__init__.py "${backup_dir}/zz_tools__init__.py.bak"
cp -a .gitignore "${backup_dir}/gitignore.bak" 2>/dev/null || true
echo "[INFO] Backups -> ${backup_dir}"

# 3) Afficher versions avant
echo "---- AVANT ----"
python3 - <<'PY'
import re, pathlib, tomllib
from pprint import pprint
data = {"pyproject":{}, "mcgt":None, "zz_tools":None}
with open("pyproject.toml","rb") as f:
    pj = tomllib.load(f)
data["pyproject"] = {
    "name": pj["project"]["name"],
    "version": pj["project"]["version"],
    "requires-python": pj["project"].get("requires-python")
}
for path, key in [("mcgt/__init__.py","mcgt"), ("zz_tools/__init__.py","zz_tools")]:
    try:
        txt = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
        m = re.search(r'__version__\s*=\s*["\']([^"\']+)["\']', txt)
        data[key] = m.group(1) if m else None
    except FileNotFoundError:
        data[key] = None
pprint(data)
PY

# 4) Mettre à jour zz_tools/__init__.py si nécessaire
need_update="$(python3 - <<PY
import re, pathlib, tomllib, sys
with open("pyproject.toml","rb") as f:
    pj = tomllib.load(f)
ver = pj["project"]["version"]
p = pathlib.Path("zz_tools/__init__.py")
txt = p.read_text(encoding="utf-8", errors="ignore")
cur = re.findall(r'__version__\s*=\s*["\']([^"\']+)["\']', txt)
if not cur or any(v!=ver for v in cur):
    import io
    new = re.sub(r'(__version__\s*=\s*["\'])([^"\']+)(["\'])',
                 lambda m: m.group(1)+ver+m.group(3), txt)
    p.write_text(new, encoding="utf-8")
    print("yes")
else:
    print("no")
PY
)"
if [[ "${need_update}" == "yes" ]]; then
  echo "[FIX] zz_tools/__init__.py mis à jour -> ${py_ver}"
else
  echo "[OK] zz_tools/__init__.py déjà cohérent avec ${py_ver}"
fi

# 5) Forcer l’ignore de l’artefact release_zenodo_codeonly/
if [[ -f .gitignore ]]; then
  if ! grep -qx 'release_zenodo_codeonly/' .gitignore; then
    echo 'release_zenodo_codeonly/' >> .gitignore
    echo "[FIX] Ajouté à .gitignore : release_zenodo_codeonly/"
  else
    echo "[OK] .gitignore contient déjà release_zenodo_codeonly/"
  fi
else
  echo 'release_zenodo_codeonly/' > .gitignore
  echo "[FIX] Créé .gitignore avec release_zenodo_codeonly/"
fi

# 6) Rappel sur l’ordre find (diagnostic non bloquant)
echo "[CHECK] Vérification rapide des usages de 'find' (ordre -maxdepth avant -type) :"
grep -RIn --exclude-dir=.git --include='*.sh' -E 'find .* -type .* -maxdepth' || true

# 7) Diff
echo "---- DIFF ----"
git --no-pager diff -- .gitignore zz_tools/__init__.py || true

echo ">>> END. Log: ${_log}"
