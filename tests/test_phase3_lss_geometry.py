from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_phase3_report_matches_growth_bao_cmb_targets():
    report = json.loads((ROOT / "phase3_lss_geometry_report.json").read_text(encoding="utf-8"))

    ch06 = report["chapter06"]
    ch07 = report["chapter07"]
    ch08 = report["chapter08"]

    assert 9.0 <= float(ch06["mean_growth_boost_percent_z_gt_10"]) <= 10.2
    assert 9.0 <= float(ch06["growth_boost_percent_z_10"]) <= 10.2
    assert 9.5 <= float(ch06["growth_boost_percent_z_15"]) <= 10.5

    assert abs(float(ch07["lyman_alpha_z"]) - 2.33) < 1.0e-12
    assert abs(float(ch07["lyman_alpha_pull"])) < 0.05
    assert float(ch07["chi2_bao_hubble"]) < 0.1

    assert 9.0 <= float(ch08["delta_rs_Mpc"]) <= 9.5
    assert abs(float(ch08["theta100_target"]) - 1.041) < 1.0e-12


def test_phase3_artifacts_exist():
    required = [
        "assets/zz-data/06_early_growth_jwst/06_jwst_growth_boost.csv",
        "assets/zz-data/07_bao_geometry/07_bao_hubble_pivot.csv",
        "assets/zz-data/08_sound_horizon/08_sound_horizon_near_decoupling.csv",
        "assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png",
        "assets/zz-figures/07_bao_geometry/07_fig_10_bao_hubble_diagram.png",
        "assets/zz-figures/08_sound_horizon/08_fig_11_sound_horizon_near_decoupling.png",
        "phase3_lss_geometry_report.txt",
        "phase3_lss_geometry_report.json",
    ]

    for relpath in required:
        assert (ROOT / relpath).exists(), relpath
