# ==== MCGT — PROBE PACK v3 (20 sondes, pauses, lecture-seule) ====
# Recommandé : sauvegarder comme tools/probe_pack_v3.sh puis:  bash tools/probe_pack_v3.sh
# Garde-fous: ne quitte jamais sur erreur; pause Entrée à chaque étape.
set +e
export LC_ALL=C.UTF-8 TZ=UTC
trap 'echo; echo "[WARN] Une commande a échoué, mais le script continue."; ' ERR
pause(){ echo; read -r -p "➡️  Appuie sur Entrée pour continuer..." _; echo; }
note(){ printf "\n==== [%02d] %s ====\n" "$1" "$2" | tee -a "$OUT/summary.txt"; }

# Contexte
conda activate mcgt-dev 2>/dev/null || true
which python || true
python -V || true
cd ~/MCGT 2>/dev/null || cd .

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="/tmp/mcgt_extract_${STAMP}_v3"
mkdir -p "$OUT"/{logs,files,ctx,grep}
echo "[ECHO] Dossier sortie: $OUT"

# 01 — Git branches, ahead/behind, HEAD bref
note 1 "Git: branches, upstream, ahead/behind"
{
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git branch -vv
    echo "----"; git for-each-ref --format='%(refname:short) %(upstream:short) A=%(ahead) B=%(behind)' refs/heads | sed 's/^/BRANCH /'
    echo "----"; git log --oneline -n 20 --decorate
  else echo "(pas un repo git)"; fi
} | tee "$OUT/files/01_git_branches.txt" >/dev/null
echo "[ECHO] $OUT/files/01_git_branches.txt"; sed -n '1,60p' "$OUT/files/01_git_branches.txt" || true
pause

# 02 — Inventaire backups / fichiers temporaires (purgebak, rescue, round3bak, .bak, .rXX.)
note 2 "Backups/artefacts (à purger plus tard) — comptage"
{ find . -type f \( -name '*.bak*' -o -name '*.purgebak*' -o -name '*.round3bak*' -o -name '*.rescue*' -o -name '*.r[0-9]*' \) -printf '%p\n' | sort; } \
| tee "$OUT/files/02_backups.txt" >/dev/null
echo "[ECHO] $OUT/files/02_backups.txt"; sed -n '1,80p' "$OUT/files/02_backups.txt" || true
pause

# 03 — PyCompile global (résumé rapide)
note 3 "py_compile global — résumé"
python - <<'PY' | tee "$OUT/files/03_pycompile.txt" >/dev/null
import os, py_compile, sys
paths=[]
for base in ("zz-scripts","_common","zz-schemas"):
    if os.path.isdir(base):
        for r,_,fs in os.walk(base):
            for f in fs:
                if f.endswith(".py"):
                    paths.append(os.path.join(r,f))
errs=[]
for p in sorted(paths):
    try: py_compile.compile(p, doraise=True)
    except Exception as e: errs.append((p,str(e)))
print(f"TOTAL={len(paths)} ERRORS={len(errs)}")
for p,e in errs: print("ERR",p,"::",e)
PY
echo "[ECHO] $OUT/files/03_pycompile.txt"; sed -n '1,120p' "$OUT/files/03_pycompile.txt" || true
pause

# 4 — Contexte étendu du fichier fautif ch09 (380–430 et 430–480)
note 4 "CTX élargi ch09/plot_fig01_phase_overlay.py (380–480)"
p='zz-scripts/chapter09/plot_fig01_phase_overlay.py'
if [ -f "$p" ]; then
  nl -ba "$p" | sed -n '380,430p' > "$OUT/ctx/04_ch09_380_430.txt"
  nl -ba "$p" | sed -n '430,480p' > "$OUT/ctx/04_ch09_430_480.txt"
  echo "[ECHO] $OUT/ctx/04_ch09_380_430.txt"; sed -n '1,80p' "$OUT/ctx/04_ch09_380_430.txt"
  echo "[ECHO] $OUT/ctx/04_ch09_430_480.txt"; sed -n '1,80p' "$OUT/ctx/04_ch09_430_480.txt"
else echo "(fichier absent)"; fi
pause

# 5 — Conformité argparse vs contrat commun (scan brut add_argument)
note 5 "Greps argparse (add_argument) — brut"
{ grep -RIn --include='plot_fig*.py' 'add_argument' zz-scripts 2>/dev/null | sed 's,^\./,,g' || true; } \
| tee "$OUT/files/05_argparse_grep.txt" >/dev/null
echo "[ECHO] $OUT/files/05_argparse_grep.txt"; sed -n '1,80p' "$OUT/files/05_argparse_grep.txt" || true
pause

# 6 — `sys.exit` hors --help (liste)
note 6 "sys.exit détectés (potentiels aborts)"
{ grep -RIn --include='*.py' 'sys\.exit' zz-scripts 2>/dev/null || true; } \
| tee "$OUT/files/06_sys_exit_all.txt" >/dev/null
echo "[ECHO] $OUT/files/06_sys_exit_all.txt"; sed -n '1,80p' "$OUT/files/06_sys_exit_all.txt" || true
pause

