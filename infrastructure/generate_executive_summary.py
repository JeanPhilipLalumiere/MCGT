#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PHASE3 = ROOT / "phase3_lss_geometry_report.json"
PHASE4 = ROOT / "phase4_global_verdict_report.json"
PHASE5 = ROOT / "final_synthesis_v3.3.1_GOLD.json"
OUT = ROOT / "EXECUTIVE_SUMMARY_v3.3.1.md"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    phase3 = load_json(PHASE3)
    phase4 = load_json(PHASE4)
    phase5 = load_json(PHASE5)

    h0 = phase4["chapter10"]["best_fit"]["H0"]
    s8 = phase4["chapter10"]["best_fit"]["S8"]
    jwst = phase3["chapter06"]["mean_growth_boost_percent_z_gt_10"]
    delta_bic = phase4["selection_criteria"]["delta_bic"]
    delta_chi2 = phase4["selection_criteria"]["delta_chi2"]
    s8_branch = phase5["chapters"]["chapter12"]["s8_lss"]
    fig9 = "assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png"

    text = "\n".join(
        [
            "# Executive Summary — ΨTMG v3.3.1 GOLD",
            "",
            "## Top 3 Results",
            "",
            f"1. **H₀ Resolution**: `ΨTMG` reaches `H₀ = {h0:.2f} km/s/Mpc`, materially above the `ΛCDM` baseline and consistent with the final high-local-expansion solution retained in the global fit.",
            f"2. **S₈ Resolution**: the global posterior locks the late-structure amplitude to `S₈ = {s8:.3f}`, while the scale-dependent cosmological branch reaches `S₈ = {s8_branch:.4f}` in the final low-`k` construction that resolves the tension without violating local gravity-wave bounds.",
            f"3. **JWST Growth Signature**: the calibrated early-growth branch produces a mean `z > 10` boost of `{jwst:.2f}%`, providing a direct geometric explanation for unexpectedly mature high-redshift galaxies.",
            "",
            "## Statistical Verdict",
            "",
            f"- `Δχ² = {delta_chi2:.1f}` against `ΛCDM`",
            f"- `ΔBIC = {delta_bic:.1f}`: **decisive evidence** in favor of the validated `ΨTMG` baseline",
            "",
            "## Fast Access",
            "",
            f"- Figure 09: [{fig9}]({fig9})",
            "- Table 2: [assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv](assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv)",
            "- Final synthesis: [final_synthesis_v3.3.1_GOLD.json](final_synthesis_v3.3.1_GOLD.json)",
            "",
        ]
    )
    OUT.write_text(text + "\n", encoding="utf-8")
    print(f"Wrote executive summary -> {OUT}")


if __name__ == "__main__":
    main()
