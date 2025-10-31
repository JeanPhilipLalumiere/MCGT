# repo_stage_readme_repro_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_readme_repro_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD

cat > README-REPRO.md <<'MD'
# MCGT — Reproductibilité (Round-2)

## Portée
- Figures validées :  
  - `zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png`  
  - `zz-figures/chapter10/10_fig_0{1..5}_*.png`
- Inventaire ADD/REVIEW via `repo_probe_round2_consistency.sh` (attendu : ADD 20/20, REVIEW 16/16).

> Note : le producteur historique `zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py` est conservé (cassé).  
> La génération ch09/fig03 se fait via **runner sûr** : `zz-scripts/chapter09/run_fig03_safe.py`.

## Environnement
- Python 3.10/3.11/3.12 (CI “ci-smoke”)
- Dépendances min : `pip install -r zz-scripts/chapter10/requirements.txt`

Option Conda :
```bash
conda create -n mcgt-dev python=3.11 -y
conda activate mcgt-dev
python -m pip install --upgrade pip
pip install -r zz-scripts/chapter10/requirements.txt
