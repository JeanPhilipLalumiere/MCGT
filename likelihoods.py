"""Modular likelihood evaluation for PsiTMG cosmological probes."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from numpy.typing import NDArray
from scipy.interpolate import CubicSpline
from scipy.linalg import block_diag, cho_factor, cho_solve

from core_physics import PsiTMGCosmology
from perturbations import StructureFormation

FloatArray = NDArray[np.float64]
C_KM_S = 299792.458
RD_FID_MPC = 147.09


@dataclass(frozen=True)
class _DistanceTable:
    """Precomputed background table for distance integrals."""

    z_grid: FloatArray
    chi_grid: FloatArray
    e_grid: FloatArray
    chi_spline: CubicSpline
    e_spline: CubicSpline


@dataclass(frozen=True)
class _BAOAnisoData:
    """Anisotropic BAO data per redshift with 2x2 covariance."""

    z: FloatArray
    dm_over_rd_obs: FloatArray
    dh_over_rd_obs: FloatArray
    obs_vec: FloatArray
    cov_chofac: tuple[NDArray[np.float64], bool]


class LikelihoodEvaluator:
    """Evaluate SNe/CMB/BAO/RSD log-likelihoods with one-time data loading.

    Data are loaded once during initialization to avoid repeated I/O during
    MCMC or nested sampling loops.

    Args:
        root: Project root directory. If None, resolves to the directory of
            this module (repository root in this project layout).
        sne_path: Relative path to Pantheon+ CSV.
        sne_cov_path: Optional full Pantheon+ covariance path. When provided,
            the SN likelihood uses analytic marginalization over a global
            magnitude offset with this covariance.
        bao_path: Relative path to BAO CSV.
        bao_aniso_path: Optional anisotropic BAO CSV path for (D_M/r_d, D_H/r_d)
            with covariance entries.
        bao_aniso_cov_path: Optional full covariance matrix path for anisotropic
            BAO (shape 2N x 2N, ordering [DM_0, DH_0, DM_1, DH_1, ...]).
        cc_path: Optional cosmic-chronometer CSV path with columns like
            (z, H_obs, H_err|sigma_H|error_H).
        rsd_path: Relative path to RSD f*sigma8 CSV.
        sigma_sys_sne: Additional SNe systematic scatter (mag).
        z_star_cmb: Recombination redshift for the shift parameter.
        planck_R: Planck shift-parameter central value.
        planck_R_sigma: Planck shift-parameter 1-sigma uncertainty.
        n_steps_distance: Number of z points for distance integration grids.
    """

    def __init__(
        self,
        root: Path | str | None = None,
        sne_path: Path | str = "assets/zz-data/08_sound_horizon/08_pantheon_data.csv",
        sne_cov_path: Path | str | None = None,
        bao_path: Path | str = "assets/zz-data/08_sound_horizon/08_bao_data.csv",
        bao_aniso_path: Path | str | None = None,
        bao_aniso_cov_path: Path | str | None = None,
        cc_path: Path | str | None = None,
        rsd_path: Path | str = "assets/zz-data/10_structure_growth/10_rsd_data.csv",
        sigma_sys_sne: float = 0.1,
        z_star_cmb: float = 1089.92,
        rd_fid_mpc: float = RD_FID_MPC,
        planck_R: float = 1.7502,
        planck_R_sigma: float = 0.0046,
        n_steps_distance: int = 1200,
    ) -> None:
        self.root = Path(root) if root is not None else Path(__file__).resolve().parent
        self.sigma_sys_sne = float(sigma_sys_sne)
        self.z_star_cmb = float(z_star_cmb)
        self.rd_fid_mpc = float(rd_fid_mpc)
        self.planck_R = float(planck_R)
        self.planck_R_sigma = float(planck_R_sigma)
        self.n_steps_distance = int(n_steps_distance)

        self._z_sne, self._mu_sne, self._sigma_mu_sne = self._load_sne(self.root / sne_path)
        self._sne_cov_chofac: tuple[NDArray[np.float64], bool] | None = None
        if sne_cov_path is not None:
            self._configure_sne_covariance(self.root / sne_cov_path, self._z_sne.size)
        self._z_bao, self._dv_bao, self._sigma_dv_bao, self._bao_is_ratio = self._load_bao(self.root / bao_path)
        self._bao_aniso: _BAOAnisoData | None = None
        if bao_aniso_path is not None:
            full_cov: FloatArray | None = None
            if bao_aniso_cov_path is not None:
                aniso_data = np.genfromtxt(
                    self.root / bao_aniso_path,
                    delimiter=",",
                    names=True,
                    dtype=float,
                    encoding="utf-8",
                )
                n_aniso = np.atleast_1d(aniso_data).shape[0]
                full_cov = self._load_square_matrix(self.root / bao_aniso_cov_path, 2 * n_aniso)
            self._bao_aniso = self._load_bao_aniso(self.root / bao_aniso_path, full_cov=full_cov)
        self._cc_data: tuple[FloatArray, FloatArray, FloatArray] | None = None
        if cc_path is not None:
            self._cc_data = self._load_cc(self.root / cc_path)
        self._z_rsd, self._fs8_rsd, self._sigma_rsd = self._load_rsd(self.root / rsd_path)

        self._last_distance_key: tuple[float, float, float, float, float] | None = None
        self._last_distance_table: _DistanceTable | None = None

    @staticmethod
    def _invalid_cosmology(cosmology: PsiTMGCosmology) -> bool:
        """Return True when cosmological parameters are outside physical priors."""
        if not np.isfinite(cosmology.H_0) or cosmology.H_0 <= 0.0:
            return True
        if not np.isfinite(cosmology.Omega_m) or cosmology.Omega_m < 0.0 or cosmology.Omega_m > 1.0:
            return True
        if not np.isfinite(cosmology.w_0) or not np.isfinite(cosmology.w_a):
            return True
        if not np.isfinite(cosmology.sigma_8) or cosmology.sigma_8 <= 0.0:
            return True
        return False

    @staticmethod
    def _load_sne(path: Path) -> tuple[FloatArray, FloatArray, FloatArray]:
        data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
        names = set(data.dtype.names or ())
        required = {"z", "mu_obs", "sigma_mu"}
        if not required.issubset(names):
            raise ValueError(f"SNe file {path} missing columns {required}.")
        z = np.asarray(data["z"], dtype=float)
        mu = np.asarray(data["mu_obs"], dtype=float)
        sigma = np.asarray(data["sigma_mu"], dtype=float)
        if np.any(sigma <= 0.0):
            raise ValueError("SNe uncertainties must be strictly positive.")
        return z, mu, sigma

    @staticmethod
    def _load_square_matrix(path: Path, n_expected: int) -> FloatArray:
        """Load covariance matrix from txt/csv/dat/npy formats."""
        if path.suffix.lower() == ".npy":
            raw = np.load(path)
        else:
            raw = np.loadtxt(path, dtype=float)

        arr = np.asarray(raw, dtype=float)
        if arr.ndim == 1:
            if arr.size == n_expected * n_expected + 1 and int(round(arr[0])) == n_expected:
                arr = arr[1:].reshape((n_expected, n_expected))
            elif arr.size == n_expected * n_expected:
                arr = arr.reshape((n_expected, n_expected))
            else:
                raise ValueError(f"Cannot reshape covariance vector of size {arr.size} to ({n_expected},{n_expected}).")
        elif arr.ndim == 2:
            if arr.shape == (n_expected, n_expected):
                pass
            elif arr.shape[0] == 1 and arr.shape[1] == n_expected * n_expected + 1:
                flat = arr.ravel()
                if int(round(flat[0])) != n_expected:
                    raise ValueError(f"Covariance header n={flat[0]} inconsistent with expected {n_expected}.")
                arr = flat[1:].reshape((n_expected, n_expected))
            else:
                raise ValueError(f"Unexpected covariance matrix shape {arr.shape}, expected ({n_expected},{n_expected}).")
        else:
            raise ValueError("Covariance file has unsupported dimensions.")
        return arr

    def _configure_sne_covariance(self, path: Path, n_expected: int) -> None:
        """Configure full Pantheon+ covariance for SN likelihood evaluation."""
        cov = self._load_square_matrix(path, n_expected)
        cov = 0.5 * (cov + cov.T)
        try:
            chofac = cho_factor(cov, lower=True, check_finite=False)
        except np.linalg.LinAlgError as exc:
            raise ValueError(f"SNe covariance is not positive definite: {path}") from exc
        self._sne_cov_chofac = chofac

    @staticmethod
    def _load_bao(path: Path) -> tuple[FloatArray, FloatArray, FloatArray, bool]:
        data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
        names = set(data.dtype.names or ())
        if "z" not in names:
            raise ValueError(f"BAO file {path} missing column z.")
        z = np.asarray(data["z"], dtype=float)

        if {"DV_obs", "sigma_DV"}.issubset(names):
            dv = np.asarray(data["DV_obs"], dtype=float)
            sigma = np.asarray(data["sigma_DV"], dtype=float)
            is_ratio = False
        elif {"ratio_obs", "ratio_err"}.issubset(names):
            dv = np.asarray(data["ratio_obs"], dtype=float)
            sigma = np.asarray(data["ratio_err"], dtype=float)
            is_ratio = True
        elif {"ratio_obs", "sigma_ratio"}.issubset(names):
            dv = np.asarray(data["ratio_obs"], dtype=float)
            sigma = np.asarray(data["sigma_ratio"], dtype=float)
            is_ratio = True
        else:
            raise ValueError(
                f"BAO file {path} must contain either (DV_obs, sigma_DV) or "
                "(ratio_obs, ratio_err|sigma_ratio)."
            )

        if np.any(sigma <= 0.0):
            raise ValueError("BAO uncertainties must be strictly positive.")
        return z, dv, sigma, is_ratio

    @staticmethod
    def _load_rsd(path: Path) -> tuple[FloatArray, FloatArray, FloatArray]:
        data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
        names = set(data.dtype.names or ())
        if "z" not in names or "fsigma8" not in names:
            raise ValueError(f"RSD file {path} must contain z and fsigma8.")
        if "erreur" in names:
            sigma = np.asarray(data["erreur"], dtype=float)
        elif "error" in names:
            sigma = np.asarray(data["error"], dtype=float)
        elif "sigma" in names:
            sigma = np.asarray(data["sigma"], dtype=float)
        else:
            raise ValueError(f"RSD file {path} missing uncertainty column: erreur|error|sigma.")

        z = np.asarray(data["z"], dtype=float)
        fs8 = np.asarray(data["fsigma8"], dtype=float)
        if np.any(sigma <= 0.0):
            raise ValueError("RSD uncertainties must be strictly positive.")
        return z, fs8, sigma

    @staticmethod
    def _load_cc(path: Path) -> tuple[FloatArray, FloatArray, FloatArray]:
        """Load cosmic chronometer data columns (z, H_obs, H_err)."""
        data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
        names = set(data.dtype.names or ())
        if "z" not in names:
            raise ValueError(f"CC file {path} must contain z.")

        h_col = "H_obs" if "H_obs" in names else ("H" if "H" in names else None)
        if h_col is None:
            raise ValueError(f"CC file {path} must contain H_obs (or H).")

        if "H_err" in names:
            err_col = "H_err"
        elif "sigma_H" in names:
            err_col = "sigma_H"
        elif "error_H" in names:
            err_col = "error_H"
        elif "error" in names:
            err_col = "error"
        else:
            raise ValueError(f"CC file {path} missing uncertainty column (H_err|sigma_H|error_H|error).")

        z = np.asarray(data["z"], dtype=float)
        h_obs = np.asarray(data[h_col], dtype=float)
        h_err = np.asarray(data[err_col], dtype=float)
        if np.any(h_err <= 0.0):
            raise ValueError("CC uncertainties must be strictly positive.")
        return z, h_obs, h_err

    @staticmethod
    def _load_bao_aniso(path: Path, full_cov: FloatArray | None = None) -> _BAOAnisoData:
        """Load anisotropic BAO data with covariance for (D_M/r_d, D_H/r_d)."""
        data = np.genfromtxt(path, delimiter=",", names=True, dtype=float, encoding="utf-8")
        names = set(data.dtype.names or ())
        required = {"z", "dm_over_rd_obs", "dh_over_rd_obs"}
        if not required.issubset(names):
            raise ValueError(f"BAO aniso file {path} missing columns {required}.")

        z = np.asarray(data["z"], dtype=float)
        dm_obs = np.asarray(data["dm_over_rd_obs"], dtype=float)
        dh_obs = np.asarray(data["dh_over_rd_obs"], dtype=float)
        n = z.size
        if n == 0:
            raise ValueError("BAO anisotropic dataset is empty.")

        blocks: list[FloatArray] = []
        if full_cov is not None:
            cov = np.asarray(full_cov, dtype=float)
            if cov.shape != (2 * n, 2 * n):
                raise ValueError(f"Full BAO aniso covariance has shape {cov.shape}, expected {(2*n, 2*n)}.")
            cov = 0.5 * (cov + cov.T)
        elif {"cov_dm_dm", "cov_dm_dh", "cov_dh_dh"}.issubset(names):
            c11 = np.asarray(data["cov_dm_dm"], dtype=float)
            c12 = np.asarray(data["cov_dm_dh"], dtype=float)
            c22 = np.asarray(data["cov_dh_dh"], dtype=float)
            for i in range(n):
                block = np.array([[c11[i], c12[i]], [c12[i], c22[i]]], dtype=float)
                if np.any(~np.isfinite(block)):
                    raise ValueError("Non-finite anisotropic BAO covariance element.")
                blocks.append(block)
            cov = np.asarray(block_diag(*blocks), dtype=float)
        elif {"sigma_dm_over_rd", "sigma_dh_over_rd", "rho_dm_dh"}.issubset(names):
            sdm = np.asarray(data["sigma_dm_over_rd"], dtype=float)
            sdh = np.asarray(data["sigma_dh_over_rd"], dtype=float)
            rho = np.asarray(data["rho_dm_dh"], dtype=float)
            if np.any(sdm <= 0.0) or np.any(sdh <= 0.0):
                raise ValueError("Anisotropic BAO sigmas must be strictly positive.")
            if np.any(np.abs(rho) >= 1.0):
                raise ValueError("Anisotropic BAO |rho| must be < 1.")
            for i in range(n):
                block = np.array(
                    [
                        [sdm[i] * sdm[i], rho[i] * sdm[i] * sdh[i]],
                        [rho[i] * sdm[i] * sdh[i], sdh[i] * sdh[i]],
                    ],
                    dtype=float,
                )
                blocks.append(block)
            cov = np.asarray(block_diag(*blocks), dtype=float)
        else:
            raise ValueError(
                f"BAO aniso file {path} must contain covariance columns "
                "(cov_dm_dm,cov_dm_dh,cov_dh_dh) or "
                "(sigma_dm_over_rd,sigma_dh_over_rd,rho_dm_dh)."
            )

        try:
            cov_chofac = cho_factor(cov, lower=True, check_finite=False)
        except np.linalg.LinAlgError as exc:
            raise ValueError(f"BAO anisotropic covariance is not positive definite: {path}") from exc

        obs_vec = np.empty(2 * n, dtype=float)
        obs_vec[0::2] = dm_obs
        obs_vec[1::2] = dh_obs

        return _BAOAnisoData(
            z=z,
            dm_over_rd_obs=dm_obs,
            dh_over_rd_obs=dh_obs,
            obs_vec=obs_vec,
            cov_chofac=cov_chofac,
        )

    @staticmethod
    def _cumulative_trapezoid(z_grid: FloatArray, f_grid: FloatArray) -> FloatArray:
        dz = np.diff(z_grid)
        avg = 0.5 * (f_grid[:-1] + f_grid[1:])
        integ = np.zeros_like(z_grid)
        integ[1:] = np.cumsum(avg * dz)
        return integ

    def _distance_table(self, cosmology: PsiTMGCosmology, z_max: float) -> _DistanceTable:
        key = (
            cosmology.H_0,
            cosmology.Omega_m,
            cosmology.w_0,
            cosmology.w_a,
            float(z_max),
        )
        if self._last_distance_key == key and self._last_distance_table is not None:
            return self._last_distance_table

        z_grid = np.linspace(0.0, z_max, self.n_steps_distance, dtype=float)
        e_grid = np.asarray(cosmology.E(z_grid), dtype=float)
        if np.any(~np.isfinite(e_grid)) or np.any(e_grid <= 0.0):
            raise ValueError("Invalid E(z) encountered while building distance table.")
        inv_e = 1.0 / e_grid

        # Build smooth inv(E) spline once, then integrate analytically through its antiderivative.
        inv_e_spline = CubicSpline(z_grid, inv_e, bc_type="natural", extrapolate=False)
        anti = inv_e_spline.antiderivative()
        chi_grid = np.asarray(anti(z_grid) - anti(0.0), dtype=float)

        chi_spline = CubicSpline(z_grid, chi_grid, bc_type="natural", extrapolate=False)
        e_spline = CubicSpline(z_grid, e_grid, bc_type="natural", extrapolate=False)
        table = _DistanceTable(
            z_grid=z_grid,
            chi_grid=chi_grid,
            e_grid=e_grid,
            chi_spline=chi_spline,
            e_spline=e_spline,
        )
        self._last_distance_key = key
        self._last_distance_table = table
        return table

    def _lnl_sne_from_table(self, cosmology: PsiTMGCosmology, table: _DistanceTable) -> float:
        dc = np.asarray(table.chi_spline(self._z_sne), dtype=float)
        if np.any(~np.isfinite(dc)):
            raise ValueError("Invalid spline-integrated comoving distance for SNe.")
        d_m = (C_KM_S / cosmology.H_0) * dc
        d_l = (1.0 + self._z_sne) * d_m
        mu_model = 5.0 * np.log10(np.maximum(d_l, 1.0e-12)) + 25.0
        resid = self._mu_sne - mu_model

        if self._sne_cov_chofac is not None:
            covinv_resid = cho_solve(self._sne_cov_chofac, resid, check_finite=False)
            chi2 = float(resid @ covinv_resid)
        else:
            sigma = np.sqrt(self._sigma_mu_sne * self._sigma_mu_sne + self.sigma_sys_sne * self.sigma_sys_sne)
            w = 1.0 / np.maximum(sigma * sigma, 1.0e-24)
            chi2 = float(np.sum(resid * resid * w))
        return float(-0.5 * chi2)

    def _lnl_bao_from_table(self, cosmology: PsiTMGCosmology, table: _DistanceTable) -> float:
        dc = np.asarray(table.chi_spline(self._z_bao), dtype=float)
        e = np.asarray(table.e_spline(self._z_bao), dtype=float)
        if np.any(~np.isfinite(dc)) or np.any(~np.isfinite(e)):
            raise ValueError("Invalid spline interpolation for BAO distances.")
        # D_V = (c/H0) * (z * D_M^2 / E(z))^(1/3), with D_M=(c/H0)*integral dz/E.
        dv_model = (C_KM_S / cosmology.H_0) * (
            self._z_bao * dc * dc / np.maximum(e, 1.0e-12)
        ) ** (1.0 / 3.0)
        bao_model = dv_model / self.rd_fid_mpc if self._bao_is_ratio else dv_model
        chi2 = np.sum(((bao_model - self._dv_bao) / self._sigma_dv_bao) ** 2)
        return float(-0.5 * chi2)

    def _lnl_cmb_from_table(self, cosmology: PsiTMGCosmology, table: _DistanceTable) -> float:
        dchi = float(np.asarray(table.chi_spline(self.z_star_cmb), dtype=float))
        if cosmology.Omega_m <= 0.0:
            raise ValueError("Omega_m must be positive for CMB shift parameter.")
        r_model = np.sqrt(cosmology.Omega_m) * dchi
        chi2 = ((r_model - self.planck_R) / self.planck_R_sigma) ** 2
        return float(-0.5 * chi2)

    def _bao_dm_dh_over_rd(
        self,
        cosmology: PsiTMGCosmology,
        table: _DistanceTable,
        z: FloatArray,
    ) -> tuple[FloatArray, FloatArray]:
        """Compute (D_M/r_d, D_H/r_d) at target redshifts."""
        dc = np.asarray(table.chi_spline(z), dtype=float)
        e = np.asarray(table.e_spline(z), dtype=float)
        if np.any(~np.isfinite(dc)) or np.any(~np.isfinite(e)):
            raise ValueError("Invalid interpolation for anisotropic BAO observables.")

        d_m = (C_KM_S / cosmology.H_0) * dc
        d_h = C_KM_S / np.maximum(cosmology.H_0 * e, 1.0e-12)
        return d_m / self.rd_fid_mpc, d_h / self.rd_fid_mpc

    def compute_lnL_SNe(self, cosmology: PsiTMGCosmology) -> float:
        """Compute SNe Pantheon+ log-likelihood."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        try:
            z_max = float(np.max(self._z_sne))
            table = self._distance_table(cosmology, z_max)
            return self._lnl_sne_from_table(cosmology, table)
        except Exception:
            return float(-np.inf)

    def compute_lnL_CMB(self, cosmology: PsiTMGCosmology) -> float:
        """Compute Planck shift-parameter log-likelihood."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        try:
            table = self._distance_table(cosmology, self.z_star_cmb)
            return self._lnl_cmb_from_table(cosmology, table)
        except Exception:
            return float(-np.inf)

    def compute_lnL_BAO(self, cosmology: PsiTMGCosmology) -> float:
        """Compute BAO eBOSS-like D_V log-likelihood."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        try:
            z_max = float(np.max(self._z_bao))
            table = self._distance_table(cosmology, z_max)
            return self._lnl_bao_from_table(cosmology, table)
        except Exception:
            return float(-np.inf)

    def compute_lnL_BAO_aniso(self, cosmology: PsiTMGCosmology) -> float:
        """Compute anisotropic BAO log-likelihood using (D_M/r_d, D_H/r_d)."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        if self._bao_aniso is None:
            return float(-np.inf)
        try:
            z_max = float(np.max(self._bao_aniso.z))
            table = self._distance_table(cosmology, z_max)
            dm_th, dh_th = self._bao_dm_dh_over_rd(cosmology, table, self._bao_aniso.z)
            th_vec = np.empty_like(self._bao_aniso.obs_vec)
            th_vec[0::2] = dm_th
            th_vec[1::2] = dh_th
            resid = th_vec - self._bao_aniso.obs_vec
            covinv_resid = cho_solve(self._bao_aniso.cov_chofac, resid, check_finite=False)
            chi2 = float(resid @ covinv_resid)
            return float(-0.5 * chi2)
        except Exception:
            return float(-np.inf)

    def compute_lnL_RSD(
        self,
        cosmology: PsiTMGCosmology,
        structure: StructureFormation,
    ) -> float:
        """Compute RSD f*sigma8 log-likelihood."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        try:
            fs8_model = np.asarray(structure.get_fsigma8(self._z_rsd), dtype=float)
            if np.any(~np.isfinite(fs8_model)):
                return float(-np.inf)
            chi2 = np.sum(((self._fs8_rsd - fs8_model) / self._sigma_rsd) ** 2)
            return float(-0.5 * chi2)
        except Exception:
            return float(-np.inf)

    def compute_lnL_CC(self, cosmology: PsiTMGCosmology) -> float:
        """Compute cosmic-chronometer log-likelihood from direct H(z) data."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        if self._cc_data is None:
            return float(-np.inf)
        try:
            z, h_obs, h_err = self._cc_data
            h_model = cosmology.H_0 * np.asarray(cosmology.E(z), dtype=float)
            if np.any(~np.isfinite(h_model)):
                return float(-np.inf)
            chi2 = np.sum(((h_obs - h_model) / h_err) ** 2)
            return float(-0.5 * chi2)
        except Exception:
            return float(-np.inf)

    def weak_lensing_kernel_q(
        self,
        cosmology: PsiTMGCosmology,
        z_lens: FloatArray,
        z_source: FloatArray,
        n_of_z: FloatArray,
    ) -> FloatArray:
        """Compute lensing efficiency kernel q(z) for a source distribution n(z).

        For a flat universe, this computes the standard geometric kernel:
            q(z) = (3/2) * Omega_m * (H0/c)^2 * (1+z) * chi(z)
                   * integral_z^inf dz' n(z') * (chi(z')-chi(z))/chi(z') * dchi/dz'

        Notes:
        - `n_of_z` is normalized internally (integral n(z) dz = 1).
        - This is a preparatory geometric kernel; full weak-lensing likelihood
          still requires non-linear matter power P_NL(k,z) and survey systematics.
        """
        z_l = np.asarray(z_lens, dtype=float)
        z_s = np.asarray(z_source, dtype=float)
        n_s = np.asarray(n_of_z, dtype=float)
        if z_s.ndim != 1 or n_s.ndim != 1 or z_s.size != n_s.size:
            raise ValueError("z_source and n_of_z must be 1D arrays of equal length.")
        if np.any(z_s < 0.0) or np.any(z_l < 0.0):
            raise ValueError("Redshift arrays must satisfy z >= 0.")
        if np.any(np.diff(z_s) <= 0.0):
            raise ValueError("z_source must be strictly increasing.")

        norm = float(np.trapezoid(n_s, z_s))
        if norm <= 0.0 or not np.isfinite(norm):
            raise ValueError("n_of_z must have positive finite normalization.")
        n_norm = n_s / norm

        z_max = float(np.max(z_s))
        table = self._distance_table(cosmology, z_max)
        chi_s = np.asarray(table.chi_spline(z_s), dtype=float)
        e_s = np.asarray(table.e_spline(z_s), dtype=float)
        dchi_dz_s = (C_KM_S / cosmology.H_0) / np.maximum(e_s, 1.0e-12)

        chi_l = np.asarray(table.chi_spline(z_l), dtype=float)
        q = np.zeros_like(z_l, dtype=float)
        pref = 1.5 * cosmology.Omega_m * (cosmology.H_0 / C_KM_S) ** 2

        for i, (zl, chil) in enumerate(zip(np.atleast_1d(z_l), np.atleast_1d(chi_l))):
            mask = z_s >= zl
            if not np.any(mask):
                q[i] = 0.0
                continue
            geom = np.maximum((chi_s[mask] - chil) / np.maximum(chi_s[mask], 1.0e-12), 0.0)
            integ = np.trapezoid(n_norm[mask] * geom * dchi_dz_s[mask], z_s[mask])
            q[i] = pref * (1.0 + zl) * chil * integ
        return q

    def compute_lnL_WeakLensing(
        self,
        cosmology: PsiTMGCosmology,
        z_source: FloatArray,
        n_of_z: FloatArray,
    ) -> float:
        """Weak-lensing likelihood placeholder (Lensing-Ready API).

        This method defines the entry point for DES/KiDS cosmic-shear analyses.
        Full evaluation requires:
        - non-linear matter power spectrum P_NL(k,z),
        - lensing observables xi_+, xi_- with full covariance/systematics,
        - Boltzmann pipeline coupling (via `boltzmann_interface` + CLASS/CAMB).

        The current architecture is therefore *Lensing-Ready* but intentionally
        does not provide a production xi_+/xi_- likelihood yet.
        """
        _ = self.weak_lensing_kernel_q(cosmology, z_lens=np.asarray(z_source, dtype=float), z_source=z_source, n_of_z=n_of_z)
        raise NotImplementedError(
            "compute_lnL_WeakLensing requires CLASS/CAMB + non-linear P_NL(k,z) "
            "and survey covariance (xi_+, xi_-) to be fully implemented."
        )

    def compute_total_lnL(
        self,
        cosmology: PsiTMGCosmology,
        structure: StructureFormation | None = None,
        use_sne: bool = True,
        use_cmb: bool = True,
        use_bao: bool = True,
        use_bao_aniso: bool = False,
        use_cc: bool = False,
        use_rsd: bool = True,
    ) -> float:
        """Compute total log-likelihood with probe-selection flags."""
        if self._invalid_cosmology(cosmology):
            return float(-np.inf)
        try:
            total = 0.0

            table_lowz: _DistanceTable | None = None
            if use_sne or use_bao:
                z_max_lowz = 0.0
                if use_sne:
                    z_max_lowz = max(z_max_lowz, float(np.max(self._z_sne)))
                if use_bao:
                    z_max_lowz = max(z_max_lowz, float(np.max(self._z_bao)))
                table_lowz = self._distance_table(cosmology, z_max_lowz)

            table_cmb: _DistanceTable | None = None
            if use_cmb:
                table_cmb = self._distance_table(cosmology, self.z_star_cmb)

            if use_sne and table_lowz is not None:
                lnl = self._lnl_sne_from_table(cosmology, table_lowz)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            if use_bao and table_lowz is not None:
                lnl = self._lnl_bao_from_table(cosmology, table_lowz)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            if use_bao_aniso:
                lnl = self.compute_lnL_BAO_aniso(cosmology)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            if use_cmb and table_cmb is not None:
                lnl = self._lnl_cmb_from_table(cosmology, table_cmb)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            if use_rsd:
                structure_model = structure if structure is not None else StructureFormation(cosmology)
                lnl = self.compute_lnL_RSD(cosmology, structure_model)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            if use_cc:
                lnl = self.compute_lnL_CC(cosmology)
                if not np.isfinite(lnl):
                    return float(-np.inf)
                total += lnl

            return float(total)
        except Exception:
            return float(-np.inf)
