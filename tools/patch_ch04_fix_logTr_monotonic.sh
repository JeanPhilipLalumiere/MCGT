#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter04/generate_data_chapter04.py est touché, avec backup .bak_fix_logTr.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH04 – Grille T_Gyr strictement croissante pour Pchip R/R0(T) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/chapter04/generate_data_chapter04.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier generate_data_chapter04.py introuvable.")

backup = path.with_suffix(".py.bak_fix_logTr")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()

old = '''    df_r = pd.read_csv(r_file)
    logT_r = np.log10(df_r["T_Gyr"])
    logR_data = np.log10(df_r["R_over_R0"])
    interp_logR = PchipInterpolator(logT_r, logR_data, extrapolate=True)
'''

new = '''    df_r = pd.read_csv(r_file)
    # Harmonisation des types + tri et suppression des doublons pour T_Gyr
    df_r = df_r.astype({"T_Gyr": float, "R_over_R0": float})
    df_r = df_r.sort_values("T_Gyr")
    df_r = df_r.drop_duplicates(subset="T_Gyr", keep="first")
    logT_r = np.log10(df_r["T_Gyr"].values)
    logR_data = np.log10(df_r["R_over_R0"].values)
    interp_logR = PchipInterpolator(logT_r, logR_data, extrapolate=True)
'''

if old not in text:
    raise SystemExit("[ERROR] Motif attendu pour df_r/logT_r/logR_data non trouvé, patch abandonné.")
path.write_text(text.replace(old, new))
print("[WRITE] Bloc df_r/logT_r/logR_data mis à jour pour garantir une grille strictement croissante.")
PYEOF

echo
echo "Terminé (patch_ch04_fix_logTr_monotonic)."
echo "Appuie sur Entrée pour revenir au shell..."
read -r _
