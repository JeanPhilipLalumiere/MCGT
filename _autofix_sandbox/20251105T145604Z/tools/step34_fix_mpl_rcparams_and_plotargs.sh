#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Assure une liste à jour des fichiers en erreur
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step34] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def fix_text(s: str) -> str:
    s2 = s

    # 1) rcParams.update: ", )"clé": ..."  -> ", "clé": ..."
    s2 = re.sub(r',\s*\)\s*(("[A-Za-z0-9_.]+"\s*:))', r', \1', s2)

    # 2) Insertion virgule entre deux listes adjacentes dans les appels de traçage
    #    .plot([..] [..]  -> .plot([..], [..]
    def add_comma_between_lists(m):
        func = m.group(1)
        a = m.group(2)
        b = m.group(3)
        return f"{func}({a}, {b}"
    s2 = re.sub(
        r'(\.(?:plot|loglog|semilogx|semilogy|plot_date|scatter))\(\s*(\[[^\]]+\])\s*(\[[^\]]+\])',
        add_comma_between_lists, s2, flags=re.S)

    # 3) ax.axis(,"off") -> ax.axis("off")
    s2 = re.sub(r'\baxis\(\s*,\s*("off")\s*\)', r'axis(\1)', s2)

    # 4) Nettoyage léger de ")*clé=" apparu lors d'autofix précédents
    s2 = re.sub(r'\)\*\s*([A-Za-z_]\w*\s*=)', r'\1', s2)

    return s2

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    new = fix_text(src)
    if new != src:
        fp.write_text(new, encoding="utf-8")
        changed += 1
        print(f"[STEP34-FIX] {p}")

print(f"[RESULT] step34_files_changed={changed}")
PY

# Re-rapport pour voir l'impact
tools/step32_report_remaining.sh | sed -n '1,140p' || true
