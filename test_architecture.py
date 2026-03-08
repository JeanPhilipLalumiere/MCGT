#!/usr/bin/env python3
"""Integration smoke test for the refactored cosmology architecture."""

from __future__ import annotations

import numpy as np

from core_physics import PsiTMGCosmology
from boltzmann_interface import CLASS_Exporter
from diagnostics import DiagnosticsManager, calculate_universe_age
from likelihoods import LikelihoodEvaluator
from perturbations import StructureFormation


def test_crash() -> None:
    """Force unphysical parameters and verify the architecture survives."""
    like = LikelihoodEvaluator()
    bad_omegas = (-0.1, 1.2)
    for om in bad_omegas:
        cosmo_bad = PsiTMGCosmology(
            H_0=74.185,
            Omega_m=om,
            w_0=-1.477,
            w_a=0.446,
            sigma_8=0.862,
        )
        structure_bad = StructureFormation(cosmo_bad)
        lnL = like.compute_total_lnL(
            cosmo_bad,
            structure_bad,
            use_sne=True,
            use_cmb=True,
            use_bao=True,
            use_rsd=True,
        )
        survived = np.isneginf(lnL)
        print(f"Crash test Omega_m={om:+.3f} -> lnL={lnL} | survived={survived}")


def main() -> None:
    """Run architecture-level checks with Nobel parameter values."""
    cosmo = PsiTMGCosmology(
        H_0=74.185,
        Omega_m=0.226,
        w_0=-1.477,
        w_a=0.446,
        sigma_8=0.862,
    )
    structure = StructureFormation(cosmo)
    diagnostics = DiagnosticsManager(output_dir="assets/zz-figures/diagnostics_test")
    exporter = CLASS_Exporter(cosmo)

    h_z0 = cosmo.H_0 * float(cosmo.E(0.0))
    w_z0 = float(cosmo.w(0.0))
    w_z6 = float(cosmo.w(6.0))
    s8 = cosmo.sigma_8 * np.sqrt(cosmo.Omega_m / 0.3)
    fs8_z051 = float(structure.get_fsigma8(0.51))
    age_gyr = calculate_universe_age(cosmo)
    omega_r_auto = cosmo.Omega_r

    # Explicit override test for Omega_r parameter handling.
    omega_r_override = 1.0e-4
    cosmo_override = PsiTMGCosmology(
        H_0=74.185,
        Omega_m=0.226,
        w_0=-1.477,
        w_a=0.446,
        sigma_8=0.862,
        Omega_r=omega_r_override,
    )
    override_ok = np.isclose(cosmo_override.Omega_r, omega_r_override)

    w_file = exporter.export_w_fluid("output/w_psitmg.dat")

    print(f"H(z=0) = {h_z0:.6f} km/s/Mpc")
    print(f"w(z=0) = {w_z0:.6f}")
    print(f"w(z=6) = {w_z6:.6f}")
    print(f"Omega_r (auto from T_CMB=2.7255K) = {omega_r_auto:.10e}")
    print(f"Omega_r override accepted = {override_ok} (value={cosmo_override.Omega_r:.10e})")
    print(f"S8 = {s8:.6f}")
    print(f"f*sigma8(z=0.51) = {fs8_z051:.6f}")
    print(f"Universe age = {age_gyr:.6f} Gyr (target ~14.08 Gyr)")
    print(f"Age > 13.8 Gyr = {age_gyr > 13.8}")
    print(f"CLASS export w(a) file = {w_file}")
    print(f"Diagnostics output directory: {diagnostics.output_dir}")
    test_crash()


if __name__ == "__main__":
    main()
