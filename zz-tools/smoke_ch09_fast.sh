export PYTHONPATH="$(git rev-parse --show-toplevel):$PYTHONPATH"
# zz-tools/smoke_ch09_fast.sh
#!/usr/bin/env bash
set -Eeuo pipefail
START_TS="$(date +%Y%m%d_%H%M%S)"
LOG="zz-out/runlogs/smoke_ch09_fast_${START_TS}.log"
mkdir -p zz-out/runlogs zz-out/chapter09 zz-figures/chapter09
exec > >(tee -a "$LOG") 2>&1
echo "[INFO] Smoke CH09 (fast)"

# 1) Génération robuste
python3 zz-scripts/chapter09/generate_data_chapter09.py

# 2) fig01 (tolérante) — non bloquant
python3 zz-scripts/chapter09/plot_fig01_phase_overlay.py || echo "[WARN] fig01 non bloquant"

# 3) Builder fig02
python3 zz-tools/build_fig02_input.py || true

# 4) Normalisation garde-fou fig02_input
python3 - <<'PY'
from pathlib import Path
import pandas as pd
p = Path("zz-out/chapter09/fig02_input.csv")
if p.exists():
    df = pd.read_csv(p)
    # f_Hz
    for cand in ("f_Hz","f","freq","frequency","frequency_Hz","nu","nu_Hz"):
        if cand in df.columns:
            if "f_Hz" not in df.columns: df["f_Hz"] = df[cand]
            break
    # phi_ref
    if "phi_ref" not in df.columns:
        for cand in ("phi_ref","phi_imr","phi_ref_cal","phi_ref_raw","phi_ref_model"):
            if cand in df.columns:
                df["phi_ref"] = df[cand]; break
    # mcgt/active
    if "phi_mcgt" not in df.columns:
        for cand in ("phi_mcgt","phi_mcgt_cal","phi_active","phi_model","phi_mcgt_active"):
            if cand in df.columns:
                df["phi_mcgt"] = df[cand]; break
    if "phi_active" not in df.columns and "phi_mcgt" in df.columns:
        df["phi_active"] = df["phi_mcgt"]
    df.to_csv(p, index=False)
    print("[OK] fig02_input normalisé")
else:
    print("[INFO] pas d'entrée fig02_input (builder non bloquant)")
PY

# 5) fig02 natif ou fallback
OUT="zz-figures/chapter09/09_fig_02_residual_phase.png"
if [[ -s zz-out/chapter09/fig02_input.csv ]]; then
  if ! python3 zz-scripts/chapter09/plot_fig02_residual_phase.py \
        --csv zz-out/chapter09/fig02_input.csv \
        --out "$OUT" --dpi 120 ; then
    echo "[WARN] fig02 natif a échoué — fallback"
    python3 zz-tools/plot_fig02_from_input.py --csv zz-out/chapter09/fig02_input.csv --out "$OUT" --dpi 120 || echo "[WARN] fallback fig02 a échoué"
  fi
else
  echo "[INFO] fig02: pas d'entrée — skip"
fi

# 6) Checks simples
test -s zz-data/chapter09/09_phases_mcgt.csv
test -s zz-figures/chapter09/09_fig_01_phase_overlay.png
test -s "$OUT" && echo "[OK] CH09 complet"
