#!/usr/bin/env python3
import os, sys, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = ["zz-figures/_legacy_conflicts/"]

# Budgets
PER_FILE_BUDGET = {
  ".png":    4_000_000,     # 4 MB / image
  ".npz":    50_000_000,    # 50 MB / npz
  ".csv.gz": 80_000_000,    # 80 MB / dataset compressé
}
TOTAL_BUDGET = {
  "zz-figures": 200_000_000,  # 200 MB cumulé
  "zz-data":    800_000_000,  # 800 MB cumulé
}

def is_excluded(rel: str) -> bool:
  rel = rel.replace("\\", "/")
  return any(rel.startswith(p) for p in EXCLUDE_PREFIXES)

def ext_of(path: str):
  p = path.lower()
  # extensions multi-suffixes d'abord
  if p.endswith(".csv.gz"): return ".csv.gz"
  return Path(p).suffix

failed = 0
totals = {"zz-figures": 0, "zz-data": 0}

def safe_is_file(p: Path) -> bool:
  try:
    return p.is_file()
  except PermissionError:
    # On traite comme non lisible => on ignore silencieusement
    return False

def safe_size(p: Path) -> int:
  try:
    return p.stat().st_size
  except PermissionError:
    # Non lisible => ignorer du budget
    return 0

def check_tree(base: str):
  global failed
  basep = ROOT / base
  if not basep.exists():
    return
  for p in basep.rglob("*"):
    # Calculer 'rel' AVANT toute stat/is_file pour pouvoir exclure sans toucher au FS
    try:
      rel = p.relative_to(ROOT).as_posix()
    except Exception:
      # En cas d'étrangeté, on skipe
      continue
    if is_excluded(rel):
      continue
    # Uniquement fichiers réguliers lisibles
    if not safe_is_file(p):
      continue
    size = safe_size(p)
    totals[base] += size
    e = ext_of(rel)
    if e in PER_FILE_BUDGET and size > PER_FILE_BUDGET[e]:
      print(f"❌ {rel}: {size} > budget {PER_FILE_BUDGET[e]} octets")
      failed = 1

for folder in ("zz-figures", "zz-data"):
  check_tree(folder)

for folder, budget in TOTAL_BUDGET.items():
  if totals.get(folder, 0) > budget:
    print(f"❌ Total {folder}: {totals[folder]} > budget {budget} octets")
    failed = 1

# Garde: aucun exécutable sans shebang
proc = subprocess.run(
  ["bash","-lc","git ls-files -z | xargs -0 -I{} bash -lc 'test -x \"{}\" && { head -n1 \"{}\" | grep -q \"^#!\"; } || exit 0' | wc -l"],
  capture_output=True, text=True
)
bad = 0
try:
  bad = int(proc.stdout.strip())
except Exception:
  pass
if bad > 0:
  print(f"❌ Exécutables sans shebang détectés: {bad}")
  failed = 1

if failed:
  print("\n⛔ Budgets/shebang non conformes. Ajustez fichiers ou budgets (tools/scan_assets_budget.py).")
  sys.exit(1)
else:
  print("✅ Budgets et shebang OK.")
