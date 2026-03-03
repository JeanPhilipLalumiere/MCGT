#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "zz-data" / "05_primordial_bbn"


def main() -> None:
    milestones = pd.read_csv(DATA_DIR / "05_bbn_milestones.csv")
    preds = pd.read_csv(DATA_DIR / "05_bbn_data.csv")

    early = milestones.sort_values("T_Gyr").iloc[0]
    pred_row = preds.iloc[(preds["T_Gyr"] - early["T_Gyr"]).abs().argmin()]
    t_3min_gyr = 180.0 / (365.25 * 24.0 * 3600.0 * 1.0e9)
    pred_3min = preds.iloc[(preds["T_Gyr"] - t_3min_gyr).abs().argmin()]

    dh_rel = abs(pred_row["DH_calc"] - early["DH_obs"]) / early["DH_obs"]
    yp_rel = abs(pred_row["Yp_calc"] - early["Yp_obs"]) / early["Yp_obs"]
    dh_rel_3min = abs(pred_3min["DH_calc"] - early["DH_obs"]) / early["DH_obs"]
    yp_rel_3min = abs(pred_3min["Yp_calc"] - early["Yp_obs"]) / early["Yp_obs"]

    summary = {
        "reference_time_gyr": float(early["T_Gyr"]),
        "target_time_gyr_3min": float(t_3min_gyr),
        "dh_rel_error": float(dh_rel),
        "yp_rel_error": float(yp_rel),
        "dh_rel_error_3min": float(dh_rel_3min),
        "yp_rel_error_3min": float(yp_rel_3min),
        "dh_within_observation": bool(dh_rel <= early["sigma_DH"] / early["DH_obs"]),
        "yp_within_observation": bool(yp_rel <= early["sigma_Yp"] / early["Yp_obs"]),
        "dh_within_observation_3min": bool(dh_rel_3min <= early["sigma_DH"] / early["DH_obs"]),
        "yp_within_observation_3min": bool(yp_rel_3min <= early["sigma_Yp"] / early["Yp_obs"]),
        "gr_convergence_at_high_temperature": bool(
            dh_rel_3min <= early["sigma_DH"] / early["DH_obs"]
            and yp_rel_3min <= early["sigma_Yp"] / early["Yp_obs"]
        ),
    }

    (DATA_DIR / "05_bbn_convergence_summary.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
