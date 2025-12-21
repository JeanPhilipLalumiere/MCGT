#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seul scripts/chapter06/plot_fig03_delta_cls_relative.py est touché, avec backup .bak_fix_try_block.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH CH06 – Normalisation du bloc _mcgt_cli_seed() dans plot_fig03_delta_cls_relative.py =="

python - << 'PYEOF'
from pathlib import Path
import shutil
import sys

path = Path("scripts/chapter06/plot_fig03_delta_cls_relative.py")
if not path.exists():
    print("[ERROR] Fichier introuvable:", path)
    sys.exit(1)

backup = path.with_suffix(".py.bak_fix_try_block")
shutil.copy2(path, backup)
print(f"[BACKUP] {backup} créé")

lines = path.read_text().splitlines()

def indent_of(line: str) -> int:
    return len(line) - len(line.lstrip("\t "))

# On cherche le bloc _mcgt_cli_seed et le premier 'try:' dedans
def_idx = None
for i, line in enumerate(lines):
    if "def _mcgt_cli_seed" in line:
        def_idx = i
        break

if def_idx is None:
    print("[WARN] def _mcgt_cli_seed introuvable, aucun patch appliqué.")
    sys.exit(0)

try_idx = None
for i in range(def_idx + 1, len(lines)):
    if lines[i].lstrip().startswith("try:"):
        try_idx = i
        break

if try_idx is None:
    print("[WARN] Aucun 'try:' trouvé dans _mcgt_cli_seed, aucun patch appliqué.")
    sys.exit(0)

base_indent = indent_of(lines[try_idx])
print(f"[INFO] 'try:' trouvé à la ligne {try_idx+1}, indent={base_indent}")

new_lines = []
# On garde tout avant le 'try:'
new_lines.extend(lines[:try_idx])

# Corps du try: on l'étend jusqu'à déindentation ou 'except'
body_start = try_idx + 1
body_end = body_start
while body_end < len(lines):
    l = lines[body_end]
    stripped = l.lstrip()
    ind = indent_of(l)
    if stripped.startswith("except "):
        break
    if stripped != "" and ind <= base_indent:
        break
    body_end += 1

print(f"[INFO] Corps du try: lignes {body_start+1} à {body_end}")

# On recopie le corps du try en le ré-indentant d'un niveau vers la gauche
for j in range(body_start, body_end):
    l = lines[j]
    if l.strip() == "":
        new_lines.append(l)
        continue
    ind = indent_of(l)
    if ind >= base_indent + 4:
        # on enlève 4 espaces de plus que le bloc 'try:'
        leading = l[:ind]
        rest = l[ind:]
        new_lines.append(leading[4:] + rest)
    else:
        new_lines.append(l)

# Maintenant on saute les blocs 'except ...' attachés à ce try (s'il y en a)
k = body_end
while k < len(lines):
    l = lines[k]
    stripped = l.lstrip()
    ind = indent_of(l)
    if stripped.startswith("except "):
        print(f"[INFO] Suppression d'un bloc 'except' à la ligne {k+1}")
        k += 1
        # on saute tout son corps
        while k < len(lines):
            l2 = lines[k]
            s2 = l2.lstrip()
            i2 = indent_of(l2)
            if s2 == "":
                k += 1
                continue
            if i2 <= base_indent:
                break
            k += 1
        # on ne 'break' pas : il pourrait y avoir un autre except
        continue
    # première ligne qui n'est ni 'except' ni dans son corps → on s'arrête
    break

# On recopie le reste du fichier tel quel
new_lines.extend(lines[k:])

path.write_text("\n".join(new_lines) + "\n")
print("[WRITE] Bloc try/except nettoyé et indentation normalisée pour os.makedirs / os.environ / mpl.*")
PYEOF

echo
echo "Terminé (patch_ch06_fix_fig03_try_block)."
