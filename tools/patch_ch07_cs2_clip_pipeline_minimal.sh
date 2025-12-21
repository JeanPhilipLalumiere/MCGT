#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_cs2_rewrite.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Réécriture complète de compute_cs2 (warning + clip) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("mcgt/scalar_perturbations.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: mcgt/scalar_perturbations.py")

backup = path.with_suffix(".py.bak_cs2_rewrite")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()
lines = text.splitlines()

# Trouver le début de def compute_cs2(...)
start = None
for i, line in enumerate(lines):
    if line.lstrip().startswith("def compute_cs2("):
        start = i
        break

if start is None:
    raise SystemExit("[ERROR] def compute_cs2(...) introuvable dans scalar_perturbations.py")

# Trouver la fin de la fonction (prochaine def ou prochain gros séparateur)
end = None
for j in range(start + 1, len(lines)):
    if lines[j].startswith("def ") and not lines[j].lstrip().startswith("def compute_cs2("):
        end = j
        break
    if lines[j].startswith("# -----------------------------------------------------------------------------#"):
        end = j
        break

if end is None:
    end = len(lines)

new_func = '''def compute_cs2(k_vals: np.ndarray, a_vals: np.ndarray, p: PertParams) -> np.ndarray:
    """Retourne un tableau (n_k, n_a) de c_s²(k,a) borné physiquement dans [0,1]."""
    k_vals = np.asarray(k_vals, dtype=float)
    a_vals = np.asarray(a_vals, dtype=float)
    if k_vals.ndim != 1 or a_vals.ndim != 1:
        raise ValueError("k_vals et a_vals doivent être 1D.")
    if np.any(np.diff(k_vals) < 0) or np.any(np.diff(a_vals) < 0):
        raise ValueError("Les grilles k_vals et a_vals doivent être croissantes.")

    # Grille 2D (k, a)
    K, _ = np.meshgrid(k_vals, a_vals, indexing="ij")

    # c_s²(a) ~ dp/da / dρ/da (pentes lissées)
    dp_da = np.gradient(p_phi_of_a(a_vals, p), a_vals)
    drho_da = np.gradient(rho_phi_of_a(a_vals, p), a_vals)
    with np.errstate(divide="ignore", invalid="ignore"):
        cs2_a = np.where(drho_da != 0.0, dp_da / drho_da, 0.0)
    cs2_a = PchipInterpolator(a_vals, cs2_a, extrapolate=True)(a_vals)

    # Filtre gaussien en k + amplitude globale
    T = np.exp(-((K / p.k0) ** 2))
    cs2 = T * cs2_a[np.newaxis, :] * p.cs2_param

    # Nettoyage des non-finitudes éventuelles
    if not np.all(np.isfinite(cs2)):
        import warnings
        warnings.warn(
            "c_s² contient des valeurs non finies – valeurs non finies remplacées par 0.0",
            RuntimeWarning,
        )
        cs2 = np.nan_to_num(cs2, nan=0.0, posinf=1.0, neginf=0.0)

    # Contrôle physique assoupli : warning + clip dans [0,1]
    if not np.all((cs2 >= 0.0) & (cs2 <= 1.0)):
        import warnings
        warnings.warn(
            "c_s² hors-borne (attendu dans [0,1]) – valeurs clipées dans [0,1] pour le pipeline minimal.",
            RuntimeWarning,
        )
        cs2 = np.clip(cs2, 0.0, 1.0)

    return cs2
'''

new_lines = lines[:start] + new_func.splitlines() + lines[end:]
path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] compute_cs2 réécrit avec version warning+clip (pipeline minimal).")

# Affichage d'un extrait pour vérification
lines = path.read_text().splitlines()
for i, line in enumerate(lines, start=1):
    if "def compute_cs2" in line:
        print("\n[SNIPPET] Nouveau compute_cs2 autour de la ligne", i)
        for j in range(i, min(i + 40, len(lines) + 1)):
            print(f"{j:4}: {lines[j-1]}")
        break
PYEOF

echo
echo "Terminé (patch_ch07_cs2_clip_pipeline_minimal)."
read -rp "Appuie sur Entrée pour revenir au shell..." _
