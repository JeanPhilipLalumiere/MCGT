"""Structure-growth solver for PsiTMG cosmology.

This module isolates matter-perturbation evolution and provides a fast
`f*sigma8(z)` evaluator suitable for repeated likelihood calls.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from numpy.typing import ArrayLike, NDArray
from scipy.integrate import solve_ivp

from core_physics import PsiTMGCosmology

FloatArray = NDArray[np.float64]


@dataclass(frozen=True)
class _GrowthCache:
    """Cached growth quantities sampled on a fixed ln(a) grid."""

    lna_grid: FloatArray
    f_grid: FloatArray
    fsigma8_grid: FloatArray


class StructureFormation:
    """Matter growth engine built on top of `PsiTMGCosmology`.

    The perturbation equation is solved in ln(a) using:
        d delta / d ln(a) = u
        d u / d ln(a) = -(2 + d ln(E)/d ln(a)) u + 1.5 * Omega_m(a) * delta

    where `E(z)=H(z)/H0` and `Omega_m(a)=Omega_m0 a^-3 / E(a)^2`.

    Important:
        The current growth equation evolves matter perturbations only and assumes
        dark-energy perturbations are negligible on sub-horizon scales. This is
        the standard quasi-static approximation used in fast likelihood scans.
        The dark-energy sound speed parameter `c2_s` is stored for theoretical
        consistency and future extensions including explicit DE perturbations.
        Unless otherwise specified, predictions should be interpreted in the
        linear regime only (roughly k < 0.15 h/Mpc).

    Args:
        cosmology: Cosmology background engine.
        lna_min: Initial ln(a) for integration (default: -10).
        n_grid: Number of sampling points for cached interpolation.
        method: `solve_ivp` method. Recommended: "LSODA" or "Radau".
        rtol: Relative tolerance for ODE integration (default: 1e-5).
        atol: Absolute tolerance for ODE integration.
        c2_s: Dark-energy rest-frame sound speed squared (default: 1.0).
    """

    def __init__(
        self,
        cosmology: PsiTMGCosmology,
        lna_min: float = -10.0,
        n_grid: int = 300,
        method: str = "LSODA",
        rtol: float = 1.0e-5,
        atol: float = 1.0e-8,
        c2_s: float = 1.0,
    ) -> None:
        self.cosmology = cosmology
        self.lna_min = float(lna_min)
        self.n_grid = int(n_grid)
        self.method = str(method)
        self.rtol = float(rtol)
        self.atol = float(atol)
        self.c2_s = float(c2_s)
        if not np.isfinite(self.c2_s) or self.c2_s <= 0.0:
            raise ValueError("c2_s must be a strictly positive finite number.")
        self._cache: _GrowthCache | None = None

    def check_phantom_stability(
        self,
        z_max: float = 10.0,
        n_samples: int = 2000,
        eps_cross: float = 5.0e-3,
        slope_threshold: float = 2.0,
    ) -> dict[str, float | bool | None]:
        """Check whether w(z) crosses -1 in a potentially unstable way.

        This diagnostic flags "brutal" phantom crossing when:
        1) `w(z)+1` changes sign (or gets very close to zero), and
        2) local slope `|dw/dz|` near crossing exceeds `slope_threshold`.

        Args:
            z_max: Maximum redshift scanned for crossing.
            n_samples: Number of redshift samples.
            eps_cross: Proximity threshold to `w=-1`.
            slope_threshold: Maximum tolerated local `|dw/dz|` near crossing.

        Returns:
            Dictionary with stability flag and crossing diagnostics.
        """
        if z_max <= 0.0:
            raise ValueError("z_max must be > 0.")
        if n_samples < 32:
            raise ValueError("n_samples must be >= 32.")

        z = np.linspace(0.0, z_max, n_samples, dtype=float)
        w = np.asarray(self.cosmology.w(z), dtype=float)
        x = w + 1.0
        sign_change = np.any(x[:-1] * x[1:] < 0.0)
        near_cross = np.any(np.abs(x) < eps_cross)

        crossing_detected = bool(sign_change or near_cross)
        if not crossing_detected:
            return {
                "stable": True,
                "crossing_detected": False,
                "crossing_z": None,
                "max_abs_dw_dz_near_cross": 0.0,
            }

        idx = int(np.argmin(np.abs(x)))
        crossing_z = float(z[idx])
        dw_dz = np.gradient(w, z)
        window = np.abs(z - crossing_z) <= (z_max / n_samples) * 8.0
        max_abs_dw = float(np.max(np.abs(dw_dz[window]))) if np.any(window) else float(abs(dw_dz[idx]))
        brutal = max_abs_dw > slope_threshold

        return {
            "stable": bool(not brutal),
            "crossing_detected": True,
            "crossing_z": crossing_z,
            "max_abs_dw_dz_near_cross": max_abs_dw,
        }

    def prepare_dark_energy_perturbations(
        self,
        z_max: float = 10.0,
        n_samples: int = 2000,
    ) -> dict[str, float | bool | None]:
        """Prepare metadata for dark-energy perturbation treatment.

        This helper documents the current modeling choice:
        matter-only growth with negligible DE perturbations at sub-horizon scales.
        It also runs `check_phantom_stability()` to pre-screen problematic CPL
        trajectories during Bayesian exploration.
        """
        phantom = self.check_phantom_stability(z_max=z_max, n_samples=n_samples)
        return {
            "c2_s": float(self.c2_s),
            "de_perturbations_included": False,
            "subhorizon_quasistatic_assumption": True,
            "phantom_stability": phantom["stable"],
            "crossing_detected": phantom["crossing_detected"],
            "crossing_z": phantom["crossing_z"],
        }

    def _omega_m_of_a(self, a: float) -> float:
        """Return Omega_m(a) from the background model."""
        z = 1.0 / a - 1.0
        e = float(np.asarray(self.cosmology.E(z), dtype=float))
        e2 = max(e * e, 1.0e-12)
        return self.cosmology.Omega_m * a ** (-3.0) / e2

    def _dlnE_dlna(self, a: float, omega_m_a: float) -> float:
        """Return d ln(E) / d ln(a) for matter + CPL dark energy."""
        z = 1.0 / a - 1.0
        w_a = float(np.asarray(self.cosmology.w(z), dtype=float))
        return -1.5 * (1.0 + w_a * (1.0 - omega_m_a))

    def _growth_rhs(self, lna: float, y: FloatArray) -> FloatArray:
        """RHS for growth system in ln(a)."""
        a = float(np.exp(lna))
        delta, ddelta_dlna = float(y[0]), float(y[1])
        omega_m_a = self._omega_m_of_a(a)
        dlnE_dlna = self._dlnE_dlna(a, omega_m_a)
        d2delta_dlna2 = -(2.0 + dlnE_dlna) * ddelta_dlna + 1.5 * omega_m_a * delta
        return np.array([ddelta_dlna, d2delta_dlna2], dtype=float)

    def _build_cache(self) -> _GrowthCache:
        """Solve growth ODE once and cache fsigma8 on a fixed grid."""
        lna_grid = np.linspace(self.lna_min, 0.0, self.n_grid, dtype=float)
        a_ini = float(np.exp(self.lna_min))
        y0 = np.array([a_ini, a_ini], dtype=float)

        try:
            sol = solve_ivp(
                fun=self._growth_rhs,
                t_span=(self.lna_min, 0.0),
                y0=y0,
                t_eval=lna_grid,
                method=self.method,
                rtol=self.rtol,
                atol=self.atol,
                vectorized=False,
            )
        except Exception as exc:
            raise RuntimeError("Growth ODE integration crashed.") from exc
        if not sol.success:
            raise RuntimeError(f"Growth ODE failed: {sol.message}")

        delta = np.asarray(sol.y[0], dtype=float)
        ddelta_dlna = np.asarray(sol.y[1], dtype=float)

        delta_0 = float(delta[-1])
        if delta_0 <= 0.0:
            raise RuntimeError("Non-physical growth solution: delta(a=1) <= 0")

        delta_norm = delta / delta_0
        # f = d ln(delta) / d ln(a)
        f_grid = ddelta_dlna / np.maximum(delta, 1.0e-12)
        fsigma8_grid = f_grid * self.cosmology.sigma_8 * delta_norm

        return _GrowthCache(lna_grid=lna_grid, f_grid=f_grid, fsigma8_grid=fsigma8_grid)

    def _ensure_cache(self) -> _GrowthCache:
        """Build growth cache lazily."""
        if self._cache is None:
            self._cache = self._build_cache()
        return self._cache

    def get_fsigma8(self, z: ArrayLike) -> float | FloatArray:
        """Return f*sigma8(z) for scalar or array-like redshift input.

        This method is optimized for repeated calls: the expensive ODE solve is
        performed once per instance, then results are obtained by interpolation.
        The underlying growth model is linear and intended for scales where
        linear perturbation theory is valid (k < 0.15 h/Mpc).

        Args:
            z: Redshift value(s), must satisfy z >= 0.

        Returns:
            Scalar or array of f*sigma8 values, matching the input shape.
        """
        z_arr = np.asarray(z, dtype=float)
        if np.any(z_arr < 0.0):
            raise ValueError("Redshift must satisfy z >= 0.")

        try:
            cache = self._ensure_cache()
            lna_target = np.log(1.0 / (1.0 + z_arr))
            fs8 = np.interp(lna_target, cache.lna_grid, cache.fsigma8_grid)
            if np.isscalar(z):
                return float(fs8)
            return fs8
        except Exception:
            if np.isscalar(z):
                return float("nan")
            return np.full_like(z_arr, np.nan, dtype=float)

    def compute_isw_source_term(self, z_array: ArrayLike) -> float | FloatArray:
        """Return late-time ISW source proxy profile: d ln(D/a) / d ln(a) = f(z) - 1.

        In linear sub-horizon GR, the potential scales as Phi ~ D/a, so the ISW
        source follows the logarithmic derivative of D/a with respect to ln(a).
        This method returns the profile:
            S_ISW(z) = f(z) - 1
        where f(z) = d ln(D)/d ln(a), obtained from the cached growth solution.
        """
        z_arr = np.asarray(z_array, dtype=float)
        if np.any(z_arr < 0.0):
            raise ValueError("Redshift must satisfy z >= 0.")

        try:
            cache = self._ensure_cache()
            lna_target = np.log(1.0 / (1.0 + z_arr))
            f_target = np.interp(lna_target, cache.lna_grid, cache.f_grid)
            source = f_target - 1.0
            if np.isscalar(z_array):
                return float(source)
            return source
        except Exception:
            if np.isscalar(z_array):
                return float("nan")
            return np.full_like(z_arr, np.nan, dtype=float)

    def generate_linear_matter_power_spectrum(self, *args: object, **kwargs: object) -> FloatArray:
        """Placeholder for linear P(k) generation interface.

        This architecture hook is reserved for linear-theory matter power
        spectrum predictions in the validity domain k < 0.15 h/Mpc.
        A dedicated implementation can be connected to CLASS/CAMB outputs or
        an internal transfer-function module in future revisions.
        """
        raise NotImplementedError(
            "Linear P(k) generation is not implemented in StructureFormation yet. "
            "Use the dedicated diagnostics/theory module for current P(k) workflows."
        )

    def apply_halofit_correction(self, *args: object, **kwargs: object) -> FloatArray:
        """Placeholder for non-linear correction (Halofit-like) pipeline.

        Future versions may implement prescriptions such as Takahashi et al.
        or HMcode/Mead to extend predictions beyond the linear regime.
        """
        raise NotImplementedError(
            "Non-linear Halofit correction is not implemented yet in this architecture."
        )
