#!/usr/bin/env bash
# probe_pack_v5.sh — Audit ECHO non destructif, anti-fermeture, interactif optionnel
# Usage:
#   PROBE_PAUSE=0 bash tools/probe_pack_v5.sh     # (défaut) sans pauses
#   PROBE_PAUSE=1 bash tools/probe_pack_v5.sh     # avec "Appuie sur Entrée..."
# Notes:
# - Pas de "set -e" → n'abandonne pas sur erreurs; on log et on continue.
# - Trap pour éviter la fermeture abrupte de la fenêtre.
set -u -o pipefail
shopt -s nullglob
trap 'echo "[WARN] Signal intercepté; on poursuit proprement."' INT TERM
: "${PROBE_PAUSE:=0}"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
ROOT="$(pwd)"
DST="/tmp/mcgt_extract_${ts}_v5"
FILES="$DST/files"
CTX="$DST/ctx"
mkdir -p "$FILES" "$CTX"

pause() { if [ "${PROBE_PAUSE}" = "1" ]; then read -r -p "➡️  Appuie sur Entrée pour continuer..."; fi; }
echo_out() { local f="$1"; printf "[ECHO] %s\n" "$f"; }

step() { printf "==== [%02d] %s ====\n" "$1" "$2"; }

# 01 — Git: branches, remotes, tags, ahead/behind (fallback)
step 1 "Git: branches, remotes, tags, ahead/behind"
{
  echo "## git rev-parse && status"; git rev-parse --is-inside-work-tree 2>&1
  git status -sb 2>&1 || true
  echo; echo "## remotes"; git remote -v 2>&1 || true
  echo; echo "## branches (local)"; git for-each-ref --format='%(refname:short) %(objectname:short) %(upstream:short)' refs/heads 2>&1 || true
  echo; echo "## tags (recent 30)"; git tag --sort=-creatordate | head -n 30 2>&1 || true
  echo; echo "## ahead/behind (best-effort)"; 
  for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do
    up=$(git rev-parse --abbrev-ref "${b}@{upstream}" 2>/dev/null || true)
    if [ -n "$up" ]; then
      ahead=$(git rev-list --left-right --count "${up}...${b}" 2>/dev/null | awk '{print $2}')
      behind=$(git rev-list --left-right --count "${up}...${b}" 2>/dev/null | awk '{print $1}')
      printf "%s  upstream=%s  ahead=%s  behind=%s\n" "$b" "$up" "${ahead:-?}" "${behind:-?}"
    else
      printf "%s  upstream=NONE\n" "$b"
    fi
  done
} > "$FILES/01_git_overview.txt" 2>&1
echo_out "$FILES/01_git_overview.txt"; pause

# 02 — Artefacts & backups (à purger plus tard)
step 2 "Backups/artefacts — comptage"
{
  echo "## motifs à surveiller"; echo "*.bak, *~ , .bak/, attic/, old/, _tmp/, .ci-out/, purgebak, round*bak"
  printf "\n# Comptages\n"
  grep -RIl --binary-files=without-match -e '' . >/dev/null 2>&1 || true
  find . -type f \( -name '*.bak' -o -name '*~' -o -name '*.tmp' -o -name '*.lock' \) | sort > /tmp/_v5_baks.txt
  find . -type d \( -name attic -o -name old -o -name _tmp -o -name '.ci-out' \) | sort > /tmp/_v5_dirs.txt
  echo "[files *.bak|*~|*.tmp|*.lock] $(wc -l < /tmp/_v5_baks.txt)"
  echo "[dirs attic|old|_tmp|.ci-out] $(wc -l < /tmp/_v5_dirs.txt)"
  echo; echo "# Liste fichiers"; cat /tmp/_v5_baks.txt
  echo; echo "# Liste dossiers"; cat /tmp/_v5_dirs.txt
} > "$FILES/02_backups.txt" 2>&1
echo_out "$FILES/02_backups.txt"; pause

# 03 — py_compile global
step 3 "py_compile global — résumé"
python3 - <<'PY' > "$FILES/03_pycompile.txt" 2>&1
import sys, py_compile
from pathlib import Path
roots = [Path("zz-scripts"), Path("chapters"), Path(".")]
seen=set(); ok=0; bad=0
def it(p):
    for x in p.rglob("*.py"):
        s=str(x)
        if any(seg.startswith(".git") for seg in x.parts): continue
        if "/.venv/" in s or "/venv/" in s: continue
        if s in seen: continue
        seen.add(s)
        try:
            py_compile.compile(s, doraise=True)
            print("[OK]", s)
            ok+=1
        except Exception as e:
            print("[ERR]", s, "→", e)
            bad+=1
for r in roots:
    if r.exists(): it(r)
