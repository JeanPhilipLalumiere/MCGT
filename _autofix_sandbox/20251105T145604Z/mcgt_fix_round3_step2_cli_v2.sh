#!/usr/bin/env bash
# fichier : mcgt_fix_round3_step2_cli_v2.sh
# répertoire : ~/MCGT
set -Eeuo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: mcgt_fix_round3_step2_cli_v2.sh [--dry-run]
  Hygiène sans toucher aux données ni à la logique scientifique :
    1) Décolle les "arguments collés" (") parser.add_argument") dans *.py sous zz-scripts/
    2) Réordonne les 'find' : place -maxdepth avant -type dans *.sh (repo entier)
    3) Ajoute l'en-tête demandé (# fichier / # répertoire) aux *.py/*.sh sous zz-scripts/
  Sauvegardes : /tmp/mcgt_backups_step2_<timestamp>/
USAGE
}

dry_run=0
[[ "${1:-}" == "--dry-run" ]] && dry_run=1

_ts="$(date -u +%Y%m%dT%H%M%SZ)"
_log="/tmp/mcgt_fix_round3_step2_${_ts}.log"
exec > >(tee -a "${_log}") 2>&1
trap 'echo; echo "[ERROR] Voir le log : ${_log}"; echo "La session reste ouverte pour inspection.";' ERR

echo ">>> START fix step2 v2 @ ${_ts}"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "repo-root: ${root}"
cd "${root}"

backup_dir="/tmp/mcgt_backups_step2_${_ts}"
mkdir -p "${backup_dir}"
export BACKUP_DIR="${backup_dir}"
echo "[INFO] BACKUP_DIR=${BACKUP_DIR}"
echo "[INFO] dry_run=${dry_run}"

safe_write() {
  local tag="$1" f="$2" tmp="$3"
  if [[ $dry_run -eq 1 ]]; then
    echo "[DRY] would update (${tag}): ${f}"
    rm -f "$tmp"
    return 0
  fi
  local b="${BACKUP_DIR}/${tag}_$(echo "$f" | sed 's#/#__#g')"
  cp -f -- "$f" "$b" || true
  mv -f -- "$tmp" "$f"
}

echo "## 1) Fix des arguments collés dans *.py (zz-scripts/)"
while IFS= read -r line; do
  if [[ "$line" == __APPLY__::* ]]; then
    f="${line#__APPLY__::}"; f="${f%%::*}"
    tmp="${line##*::}"
    safe_write "PY" "$f" "$tmp"
  else
    [[ "$line" != "__DONE__" ]] && echo "$line"
  fi
done < <(python3 - <<'PY'
import pathlib,re,tempfile,sys
base=pathlib.Path("zz-scripts")
pat=re.compile(r'\)\s+(?=parser\.add_argument)')
for p in base.rglob("*.py"):
    try:
        txt=p.read_text(encoding="utf-8",errors="ignore")
    except Exception:
        continue
    new=pat.sub(')\n        ', txt)
    if new!=txt:
        tmp=tempfile.mkstemp(prefix="fix_py_",suffix=".tmp")[1]
        with open(tmp,"w",encoding="utf-8") as w: w.write(new)
        print(str(p))
        print(f"__APPLY__::{p}::{tmp}")
print("__DONE__")
PY
)

echo
echo "## 2) Réordonner 'find' (-maxdepth avant -type) dans *.sh (repo)"
while IFS= read -r line; do
  if [[ "$line" == __APPLY__::* ]]; then
    f="${line#__APPLY__::}"; f="${f%%::*}"
    tmp="${line##*::}"
    safe_write "SH" "$f" "$tmp"
  else
    [[ "$line" != "__DONE__" ]] && echo "$line"
  fi
done < <(python3 - <<'PY'
import pathlib,re,tempfile
base=pathlib.Path(".")
pat=re.compile(r'(find\s+[^|;\n]*?)\s(-type\s+\S+)\s(-maxdepth\s+\d+)', re.IGNORECASE)
for p in base.rglob("*.sh"):
    try:
        txt=p.read_text(encoding="utf-8",errors="ignore")
    except Exception:
        continue
    new=pat.sub(lambda m: f"{m.group(1)} {m.group(3)} {m.group(2)}", txt)
    if new!=txt:
        tmp=tempfile.mkstemp(prefix="fix_sh_",suffix=".tmp")[1]
        with open(tmp,"w",encoding="utf-8") as w: w.write(new)
        print(f"__APPLY__::{p}::{tmp}")
print("__DONE__")
PY
)

echo
echo "## 3) Ajouter en-tête (# fichier / # répertoire) aux *.py/*.sh (zz-scripts/)"
while IFS= read -r line; do
  if [[ "$line" == __APPLY__::* ]]; then
    f="${line#__APPLY__::}"; f="${f%%::*}"
    tmp="${line##*::}"
    safe_write "HDR" "$f" "$tmp"
  else
    [[ "$line" != "__DONE__" ]] && echo "$line"
  fi
done < <(python3 - <<'PY'
import pathlib,tempfile
root=pathlib.Path(".").resolve()
base=pathlib.Path("zz-scripts")
def inject_header(path: pathlib.Path, txt: str) -> str:
    rel=path.resolve().relative_to(root)
    header=f"# fichier : {rel.as_posix()}\n# répertoire : {rel.parent.as_posix()}\n"
    if txt.startswith("#!"):
        first,rest = (txt.split("\n",1)+[""])[:2]
        return first+"\n"+header+rest
    return header + txt
for p in base.rglob("*"):
    if not p.is_file() or p.suffix not in (".py",".sh"):
        continue
    try:
        txt=p.read_text(encoding="utf-8",errors="ignore")
    except Exception:
        continue
    head="\n".join(txt.splitlines()[:5])
    if "# fichier :" in head and "# répertoire :" in head:
        continue
    new=inject_header(p, txt)
    tmp=tempfile.mkstemp(prefix="hdr_",suffix=".tmp")[1]
    with open(tmp,"w",encoding="utf-8") as w: w.write(new)
    print(f"__APPLY__::{p}::{tmp}")
print("__DONE__")
PY
)

echo
echo "---- DIFF (git) ----"
git --no-pager diff -- zz-scripts . || true

echo ">>> END. Log: ${_log}"
echo "[INFO] Sauvegardes : ${BACKUP_DIR}"
