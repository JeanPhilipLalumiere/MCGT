#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/06_early_growth_jwst/generate_data_chapter06.py est touché, avec backup .bak_fix_try_block.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Normalisation du bloc _mcgt_cli_seed() (suppression try/except bancal) =="
echo

python - << 'PYEOF'
from pathlib import Path
import shutil

path = Path("scripts/06_early_growth_jwst/generate_data_chapter06.py")
if not path.exists():
    print("[ERROR] Fichier introuvable :", path)
    raise SystemExit(1)

backup = path.with_suffix(".py.bak_fix_try_block")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

# --- 1) Localiser def _mcgt_cli_seed ----------------------------------------
start = None
for i, l in enumerate(lines):
    if "def _mcgt_cli_seed" in l:
        start = i
        indent_def = l[: len(l) - len(l.lstrip())]
        break

if start is None:
    print("[ERROR] def _mcgt_cli_seed introuvable.")
    raise SystemExit(1)

indent_body = indent_def + "    "

# --- 2) Trouver le début du corps (première ligne au niveau indent_body) ----
body_start = None
for i in range(start + 1, len(lines)):
    l = lines[i]
    if l.strip() == "":
        continue
    if l.startswith(indent_body):
        body_start = i
        break

if body_start is None:
    print("[ERROR] Début de corps introuvable pour _mcgt_cli_seed.")
    raise SystemExit(1)

# --- 3) Trouver la fin du corps (dé-dent à indent_def) ----------------------
body_end = len(lines)
for i in range(body_start, len(lines)):
    l = lines[i]
    if l.strip() == "":
        continue
    if l.startswith(indent_def) and not l.startswith(indent_body):
        body_end = i
        break

body = lines[body_start:body_end]

# --- 4) Localiser la ligne 'args = parser.parse_args()' ----------------------
args_idx = None
for j, l in enumerate(body):
    if "args = parser.parse_args()" in l:
        args_idx = j
        break

if args_idx is None:
    print("[ERROR] Ligne 'args = parser.parse_args()' introuvable dans _mcgt_cli_seed.")
    raise SystemExit(1)

prefix = body[: args_idx + 1]

# --- 5) Nouveau bloc post-parse_args, sans try/except foireux ---------------
new_tail = [
    f"{indent_body}import os",
    f"{indent_body}import matplotlib as mpl",
    f"{indent_body}os.makedirs(args.outdir, exist_ok=True)",
    f"{indent_body}os.environ['MCGT_OUTDIR'] = args.outdir",
    f"{indent_body}mpl.rcParams['savefig.dpi'] = args.dpi",
]

new_body = prefix + new_tail

lines[body_start:body_end] = new_body

path.write_text("\n".join(lines) + "\n")
print("[PATCH] Bloc post-parse_args de _mcgt_cli_seed() réécrit proprement (sans try/except problématiques).")
PYEOF

echo
echo "Terminé (patch_ch06_fix_try_block)."
