"""Equation-of-state helpers shared by the inference pipelines."""

from __future__ import annotations

import math

import numpy as np

TIDE_TAU_H0 = 0.0022
TIDE_SENTINEL_A_MIN = 1.0e-6
TIDE_SENTINEL_RHO_FLOOR = 1.0e-16
_TIDE_LOG_RHO_FLOOR = math.log(TIDE_SENTINEL_RHO_FLOOR)


class TIDE_EquationOfState:
    """Alejandro Rey's TIDE parameterization with early-time sentinel guards."""

    def __init__(self, tau_h0: float = TIDE_TAU_H0) -> None:
        self.tau_h0 = float(tau_h0)

    def w_of_a(self, a: np.ndarray | float, kappa: float) -> np.ndarray | float:
        a_arr = np.asarray(a, dtype=float)
        a_safe = np.clip(a_arr, TIDE_SENTINEL_A_MIN, None)
        values = -1.0 - (float(kappa) * self.tau_h0 * np.power(a_safe, -1.5))
        return values if np.ndim(a_arr) else float(values)

    def density_factor(self, a: np.ndarray | float, kappa: float) -> np.ndarray | float:
        a_arr = np.asarray(a, dtype=float)
        a_safe = np.clip(a_arr, TIDE_SENTINEL_A_MIN, None)
        exponent = 2.0 * float(kappa) * self.tau_h0 * (1.0 - np.power(a_safe, -1.5))
        density = np.exp(np.clip(exponent, -745.0, 80.0))
        density = np.where((a_arr <= TIDE_SENTINEL_A_MIN) | (exponent <= _TIDE_LOG_RHO_FLOOR), 0.0, density)
        return density if np.ndim(a_arr) else float(density)


_TIDE = TIDE_EquationOfState()


def tide_w_of_a(a: np.ndarray | float, kappa: float) -> np.ndarray | float:
    """Return Alejandro Rey's TIDE equation of state."""
    return _TIDE.w_of_a(a, kappa)


def tide_density_factor(a: np.ndarray | float, kappa: float) -> np.ndarray | float:
    """
    Return rho_TIDE(a) / rho_TIDE(a=1) with an early-time sentinel.

    For w(a) = -1 - kappa * tauH0 * a^-1.5, the exact density scaling is:
      rho(a)/rho(1) = exp(2 * kappa * tauH0 * (1 - a^-1.5)).
    The sentinel forces rho -> 0 as a -> 0 while avoiding unstable underflow.
    """
    return _TIDE.density_factor(a, kappa)
