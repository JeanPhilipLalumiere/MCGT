"""Export helpers for external Boltzmann solvers (CLASS/CAMB)."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from numpy.typing import NDArray

from core_physics import PsiTMGCosmology

FloatArray = NDArray[np.float64]
C_KM_S = 299792.458


class CLASS_Exporter:
    """Exporter for PsiTMG background tables compatible with CLASS workflows."""

    def __init__(self, cosmology: PsiTMGCosmology) -> None:
        self.cosmology = cosmology

    @staticmethod
    def _cumtrapz(x: FloatArray, y: FloatArray) -> FloatArray:
        dx = np.diff(x)
        avg = 0.5 * (y[:-1] + y[1:])
        out = np.zeros_like(x)
        out[1:] = np.cumsum(dx * avg)
        return out

    def export_w_fluid(
        self,
        filename: str | Path = "w_psitmg.dat",
        a_min: float = 1.0e-6,
        n_a: int = 2000,
    ) -> Path:
        """Export a two-column table (a, w(a)) for CLASS w-fluid usage."""
        if not (0.0 < a_min < 1.0):
            raise ValueError("a_min must satisfy 0 < a_min < 1.")
        if n_a < 64:
            raise ValueError("n_a must be >= 64.")

        a = np.geomspace(a_min, 1.0, n_a, dtype=float)
        z = 1.0 / a - 1.0
        w = np.asarray(self.cosmology.w(z), dtype=float)
        data = np.column_stack([a, w])

        out = Path(filename)
        out.parent.mkdir(parents=True, exist_ok=True)
        np.savetxt(
            out,
            data,
            fmt="%.10e",
            header="a w(a)",
            comments="",
        )
        return out

    def export_background(
        self,
        filename: str | Path = "background_psitmg.dat",
        z_max: float = 1.0e4,
        n_z: int = 4000,
    ) -> Path:
        """Export (z, H(z), chi(z)) for external validation.

        Columns:
            z: redshift
            H(z): Hubble parameter in km/s/Mpc
            chi(z): line-of-sight comoving distance in Mpc
        """
        if z_max <= 0.0:
            raise ValueError("z_max must be > 0.")
        if n_z < 200:
            raise ValueError("n_z must be >= 200.")

        z_low = np.linspace(0.0, min(20.0, z_max), n_z // 2, dtype=float)
        if z_max > 20.0:
            z_high = np.geomspace(20.0, z_max, n_z - (n_z // 2), dtype=float)
            z = np.concatenate([z_low, z_high[1:]])
        else:
            z = z_low

        e = np.asarray(self.cosmology.E(z), dtype=float)
        h_z = self.cosmology.H_0 * e
        chi = (C_KM_S / self.cosmology.H_0) * self._cumtrapz(z, 1.0 / np.maximum(e, 1.0e-12))

        data = np.column_stack([z, h_z, chi])
        out = Path(filename)
        out.parent.mkdir(parents=True, exist_ok=True)
        np.savetxt(
            out,
            data,
            fmt="%.10e",
            header="z H(z)_km_s_Mpc chi_Mpc",
            comments="",
        )
        return out

    def configure_for_cmb_lensing(self) -> dict[str, str]:
        """Return CLASS flags required for CMB-lensing-ready runs.

        This helper centralizes the minimal CLASS settings for CMB lensing:
        - lensing = yes
        - non linear = halofit

        The resulting dictionary can be merged into a CLASS parameter file or
        passed to a Python wrapper (e.g. classy) in future integrations.

        Note:
            In PsiTMG, modifications to the linear growth history D(z) alter
            matter clustering and therefore the line-of-sight lensing potential.
            This propagates directly to the CMB lensing spectrum C_ell^{phi phi}.
        """
        return {
            "lensing": "yes",
            "non linear": "halofit",
        }
