#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    out = repo / "assets" / "zz-manifests" / "integrity.json"
    targets = [
        repo / "paper" / "main.pdf",
        repo / "output" / "ptmg_corner_plot.pdf",
        repo / "output" / "ptmg_predictions_z0_to_z20.csv",
    ]

    entries = []
    for path in targets:
        if path.exists():
            entries.append(
                {
                    "path": str(path.relative_to(repo)),
                    "sha256": sha256(path),
                }
            )

    payload = {
        "version": "v4.0.0",
        "entries": entries,
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"[OK] wrote {out.relative_to(repo)} with {len(entries)} entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
