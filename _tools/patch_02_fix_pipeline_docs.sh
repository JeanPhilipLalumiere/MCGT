#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Seuls les fichiers CH*_PIPELINE_MINIMAL*.md ont été touchés, et toujours avec backup.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== PATCH 02 – Correction des chemins dans les CH*_PIPELINE_MINIMAL*.md =="
echo

python - << 'PYEOF'
import pathlib
import datetime

docs_dir = pathlib.Path("zz-docs")
ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

# Dictionnaire global (ancien chemin -> nouveau chemin)
replacements = {
    # CH01
    "zz-figures/chapter01/fig_01_early_plateau.png": "zz-figures/chapter01/01_fig_01_early_plateau.png",
    "zz-figures/chapter01/fig_02_logistic_calibration.png": "zz-figures/chapter01/01_fig_02_logistic_calibration.png",
    "zz-figures/chapter01/fig_03_relative_error_timeline.png": "zz-figures/chapter01/01_fig_03_relative_error_timeline.png",
    "zz-figures/chapter01/fig_04_P_vs_T_evolution.png": "zz-figures/chapter01/01_fig_04_p_vs_t_evolution.png",
    "zz-figures/chapter01/fig_05_I1_vs_T.png": "zz-figures/chapter01/01_fig_05_i1_vs_t.png",
    "zz-figures/chapter01/fig_06_P_derivative_comparison.png": "zz-figures/chapter01/01_fig_06_p_derivative_comparison.png",

    # CH02
    "zz-figures/chapter02/fig_00_spectrum.png": "zz-figures/chapter02/02_fig_00_spectrum.png",
    "zz-figures/chapter02/fig_01_P_vs_T_evolution.png": "zz-figures/chapter02/02_fig_01_p_vs_t_evolution.png",
    "zz-figures/chapter02/fig_02_calibration.png": "zz-figures/chapter02/02_fig_02_calibration.png",
    "zz-figures/chapter02/fig_03_relative_errors.png": "zz-figures/chapter02/02_fig_03_relative_errors.png",
    "zz-figures/chapter02/fig_04_pipeline_diagram.png": "zz-figures/chapter02/02_fig_04_pipeline_diagram.png",
    "zz-figures/chapter02/fig_05_FG_series.png": "zz-figures/chapter02/02_fig_05_fg_series.png",
    "zz-figures/chapter02/fig_06_fit_alpha.png": "zz-figures/chapter02/02_fig_06_alpha_fit.png",
    "zz-scripts/chapter02/plot_fig*.py": "",
    "zz-scripts/chapter02/requirements.txt": "",

    # CH03
    "zz-figures/chapter03/fig_05_interpolated_milestones.png": "zz-figures/chapter03/03_fig_05_interpolated_milestones.png",

    # CH04
    "zz-figures/chapter04/fig_01_invariants_schematic.png": "zz-figures/chapter04/04_fig_01_invariants_schematic.png",
    "zz-figures/chapter04/fig_02_invariants_histogram.png": "zz-figures/chapter04/04_fig_02_invariants_histogram.png",
    "zz-figures/chapter04/fig_03_invariants_vs_T.png": "zz-figures/chapter04/04_fig_03_invariants_vs_t.png",
    "zz-figures/chapter04/fig_04_relative_deviations.png": "zz-figures/chapter04/04_fig_04_relative_deviations.png",

    # CH06
    "zz-figures/chapter06/fig_01_cmb_dataflow_diagram.png": "zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png",
    "zz-figures/chapter06/fig_02_cls_lcdm_vs_mcgt.png": "zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png",
    "zz-figures/chapter06/fig_03_delta_cls_relative.png": "zz-figures/chapter06/06_fig_03_delta_cls_relative.png",
    "zz-figures/chapter06/fig_04_delta_rs_vs_params.png": "zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png",
    "zz-figures/chapter06/fig_05_delta_chi2_heatmap.png": "zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png",

    # CH07 – data d(k) -> vs_k
    "zz-data/chapter07/07_dcs2_dk.csv": "zz-data/chapter07/07_dcs2_vs_k.csv",
    "zz-data/chapter07/07_ddelta_phi_dk.csv": "zz-data/chapter07/07_ddelta_phi_vs_k.csv",

    # CH07 – figures
    "zz-figures/chapter07/fig_00_loglog_sampling_test.png": "",
    "zz-figures/chapter07/fig_01_cs2_heatmap_k_a.png": "zz-figures/chapter07/07_fig_01_cs2_heatmap.png",
    "zz-figures/chapter07/fig_02_delta_phi_heatmap_k_a.png": "zz-figures/chapter07/07_fig_02_delta_phi_heatmap.png",
    "zz-figures/chapter07/fig_03_invariant_I1.png": "zz-figures/chapter07/07_fig_03_invariant_i1.png",
    "zz-figures/chapter07/fig_04_dcs2_dk_vs_k.png": "zz-figures/chapter07/07_fig_04_dcs2_vs_k.png",
    "zz-figures/chapter07/fig_05_ddelta_phi_dk_vs_k.png": "zz-figures/chapter07/07_fig_05_ddelta_phi_vs_k.png",
    "zz-figures/chapter07/fig_06_comparison.png": "zz-figures/chapter07/07_fig_06_comparison.png",
    "zz-figures/chapter07/fig_07_invariant_I2.png": "zz-figures/chapter07/07_fig_07_invariant_i2.png",

    # CH07 – scripts tracer -> plot
    "zz-scripts/chapter07/tracer_fig03_invariant_I1.py": "zz-scripts/chapter07/plot_fig03_invariant_i1.py",
    "zz-scripts/chapter07/tracer_fig04_dcs2_vs_k.py": "zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py",
    "zz-scripts/chapter07/tracer_fig05_ddelta_phi_vs_k.py": "zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py",
    "zz-scripts/chapter07/tracer_fig07_invariant_I2.py": "zz-scripts/chapter07/plot_fig07_invariant_i2.py",

    # CH08 – figures vers 08_fig_XX_*.png
    "zz-figures/chapter08/fig_01_chi2_total_vs_q0.png": "zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png",
    "zz-figures/chapter08/fig_02_dv_vs_z.png": "zz-figures/chapter08/08_fig_02_dv_vs_z.png",
    "zz-figures/chapter08/fig_03_mu_vs_z.png": "zz-figures/chapter08/08_fig_03_mu_vs_z.png",
    "zz-figures/chapter08/fig_05_residuals.png": "zz-figures/chapter08/08_fig_05_residuals.png",
    "zz-figures/chapter08/fig_06_normalized_residuals.png": "zz-figures/chapter08/08_fig_06_normalized_residuals_distribution.png",
    "zz-figures/chapter08/fig_07_chi2_profile.png": "zz-figures/chapter08/08_fig_07_chi2_profile.png",
    "zz-scripts/chapter08/utils/*.py": "",

    # CH09
    "zz-figures/chapter09/fig_01_phase_overlay.png": "zz-figures/chapter09/09_fig_01_phase_overlay.png",
    "zz-figures/chapter09/fig_02_residual_phase.png": "zz-figures/chapter09/09_fig_02_residual_phase.png",
    "zz-figures/chapter09/p95_check_control.png": "",

    # CH10
    "zz-figures/chapter10/fig_01_iso_p95_maps.png": "zz-figures/chapter10/10_fig_01_iso_p95_maps.png",
    "zz-figures/chapter10/fig_02_scatter_phi_at_fpeak.png": "zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png",
    "zz-figures/chapter10/fig_03_convergence_p95_vs_n.png": "zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png",
    "zz-figures/chapter10/fig_03b_coverage_bootstrap_vs_n_hires.png": "zz-figures/chapter10/10_fig_03_b_coverage_bootstrap_vs_n_hires.png",
    "zz-figures/chapter10/fig_04_scatter_p95_recalc_vs_orig.png": "zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png",
    "zz-figures/chapter10/fig_05_hist_cdf_metrics.png": "zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png",
    "zz-figures/chapter10/fig_06_heatmap_absdp95_m1m2.png": "zz-figures/chapter10/10_fig_06_residual_map.png",
    "zz-figures/chapter10/fig_07_summary_comparison.png": "zz-figures/chapter10/10_fig_07_synthesis.png",
}

for md_path in sorted(docs_dir.glob("CH*_PIPELINE_MINIMAL*.md")):
    text = md_path.read_text(encoding="utf-8")
    original = text

    for old, new in replacements.items():
        if old in text:
            if new == "":
                text = text.replace(old, "")
                print(f"  [PATCH] {md_path}: suppression de {old!r}")
            else:
                text = text.replace(old, new)
                print(f"  [PATCH] {md_path}: {old!r} -> {new!r}")

    if text != original:
        bak = md_path.with_suffix(md_path.suffix + f".bak_patch_{ts}")
        bak.write_text(original, encoding="utf-8")
        md_path.write_text(text, encoding="utf-8")
        print(f"  [WRITE] sauvegarde -> {bak}")
        print(f"  [WRITE] fichier mis à jour -> {md_path}")
    else:
        print(f"  [SKIP]  {md_path}: aucune occurrence à modifier")

PYEOF

echo
echo "Terminé (patch_02_fix_pipeline_docs)."
read -rp "Appuie sur Entrée pour revenir au shell..." _
