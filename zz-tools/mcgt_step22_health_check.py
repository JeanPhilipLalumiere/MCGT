#!/usr/bin/env python
from __future__ import annotations

import subprocess
from pathlib import Path
from datetime import datetime, timezone
import sys


def main() -> int:
    # Racine du dépôt
    root = Path(__file__).resolve().parents[1]
    logs_dir = root / "zz-logs"
    logs_dir.mkdir(parents=True, exist_ok=True)

    # Horodatage UTC
    now = datetime.now(timezone.utc)
    timestamp = now.strftime("%Y%m%dT%H%M%SZ")

    log_path = logs_dir / f"step22_health_{timestamp}.log"

    def log(line: str) -> None:
        print(line, file=log_fh)
        log_fh.flush()

    def run_step(title: str, cmd: list[str]) -> int:
        sep = "-" * 60
        log(sep)
        log(f"[STEP] {title}")
        log(f"    -> {' '.join(cmd)}")
        try:
            proc = subprocess.run(
                cmd,
                cwd=root,
                stdout=log_fh,
                stderr=subprocess.STDOUT,
                text=True,
            )
            log(f"[INFO] Commande terminée avec code {proc.returncode}")
            return proc.returncode
        except Exception as e:  # pragma: no cover
            log(f"[ERROR] Exception pendant '{title}': {e!r}")
            return 1

    with log_path.open("w", encoding="utf-8") as log_fh:
        log("=== MCGT Step22 : health-check complet (diag + smoke) ===")
        log(f"[INFO] Repo root : {root}")
        log(f"[INFO] Horodatage (UTC) : {timestamp}")

        exit_code = 0

        # 1) Smoke CH09 (fast) – régénère metrics & fig CH09
        rc = run_step(
            "Smoke CH09 (fast)",
            ["bash", "zz-tools/smoke_ch09_fast.sh"],
        )
        exit_code = exit_code or rc

        # 2) Smoke global (squelette) – revalide CH09 + squelette
        rc = run_step(
            "Smoke global (squelette)",
            ["bash", "zz-tools/smoke_all_skeleton.sh"],
        )
        exit_code = exit_code or rc

        # 3) Resync manifest sur CH09 (metrics + fig)
        rc = run_step(
            "Resync manifest CH09 (mcgt_step25_fix_manifest_ch09)",
            ["python", "zz-tools/mcgt_step25_fix_manifest_ch09.py"],
        )
        exit_code = exit_code or rc

        # 4) Diagnostic complet des manifests
        rc = run_step(
            "Diagnostic de cohérence des manifests",
            [
                "python",
                "zz-manifests/diag_consistency.py",
                "zz-manifests/manifest_master.json",
                "--report",
                "text",
            ],
        )
        exit_code = exit_code or rc

        # 5) Probe des versions (pyproject, __init__, CITATION, manifests)
        rc = run_step(
            "Probe des versions (mcgt_probe_versions_v1)",
            ["python", "tools/mcgt_probe_versions_v1.py"],
        )
        exit_code = exit_code or rc

        log("")
        log(f"[INFO] Step22 terminé avec code {exit_code}.")
        log(f"[INFO] Log complet : {log_path}")

    print(f"[INFO] Step22 terminé avec code {exit_code}. Log : {log_path}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