# 7 — Utilisation pyplot directe (plt.) — (fixé /dev/null)
note 7 "Usage pyplot direct (plt.)"
{ grep -RIn --include='plot_fig*.py' '\bplt\.' zz-scripts 2>/dev/null || true; } \
| tee "$OUT/files/07_pyplot.txt" >/dev/null
echo "[ECHO] $OUT/files/07_pyplot.txt"; sed -n '1,120p' "$OUT/files/07_pyplot.txt" || true
pause

# 8 — savefig/os.makedirs patterns
note 8 "savefig / makedirs — patterns"
{
  echo "## makedirs"; grep -RIn --include='plot_fig*.py' 'os\.makedirs' zz-scripts 2>/dev/null || true
  echo "## savefig";  grep -RIn --include='plot_fig*.py' 'savefig\('    zz-scripts 2>/dev/null || true
} | tee "$OUT/files/08_io_patterns.txt" >/dev/null
echo "[ECHO] $OUT/files/08_io_patterns.txt"; sed -n '1,120p' "$OUT/files/08_io_patterns.txt" || true
pause

# 9 — Backend Matplotlib et style repo (mcgt.mplstyle / rc)
note 9 "MPL backend/style (présence fichiers config)"
{
  python - <<'PY'
import matplotlib, os, json
print("backend_default:", matplotlib.get_backend())
print("MPLCONFIGDIR:", os.environ.get("MPLCONFIGDIR"))
PY
  for f in zz-configuration/mcgt.mplstyle zz-configuration/mcgt_rc.toml; do
    if [ -f "$f" ]; then echo "OK $f"; head -n 20 "$f"; else echo "NOK $f"; fi
  done
} | tee "$OUT/files/09_mpl_style.txt" >/dev/null
echo "[ECHO] $OUT/files/09_mpl_style.txt"; sed -n '1,80p' "$OUT/files/09_mpl_style.txt" || true
pause

# 10 — Présence/état zz-config/ (params table + levels)
note 10 "zz-config (params.default.toml / params.levels.json / overrides)"
{
  for f in zz-config/params.default.toml zz-config/params.levels.json; do
    if [ -f "$f" ]; then echo "OK $f"; sed -n '1,80p' "$f"; else echo "NOK $f"; fi
  done
  [ -d zz-config/overrides ] && ls -l zz-config/overrides || echo "(pas d'overrides/)"
} | tee "$OUT/files/10_zz_config.txt" >/dev/null
echo "[ECHO] $OUT/files/10_zz_config.txt"; sed -n '1,120p' "$OUT/files/10_zz_config.txt" || true
pause

# 11 — Scripts fumée candidats (présence & --help)
note 11 "Smoke candidats: --help (sans exécuter)"
{
  for s in \
    zz-scripts/chapter02/plot_fig06_alpha_fit.py \
    zz-scripts/chapter04/plot_fig02_invariants_histogram.py \
    zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py \
    zz-scripts/chapter09/plot_fig01_phase_overlay.py \
    zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  ; do
    if [ -f "$s" ]; then
      echo "---- $s --help"
      python "$s" --help 2>&1 | head -n 50
    else
      echo "(absent) $s"
    fi
  done
} | tee "$OUT/files/11_smoke_help.txt" >/dev/null
echo "[ECHO] $OUT/files/11_smoke_help.txt"; sed -n '1,120p' "$OUT/files/11_smoke_help.txt" || true
pause

# 12 — Mapping scripts→inputs (grep pd.read_csv/json/configparser)
note 12 "Mapping (scripts → inputs référencés)"
{ grep -RIn --include='plot_fig*.py' -E 'read_csv|json\.load|configparser' zz-scripts 2>/dev/null | sed 's,^\./,,g' || true; } \
| tee "$OUT/files/12_mapping_inputs.txt" >/dev/null
echo "[ECHO] $OUT/files/12_mapping_inputs.txt"; sed -n '1,120p' "$OUT/files/12_mapping_inputs.txt" || true
pause

# 13 — Existence effective des inputs clés ch09/ch10
note 13 "Existence physique des inputs (ch09/ch10) — best guesses"
{
  for f in \
    zz-data/chapter09/09_phase_data.csv \
    zz-data/chapter09/09_phase_meta.json \
    zz-data/chapter10/10_metrics_primary.csv \
    zz-data/chapter10/10_milestones.csv \
  ; do
    if [ -f "$f" ]; then echo "OK  $f"; ls -lh "$f"; head -n 3 "$f" 2>/dev/null || true
    else echo "NOK $f"; fi
  done
} | tee "$OUT/files/13_inputs_exist.txt" >/dev/null
echo "[ECHO] $OUT/files/13_inputs_exist.txt"; sed -n '1,80p' "$OUT/files/13_inputs_exist.txt" || true
pause

# 14 — Figures attendues (convention chapterNN/NN_fig_XX_*.png)
note 14 "Conformité chemins figures (pattern convention)"
{
  find zz-figures -type f -name '[0-9][0-9]_fig_[0-9][0-9]_*.png' -printf '%P\n' 2>/dev/null | sort | head -n 120
} | tee "$OUT/files/14_fig_paths.txt" >/dev/null
echo "[ECHO] $OUT/files/14_fig_paths.txt"; sed -n '1,120p' "$OUT/files/14_fig_paths.txt" || true
pause

