"""Diagnostics utilities for S8 tension and matter power-spectrum validation."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import warnings

import numpy as np
from numpy.typing import NDArray

from core_physics import PsiTMGCosmology

FloatArray = NDArray[np.float64]
HUBBLE_TIME_GYR_AT_H100 = 9.777922


def calculate_s8_tension(cosmo_model: PsiTMGCosmology) -> dict[str, float]:
    """Compute S8 and its offsets to Planck and DES reference values.

    Args:
        cosmo_model: Cosmological model instance.

    Returns:
        Dictionary containing model S8 and signed/absolute differences against
        Planck (0.834) and DES (0.776).
    """
    s8_model = cosmo_model.sigma_8 * np.sqrt(cosmo_model.Omega_m / 0.3)
    planck = 0.834
    des = 0.776
    return {
        "S8_model": float(s8_model),
        "S8_planck": planck,
        "S8_des": des,
        "delta_planck": float(s8_model - planck),
        "delta_des": float(s8_model - des),
        "abs_delta_planck": float(abs(s8_model - planck)),
        "abs_delta_des": float(abs(s8_model - des)),
    }


def calculate_universe_age(
    cosmo_model: PsiTMGCosmology,
    z_max: float = 1.0e4,
    n_grid: int = 20000,
) -> float:
    """Compute the age of the Universe in Gyr.

    The age is:
        t0 = integral_0^inf dz / ((1+z) H(z))
           = (9.777922 / h) * integral_0^inf dz / ((1+z) E(z))   [Gyr]
    where h = H0/100.

    Args:
        cosmo_model: Cosmological model instance.
        z_max: Finite upper limit approximating infinity.
        n_grid: Number of redshift samples.

    Returns:
        Universe age in Gyr.
    """
    if cosmo_model.H_0 <= 0.0:
        raise ValueError("H_0 must be strictly positive.")
    if z_max <= 10.0:
        raise ValueError("z_max must be large enough to approximate infinity (e.g. 1e4).")
    if n_grid < 2000:
        raise ValueError("n_grid must be >= 2000 for stable age integration.")

    # Dense low-z + logarithmic high-z sampling for robust convergence.
    z_low = np.linspace(0.0, 10.0, n_grid // 2, dtype=float)
    z_high = np.geomspace(10.0, z_max, n_grid // 2, dtype=float)
    z = np.concatenate([z_low, z_high[1:]])

    e = np.asarray(cosmo_model.E(z), dtype=float)
    integrand = 1.0 / ((1.0 + z) * np.maximum(e, 1.0e-12))
    integral_dimless = float(np.trapezoid(integrand, z))

    h = cosmo_model.H_0 / 100.0
    return float((HUBBLE_TIME_GYR_AT_H100 / h) * integral_dimless)


def estimate_bbn_abundances(
    cosmo_model: PsiTMGCosmology,
    omega_b: float = 0.0224,
    t_bbn_mev: float = 0.1,
) -> dict[str, float | bool]:
    """Estimate BBN abundances and equivalent Delta N_eff from modified H(z).

    This routine provides a fast consistency diagnostic using standard
    fitting-style approximations around the BBN epoch (T ~ 0.1 MeV).

    Steps:
    1. Convert BBN temperature to redshift via T/T0 = 1+z.
    2. Compute expansion boost S = H_model / H_std, where H_std keeps
       radiation + matter only (no dark-energy term).
    3. Map expansion boost to equivalent extra radiation:
           DeltaN_eff ~= (43/7) * (S^2 - 1)
    4. Estimate Y_p and 1e5*(D/H) with compact fitting formulas:
           Y_p ~= 0.2485 + 0.0016 * [ (eta10 - 6) + 100*(S - 1) ]
           1e5 D/H ~= 2.6 * (6 / eta10)^1.6 * S^0.4
       with eta10 ~= 273.9 * omega_b.

    Args:
        cosmo_model: Cosmological model instance.
        omega_b: Physical baryon density omega_b = Omega_b h^2.
        t_bbn_mev: BBN temperature in MeV (default: 0.1).

    Returns:
        Dictionary containing z_bbn, expansion boost, DeltaN_eff estimate,
        abundances (Y_p, D/H), and pass/fail flag for DeltaN_eff < 0.3.
    """
    if omega_b <= 0.0:
        raise ValueError("omega_b must be strictly positive.")
    if t_bbn_mev <= 0.0:
        raise ValueError("t_bbn_mev must be strictly positive.")

    # 1 eV = 11604.518 K, so 0.1 MeV = 1e5 eV.
    t_bbn_k = t_bbn_mev * 1.0e6 * 11604.518
    z_bbn = t_bbn_k / cosmo_model.T_cmb - 1.0
    opz = 1.0 + z_bbn

    h_model = float(cosmo_model.H_0 * np.asarray(cosmo_model.E(z_bbn), dtype=float))

    # Standard early-time background used as BBN baseline: radiation + matter.
    e2_std = cosmo_model.Omega_r * opz**4 + cosmo_model.Omega_m * opz**3
    h_std = cosmo_model.H_0 * np.sqrt(max(e2_std, 1.0e-30))
    s = h_model / max(h_std, 1.0e-30)
    delta_h_over_h = s - 1.0

    # Common BBN mapping between expansion-rate change and extra relativistic dof.
    delta_neff = (43.0 / 7.0) * (s * s - 1.0)

    eta10 = 273.9 * omega_b
    yp = 0.2485 + 0.0016 * ((eta10 - 6.0) + 100.0 * (s - 1.0))
    d_h_1e5 = 2.6 * (6.0 / eta10) ** 1.6 * s**0.4

    passes_planck = bool(delta_neff < 0.3)
    if not passes_planck:
        warnings.warn(
            (
                f"BBN/Planck warning: DeltaN_eff={delta_neff:.3f} exceeds 0.3 "
                f"(DeltaH/H={delta_h_over_h:.3%} at T~{t_bbn_mev} MeV)."
            ),
            RuntimeWarning,
            stacklevel=2,
        )

    return {
        "z_bbn": float(z_bbn),
        "T_bbn_MeV": float(t_bbn_mev),
        "omega_b": float(omega_b),
        "H_model_over_H_std": float(s),
        "delta_H_over_H": float(delta_h_over_h),
        "delta_N_eff_equiv": float(delta_neff),
        "Y_p_estimate": float(yp),
        "D_over_H_times_1e5_estimate": float(d_h_1e5),
        "passes_planck_delta_neff": passes_planck,
    }


@dataclass
class DiagnosticsManager:
    """OO helper for diagnostics outputs and plotting.

    Args:
        output_dir: Directory where plots are saved.
    """

    output_dir: Path | str = "assets/zz-figures/diagnostics"

    def __post_init__(self) -> None:
        self.output_dir = Path(self.output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _transfer_function_bbks(k_hmpc: FloatArray, omega_m: float, h: float) -> FloatArray:
        """Approximate BBKS-like transfer function."""
        gamma = max(omega_m * h, 1.0e-8)
        q = k_hmpc / (gamma * np.exp(-0.02 * (1.0 - omega_m)))
        l = np.log(1.0 + 2.34 * q) / np.maximum(2.34 * q, 1.0e-12)
        c = (1.0 + 3.89 * q + (16.1 * q) ** 2 + (5.46 * q) ** 3 + (6.71 * q) ** 4) ** (-0.25)
        return l * c

    @staticmethod
    def _approx_pk(k_hmpc: FloatArray, model: PsiTMGCosmology, n_s: float = 0.965) -> FloatArray:
        """Approximate matter power spectrum shape normalized by sigma8^2."""
        h = model.H_0 / 100.0
        t_k = DiagnosticsManager._transfer_function_bbks(k_hmpc, model.Omega_m, h)
        pk_raw = np.power(k_hmpc, n_s) * np.square(t_k)
        return pk_raw * (model.sigma_8**2)

    @staticmethod
    def check_bbn_integrity(
        cosmo_model: PsiTMGCosmology,
        z_bbn: float = 1.0e9,
        max_fraction: float = 0.01,
    ) -> dict[str, float | bool]:
        """Check that dark energy is negligible at BBN epoch.

        The tested quantity is:
            Omega_DE(z) / E(z)^2
        evaluated at `z_bbn` (default: 1e9). A warning is raised if this
        fraction exceeds `max_fraction` (default: 1%).

        Args:
            cosmo_model: Cosmological model to test.
            z_bbn: Redshift representative of BBN epoch.
            max_fraction: Maximum tolerated DE fraction at BBN.

        Returns:
            Dictionary with the computed ratio and pass/fail status.
        """
        if z_bbn <= 0.0:
            raise ValueError("z_bbn must be strictly positive.")
        if max_fraction <= 0.0:
            raise ValueError("max_fraction must be strictly positive.")

        z = float(z_bbn)
        opz = 1.0 + z
        de_evol = np.exp(3.0 * cosmo_model.w_a * (z / opz - np.log(opz)))
        omega_de_z_term = (
            cosmo_model.Omega_de
            * opz ** (3.0 * (1.0 + cosmo_model.w_0 + cosmo_model.w_a))
            * de_evol
        )
        e2 = float(np.asarray(cosmo_model.E(z), dtype=float) ** 2)
        if e2 <= 0.0 or not np.isfinite(e2):
            raise ValueError("Invalid E(z)^2 while evaluating BBN integrity.")

        ratio = float(omega_de_z_term / e2)
        passes = bool(ratio < max_fraction)
        if not passes:
            warnings.warn(
                (
                    f"BBN integrity warning: Omega_DE(z={z_bbn:.3e})/E(z)^2={ratio:.3e} "
                    f"exceeds threshold {max_fraction:.3e}."
                ),
                RuntimeWarning,
                stacklevel=2,
            )

        return {
            "z_bbn": z,
            "omega_de_over_e2": ratio,
            "max_fraction": float(max_fraction),
            "passes_bbn_integrity": passes,
        }

    @staticmethod
    def evaluate_nec_violation(
        cosmo_model: PsiTMGCosmology,
        z_max: float = 10.0,
        n_samples: int = 4000,
    ) -> dict[str, float | int | bool]:
        """Evaluate NEC behavior for dynamical dark energy.

        For a dark-energy fluid, the Null Energy Condition (NEC) is tied to:
            rho_DE + p_DE = rho_DE * (1 + w(z)).
        Hence NEC is violated where `1 + w(z) < 0` (phantom regime).

        This diagnostic reports:
        - minimum equation-of-state value (`w_min`, violation depth),
        - whether phantom crossing exists (`w=-1` crossing),
        - number of distinct crossings over `z in [0, z_max]`,
        - whether multiple crossings occur (a stronger warning flag).

        Theoretical note:
            In an Effective Field Theory (EFT) treatment, mild NEC-violating
            behavior can remain phenomenologically viable if interpreted below a
            UV cutoff where the effective description applies.

        Args:
            cosmo_model: Cosmological model instance.
            z_max: Maximum redshift of the NEC scan.
            n_samples: Number of redshift samples.

        Returns:
            Dictionary with NEC/phantom diagnostics and warning flags.
        """
        if z_max <= 0.0:
            raise ValueError("z_max must be > 0.")
        if n_samples < 64:
            raise ValueError("n_samples must be >= 64.")

        z = np.linspace(0.0, z_max, n_samples, dtype=float)
        w = np.asarray(cosmo_model.w(z), dtype=float)
        one_plus_w = 1.0 + w

        # Crossing count via sign changes of 1+w.
        sign = np.sign(one_plus_w)
        sign[sign == 0.0] = 1.0
        crossing_count = int(np.count_nonzero(sign[:-1] * sign[1:] < 0.0))
        has_crossing = crossing_count > 0
        multiple_crossing = crossing_count > 1

        w_min = float(np.min(w))
        min_one_plus_w = float(np.min(one_plus_w))
        nec_violated = bool(min_one_plus_w < 0.0)
        theoretical_warning = bool(multiple_crossing)

        if theoretical_warning:
            warnings.warn(
                (
                    f"Multiple phantom crossings detected ({crossing_count}) on "
                    f"z in [0, {z_max}]. Check EFT stability assumptions."
                ),
                RuntimeWarning,
                stacklevel=2,
            )

        return {
            "z_max": float(z_max),
            "w_min": w_min,
            "min_one_plus_w": min_one_plus_w,
            "nec_violated": nec_violated,
            "has_phantom_crossing": has_crossing,
            "phantom_crossing_count": crossing_count,
            "multiple_phantom_crossing": multiple_crossing,
            "theoretical_warning": theoretical_warning,
        }

    def plot_matter_power_spectrum(
        self,
        model: PsiTMGCosmology,
        lcdm_baseline: PsiTMGCosmology,
        filename: str = "matter_power_spectrum_comparison.png",
        k_min: float = 1.0e-4,
        k_max: float = 1.0e1,
        n_k: int = 500,
        title: str = "Matter Power Spectrum Comparison",
    ) -> Path:
        """Plot and save P(k) comparison between model and Lambda-CDM baseline.

        Args:
            model: Main cosmological model to validate.
            lcdm_baseline: Baseline Lambda-CDM model.
            filename: Output image file name.
            k_min: Minimum k in h/Mpc.
            k_max: Maximum k in h/Mpc.
            n_k: Number of k samples.
            title: Figure title.

        Returns:
            Path to the saved figure.
        """
        if k_min <= 0.0 or k_max <= k_min:
            raise ValueError("Require k_min > 0 and k_max > k_min.")
        if n_k < 20:
            raise ValueError("n_k must be >= 20.")

        try:
            import matplotlib.pyplot as plt
        except ImportError as exc:
            raise RuntimeError("matplotlib is required for plotting.") from exc

        k = np.logspace(np.log10(k_min), np.log10(k_max), n_k, dtype=float)
        pk_model = self._approx_pk(k, model)
        pk_lcdm = self._approx_pk(k, lcdm_baseline)

        fig, ax = plt.subplots(figsize=(8.0, 5.5))
        ax.loglog(k, pk_model, color="#c62828", lw=2.3, label=r"$\Psi$TMG")
        ax.loglog(k, pk_lcdm, color="#1565c0", lw=2.0, ls="--", label=r"$\Lambda$CDM")
        ax.axvspan(0.01, 0.1, color="#9e9e9e", alpha=0.12, label="Galaxy scales")
        ax.set_xlabel(r"$k$ [$h\,\mathrm{Mpc}^{-1}$]")
        ax.set_ylabel(r"$P(k)$ [$(h^{-1}\mathrm{Mpc})^3$]")
        ax.set_title(title)
        ax.grid(True, which="both", alpha=0.25)
        ax.legend(frameon=False)
        fig.tight_layout()

        out_path = self.output_dir / filename
        fig.savefig(out_path, dpi=180)
        plt.close(fig)
        return out_path
