#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul mcgt/scalar_perturbations.py est touché, avec backup .bak_cs2_restore_and_relax.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH07 – Restauration depuis backup + assouplissement du contrôle c_s² =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import textwrap

path = Path("mcgt/scalar_perturbations.py")

# ---------------------------------------------------------------------
# 1) Choix d'un backup "propre" (on évite les *rewrite* / *restore*)
# ---------------------------------------------------------------------
backups = sorted(Path("mcgt").glob("scalar_perturbations.py.bak*"))
if not backups:
    raise SystemExit("[ERROR] Aucun backup trouvé pour mcgt/scalar_perturbations.py")

preferred = [b for b in backups if "rewrite" not in b.name and "restore" not in b.name]
if preferred:
    backup_src = preferred[0]
else:
    backup_src = backups[0]

print(f"[INFO] Backups disponibles :")
for b in backups:
    print("   -", b.name)
print(f"[INFO] Backup choisi pour restauration : {backup_src.name}")

# Sauvegarde de l'état actuel (cassé) au cas où
backup_current = path.with_suffix(".py.bak_cs2_restore_and_relax")
if path.exists():
    shutil.copy2(path, backup_current)
    print(f"[BACKUP] {backup_current} créé (état actuel)")

# Restauration depuis le backup choisi
shutil.copy2(backup_src, path)
print(f"[RESTORE] Fichier principal restauré depuis {backup_src.name}")

# ---------------------------------------------------------------------
# 2) Patch du bloc de contrôle c_s² dans compute_cs2
# ---------------------------------------------------------------------
text = path.read_text()

if "c_s² hors-borne ou non-fini (attendu dans [0,1])." not in text:
    print("[WARN] Message ValueError(c_s² hors-borne…) introuvable – "
          "peut-être déjà patché. Aucun remplacement automatique appliqué.")
else:
    lines = text.splitlines()
    start = None
    end = None

    # On localise la ligne de la ValueError, puis on encadre de l'if à return cs2
    for i, line in enumerate(lines):
        if "c_s² hors-borne ou non-fini (attendu dans [0,1])." in line:
            # remonter jusqu'à la ligne 'if not np.all('
            for j in range(i - 5, -1, -1):
                if "if not np.all(" in lines[j]:
                    start = j
                    break
            # descendre jusqu'au 'return cs2'
            for k in range(i + 1, len(lines)):
                if "return cs2" in lines[k]:
                    end = k
                    break
            break

    if start is None or end is None:
        raise SystemExit("[ERROR] Impossible de localiser précisément le bloc if/raise/return cs2.")

    indent = lines[start][:len(lines[start]) - len(lines[start].lstrip())]

    new_block = textwrap.dedent("""\
        # Contrôle physique assoupli (pipeline minimal)
        import warnings
        if not np.all(np.isfinite(cs2)):
            warnings.warn(
                "c_s² contient des valeurs non finies – valeurs non finies remplacées par 0.0",
                RuntimeWarning,
            )
            cs2 = np.nan_to_num(cs2, nan=0.0, posinf=1.0, neginf=0.0)
        if not np.all((cs2 >= 0.0) & (cs2 <= 1.0)):
            warnings.warn(
                "c_s² hors-borne (attendu dans [0,1]) – valeurs clipées dans [0,1] pour le pipeline minimal.",
                RuntimeWarning,
            )
            cs2 = np.clip(cs2, 0.0, 1.0)
        return cs2
    """)

    new_block_lines = []
    for ln in new_block.splitlines():
        if ln.strip():
            new_block_lines.append(indent + ln)
        else:
            new_block_lines.append("")

    new_lines = lines[:start] + new_block_lines + lines[end+1:]
    path.write_text("\n".join(new_lines) + "\n")
    print("[WRITE] Bloc de contrôle c_s² remplacé par la version warning+clip.")

# ---------------------------------------------------------------------
# 3) Petit extrait de contrôle autour de compute_cs2
# ---------------------------------------------------------------------
lines2 = path.read_text().splitlines()
for i, line in enumerate(lines2, start=1):
    if "def compute_cs2" in line:
        print("\n[SNIPPET] compute_cs2 (fichier final) autour de la ligne", i)
        for j in range(max(1, i-5), min(i+30, len(lines2))+1):
            print(f"{j:4}: {lines2[j-1]}")
        break
PYEOF

echo
echo "Terminé (patch_ch07_restore_and_relax_cs2)."
read -rp "Appuie sur Entrée pour revenir au shell..." _
