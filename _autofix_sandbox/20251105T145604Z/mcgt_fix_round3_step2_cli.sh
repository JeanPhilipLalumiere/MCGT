#!/usr/bin/env bash
# fichier : mcgt_fix_round3_step2_cli.sh
# répertoire : ~/MCGT
set -Eeuo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: mcgt_fix_round3_step2_cli.sh [--dry-run]
  - Corrige uniquement l'hygiène des scripts (sans changer la science) :
    1) Décolle les "arguments collés" dans les .py (") parser.add_argument").
    2) Réordonne 'find' -> place -maxdepth avant -type dans les .sh.
    3) Ajoute l'en-tête requis (# fichier / # répertoire) aux .py/.sh sous zz-scripts/.
  - Sauvegardes complètes dans /tmp/mcgt_backups_step2_<timestamp>/
  - Affiche le diff Git final.
USAGE
}

dry_run=0
[[ "${1:-}" == "--dry-run" ]] && dry_run=1

_ts="$(date -u +%Y%m%dT%H%M%SZ)"
_log="/tmp/mcgt_fix_round3_step2_${_ts}.log"
exec > >(tee -a "${_log}") 2>&1
trap 'echo; echo "[ERROR] Voir le log : ${_log}"; echo "La session reste ouverte pour inspection.";' ERR

echo ">>> START fix step2 @ ${_ts}"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "repo-root: ${root}"
cd "${root}"

backup_dir="/tmp/mcgt_backups_step2_${_ts}"
mkdir -p "${backup_dir}"
export BACKUP_DIR="${backup_dir}"
echo "[INFO] BACKUP_DIR=${BACKUP_DIR}"
echo "[INFO] dry_run=${dry_run}"

# --- helper: safe_write <path> <newcontent> (with backup) ---
safe_write_py() {
  local f="$1"; local tmp="$2"
  if [[ $dry_run -eq 1 ]]; then
    echo "[DRY] would update: ${f}"
    rm -f "$tmp"
    return 0
  fi
  local b="${BACKUP_DIR}/PY_$(echo "$f" | sed 's#/#__#g')"
  cp -f -- "$f" "$b" || true
  mv -f -- "$tmp" "$f"
}
safe_write_sh() {
  local f="$1"; local tmp="$2"
  if [[ $dry_run -eq 1 ]]; then
    echo "[DRY] would update: ${f}"
    rm -f "$tmp"
    return 0
  fi
  local b="${BACKUP_DIR}/SH_$(echo "$f" | sed 's#/#__#g')"
  cp -f -- "$f" "$b" || true
  mv -f -- "$tmp" "$f"
}
safe_write_hdr() {
  local f="$1"; local tmp="$2"
  if [[ $dry_run -eq 1 ]]; then
    echo "[DRY] would add header: ${f}"
    rm -f "$tmp"
    return 0
  fi
  local b="${BACKUP_DIR}/HDR_$(echo "$f" | sed 's#/#__#g')"
  cp -f -- "$f" "$b" || true
  mv -f -- "$tmp" "$f"
}

echo "## 1) Fix des arguments collés dans *.py (zz-scripts/)"
python3 - <<'PY'
import pathlib,re,os,sys,tempfile,shutil
base=pathlib.Path("zz-scripts")
pat=re.compile(r'\)\s+(?=parser\.add_argument)')
changed=[]
for p in base.rglob("*.py"):
    try:
        txt=p.read_text(encoding="utf-8",errors="ignore")
    except Exception:
        continue
    new=pat.sub(')\n        ', txt)
    if new!=txt:
        tmp=pathlib.Path(tempfile.mkstemp(prefix="fix_py_",suffix=".tmp")[1])
        tmp.write_text(new,encoding="utf-8")
        print(str(p))
        # pass path back to shell to safe_write
        print(f"__APPLY__::{p}::{tmp}", flush=True)
        changed.append(p)
# marker for shell parser
print("__DONE__", flush=True)
PY
# appliquer via shell (pour faire backup)
while IFS= read -r line; do
  [[ "$line" == "__DONE__" ]] && break
  if [[ "$line" == __APPLY__::* ]]; then
    f="$(echo "$line" | cut -d: -f3)"
    tmpf="$(echo "$line" | cut -d: -f5)"
    safe_write_py "$f" "$tmpf"
  else
    : # echo "$line"
  fi
done

echo
echo "## 2) Corriger l'ordre des 'find' (-maxdepth avant -type) dans tous les .sh du repo"
python3 - <<'PY'
import pathlib,re,os,tempfile
base=pathlib.Path(".")
pat=re.compile(r'(find\s+[^|;\n]*?)\s(-type\s+\S+)\s(-maxdepth\s+\d+)', re.IGNORECASE)
for p in base.rglob("*.sh"):
    try:
        txt=p.read_text(encoding="utf-8",errors="ignore")
    except Exception:
        continue
    m=pat.search(txt)
    if not m:
        continue
    new=pat.sub(lambda m: f"{m.group(1)} {m.group(3)} {m.group(2)}", txt)
    if new!=txt:
        import tempfile
        tmp=tempfile.mkstemp(prefix="fix_sh_",suffix=".tmp")[1]
        with open(tmp,"w",encoding="utf-8") as w: w.write(new)
        print(f"__APPLY__::{p}::{tmp}")
print("__DONE__")
PY
while IFS= read -r line; do
  [[ "$line" == "__DONE__" ]] && break
  if [[ "$line" == __APPLY__::* ]]; then
    f="$(echo "$line" | cut -d: -f3)"
    tmpf="$(echo "$line" | cut -d: -f5)"
    safe_write_sh "$f" "$tmpf"
  fi
done

echo
echo "## 3) Ajouter en-tête (# fichier / # répertoire) manquant aux .py/.sh sous zz-scripts/"
python3 - <<'PY'
import pathlib,os,tempfile
root=pathlib.Path(".").resolve()
base=pathlib.Path("zz-scripts")
def inject_header(path: pathlib.Path, txt: str) -> str:
    rel=path.resolve().relative_to(root)
    header=f"# fichier : {rel.as_posix()}\n# répertoire : {rel.parent.as_posix()}\n"
    if txt.startswith("#!"):
        first,rest = txt.split("\n",1) if "\n" in txt else (txt,"")
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
while IFS= read -r line; do
  [[ "$line" == "__DONE__" ]] && break
  if [[ "$line" == __APPLY__::* ]]; then
    f="$(echo "$line" | cut -d: -f3)"
    tmpf="$(echo "$line" | cut -d: -f5)"
    safe_write_hdr "$f" "$tmpf"
  fi
done

echo
echo "---- DIFF (git) ----"
git --no-pager diff -- zz-scripts . || true

echo ">>> END. Log: ${_log}"
echo "[INFO] Sauvegardes : ${BACKUP_DIR}"
