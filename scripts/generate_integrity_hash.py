#!/usr/bin/env python3
"""Generate a signed SHA-256 certificate for the final delivery artifacts."""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ZENODO_ROOT = ROOT / "zz-zenodo"
PRIMARY_TARGETS = [
    ROOT / "manuscript" / "Thesis_MCGT_Lalumiere_v4.0.0_GOLD.pdf",
    ROOT / "output" / "ptmg_predictions_z0_to_z20.csv",
    ROOT / "output" / "ptmg_corner_plot.pdf",
]
OUTPUT = ROOT / "CERTIFICATE_OF_INTEGRITY.txt"
SIGNATORY = "Jean-Philip Lalumière"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def delivery_targets() -> list[Path]:
    files = [path for path in ZENODO_ROOT.rglob("*") if path.is_file()]
    primary = [path for path in PRIMARY_TARGETS if path.exists()]
    return sorted(primary + files, key=lambda path: str(path.relative_to(ROOT)))


def render_certificate() -> str:
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    targets = delivery_targets()
    lines = [
        "CERTIFICATE OF INTEGRITY",
        "Version: v4.0.0 GOLD",
        f"Generated (UTC): {timestamp}",
        "",
        "This certificate binds the final manuscript and every delivery artifact",
        "currently staged under zz-zenodo/ to the local v4.0.0 GOLD state through",
        "SHA-256 fingerprints.",
        "",
        f"Delivery root: {ZENODO_ROOT.relative_to(ROOT)}",
        f"Artifacts sealed: {len(targets)}",
        "",
    ]
    for path in targets:
        rel = path.relative_to(ROOT)
        lines.extend(
            [
                f"File: {rel}",
                f"SHA256: {sha256(path)}",
                "",
            ]
        )
    lines.extend(
        [
            "Statement:",
            "The files listed above are the validated GOLD manuscript and delivery",
            "artifacts used for the final thesis release. Any post-validation",
            "modification would change the hashes recorded in this certificate.",
            "",
            f"Signed by: {SIGNATORY}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    if not ZENODO_ROOT.exists():
        raise FileNotFoundError(f"Missing delivery root: {ZENODO_ROOT.relative_to(ROOT)}")
    OUTPUT.write_text(render_certificate(), encoding="utf-8")
    print(f"Wrote certificate -> {OUTPUT}")


if __name__ == "__main__":
    main()
