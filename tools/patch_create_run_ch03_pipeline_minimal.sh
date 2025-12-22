#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul tools/run_ch03_pipeline_minimal.sh est touché (avec backup .bak si existant).";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH03 – Création / normalisation de run_ch03_pipeline_minimal.sh =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("tools/run_ch03_pipeline_minimal.sh")
if path.exists():
    backup = path.with_suffix(".sh.bak_before_ch03_patch")
    shutil.copy2(path, backup)
    print(f"[BACKUP] {backup} créé")

content = """#!/usr/bin/env bash
set -Eeuo pipefail

echo "== CH03 – PIPELINE MINIMAL : stabilite-fR =="
echo

echo "[1/2] Génération des données..."
python scripts/03_stability_domain/generate_data_chapter03.py
echo "✅ Génération Chapter 3 OK"
echo

echo "[2/2] Génération des figures..."
python scripts/03_stability_domain/plot_fig01_fR_stability_domain.py
python scripts/03_stability_domain/plot_fig02_fR_fRR_vs_f.py
python scripts/03_stability_domain/plot_fig03_ms2_R0_vs_f.py
python scripts/03_stability_domain/plot_fig04_fR_fRR_vs_f.py
python scripts/03_stability_domain/plot_fig05_interpolated_milestones.py
python scripts/03_stability_domain/plot_fig06_grid_quality.py
python scripts/03_stability_domain/plot_fig07_ricci_fR_vs_z.py
python scripts/03_stability_domain/plot_fig08_ricci_fR_vs_T.py

echo
echo "[OK] CH03 pipeline minimal terminé sans erreur."
"""

path.write_text(content)
print("[WRITE] tools/run_ch03_pipeline_minimal.sh écrit / mis à jour.")
PYEOF

echo
echo "Terminé (patch_create_run_ch03_pipeline_minimal)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
