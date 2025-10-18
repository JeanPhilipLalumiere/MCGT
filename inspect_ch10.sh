#!/usr/bin/env bash
# inspect_ch10.sh — Diagnostique les KO chap.10 et empêche la fermeture de la fenêtre

set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    echo "[HOLD] Pas de TTY : ouverture d'un shell interactif (tapez 'exit' pour fermer)."
    bash --noprofile --norc -i
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT

# (optionnel) activer l’environnement
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

SCRIPTS=(
  "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
  "zz-scripts/chapter10/plot_fig06_residual_map.py"
)

LOG="zz-manifests/last_orchestration_ch10.log"
if [ ! -s "$LOG" ]; then
  echo "[ERR] Log $LOG introuvable ou vide. Lance d'abord ./run_ch10_v3.sh"
  exit 2
fi

echo "[INFO] Analyse de $LOG"
python3 - "$LOG" <<'PY'
import sys, re, pathlib, json, itertools
logp = pathlib.Path(sys.argv[1]); txt = logp.read_text(errors="ignore")

# découper en blocs par [RUN]
blocks = []
cur = None
for line in txt.splitlines():
    m = re.match(r"^\[RUN\]\s+(.+plot_fig[^\s]+\.py).*$", line)
    if m:
        cur = {"script": m.group(1).strip(), "lines":[]}
        blocks.append(cur); continue
    if cur: cur["lines"].append(line)

def tail_exc(lines, n=50):
    # heuristique: prendre la dernière trace (stack/erreur)
    tail = "\n".join(lines[-n:])
    return tail

# regrouper erreurs simples
summary = {}
for b in blocks:
    body = "\n".join(b["lines"])
    kinds = []
    if "error: the following arguments are required:" in body:
        kinds.append("ARGS_MANQUANTS")
    if "FileNotFoundError" in body or "No such file or directory" in body:
        kinds.append("FICHIER_MANQUANT")
    if re.search(r"KeyError:\s*'", body):
        kinds.append("COLONNE_MANQUANTE")
    if "ValueError" in body:
        kinds.append("VALUE_ERROR")
    if "TypeError" in body:
        kinds.append("TYPE_ERROR")
    if not kinds:
        kinds.append("AUTRE")
    summary.setdefault(b["script"], set()).update(kinds)

print("=== KO chap.10 — Typologie (par script) ===")
for scr, ks in summary.items():
    print(f"- {scr}: {', '.join(sorted(ks))}")

print("\n=== Détails (dernière trace/50 lignes) ===")
for b in blocks:
    print(f"\n--- {b['script']} ---")
    print(tail_exc(b["lines"], n=50))
PY

echo
echo "[INFO] Affichage des signatures d'arguments (-h) pour chaque script KO détecté :"
for s in "${SCRIPTS[@]}"; do
  echo
  echo ">>> $s -h"
  python3 "$s" -h 2>&1 | sed -n '1,200p' || true
done

echo
echo "[HINT] Si des messages indiquent des chemins/colonnes manquants :"
echo "  - crée un alias/symlink vers le fichier attendu dans zz-data/chapter10/"
echo "  - ou adapte les flags (--x-col/--y-col/--group-col/--p95-ref/--boot-ci, etc.) dans run_ch10_v3.sh"
