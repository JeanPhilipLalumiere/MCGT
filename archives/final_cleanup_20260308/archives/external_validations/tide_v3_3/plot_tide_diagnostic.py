#!/usr/bin/env python3
"""Diagnostic plots and go/no-go text report for TIDE v3.3 trajectory."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

from tide_psi_bridge import TidePsiBridge


def _cumtrapz(y: np.ndarray, x: np.ndarray) -> np.ndarray:
    out = np.zeros_like(y, dtype=float)
    dx = np.diff(x)
    out[1:] = np.cumsum(0.5 * (y[1:] + y[:-1]) * dx)
    return out


def _rho_de_relative_from_w(z_asc: np.ndarray, w_asc: np.ndarray) -> np.ndarray:
    integrand = (1.0 + w_asc) / (1.0 + z_asc)
    integ = _cumtrapz(integrand, z_asc)
    return np.exp(3.0 * integ)


def _h_ratio_curves(
    z_desc: np.ndarray, omega_m0: float, a_vac: float, alpha: float
) -> tuple[np.ndarray, np.ndarray]:
    z_asc = z_desc[::-1]
    a_asc = 1.0 / (1.0 + z_asc)

    w_dyn = -1.0 - (a_vac * a_asc ** (-1.5)) / np.sqrt(1.0 + alpha * a_asc ** (-3.0))
    w_const = -1.0 - (a_vac * a_asc ** (-1.5))

    rho_de_dyn = _rho_de_relative_from_w(z_asc, w_dyn)
    rho_de_const = _rho_de_relative_from_w(z_asc, w_const)

    e2_lcdm = omega_m0 * (1.0 + z_asc) ** 3 + (1.0 - omega_m0)
    e2_dyn = omega_m0 * (1.0 + z_asc) ** 3 + (1.0 - omega_m0) * rho_de_dyn
    e2_const = omega_m0 * (1.0 + z_asc) ** 3 + (1.0 - omega_m0) * rho_de_const

    ratio_dyn = np.sqrt(e2_dyn / e2_lcdm)[::-1]
    ratio_const = np.sqrt(e2_const / e2_lcdm)[::-1]
    return ratio_dyn, ratio_const


def main() -> None:
    base_dir = Path(__file__).resolve().parent
    outputs = base_dir / "outputs"
    outputs.mkdir(parents=True, exist_ok=True)

    bridge = TidePsiBridge(outputs_dir=outputs)
    csv_path = outputs / "tide_tau_evolution.csv"
    if not csv_path.exists():
        bridge.export_tau_evolution_csv()

    data = np.genfromtxt(csv_path, delimiter=",", names=True)
    z = np.asarray(data["z"], dtype=float)  # expected descending 1100 -> 0
    tau = np.asarray(data["tau_gyr"], dtype=float)

    ratio_dyn, ratio_const = _h_ratio_curves(z, bridge.omega_m0, bridge.a_vac, bridge.alpha)

    z_asc = z[::-1]
    tau_asc = tau[::-1]
    dtau_dz_asc = np.gradient(tau_asc, z_asc)
    dtau_dz_at_10 = float(np.interp(10.0, z_asc, dtau_dz_asc))

    tau_cluster = float(bridge.get_dynamic_tau(z=0.0, delta_m=3600.0))
    tau_target = bridge.tau0_gyr / 60.0

    idx_rec = int(np.argmin(np.abs(z - 1100.0)))
    idx_de = int(np.argmin(np.abs(z - 0.7)))
    idx_hi = int(np.argmin(np.abs(z - 1100.0)))
    cmb_dev_dyn = abs(float(ratio_dyn[idx_hi] - 1.0))
    cmb_dev_const = abs(float(ratio_const[idx_hi] - 1.0))

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 10), constrained_layout=True)

    ax1.plot(z, tau, lw=2.2, color="#005f73", label=r"$\tau(z)$ dynamique")
    ax1.axvline(1100.0, color="#ae2012", ls="--", lw=1.5, label="Recombinaison z~1100")
    ax1.axvline(0.7, color="#bb3e03", ls=":", lw=1.8, label="Transition DE z~0.7")
    ax1.scatter([z[idx_rec], z[idx_de]], [tau[idx_rec], tau[idx_de]], color="#001219", zorder=4)
    ax1.set_xscale("symlog", linthresh=1.0)
    ax1.set_xlim(1100.0, 0.0)
    ax1.set_xlabel("Redshift z (symlog)")
    ax1.set_ylabel(r"$\tau(z)$ [Gyr]")
    ax1.set_title(r"Audit TIDE v3.3 - Evolution de $\tau(z)$")
    ax1.grid(True, alpha=0.3)
    ax1.legend(loc="best")

    ax2.plot(z, ratio_dyn, lw=2.2, color="#0a9396", label=r"$H_{TIDE,dyn}/H_{\Lambda CDM}$")
    ax2.plot(
        z,
        ratio_const,
        lw=1.8,
        color="#9b2226",
        ls="--",
        label=r"$H_{TIDE,\tau\,const}/H_{\Lambda CDM}$",
    )
    ax2.axhline(1.0, color="black", lw=1.0, alpha=0.6)
    ax2.set_xscale("symlog", linthresh=1.0)
    ax2.set_xlim(1100.0, 0.0)
    ax2.set_xlabel("Redshift z (symlog)")
    ax2.set_ylabel(r"$H_{TIDE}(z) / H_{\Lambda CDM}(z)$")
    ax2.set_title("Impact sur l'expansion")
    ax2.grid(True, alpha=0.3)
    ax2.legend(loc="best")

    fig_path = outputs / "tide_v3_3_trajectory_audit.png"
    fig.savefig(fig_path, dpi=180)
    plt.close(fig)

    verdict = "GO" if (cmb_dev_dyn < 1e-3 and cmb_dev_dyn <= cmb_dev_const) else "NO-GO"
    verdict_text = "\n".join(
        [
            "TIDE v3.3 trajectory diagnostic",
            f"Verdict: {verdict}",
            (
                "Question: La suppression de tau a z=1100 est-elle assez forte pour "
                "decoupler TIDE de la dynamique du CMB ?"
            ),
            (
                "Reponse: "
                + (
                    "Oui, l'ecart de H_TIDE/H_LCDM au voisinage de z=1100 est tres faible."
                    if verdict == "GO"
                    else "Non, l'ecart CMB reste trop important au voisinage de z=1100."
                )
            ),
            f"|H_dyn/H_LCDM - 1| a z=1100 : {cmb_dev_dyn:.6e}",
            f"|H_const/H_LCDM - 1| a z=1100 : {cmb_dev_const:.6e}",
            f"d(tau)/dz autour de z=10 : {dtau_dz_at_10:.6e} Gyr/redshift",
            f"tau(delta_m=3600) : {tau_cluster:.6e} Gyr",
            f"cible 1.8/60 : {tau_target:.6e} Gyr",
            f"ecart relatif cluster: {abs(tau_cluster - tau_target)/tau_target:.3%}",
            f"Figure: {fig_path}",
        ]
    )
    verdict_path = outputs / "trajectory_verdict.txt"
    verdict_path.write_text(verdict_text + "\n", encoding="utf-8")

    print(f"Saved figure: {fig_path}")
    print(f"Saved verdict: {verdict_path}")
    print(f"d(tau)/dz @ z~10 = {dtau_dz_at_10:.6e} Gyr/redshift")
    print(f"tau(delta_m=3600) = {tau_cluster:.6e} Gyr (target {tau_target:.6e})")


if __name__ == "__main__":
    main()
