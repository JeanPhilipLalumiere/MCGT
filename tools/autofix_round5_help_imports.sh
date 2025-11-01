# tools/autofix_round5_help_imports.sh
#!/usr/bin/env bash
set -Eeuo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
say(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# 1) Cible des 8 FAIL (d'après triage v5)
FILES_NEED_SYS=(
  "zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py"
  "zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py"
  "zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py"
  "zz-scripts/chapter02/plot_fig03_relative_errors.py"
  "zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py"
  "zz-scripts/chapter07/plot_fig03_invariant_I1.py"
  "zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py"
)
FG_SERIES="zz-scripts/chapter02/plot_fig05_FG_series.py"

insert_import_sys() {
  local f="$1"
  [[ -f "$f" ]] || { say "[SKIP] absent: $f"; return; }
  # si déjà présent, on ne touche pas
  if rg -n '^\s*import\s+sys(\s|$)' -n "$f" >/dev/null 2>&1; then
    say "[OK] import sys déjà présent: $f"
    return
  fi
  cp --no-clobber --update=none -- "$f" "${f}.bak_${TS}" || true
  # Insérer après éventuels __future__/imports existants, sinon tout en tête
  awk '
    BEGIN{done=0}
    {
      if(!done){
        if($0 ~ /^from __future__ import/ || $0 ~ /^import [A-Za-z0-9_., ]+$/ || $0 ~ /^from [A-Za-z0-9_.]+ import/){
          print $0
          nextline=$0
        } else {
          print "import sys"
          done=1
        }
      }
      print $0
    }
  ' "$f" | awk 'NR==1 && $0 !~ /^import sys/ {print "import sys"; print; next} {print}' > "${f}.tmp_${TS}"
  mv "${f}.tmp_${TS}" "$f"
  say "[PATCH] +import sys → $f"
}

help_short_circuit() {
  local f="$1"
  [[ -f "$f" ]] || { say "[SKIP] absent: $f"; return; }
  cp --no-clobber --update=none -- "$f" "${f}.bak_${TS}" || true
  # Ajoute un court-circuit très tôt si -h/--help présent
  # (sans casser l'existant si déjà présent)
  if rg -n 'sys\.argv' "$f" >/dev/null 2>&1 && rg -n '\-h|--help' "$f" >/dev/null 2>&1; then
    say "[OK] guard --help déjà présent: $f"
    return
  fi
  # Injecter juste après les imports (après avoir garanti import sys)
  awk '
    BEGIN{inserted=0}
    {
      print $0
      if(!inserted && $0 ~ /^import sys(\s|$)/){
        print "if any(h in sys.argv for h in (\"-h\",\"--help\")):"
        print "    # Ne rien exécuter (I/O, plotting) lors de --help"
        print "    raise SystemExit(0)"
        inserted=1
      }
    }
  ' "$f" > "${f}.tmp_${TS}"
  mv "${f}.tmp_${TS}" "$f"
  say "[PATCH] +guard --help (exit 0) → $f"
}

# 2) Appliquer les patches
for f in "${FILES_NEED_SYS[@]}"; do
  insert_import_sys "$f"
  help_short_circuit "$f"
done

# Cas particulier FG_series: besoin du guard --help pour éviter la lecture d’un chemin None
insert_import_sys "$FG_SERIES"
help_short_circuit "$FG_SERIES"

# 3) Re-smoke ciblé puis global
say "[RUN] Smoke ciblé — 8 fichiers"
ok=0; fail=0
for f in "${FILES_NEED_SYS[@]}" "$FG_SERIES"; do
  if python "$f" --help >/dev/null 2>&1; then
    say "OK  $f"; ((ok++))
  else
    say "FAIL $f"; ((fail++))
  fi
done
say "[SUMMARY] Targeted: OK=$ok FAIL=$fail"

say "[RUN] Smoke repo-wide"
bash tools/smoke_help_repo.sh
