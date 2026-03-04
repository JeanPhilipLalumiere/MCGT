from __future__ import annotations

import csv
import json
import tarfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_DIR = ROOT / "zz-zenodo" / "phase4_global_verdict_v3.3.1"
PACKAGE_TARBALL = ROOT / "zz-zenodo" / "phase4_global_verdict_v3.3.1.tar.gz"

EXPECTED_STAGED = {
    "files/phase4_global_verdict_report.json",
    "files/output/ptmg_predictions_z0_to_z20.csv",
    "files/output/ptmg_corner_plot.pdf",
    "files/assets/zz-data/10_global_scan/10_mcmc_affine_chain.csv.gz",
    "files/assets/zz-data/10_global_scan/10_mcmc_global_summary.json",
    "files/assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv",
    "files/assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.md",
    "files/assets/zz-figures/09_dark_energy_cpl/09_fig_12_equation_of_state_evolution.png",
    "files/assets/zz-figures/09_dark_energy_cpl/09_fig_13_cpl_constraints_contours.png",
    "files/assets/zz-figures/10_global_scan/10_fig_17_5d_corner_plot.png",
}


def test_phase4_package_contains_expected_payload_and_metadata():
    assert PACKAGE_DIR.exists()

    metadata = json.loads((PACKAGE_DIR / "phase4_zenodo_metadata.json").read_text(encoding="utf-8"))
    inventory = json.loads((PACKAGE_DIR / "phase4_zenodo_inventory.json").read_text(encoding="utf-8"))

    assert metadata["publication_status"] == "local_package_only"
    assert metadata["publish_to_zenodo"] is False
    assert metadata["version"] == "v3.3.1"
    assert metadata["authors"] == [{"name": "Jean-Philip Lalumière"}]
    assert metadata["files_staged"] == len(EXPECTED_STAGED)
    assert {row["staged"] for row in inventory} == EXPECTED_STAGED


def test_phase4_package_checksums_and_csv_inventory_are_consistent():
    checksum_path = PACKAGE_DIR / "phase4_zenodo_checksums.txt"
    csv_path = PACKAGE_DIR / "phase4_zenodo_inventory.csv"

    checksum_entries = {}
    for line in checksum_path.read_text(encoding="utf-8").splitlines():
        digest, relpath = line.split("  ", 1)
        checksum_entries[relpath] = digest

    with csv_path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    assert {row["staged"] for row in rows} == EXPECTED_STAGED
    assert checksum_entries.keys() == EXPECTED_STAGED
    for row in rows:
        assert checksum_entries[row["staged"]] == row["sha256"]


def test_phase4_package_tarball_mirrors_directory_payload():
    assert PACKAGE_TARBALL.exists()
    with tarfile.open(PACKAGE_TARBALL, "r:gz") as archive:
        members = {
            member.name.removeprefix("phase4_global_verdict_v3.3.1/")
            for member in archive.getmembers()
            if member.isfile()
        }

    expected = EXPECTED_STAGED | {
        "README.txt",
        "phase4_zenodo_checksums.txt",
        "phase4_zenodo_inventory.csv",
        "phase4_zenodo_inventory.json",
        "phase4_zenodo_metadata.json",
    }
    assert expected.issubset(members)