# 15 — Manifest(s) chargés + cohérence simple (chemins existants)
note 15 "Manifest(s): figures listées → existent-elles ?"
python - <<'PY' | tee "$OUT/files/15_manifest_check.txt" >/dev/null
from pathlib import Path
import json, sys
root=Path(".")
candidates=[
    root/"zz-manifests/manifest_master.json",
    root/"zz-manifests/manifest_publication.json",
]
for p in candidates:
    if not p.exists(): print(f"(absent) {p}"); continue
    d=json.loads(p.read_text(encoding="utf-8"))
    print(f"== {p} ==")
    miss=0; tot=0
    for it in d if isinstance(d,list) else d.get("entries",[]):
        path=it.get("path") or it.get("output") or ""
        if path:
            tot+=1
            if not (root/path).exists():
                miss+=1
    print(f"FIG_ENTRIES={tot} MISSING={miss}")
PY
echo "[ECHO] $OUT/files/15_manifest_check.txt"; sed -n '1,120p' "$OUT/files/15_manifest_check.txt" || true
pause

# 16 — Lints doctrinaux rapides (except nu, tabs, trailing)
note 16 "Lints doctrinaux (except nu / tabs / trailing)"
{
  echo "## except nu"; grep -RIn --include='*.py' '^[[:space:]]*except:[[:space:]]*$' zz-scripts 2>/dev/null || true
  echo "## tabs"; grep -RInP "\t" zz-scripts 2>/dev/null || true
  echo "## trailing"; grep -RInE " +$" zz-scripts 2>/dev/null | head -n 200 || true
} | tee "$OUT/files/16_lints.txt" >/dev/null
echo "[ECHO] $OUT/files/16_lints.txt"; sed -n '1,120p' "$OUT/files/16_lints.txt" || true
pause

# 17 — Heuristique: add_argument manquants vs contrat commun (liste brute)
note 17 "Heuristique: options manquantes (out,outdir,format,dpi,figsize,transparent,style,log-level,seed,save-pdf,save-svg,show)"
python - <<'PY' | tee "$OUT/files/17_cli_missing.txt" >/dev/null
import re, os
req = ["--out","--outdir","--format","--dpi","--figsize","--transparent","--style","--log-level","--seed","--save-pdf","--save-svg","--show"]
hits={}
for dirpath,_,files in os.walk("zz-scripts"):
    for f in files:
        if not f.startswith("plot_fig") or not f.endswith(".py"): continue
        p=os.path.join(dirpath,f)
        txt=open(p,"r",encoding="utf-8",errors="replace").read()
        present=set()
        for r in req:
            if re.search(re.escape(r), txt): present.add(r)
        missing=[r for r in req if r not in present]
        if missing:
            print(p, "MISSING:", ",".join(missing))
PY
echo "[ECHO] $OUT/files/17_cli_missing.txt"; sed -n '1,120p' "$OUT/files/17_cli_missing.txt" || true
pause

# 18 — Déterminisme (vars CPU/BLAS) + numpy RNG usage (grep simple)
note 18 "Determinisme: ENV & RNG np.random vs default_rng"
{
  env | grep -E '^(OMP|MKL|OPENBLAS|NUMEXPR|PYTHONHASHSEED)=' || true
  echo "## np.random.seed usage"; grep -RIn --include='*.py' 'np\.random\.seed\(' zz-scripts 2>/dev/null || true
  echo "## default_rng usage"; grep -RIn --include='*.py' 'np\.random\.default_rng\(' zz-scripts 2>/dev/null || true
} | tee "$OUT/files/18_determinism.txt" >/dev/null
echo "[ECHO] $OUT/files/18_determinism.txt"; sed -n '1,120p' "$OUT/files/18_determinism.txt" || true
pause

# 19 — Présence _common/ (inventaire si jamais apparu) + zips précédents
note 19 "_common/ et archives précédentes"
{
  if [ -d "_common" ]; then find _common -maxdepth 2 -type f -name '*.py' -printf '%P\n' | sort; else echo "(pas de _common/)"; fi
  echo "## archives /tmp mcgt_extract_*"; ls -1 /tmp/mcgt_extract_* 2>/dev/null | tail -n 20 || true
} | tee "$OUT/files/19_common_archives.txt" >/dev/null
echo "[ECHO] $OUT/files/19_common_archives.txt"; sed -n '1,120p' "$OUT/files/19_common_archives.txt" || true
pause

# 20 — Packaging final
note 20 "Tarball de tous les rapports"
tar -C /tmp -czf "/tmp/mcgt_extract_${STAMP}_v3.tgz" "$(basename "$OUT")" 2>/dev/null || true
echo ">> Résumé:  $OUT/summary.txt"
echo ">> Archive: /tmp/mcgt_extract_${STAMP}_v3.tgz"
echo ">> Dossiers: $OUT/files/  $OUT/ctx/"
read -r -p "✅ Fin du pack v3. Appuie sur Entrée pour revenir au prompt..." _
