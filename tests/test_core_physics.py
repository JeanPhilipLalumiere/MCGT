from __future__ import annotations

import numpy as np
import pytest

from core_physics import PsiTMGCosmology


def test_hubble_z0() -> None:
    """H(z=0) must reproduce H0."""
    h0 = 74.185
    cosmo = PsiTMGCosmology(H_0=h0, Omega_m=0.226, w_0=-1.477, w_a=0.446, sigma_8=0.862)
    hz0 = h0 * float(cosmo.E(0.0))
    assert hz0 == pytest.approx(h0, rel=0.0, abs=1e-12)


def test_w_phantom_limit() -> None:
    """CPL equation-of-state must match analytic values at z=0 and z=10."""
    w0 = -1.2
    wa = 0.4
    cosmo = PsiTMGCosmology(H_0=70.0, Omega_m=0.3, w_0=w0, w_a=wa, sigma_8=0.8)
    assert float(cosmo.w(0.0)) == pytest.approx(w0, rel=0.0, abs=1e-15)
    expected_z10 = w0 + wa * (10.0 / 11.0)
    assert float(cosmo.w(10.0)) == pytest.approx(expected_z10, rel=0.0, abs=1e-15)


def test_ez_positivity() -> None:
    """E(z)^2 must remain non-negative for extreme redshift ranges."""
    cosmo = PsiTMGCosmology(H_0=70.0, Omega_m=0.01, w_0=-1.7, w_a=1.2, sigma_8=0.8)
    z = np.concatenate(([0.0], np.geomspace(1.0e-6, 1.0e9, 1000)))
    e = np.asarray(cosmo.E(z), dtype=float)
    e2 = e * e
    assert np.all(np.isfinite(e2))
    assert np.all(e2 >= 1.0e-10)

