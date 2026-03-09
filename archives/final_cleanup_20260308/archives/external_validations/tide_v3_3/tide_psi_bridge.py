#!/usr/bin/env python3
"""Satellite bridge between Sentinel background density and TIDE dynamic tau."""

from __future__ import annotations

import csv
from dataclasses import replace
from pathlib import Path
import importlib.util

import numpy as np

try:
    # Preferred namespace requested by spec.
    from mcgt import sentinel as sentinel_bg  # type: ignore
except Exception:
    sentinel_bg = None

from mcgt.scalar_perturbations import H_of_a, _default_params


def _load_tide_params(module_path: Path) -> tuple[float, float, float, float]:
    """Load Omega_m, H_0, A_vac, alpha from external TIDE parameters."""
    spec = importlib.util.spec_from_file_location("tide_v33_parameters", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load TIDE parameter file: {module_path}")

    module = importlib.util.module_from_spec(spec)
    module.__dict__.setdefault("np", np)
    spec.loader.exec_module(module)

    theta = np.asarray(module.THETA_BESTFIT_TIDE, dtype=float)
    if theta.size < 4:
        raise ValueError("THETA_BESTFIT_TIDE must contain at least 4 parameters.")
    omega_m, h_0, a_vac, alpha = map(float, theta[:4])
    return omega_m, h_0, a_vac, alpha


class TidePsiBridge:
    """Bridge object to evaluate density-coupled TIDE relaxation time."""

    def __init__(
        self,
        tide_params_path: Path | None = None,
        outputs_dir: Path | None = None,
        tau0_gyr: float = 1.8,
    ) -> None:
        base_dir = Path(__file__).resolve().parent
        self.base_dir = base_dir
        self.outputs_dir = outputs_dir or (base_dir / "outputs")
        self.outputs_dir.mkdir(parents=True, exist_ok=True)

        tide_path = tide_params_path or (base_dir / "external_src" / "TIDE_v3.3_parameters.py")
        self.omega_m0, self.h0, self.a_vac, self.alpha = _load_tide_params(tide_path)
        self.tau0_gyr = float(tau0_gyr)

        # Sentinel-compatible parameter container for H(a) and matter density evolution.
        p0 = _default_params()
        h = self.h0 / 100.0
        omega_b = min(0.049, 0.9 * self.omega_m0)
        omega_c = max(self.omega_m0 - omega_b, 1e-6)
        self._sentinel_params = replace(
            p0,
            H0=self.h0,
            ombh2=omega_b * h * h,
            omch2=omega_c * h * h,
            omk=0.0,
        )

    @staticmethod
    def _to_array(z: float | np.ndarray) -> np.ndarray:
        z_arr = np.asarray(z, dtype=float)
        if np.any(z_arr < 0.0):
            raise ValueError("z must be >= 0 for the current background test domain.")
        return z_arr

    def omega_m_of_z(self, z: float | np.ndarray) -> np.ndarray:
        """Matter fraction Omega_m(z) computed from Sentinel background H(a)."""
        z_arr = self._to_array(z)
        a = 1.0 / (1.0 + z_arr)
        hz = H_of_a(a, self._sentinel_params)
        ez2 = np.square(hz / self.h0)
        return self.omega_m0 * np.power(1.0 + z_arr, 3.0) / ez2

    def rho_m_relative(self, z: float | np.ndarray) -> np.ndarray:
        """Matter density normalized to present-day density: rho_m(z)/rho_m0."""
        z_arr = self._to_array(z)
        return np.power(1.0 + z_arr, 3.0)

    def get_dynamic_tau(
        self,
        z: float | np.ndarray,
        delta_m: float | np.ndarray | None = None,
    ) -> np.ndarray:
        """Dynamic tau law from Annex G with optional local-density contrast model."""
        if delta_m is not None:
            delta = np.asarray(delta_m, dtype=float)
            # Local screening mode: tau/tau0 ~ 1/sqrt(1+delta_m),
            # so delta_m~3600 gives a suppression close to 1/60.
            tau = self.tau0_gyr / np.sqrt(1.0 + np.clip(delta, 0.0, None))
            return np.clip(tau, 0.0, self.tau0_gyr)

        omega_m_z = self.omega_m_of_z(z)
        tau = self.tau0_gyr * np.sqrt(self.omega_m0 / omega_m_z)
        # Safety limit: tau should asymptotically approach tau0 (~1.8 Gyr) in low density.
        return np.clip(tau, 0.0, self.tau0_gyr)

    def export_tau_evolution_csv(
        self,
        z_max: float = 1100.0,
        n_points: int = 800,
        filename: str = "tide_tau_evolution.csv",
    ) -> Path:
        """Write z=1100->0 tau evolution for quick background sanity-check plots."""
        if z_max <= 0.0 or n_points < 2:
            raise ValueError("z_max must be >0 and n_points must be >=2.")
        z_grid = np.linspace(float(z_max), 0.0, int(n_points))
        a_grid = 1.0 / (1.0 + z_grid)
        omega_m_z = self.omega_m_of_z(z_grid)
        rho_rel = self.rho_m_relative(z_grid)
        tau = self.get_dynamic_tau(z_grid)

        out_path = self.outputs_dir / filename
        with out_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["z", "a", "rho_m_over_rho_m0", "Omega_m_z", "tau_gyr"])
            for i in range(z_grid.size):
                writer.writerow(
                    [
                        f"{z_grid[i]:.8f}",
                        f"{a_grid[i]:.12e}",
                        f"{rho_rel[i]:.12e}",
                        f"{omega_m_z[i]:.12e}",
                        f"{tau[i]:.12e}",
                    ]
                )
        return out_path


def get_dynamic_tau(
    z: float | np.ndarray,
    delta_m: float | np.ndarray | None = None,
    tau0_gyr: float = 1.8,
) -> np.ndarray:
    """Module-level convenience wrapper for MCMC prototyping."""
    bridge = TidePsiBridge(tau0_gyr=tau0_gyr)
    return bridge.get_dynamic_tau(z=z, delta_m=delta_m)


def main() -> None:
    bridge = TidePsiBridge()
    csv_path = bridge.export_tau_evolution_csv()
    print(f"Generated: {csv_path}")
    print("tau(z=0) [Gyr] =", float(bridge.get_dynamic_tau(0.0)))
    print("tau(z=1100) [Gyr] =", float(bridge.get_dynamic_tau(1100.0)))


if __name__ == "__main__":
    main()
