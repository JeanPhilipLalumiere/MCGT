from __future__ import annotations

import json
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]


def test_phase5_gold_outputs_exist_and_match_targets():
    gold = json.loads((ROOT / "final_synthesis_v4.0.0_GOLD.json").read_text(encoding="utf-8"))

    assert gold["status"] == "GOLD"
    assert abs(gold["chapters"]["chapter11"]["conflict_factor_branch"] - 2000.0) < 1.0e-12
    assert abs(gold["chapters"]["chapter12"]["k_c_h_per_Mpc"] - 1.0e-4) < 1.0e-12
    assert abs(gold["chapters"]["chapter12"]["s8_lss"] - 0.772525295418195) < 1.0e-8
    assert gold["chapters"]["chapter12"]["gw_transition_phase_shift_pass"] is True
    assert gold["ligo_compliance"]["compliance_fraction"] == 1.0


def test_phase5_figures_and_manifest_entries_exist():
    manifest = json.loads(
        (ROOT / "assets/zz-manifests/manuscript_artifact_manifest.json").read_text(encoding="utf-8")
    )
    tracked = {row["path"]: row for row in manifest["tracked_files"]}

    required_paths = [
        "assets/zz-figures/11_lss_s8_tension/11_fig_19_screening_failures.png",
        "assets/zz-figures/12_cmb_verdict/12_fig_21_perfect_k_transition_law.png",
        "assets/zz-data/11_lss_s8_tension/11_scale_conflict_summary.json",
        "assets/zz-data/12_cmb_verdict/12_step_transition_summary.json",
        "final_synthesis_v4.0.0_GOLD.json",
    ]

    for relpath in required_paths:
        assert (ROOT / relpath).exists()
        assert relpath in tracked
        assert tracked[relpath]["exists"] is True


def test_ptmg_prediction_export_is_on_gold_branch():
    df = pd.read_csv(ROOT / "zz-zenodo" / "ptmg_predictions_z0_to_z20.csv")

    assert {"z", "f_ptmg", "f_lcdm", "f_ratio", "delta_ptmg", "delta_lcdm"}.issubset(df.columns)
    high_z = df[df["z"] >= 10.0]
    assert 1.09 <= float(high_z["f_ratio"].mean()) <= 1.10
