#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Spectre primordial MCGT — version minimale Phase 0.

API offerte:
- A_s(alpha), n_s(alpha), P_R(k, alpha)
- generate_spec(): écrit zz-data/chapter02/02_primordial_spectrum_spec.json
"""

from __future__ import annotations

import json
from pathlib import Path
import numpy as np

A_S0 = 2.1e-9
NS0 = 0.965
C1 = 0.5
C2 = -0.02

SPEC_FILE = Path("zz-data/chapter02/02_primordial_spectrum_spec.json")


def A_s(alpha: float) -> float:
    return float(A_S0 * (1.0 + C1 * float(alpha)))


def n_s(alpha: float) -> float:
    return float(NS0 + C2 * float(alpha))


def P_R(k: np.ndarray, alpha: float) -> np.ndarray:
    alpha = float(alpha)
    if not (-0.1 <= alpha <= 0.1):
        raise ValueError("alpha doit être dans [-0.1, 0.1] (Phase 0).")
    k = np.asarray(k, dtype=float)
    k = np.where(k <= 0.0, np.nan, k)
    return A_s(alpha) * np.power(k, n_s(alpha) - 1.0)


def generate_spec() -> None:
    spec = {
        "model": "MCGT-primordial",
        "formula": "P_R(k;alpha)=A_s(alpha)*k^(n_s(alpha)-1)",
        "params": {"A_S0": A_S0, "NS0": NS0, "C1": C1, "C2": C2},
    }
    SPEC_FILE.parent.mkdir(parents=True, exist_ok=True)
    with SPEC_FILE.open("w", encoding="utf-8") as f:
        json.dump(spec, f, ensure_ascii=False, indent=2)
    print(f"[OK] wrote {SPEC_FILE.as_posix()}")


if __name__ == "__main__":
    generate_spec()
