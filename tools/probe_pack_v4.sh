#!/usr/bin/env bash
# tools/probe_pack_v4.sh — extraction lecture seule, sûre, avec garde-fou
# Usage: bash tools/probe_pack_v4.sh
set -u -o pipefail   # PAS de -e (on ne sort pas sur erreur)
umask 022

ROOT="$(pwd)"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="/tmp/mcgt_extract_${TS}_v4"
LOG="$OUT/logs/run.log"
mkdir -p "$OUT"/{files,ctx,grep,logs} || true

# Garde-fou: ne jamais fermer la fenêtre sur erreur; on logge et on continue.
err() { code="$?"; echo "[WARN] étape échouée (rc=$code) — on continue" | tee -a "$LOG"; }
trap err ERR

pause() {
  if [ -t 0 ]; then
    read -r -p $'➡️  Appuie sur Entrée pour continuer...' _ || true
  fi
}

note() { echo -e "==== $* ====" | tee -a "$LOG"; }

run() { # run "label" "command" "outfile"
  local label="$1" cmd="$2" out="$3"
  note "$label"
  # shellcheck disable=SC2086
  bash -lc "$cmd" >"$out" 2>&1 || true
  echo "[ECHO] $out"
}

# ---------- [01] Git branches + ahead/behind (fallback robuste) ----------
git_branch_report() {
  local out="$OUT/files/01_git_branches.txt"
  note "[01] Git: branches, upstream, ahead/behind (fallback)"
  {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; return 0; }
    printf "%-45s  %s\n" "BRANCH" "INFO"
    git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | while read -r b u; do
      if [ -n "$u" ]; then
        # behind ahead via rev-list (triple dot: commits exclusifs)
        read -r behind ahead < <(git rev-list --left-right --count "$u...$b" 2>/dev/null | awk '{print $1, $2}')
        printf "%-45s  [upstream=%s] ahead=%s behind=%s\n" "$b" "$u" "${ahead:-?}" "${behind:-?}"
      else
        printf "%-45s  [no upstream]\n" "$b"
      fi
    done
    echo
    git status -sb || true
    echo
    git log --oneline -n 40 || true
  } >"$out" 2>&1
  echo "[ECHO] $out"
}

git_branch_report
pause

# ---------- [02] Backups/artefacts ----------
run "[02] Backups/artefacts (à purger plus tard) — comptage" \
    "find . -type f \\( -name '*.bak' -o -name '*.purgebak*' -o -name '*.round3bak*' -o -path './_tmp/*' -o -path './_autofix_sandbox/*' -o -path './_attic_untracked/*' \\) -printf '%p\n' | sort" \
    "$OUT/files/02_backups.txt"
pause

# ---------- [03] py_compile global ----------
run "[03] py_compile global — résumé" \
    "python3 - <<'PY'
import compileall, sys
ok = compileall.compile_dir('zz-scripts', force=True, quiet=1)
print('py_compile OK=', bool(ok))
PY" \
    "$OUT/files/03_pycompile.txt"
pause

# ---------- [04] Contexte fichier sensible ch09 ----------
run "[04] CTX élargi ch09/plot_fig01_phase_overlay.py (380–480)" \
    "python3 - <<'PY'
from pathlib import Path
p=Path('zz-scripts/chapter09/plot_fig01_phase_overlay.py')
if p.exists():
    L=p.read_text(encoding='utf-8', errors='replace').splitlines()
    s='\\n'.join(f'{i+1:6d}  {L[i]}' for i in range(min(len(L),480))[379:480])
    print(s)
PY" \
    "$OUT/ctx/04_ch09_380_480.txt"
pause

# ---------- [05] Greps argparse ----------
run "[05] Greps argparse (add_argument) — brut" \
    "grep -RIn --line-number --include='*.py' 'add_argument\\(' zz-scripts || true" \
    "$OUT/files/05_argparse_grep.txt"
pause

# ---------- [06] sys.exit détectés ----------
run "[06] sys.exit détectés (potentiels aborts)" \
    "grep -RIn --include='*.py' 'sys\\.exit\\(' zz-scripts || true" \
    "$OUT/files/06_sys_exit_all.txt"
pause

# ---------- [07] Usage pyplot direct ----------
run "[07] Usage pyplot direct (plt.)" \
    "grep -RIn --include='*.py' 'plt\\.' zz-scripts || true" \
    "$OUT/files/07_pyplot.txt"
pause

# ---------- [08] savefig / makedirs ----------
run "[08] savefig / makedirs — patterns" \
    "echo '## makedirs'; grep -RIn --include='*.py' 'os\\.makedirs\\(' zz-scripts || true; echo '## savefig'; grep -RIn --include='*.py' 'savefig\\(' zz-scripts || true" \
    "$OUT/files/08_io_patterns.txt"
pause

# ---------- [09] MPL backend/style ----------
run "[09] MPL backend/style (présence fichiers config)" \
    "python3 - <<'PY'
import matplotlib as mpl, os, sys, json, pathlib
print('backend_default:', mpl.get_backend().lower())
print('MPLCONFIGDIR:', os.environ.get('MPLCONFIGDIR'))
for fp in ['zz-configuration/mcgt.mplstyle','zz-configuration/mcgt_rc.toml']:
    print(('OK ' if pathlib.Path(fp).exists() else 'NOK ')+fp)