print(f"\nSummary: OK={ok} ERR={bad}")
PY
echo_out "$FILES/03_pycompile.txt"; pause

# 04 — Greps argparse (add_argument)
step 4 "Greps argparse (add_argument) — brut"
grep -RIn --line-number -E 'argparse|add_argument|ArgumentParser' zz-scripts chapters 2>/dev/null | sed 's#^\./##' \
  > "$FILES/04_argparse_grep.txt" || true
echo_out "$FILES/04_argparse_grep.txt"; pause

# 05 — sys.exit détectés
step 5 "sys.exit détectés (potentiels aborts)"
grep -RIn --line-number -E '\bsys\.exit\(' zz-scripts chapters 2>/dev/null | sed 's#^\./##' \
  > "$FILES/05_sys_exit_all.txt" || true
echo_out "$FILES/05_sys_exit_all.txt"; pause

# 06 — Usage pyplot direct (plt.)
step 6 "Usage pyplot direct (plt.)"
grep -RIn --line-number -E '\bplt\.' zz-scripts chapters 2>/dev/null | sed 's#^\./##' \
  > "$FILES/06_pyplot.txt" || true
echo_out "$FILES/06_pyplot.txt"; pause

# 07 — savefig / makedirs — patterns I/O
step 7 "savefig / makedirs — patterns"
grep -RIn --line-number -E 'savefig\(|os\.makedirs\(|Path\(.+\)\.mkdir\(' zz-scripts chapters 2>/dev/null | sed 's#^\./##' \
  > "$FILES/07_io_patterns.txt" || true
echo_out "$FILES/07_io_patterns.txt"; pause

# 08 — MPL backend/style (fichiers config)
step 8 "MPL backend/style (présence config)"
{
  echo "MPLBACKEND env = ${MPLBACKEND:-<unset>}"
  for f in matplotlibrc mplstyle.mplstyle .config/matplotlib/matplotlibrc; do
    [ -f "$f" ] && echo "FOUND: $f"
  done
} > "$FILES/08_mpl_style.txt" 2>&1
echo_out "$FILES/08_mpl_style.txt"; pause

# 09 — zz-config / params.* / overrides
step 9 "zz-config (params.* / levels / overrides)"
{
  find . -maxdepth 3 -type f -path './zz-*/*' \( -name 'params.*' -o -name '*levels*.json' -o -name '*override*' \) -print
} > "$FILES/09_zz_config.txt" 2>&1
echo_out "$FILES/09_zz_config.txt"; pause

# 10 — Inventaire CLI statique (sans exécuter)
step 10 "Inventaire CLI statique (sans exécuter)"
{
  for s in $(git ls-files '*.py'); do
    if grep -q 'add_argument' "$s"; then
      echo "### $s"
      grep -E "add_argument\(" -n "$s" | sed 's/^\([0-9]\+\):/  L\1:/'
      echo
    fi
  done
} > "$FILES/10_static_help.txt" 2>&1
echo_out "$FILES/10_static_help.txt"; pause

# 11 — Mapping (scripts → inputs pressentis)
step 11 "Mapping (scripts → inputs référencés)"
{
  for s in $(git ls-files '*.py'); do
    hits=$(grep -nE "read_csv\(|read_json\(|np\.load\(|open\(" "$s" 2>/dev/null || true)
    if [ -n "$hits" ]; then
      echo "### $s"; echo "$hits" | sed 's/^/  /'; echo
    fi
  done
} > "$FILES/11_mapping_inputs.txt" 2>&1
echo_out "$FILES/11_mapping_inputs.txt"; pause

# 12 — Existence inputs (best-effort)
step 12 "Existence inputs — best-effort"
python3 - <<'PY' > "$FILES/12_inputs_exist.txt" 2>&1
from pathlib import Path
import re, sys
pairs=[]
for s in sys.stdin:
    pass
PY
# Simplifié: on vérifie qq chemins canoniques courants
{
  for p in zz-data zz-figures chapters chapter*/zz-data; do [ -e "$p" ] && echo "EXISTS $p"; done
  for p in zz-data/chapter07/07_dcs2_dk.csv zz-data/chapter10/10_metrics_primary.csv; do
    [ -e "$p" ] && echo "[OK] $p" || echo "[MISS] $p"
  done
} > "$FILES/12_inputs_exist.txt"
echo_out "$FILES/12_inputs_exist.txt"; pause

# 13 — Conformité chemins figures (pattern)
step 13 "Conformité chemins figures (pattern)"
grep -RIn --line-number -E 'zz-figures/|\.ci-out/|/fig' zz-scripts chapters 2>/dev/null | sed 's#^\./##' \
  > "$FILES/13_fig_paths.txt" || true
echo_out "$FILES/13_fig_paths.txt"; pause

