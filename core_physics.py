"""Core cosmological background physics for PsiTMG.

This module defines a compact, vectorized cosmology engine used to evaluate
the CPL dark-energy equation of state and the normalized Hubble expansion.
"""

from __future__ import annotations

from typing import Union

import numpy as np
from numpy.typing import ArrayLike, NDArray

try:
    from numba import njit
except Exception:  # pragma: no cover - fallback when numba is not installed.
    def njit(*args, **kwargs):  # type: ignore[override]
        """Fallback decorator that keeps functions usable without numba."""

        def _decorator(func):
            return func

        return _decorator

FloatArray = NDArray[np.float64]
ScalarOrArray = Union[float, FloatArray]


@njit(cache=True)
def _compute_ez_sq(
    z_arr: NDArray[np.float64],
    omega_r: float,
    omega_m: float,
    omega_de: float,
    w0: float,
    wa: float,
) -> NDArray[np.float64]:
    """Compute E(z)^2 for an input array; JIT-compiled when numba is available."""
    one_plus_z = 1.0 + z_arr
    de_evol = np.exp(3.0 * wa * (z_arr / one_plus_z - np.log(one_plus_z)))
    de_density = one_plus_z ** (3.0 * (1.0 + w0 + wa)) * de_evol
    return omega_r * one_plus_z**4 + omega_m * one_plus_z**3 + omega_de * de_density


@njit(cache=True)
def _compute_w_cpl(z_arr: NDArray[np.float64], w0: float, wa: float) -> NDArray[np.float64]:
    """Compute CPL equation of state w(z) on an array."""
    return w0 + wa * z_arr / (1.0 + z_arr)


class PsiTMGCosmology:
    """Background cosmology helper for PsiTMG analyses.

    The model assumes a spatially flat late-time universe with matter and
    dynamical dark energy described by the CPL equation of state.

    Args:
        H_0: Hubble constant at z=0 in km/s/Mpc.
        Omega_m: Matter density fraction at z=0.
        w_0: CPL present-day equation-of-state parameter.
        w_a: CPL time-variation parameter.
        sigma_8: RMS matter fluctuation amplitude at 8 h^-1 Mpc (z=0).
        Omega_r: Radiation density fraction at z=0. If None, computed from
            T_cmb and N_eff.
        T_cmb: CMB temperature in Kelvin (used when Omega_r is None).
        N_eff: Effective number of relativistic species (used for Omega_r).
    """

    def __init__(
        self,
        H_0: float,
        Omega_m: float,
        w_0: float,
        w_a: float,
        sigma_8: float,
        Omega_r: float | None = None,
        T_cmb: float = 2.7255,
        N_eff: float = 3.046,
    ) -> None:
        self.H_0 = float(H_0)
        self.Omega_m = float(Omega_m)
        self.w_0 = float(w_0)
        self.w_a = float(w_a)
        self.sigma_8 = float(sigma_8)
        self.T_cmb = float(T_cmb)
        self.N_eff = float(N_eff)

        if Omega_r is None:
            # omega_gamma*h^2 = 2.469e-5 * (T_cmb / 2.7255)^4 ; includes photons + neutrinos.
            h = self.H_0 / 100.0
            omega_gamma_h2 = 2.469e-5 * (self.T_cmb / 2.7255) ** 4
            omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * self.N_eff)
            self.Omega_r = omega_r_h2 / (h * h)
        else:
            self.Omega_r = float(Omega_r)

        self.Omega_de = 1.0 - self.Omega_m - self.Omega_r

    def w(self, z: ArrayLike) -> ScalarOrArray:
        """Return the CPL equation of state w(z), vectorized.

        The parametrization is:
            w(z) = w_0 + w_a * z / (1 + z)

        Args:
            z: Redshift values.

        Returns:
            CPL equation-of-state value(s), matching the input shape.
        """
        z_arr = np.asarray(z, dtype=float)
        w_z = _compute_w_cpl(z_arr, self.w_0, self.w_a)
        if np.isscalar(z):
            return float(w_z)
        return w_z

    def E(self, z: ArrayLike) -> ScalarOrArray:
        """Return normalized Hubble expansion E(z) = H(z)/H0.

        Uses the exact analytic CPL dark-energy evolution already used in
        project scripts:
            de_evol = exp(3 w_a [z/(1+z) - ln(1+z)])
            rho_de(z)/rho_de0 = (1+z)^(3(1+w_0+w_a)) * de_evol

        Under flatness (Omega_de = 1 - Omega_m - Omega_r):
            E(z)^2 = Omega_r (1+z)^4 + Omega_m (1+z)^3
                     + Omega_de * rho_de(z)/rho_de0

        Args:
            z: Redshift values.

        Returns:
            Normalized Hubble parameter value(s), matching the input shape.
        """
        z_arr = np.asarray(z, dtype=float)
        ez_sq = _compute_ez_sq(
            z_arr,
            self.Omega_r,
            self.Omega_m,
            self.Omega_de,
            self.w_0,
            self.w_a,
        )
        e = np.sqrt(np.maximum(ez_sq, 1.0e-10))
        if np.isscalar(z):
            return float(e)
        return e

    def hubble_inverse(self, z: ArrayLike) -> ScalarOrArray:
        """Return 1 / H(z) with numerical protection against zero division.

        Computes:
            1 / H(z) = 1 / (H_0 * E(z))
        with denominator clamped as `np.maximum(H_0 * E(z), 1e-10)`.

        Args:
            z: Redshift values.

        Returns:
            Inverse Hubble parameter value(s), matching the input shape.
        """
        z_arr = np.asarray(z, dtype=float)
        ez_sq = _compute_ez_sq(
            z_arr,
            self.Omega_r,
            self.Omega_m,
            self.Omega_de,
            self.w_0,
            self.w_a,
        )
        inv_h = 1.0 / (self.H_0 * np.sqrt(np.maximum(ez_sq, 1.0e-10)))
        if np.isscalar(z):
            return float(inv_h)
        return inv_h