PY" \
    "$OUT/files/09_mpl_style.txt"
pause

# ---------- [10] zz-config présence ----------
run "[10] zz-config (params.default.toml / params.levels.json / overrides)" \
    "for f in zz-config/params.default.toml zz-config/params.levels.json; do [ -f \$f ] && echo OK \$f || echo NOK \$f; done" \
    "$OUT/files/10_zz_config.txt"
pause

# ---------- [11] 'Static help' : ne lance aucun script ----------
run "[11] Static help (inventaire CLI sans exécuter)" \
    "python3 - <<'PY'
# On infère les options communes par greps (ne lance pas les scripts).
import re, pathlib, json
root=pathlib.Path('zz-scripts')
rows=[]
for p in root.rglob('*.py'):
    s=p.read_text('utf-8','ignore')
    opts=set(m.group(1) for m in re.finditer(r\"--([a-z0-9-]+)\" , s))
    rows.append({'file':str(p),'opts':sorted(opts)})
want={'out','outdir','format','dpi','figsize','transparent','style','log-level','seed','save-pdf','save-svg','show'}
missing=[]
for r in rows:
    miss=sorted(want-set(r['opts']))
    if miss:
        missing.append({'file':r['file'],'missing':miss})
for it in missing:
    print(f\"{it['file']} MISSING: \"+', '.join('--'+m for m in it['missing']))
PY" \
    "$OUT/files/11_static_help.txt"
pause

# ---------- [12] Mapping (scripts → inputs référencés) ----------
run "[12] Mapping (scripts → inputs référencés)" \
    "grep -RIn --include='*.py' -E 'pd\\.read_csv\\(|json\\.load\\(|read_text\\(' zz-scripts | sed 's#\\s\\+# #g' || true" \
    "$OUT/files/12_mapping_inputs.txt"
pause

# ---------- [13] Existence physique des inputs ch09/ch10 ----------
run "[13] Existence inputs (ch09/ch10) — best guesses" \
    "for f in zz-data/chapter09/09_phase_data.csv zz-data/chapter09/09_phase_meta.json zz-data/chapter10/10_metrics_primary.csv zz-data/chapter10/10_milestones.csv; do [ -f \"\$f\" ] && echo OK \"\$f\" || echo NOK \"\$f\"; done" \
    "$OUT/files/13_inputs_exist.txt"
pause

# ---------- [14] Chemins figures convention ----------
run "[14] Conformité chemins figures (pattern)" \
    "git ls-files 'zz-figures/**.png' 'zz-figures/**.pdf' 'zz-figures/**.svg' 2>/dev/null | sed 's#^zz-figures/##' | sort || true" \
    "$OUT/files/14_fig_paths.txt"
pause

# ---------- [15] Manifest(s) : stats & manquants ----------
run "[15] Manifest(s): figures listées → existent-elles ?" \
    "python3 - <<'PY'
from pathlib import Path
import json, os
def check(fp):
    if not Path(fp).exists():
        print(f'!! missing file: {fp}')
        return
    J=json.loads(Path(fp).read_text('utf-8'))
    figs=[e.get('path') for e in J if isinstance(e, dict)]
    missing=[]
    for f in figs:
        if not f: continue
        if not Path(f).exists():
            missing.append(f)
    print(f'== {fp} ==')
    print(f'FIG_ENTRIES={len(figs)} MISSING={len(missing)}')
    for m in missing[:50]:
        print('  MISSING', m)
check('zz-manifests/manifest_master.json')
check('zz-manifests/manifest_publication.json')
PY" \
    "$OUT/files/15_manifest_check.txt"
pause

# ---------- [16] Lints simples ----------
run "[16] Lints doctrinaux (tabs/trailing)" \
    "echo '## tabs'; grep -RInP --include='*.py' '\\t' zz-scripts || true; echo '## trailing'; grep -RInP --include='*.py' ' +$' zz-scripts || true" \
    "$OUT/files/16_lints.txt"
pause

# ---------- [17] Déterminisme (np.random) ----------
run "[17] Determinisme: np.random vs default_rng" \
    "echo '## np.random.seed usage'; grep -RIn --include='*.py' 'np\\.random\\.seed' zz-scripts || true; echo '## default_rng usage'; grep -RIn --include='*.py' 'default_rng\\(' zz-scripts || true" \
    "$OUT/files/17_determinism.txt"
pause

# ---------- [18] _common/ existence ----------
run "[18] _common/ et archives précédentes" \
    "([ -d zz-scripts/_common ] && echo OK _common || echo '(pas de _common/)'); echo '## archives /tmp mcgt_extract_*'; ls -d /tmp/mcgt_extract_* 2>/dev/null || true" \
    "$OUT/files/18_common_archives.txt"
pause

# ---------- [19] Résumé + tarball ----------
{
  echo ">> Résumé:  $OUT/summary.txt"
  echo ">> Archive: $OUT.tgz"
  echo ">> Dossiers: $OUT/files/  $OUT/ctx/"
} | tee "$OUT/summary.txt"

tar -C "$(dirname "$OUT")" -czf "$OUT.tgz" "$(basename "$OUT")" 2>/dev/null || true
echo "[OK] Extraction v4 terminée. Dossier: $OUT"