# 14 — Manifest(s): figures listées → existent-elles ?
step 14 "Manifest(s) : existence réelle"
python3 - <<'PY' > "$FILES/14_manifest_check.txt" 2>&1
from pathlib import Path
import json, sys
cands = ["zz-manifests/manifest_publication.json", "zz-manifests/manifest_master.json"]
for c in cands:
    p=Path(c)
    print("==>", c, "exists=", p.exists())
    if not p.exists(): continue
    try:
        j=json.loads(p.read_text(encoding="utf-8", errors="replace"))
    except Exception as e:
        print("[ERR] JSON", c, "→", e); continue
    miss=0; total=0
    def walk(x):
        if isinstance(x, dict):
            for k,v in x.items(): walk(v)
        elif isinstance(x, list):
            for v in x: walk(v)
        elif isinstance(x, str):
            if any(x.endswith(ext) for ext in (".png",".pdf",".svg",".csv",".json",".txt")):
                nonlocal miss,total
                total+=1
                if not Path(x).exists():
                    miss+=1; print("[MISS]", x)
    walk(j)
    print(f"Summary {c}: total_refs={total} missing={miss}")
PY
echo_out "$FILES/14_manifest_check.txt"; pause

# 15 — Lints doctrinaux (tabs / trailing spaces)
step 15 "Lints doctrinaux (tabs/trailing)"
{
  echo "# Tabs";   grep -RIn $'\t' zz-scripts chapters 2>/dev/null | sed 's#^\./##'
  echo; echo "# Trailing spaces"; grep -RIn --line-number -E '[[:space:]]+$' zz-scripts chapters 2>/dev/null | sed 's#^\./##'
} > "$FILES/15_lints.txt" 2>&1
echo_out "$FILES/15_lints.txt"; pause

# 16 — Determinisme: np.random vs default_rng
step 16 "Determinisme: np.random vs default_rng"
{
  echo "# default_rng usages"; grep -RIn --line-number -E 'np\.random\.default_rng\(' zz-scripts chapters 2>/dev/null | sed 's#^\./##' || true
  echo; echo "# random.*seed usages"; grep -RIn --line-number -E 'np\.random\.(RandomState|seed)\(' zz-scripts chapters 2>/dev/null | sed 's#^\./##' || true
} > "$FILES/16_determinism.txt" 2>&1
echo_out "$FILES/16_determinism.txt"; pause

# 17 — _common/ et archives précédentes
step 17 "_common/ & archives précédentes"
{
  find zz-scripts/_common -maxdepth 2 -type f -print 2>/dev/null || true
  ls -1 /tmp | grep -E '^mcgt_extract_.*_v[0-9]$' || true
} > "$FILES/17_common_archives.txt" 2>&1
echo_out "$FILES/17_common_archives.txt"; pause

# 18 — Gros fichiers (>50MB) & Git LFS
step 18 "Gros fichiers (>50MB) & Git LFS"
{
  echo "# Fichiers >50MB (worktree)"; 
  find . -type f -size +50M -not -path "./.git/*" -print 2>/dev/null
  echo; echo "# git lfs ls-files"; git lfs ls-files 2>/dev/null || echo "(git-lfs non configuré)"
} > "$FILES/18_large_lfs.txt" 2>&1
echo_out "$FILES/18_large_lfs.txt"; pause

# 19 — Workflows CI & Trusted publishing
step 19 "Workflows CI & Trusted publishing"
{
  echo "## .github/workflows/"
  [ -d .github/workflows ] && ls -1 .github/workflows || echo "(absent)"
  echo; echo "## Hints trusted publishing (PyPI)"
  grep -RIn --line-number -E 'pypi|trusted|id: publish|pypi-project' .github/workflows 2>/dev/null || true
} > "$FILES/19_ci_workflows.txt" 2>&1
echo_out "$FILES/19_ci_workflows.txt"; pause

# 20 — pyproject / metadata
step 20 "pyproject / metadata"
{
  for f in pyproject.toml setup.cfg setup.py CITATION.cff LICENSE* README*; do
    [ -e "$f" ] && { echo "=== $f"; sed -n '1,160p' "$f"; echo; }
  done
} > "$FILES/20_metadata.txt" 2>&1
echo_out "$FILES/20_metadata.txt"; pause

# Résumé final (pointeurs)
{
  echo ">> Résumé:  $DST/summary.txt"
  echo ">> Archive: $DST.tgz"
  echo ">> Dossiers: $FILES  $CTX"
} > "$DST/summary.txt"

tar -C "$(dirname "$DST")" -czf "$DST.tgz" "$(basename "$DST")" >/dev/null 2>&1 || true
printf "[OK] Extraction v5 terminée. Dossier: %s\n" "$DST"
