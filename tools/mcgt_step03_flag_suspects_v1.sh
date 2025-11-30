#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="zz-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/step03_candidates_${STAMP}.log"

python - "$LOG_FILE" << 'PYEOF'
import sys
import subprocess
import datetime
from pathlib import Path

log_file = sys.argv[1]
root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
root_path = Path(root)

chapters = [f"{i:02d}" for i in range(1, 11)]

with open(log_file, "w", encoding="utf-8") as out:
    w = out.write
    w("=== MCGT Step 03 : candidats au nettoyage ===\n")
    w(f"[INFO] Repo root : {root}\n")
    w(f"[INFO] Horodatage (UTC) : {datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}\n\n")

    for ch in chapters:
        w("------------------------------------------------------------\n")
        w(f"[CH{ch}] Figures non canoniques (ne commencent pas par {ch}_fig_)\n")
        fig_dir = root_path / "zz-figures" / f"chapter{ch}"
        if fig_dir.is_dir():
            figs = sorted(fig_dir.glob("*.png"))
            any_fig = False
            for p in figs:
                if not p.name.startswith(f"{ch}_fig_"):
                    w(str(p.relative_to(root_path)) + "\n")
                    any_fig = True
            if not any_fig:
                w("(aucune figure non canonique détectée)\n")
        else:
            w(f"(aucun répertoire zz-figures/chapter{ch})\n")

        w("\n")
        w(f"[CH{ch}] Données suspectes (placeholder/dummy/example)\n")
        data_dir = root_path / "zz-data" / f"chapter{ch}"
        if data_dir.is_dir():
            any_data = False
            for p in sorted(data_dir.glob("*")):
                if p.is_file():
                    name_lower = p.name.lower()
                    if any(tok in name_lower for tok in ("placeholder", "dummy", "example")):
                        w(str(p.relative_to(root_path)) + "\n")
                        any_data = True
            if not any_data:
                w("(aucune donnée suspecte détectée)\n")
        else:
            w(f"(aucun répertoire zz-data/chapter{ch})\n")

        w("\n")
        w(f"[CH{ch}] Scripts avec doublons potentiels (noms insensibles à la casse)\n")
        scripts_dir = root_path / "zz-scripts" / f"chapter{ch}"
        if scripts_dir.is_dir():
            mapping = {}
            for p in sorted(scripts_dir.glob("*.py")):
                key = p.name.lower()
                mapping.setdefault(key, []).append(p)
            any_dup = False
            for key, paths in mapping.items():
                if len(paths) > 1:
                    any_dup = True
                    w(f"# key={key}\n")
                    for p in paths:
                        w(str(p.relative_to(root_path)) + "\n")
            if not any_dup:
                w("(aucun doublon détecté)\n")
        else:
            w(f"(aucun répertoire zz-scripts/chapter{ch})\n")

        w("\n")

PYEOF

echo "=== MCGT Step 03 : candidats au nettoyage ==="
echo "[INFO] Rapport écrit dans : $LOG_FILE"
