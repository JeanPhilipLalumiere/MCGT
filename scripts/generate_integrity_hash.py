#!/usr/bin/env python3
"""Generate a signed SHA-256 certificate for the final manuscript and MCMC chains."""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    ROOT / "manuscript" / "Thesis_MCGT_Lalumiere_v3.3.1_GOLD.pdf",
    ROOT / "assets" / "zz-data" / "10_global_scan" / "10_mcmc_affine_chain.csv.gz",
    ROOT / "output" / "ptmg_chains.h5",
]
OUTPUT = ROOT / "CERTIFICATE_OF_INTEGRITY.txt"
SIGNATORY = "Jean-Philip Lalumière"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def render_certificate() -> str:
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    lines = [
        "CERTIFICATE OF INTEGRITY",
        "Version: v3.3.1 GOLD",
        f"Generated (UTC): {timestamp}",
        "",
        "This certificate binds the final manuscript and the validated MCMC chains",
        "to the local v3.3.1 GOLD artifact state through SHA-256 fingerprints.",
        "",
    ]
    for path in TARGETS:
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
            "The files listed above are the validated GOLD manuscript and chain artifacts",
            "used for the final thesis release. Any post-validation modification would",
            "change the hashes recorded in this certificate.",
            "",
            f"Signed by: {SIGNATORY}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    missing = [path for path in TARGETS if not path.exists()]
    if missing:
        missing_str = ", ".join(str(path.relative_to(ROOT)) for path in missing)
        raise FileNotFoundError(f"Missing integrity target(s): {missing_str}")
    OUTPUT.write_text(render_certificate(), encoding="utf-8")
    print(f"Wrote certificate -> {OUTPUT}")


if __name__ == "__main__":
    main()
