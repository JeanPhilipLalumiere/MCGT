# ============================
#   TIDE v3.3 PARAMETERS
# ============================

PARAM_NAMES_TIDE = ("Omega_m", "H_0", "A_vac", "alpha", "S_8")

THETA_BESTFIT_TIDE = np.array([
    0.315,    # Omega_m
    74.11,    # H_0
    0.1336,   # A_vac  (kappa ≈ 60.7 → tau_vac / tau_cluster)
    3600.0,   # alpha  (density contrast^2 between clusters and voids)
    0.740     # S_8
], dtype=float)

INIT_SIGMA_TIDE = np.array([
    0.01,     # Omega_m
    0.50,     # H_0
    0.015,    # A_vac
    200.0,    # alpha
    0.015     # S_8
], dtype=float)

PRIOR_BOUNDS_TIDE = {
    "Omega_m": (0.20, 0.40),
    "H_0":     (65.0, 80.0),
    "A_vac":   (0.0, 1.0),
    "alpha":   (0.0, 10000.0),
    "S_8":     (0.60, 0.90),
}

def w_tide(a, A_vac, alpha):
    if a < 1e-10:
        return -1.0
    return -1.0 - (A_vac * a**(-1.5)) / np.sqrt(1.0 + alpha * a**(-3))

def _unpack_theta_tide(theta):
    Omega_m, H_0, A_vac, alpha, S_8 = theta
    return float(Omega_m), float(H_0), float(A_vac), float(alpha), float(S_8)
