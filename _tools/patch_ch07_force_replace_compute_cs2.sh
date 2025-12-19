#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_cs2_force_replace.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Remplacement forcé de compute_cs2 (warning + clip) =="

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("mcgt/scalar_perturbations.py")
if not path.exists():
    raise SystemExit("[ERROR] Fichier introuvable: " + str(path))

# Backup de l'état actuel (restauré depuis un .bak propre)
backup = path.with_suffix(".py.bak_cs2_force_replace")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

text = path.read_text()
lines = text.splitlines()

# Localiser le début / fin de compute_cs2
start = None
end = None
for i, line in enumerate(lines):
    if line.lstrip().startswith("def compute_cs2"):
        start = i
        break

if start is None:
    raise SystemExit("[ERROR] def compute_cs2(...) introuvable dans scalar_perturbations.py")

# On cherche la prochaine définition de top-level (def ou class non indentée)
for j in range(start + 1, len(lines)):
    stripped = lines[j].lstrip()
    if stripped.startswith("def ") or stripped.startswith("class "):
        # On considère que compute_cs2 se termine juste avant
        end = j - 1
        break

if end is None:
    # compute_cs2 va jusqu'à la fin du fichier
    end = len(lines) - 1

print(f"[INFO] compute_cs2 détectée de la ligne {start+1} à {end+1}")

# Nouvelle version de compute_cs2 (warning + clip)
new_func = """def compute_cs2(k_vals: np.ndarray, a_vals: np.ndarray, p: PertParams) -> np.ndarray:
    \"\"\"Retourne un tableau (n_k, n_a) de c_s²(k,a) borné physiquement dans [0,1].

    Version assouplie pour le *pipeline minimal* :
    - on nettoie les NaN / ±inf,
    - on émet un warning si des valeurs sortent de [0,1],
    - on clippe ensuite dans [0,1] au lieu de lever une ValueError.
    \"\"\"
    # Validation basique des grilles
    k_vals = np.asarray(k_vals, dtype=float)
    a_vals = np.asarray(a_vals, dtype=float)
    if k_vals.ndim != 1 or a_vals.ndim != 1:
        raise ValueError("k_vals et a_vals doivent être 1D.")
    if not (np.all(np.diff(k_vals) >= 0.0) and np.all(np.diff(a_vals) >= 0.0)):
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
    import warnings
    if not np.all(np.isfinite(cs2)):
        warnings.warn(
            "c_s² contient des valeurs non finies – valeurs non finies remplacées par 0.0",
            RuntimeWarning,
        )
        cs2 = np.nan_to_num(cs2, nan=0.0, posinf=1.0, neginf=0.0)

    # Contrôle physique assoupli : warning + clip dans [0,1]
    if not np.all((cs2 >= 0.0) & (cs2 <= 1.0)):
        warnings.warn(
            "c_s² hors-borne (attendu dans [0,1]) – valeurs clipées dans [0,1] pour le pipeline minimal.",
            RuntimeWarning,
        )
        cs2 = np.clip(cs2, 0.0, 1.0)

    return cs2
"""

new_func_lines = new_func.splitlines()

# Reconstruction du fichier : avant compute_cs2 + nouvelle version + après compute_cs2
new_lines = lines[:start] + new_func_lines + lines[end+1:]
path.write_text("\n".join(new_lines) + "\n")

print("[WRITE] compute_cs2 remplacée par une version warning+clip.")
print("\n[SNIPPET] Aperçu autour de compute_cs2 :")
for i, line in enumerate(new_lines, start=1):
    if "def compute_cs2" in line:
        for j in range(max(1, i-3), min(len(new_lines), i+22)+1):
            print(f"{j:4}: {new_lines[j-1]}")
        break
PYEOF

echo
echo "Terminé (patch_ch07_force_replace_compute_cs2)."
read -rp "Appuie sur Entrée pour revenir au shell..." _
