from __future__ import annotations

import subprocess
import sys
from dataclasses import replace
from pathlib import Path

import numpy as np

from mcgt.scalar_perturbations import _default_params, evaluate_sentinel


ROOT = Path(__file__).resolve().parents[1]


def test_evaluate_sentinel_accepts_default_params():
    params = _default_params()
    a_vals = np.linspace(0.05, 1.0, 16)
    k_vals = np.array([1.0e-4, 1.0e-2, 1.0e-1], dtype=float)

    result = evaluate_sentinel(k_vals, a_vals, params, check_delta_phi=True)

    assert result.accepted is True
    assert result.causality_ok is True
    assert result.rho_positive_ok is True
    assert result.linear_stability_ok is True
    assert result.reasons == []


def test_evaluate_sentinel_rejects_out_of_bounds_cs2():
    params = replace(_default_params(), cs2_param=2.0)
    a_vals = np.linspace(0.05, 1.0, 16)
    k_vals = np.array([1.0e-4, 1.0e-2, 1.0e-1], dtype=float)

    result = evaluate_sentinel(k_vals, a_vals, params, check_delta_phi=False)

    assert result.accepted is False
    assert result.causality_ok is False
    assert "cs2_out_of_bounds_or_nonfinite" in result.reasons


def test_ch02_script_runs_from_current_layout():
    cmd = [sys.executable, "scripts/02_primordial_spectrum/generate_data_chapter02.py"]
    cp = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)

    assert cp.returncode == 0, cp.stderr
    assert (ROOT / "assets/zz-data/02_primordial_spectrum/02_As_ns_vs_alpha.csv").exists()


def test_ch03_script_runs_from_current_layout():
    cmd = [
        sys.executable,
        "scripts/03_stability_domain/generate_data_chapter03.py",
        "--config",
        "config/gw_phase.ini",
        "--npts",
        "700",
    ]
    cp = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)

    assert cp.returncode == 0, cp.stderr
    out = ROOT / "assets/zz-data/03_stability_domain/03_ricci_fR_vs_T.csv"
    assert out.exists()


def test_ch01_hubble_invariant_file_exists_after_rerun():
    cmd = [
        sys.executable,
        "scripts/01_invariants_stability/generate_data_chapter01.py",
        "--csv",
        "assets/zz-data/01_invariants_stability/01_timeline_milestones.csv",
    ]
    cp = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)

    assert cp.returncode == 0, cp.stderr
    out = ROOT / "assets/zz-data/01_invariants_stability/01_hubble_invariant.csv"
    assert out.exists()


def test_ch03_trajectory_is_hamiltonian_stable_after_stabilization():
    import pandas as pd

    df = pd.read_csv(ROOT / "assets/zz-data/03_stability_domain/03_ricci_fR_vs_z.csv")

    assert (1.0 + df["f_R"]).min() > 0.0
    assert (df["m_s2_over_R0"] > 0.0).all()
    assert "hamiltonian_energy_proxy" in df.columns
    assert (df["hamiltonian_energy_proxy"] < 0.0).all()
