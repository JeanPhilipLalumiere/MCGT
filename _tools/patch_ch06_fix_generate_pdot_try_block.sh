#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul zz-scripts/chapter06/generate_pdot_plateau_vs_z.py est touché, avec backup .bak_fix_try_block.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Normalisation du bloc CLI dans generate_pdot_plateau_vs_z.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil, sys

path = Path("zz-scripts/chapter06/generate_pdot_plateau_vs_z.py")
if not path.exists():
    print("[ERROR] Fichier introuvable :", path)
    sys.exit(1)

backup = path.with_suffix(".py.bak_fix_try_block")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

# --- 1) Détecter la signature de main() pour savoir si on lui passe args ou non ---
has_args = False
for line in lines:
    s = line.lstrip()
    if s.startswith("def main("):
        inside = s[len("def main("):]
        if ")" in inside:
            inside = inside.split(")")[0]
        if inside.strip():
            has_args = True
        break

# --- 2) Localiser le bloc if __name__ == "__main__": ---
idx_main_if = None
for i, line in enumerate(lines):
    normalized = line.replace("'", '"')
    if 'if __name__ == "__main__"' in normalized:
        idx_main_if = i
        break

if idx_main_if is None:
    print("[ERROR] Aucun bloc 'if __name__ == \"__main__\"' trouvé, abandon.")
    sys.exit(1)

prefix = lines[:idx_main_if]

# --- 3) Nouveau bloc CLI propre ---
tail = []
tail.append('if __name__ == "__main__":')
tail.append('    import argparse, os, sys, traceback')
tail.append('    parser = argparse.ArgumentParser(description="Génère pdot_plateau_vs_z pour le Chapitre 6.")')
tail.append('    parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"),')
tail.append('                        help="Dossier de sortie (par défaut: .ci-out)")')
tail.append('    parser.add_argument("-v", "--verbose", action="count", default=0,')
tail.append('                        help="Verbosity cumulable (-v, -vv).")')
tail.append('    args = parser.parse_args()')
tail.append('    try:')
tail.append('        os.makedirs(args.outdir, exist_ok=True)')
tail.append('        os.environ["MCGT_OUTDIR"] = args.outdir')
if has_args:
    tail.append('        main(args)')
else:
    tail.append('        main()')
tail.append('    except SystemExit:')
tail.append('        raise')
tail.append('    except Exception:')
tail.append('        traceback.print_exc()')
tail.append('        sys.exit(1)')

new_lines = prefix + [""] + tail
path.write_text("\n".join(new_lines) + "\n")

print("[WRITE] Bloc CLI réécrit proprement à partir de 'if __name__ == \"__main__\"'.")
PYEOF

echo
echo "Terminé (patch_ch06_fix_generate_pdot_try_block)."
