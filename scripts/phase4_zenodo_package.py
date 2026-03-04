#!/usr/bin/env python3
from __future__ import annotations

import csv
import hashlib
import json
import shutil
import tarfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_NAME = "phase4_global_verdict_v3.3.1"
PACKAGE_DIR = ROOT / "zz-zenodo" / PACKAGE_NAME
PACKAGE_FILES_DIR = PACKAGE_DIR / "files"
PACKAGE_TARBALL = ROOT / "zz-zenodo" / f"{PACKAGE_NAME}.tar.gz"
PHASE4_REPORT = ROOT / "phase4_global_verdict_report.json"
AUTHOR_NAME = "Jean-Philip Lalumière"

INVENTORY_JSON = PACKAGE_DIR / "phase4_zenodo_inventory.json"
INVENTORY_CSV = PACKAGE_DIR / "phase4_zenodo_inventory.csv"
CHECKSUMS_TXT = PACKAGE_DIR / "phase4_zenodo_checksums.txt"
METADATA_JSON = PACKAGE_DIR / "phase4_zenodo_metadata.json"
README_TXT = PACKAGE_DIR / "README.txt"

REQUIRED_FILES = [
    Path("phase4_global_verdict_report.json"),
    Path("output/ptmg_predictions_z0_to_z20.csv"),
    Path("output/ptmg_corner_plot.pdf"),
    Path("assets/zz-data/10_global_scan/10_mcmc_affine_chain.csv.gz"),
    Path("assets/zz-data/10_global_scan/10_mcmc_global_summary.json"),
    Path("assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv"),
    Path("assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.md"),
    Path("assets/zz-figures/09_dark_energy_cpl/09_fig_12_equation_of_state_evolution.png"),
    Path("assets/zz-figures/09_dark_energy_cpl/09_fig_13_cpl_constraints_contours.png"),
    Path("assets/zz-figures/10_global_scan/10_fig_17_5d_corner_plot.png"),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def stage_file(rel_path: Path) -> dict[str, object]:
    src = ROOT / rel_path
    dst = PACKAGE_FILES_DIR / rel_path
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return {
        "source": str(rel_path),
        "staged": str(dst.relative_to(PACKAGE_DIR)),
        "size_bytes": src.stat().st_size,
        "sha256": sha256(src),
    }


def load_phase4_report() -> dict:
    return json.loads(PHASE4_REPORT.read_text(encoding="utf-8"))


def build_metadata(report: dict, inventory: list[dict[str, object]]) -> dict[str, object]:
    chapter09 = report["chapter09"]
    chapter10 = report["chapter10"]
    selection = report["selection_criteria"]
    return {
        "package_name": PACKAGE_NAME,
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "publication_status": "local_package_only",
        "publish_to_zenodo": False,
        "authors": [{"name": AUTHOR_NAME}],
        "title": "PsiTMG v3.3.1 Phase 4 Global Verdict Package",
        "description": (
            "Local Zenodo-ready package for the PsiTMG v3.3.1 Chapter 09-10 outputs. "
            "This package stages the CPL dark-energy audit, affine-invariant global MCMC products, "
            "and the summary verdict JSON without publishing anything externally."
        ),
        "keywords": [
            "cosmology",
            "dark energy",
            "CPL",
            "MCMC",
            "Pantheon+",
            "BAO",
            "CMB",
            "RSD",
            "PsiTMG",
        ],
        "version": "v3.3.1",
        "chapters": ["09_dark_energy_cpl", "10_global_scan"],
        "map_point": chapter09["map"],
        "best_fit": chapter10["best_fit"],
        "sampler": chapter10["sampler"],
        "walkers": chapter10["walkers"],
        "steps_per_walker": chapter10["steps_per_walker"],
        "burn_in_fraction": chapter10["burn_in_fraction"],
        "diagnostics": chapter10["diagnostics"],
        "selection_criteria": {
            "delta_chi2": selection["delta_chi2"],
            "delta_aic": selection["delta_aic"],
            "delta_bic": selection["delta_bic"],
            "n_data": selection["n_data"],
        },
        "files_staged": len(inventory),
        "total_size_bytes": sum(int(item["size_bytes"]) for item in inventory),
    }


def write_inventory(inventory: list[dict[str, object]]) -> None:
    safe_write_text(INVENTORY_JSON, json.dumps(inventory, indent=2))

    lines = []
    with INVENTORY_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["source", "staged", "size_bytes", "sha256"])
        writer.writeheader()
        writer.writerows(inventory)
    lines.append("Phase 4 Zenodo package inventory written.")


def write_checksums(inventory: list[dict[str, object]]) -> None:
    lines = [f"{item['sha256']}  {item['staged']}" for item in inventory]
    safe_write_text(CHECKSUMS_TXT, "\n".join(lines) + "\n")


def write_readme(metadata: dict[str, object], inventory: list[dict[str, object]]) -> None:
    lines = [
        f"{metadata['title']}",
        "",
        f"Author: {AUTHOR_NAME}",
        "Status: local package only; no Zenodo publication was performed.",
        f"Version: {metadata['version']}",
        f"Generated at (UTC): {metadata['generated_at_utc']}",
        "",
        "Contents:",
        "- CPL dark-energy figures (Figure 12 and Figure 13)",
        "- Global affine-invariant MCMC chain, summary, and Table 2",
        "- Output-stage prediction CSV and corner plot synchronized with the validated build",
        "- Phase 4 verdict JSON report",
        "",
        "Key metrics:",
        f"- MAP: w0={metadata['map_point']['w0']}, wa={metadata['map_point']['wa']}",
        (
            "- Best fit: "
            f"H0={metadata['best_fit']['H0']}, "
            f"omega_m={metadata['best_fit']['omega_m']}, "
            f"S8={metadata['best_fit']['S8']}"
        ),
        (
            "- Selection criteria: "
            f"delta_chi2={metadata['selection_criteria']['delta_chi2']}, "
            f"delta_aic={metadata['selection_criteria']['delta_aic']}, "
            f"delta_bic={metadata['selection_criteria']['delta_bic']}"
        ),
        "",
        f"Files staged: {len(inventory)}",
        f"Checksums: {CHECKSUMS_TXT.name}",
        f"Inventory: {INVENTORY_JSON.name}, {INVENTORY_CSV.name}",
    ]
    safe_write_text(README_TXT, "\n".join(lines) + "\n")


def build_tarball() -> None:
    PACKAGE_TARBALL.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(PACKAGE_TARBALL, "w:gz") as archive:
        archive.add(PACKAGE_DIR, arcname=PACKAGE_DIR.name)


def main() -> None:
    missing = [str(path) for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        raise FileNotFoundError(
            "Missing Phase 4 outputs required for the local Zenodo package: " + ", ".join(missing)
        )

    if PACKAGE_DIR.exists():
        shutil.rmtree(PACKAGE_DIR)
    PACKAGE_FILES_DIR.mkdir(parents=True, exist_ok=True)
    report = load_phase4_report()
    inventory = [stage_file(rel_path) for rel_path in REQUIRED_FILES]
    metadata = build_metadata(report, inventory)

    write_inventory(inventory)
    write_checksums(inventory)
    safe_write_text(METADATA_JSON, json.dumps(metadata, indent=2))
    write_readme(metadata, inventory)
    build_tarball()
    print(f"Wrote local package -> {PACKAGE_DIR}")
    print(f"Wrote tarball -> {PACKAGE_TARBALL}")


if __name__ == "__main__":
    main()
