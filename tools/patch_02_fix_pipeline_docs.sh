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

docs_dir = pathlib.Path("docs")
ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")

# Dictionnaire global (ancien chemin -> nouveau chemin)
replacements = {
    # CH01
    "assets/zz-figures/chapter01/01_fig_01_early_plateau.png": "assets/zz-figures/chapter01/01_fig_01_early_plateau.png",
    "assets/zz-figures/chapter01/01_fig_02_logistic_calibration.png": "assets/zz-figures/chapter01/01_fig_02_logistic_calibration.png",
    "assets/zz-figures/chapter01/01_fig_03_relative_error_timeline.png": "assets/zz-figures/chapter01/01_fig_03_relative_error_timeline.png",
    "assets/zz-figures/chapter01/01_fig_04_P_vs_T_evolution.png": "assets/zz-figures/chapter01/01_fig_04_p_vs_t_evolution.png",
    "assets/zz-figures/chapter01/01_fig_05_I1_vs_T.png": "assets/zz-figures/chapter01/01_fig_05_i1_vs_t.png",
    "assets/zz-figures/chapter01/01_fig_06_P_derivative_comparison.png": "assets/zz-figures/chapter01/01_fig_06_p_derivative_comparison.png",

    # CH02
    "assets/zz-figures/chapter02/02_fig_00_spectrum.png": "assets/zz-figures/chapter02/02_fig_00_spectrum.png",
    "assets/zz-figures/chapter02/02_fig_01_P_vs_T_evolution.png": "assets/zz-figures/chapter02/02_fig_01_p_vs_t_evolution.png",
    "assets/zz-figures/chapter02/02_fig_02_calibration.png": "assets/zz-figures/chapter02/02_fig_02_calibration.png",
    "assets/zz-figures/chapter02/02_fig_03_relative_errors.png": "assets/zz-figures/chapter02/02_fig_03_relative_errors.png",
    "assets/zz-figures/chapter02/02_fig_04_pipeline_diagram.png": "assets/zz-figures/chapter02/02_fig_04_pipeline_diagram.png",
    "assets/zz-figures/chapter02/02_fig_05_FG_series.png": "assets/zz-figures/chapter02/02_fig_05_fg_series.png",
    "assets/zz-figures/chapter02/02_fig_06_fit_alpha.png": "assets/zz-figures/chapter02/02_fig_06_alpha_fit.png",
    "scripts/02_primordial_spectrum/plot_fig*.py": "",
    "scripts/02_primordial_spectrum/requirements.txt": "",

    # CH03
    "assets/zz-figures/chapter03/03_fig_05_interpolated_milestones.png": "assets/zz-figures/chapter03/03_fig_05_interpolated_milestones.png",

    # CH04
    "assets/zz-figures/chapter04/04_fig_01_invariants_schematic.png": "assets/zz-figures/chapter04/04_fig_01_invariants_schematic.png",
    "assets/zz-figures/chapter04/04_fig_02_invariants_histogram.png": "assets/zz-figures/chapter04/04_fig_02_invariants_histogram.png",
    "assets/zz-figures/chapter04/04_fig_03_invariants_vs_T.png": "assets/zz-figures/chapter04/04_fig_03_invariants_vs_t.png",
    "assets/zz-figures/chapter04/04_fig_04_relative_deviations.png": "assets/zz-figures/chapter04/04_fig_04_relative_deviations.png",

    # CH06
    "assets/zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png": "assets/zz-figures/chapter06/06_fig_01_cmb_dataflow_diagram.png",
    "assets/zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png": "assets/zz-figures/chapter06/06_fig_02_cls_lcdm_vs_mcgt.png",
    "assets/zz-figures/chapter06/06_fig_03_delta_cls_relative.png": "assets/zz-figures/chapter06/06_fig_03_delta_cls_relative.png",
    "assets/zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png": "assets/zz-figures/chapter06/06_fig_04_delta_rs_vs_params.png",
    "assets/zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png": "assets/zz-figures/chapter06/06_fig_05_delta_chi2_heatmap.png",

    # CH07 – data d(k) -> vs_k
    "assets/zz-data/chapter07/07_dcs2_dk.csv": "assets/zz-data/chapter07/07_dcs2_vs_k.csv",
    "assets/zz-data/chapter07/07_ddelta_phi_dk.csv": "assets/zz-data/chapter07/07_ddelta_phi_vs_k.csv",

    # CH07 – figures
    "assets/zz-figures/chapter07/07_fig_00_loglog_sampling_test.png": "",
    "assets/zz-figures/chapter07/07_fig_01_cs2_heatmap_k_a.png": "assets/zz-figures/chapter07/07_fig_01_cs2_heatmap.png",
    "assets/zz-figures/chapter07/07_fig_02_delta_phi_heatmap_k_a.png": "assets/zz-figures/chapter07/07_fig_02_delta_phi_heatmap.png",
    "assets/zz-figures/chapter07/07_fig_03_invariant_I1.png": "assets/zz-figures/chapter07/07_fig_03_invariant_i1.png",
    "assets/zz-figures/chapter07/07_fig_04_dcs2_dk_vs_k.png": "assets/zz-figures/chapter07/07_fig_04_dcs2_vs_k.png",
    "assets/zz-figures/chapter07/07_fig_05_ddelta_phi_dk_vs_k.png": "assets/zz-figures/chapter07/07_fig_05_ddelta_phi_vs_k.png",
    "assets/zz-figures/chapter07/07_fig_06_comparison.png": "assets/zz-figures/chapter07/07_fig_06_comparison.png",
    "assets/zz-figures/chapter07/07_fig_07_invariant_I2.png": "assets/zz-figures/chapter07/07_fig_07_invariant_i2.png",

    # CH07 – scripts tracer -> plot
    "scripts/07_bao_geometry/tracer_fig03_invariant_I1.py": "scripts/07_bao_geometry/plot_fig03_invariant_i1.py",
    "scripts/07_bao_geometry/tracer_fig04_dcs2_vs_k.py": "scripts/07_bao_geometry/plot_fig04_dcs2_vs_k.py",
    "scripts/07_bao_geometry/tracer_fig05_ddelta_phi_vs_k.py": "scripts/07_bao_geometry/plot_fig05_ddelta_phi_vs_k.py",
    "scripts/07_bao_geometry/tracer_fig07_invariant_I2.py": "scripts/07_bao_geometry/plot_fig07_invariant_i2.py",

    # CH08 – figures vers 08_fig_XX_*.png
    "assets/zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png": "assets/zz-figures/chapter08/08_fig_01_chi2_total_vs_q0.png",
    "assets/zz-figures/chapter08/08_fig_02_dv_vs_z.png": "assets/zz-figures/chapter08/08_fig_02_dv_vs_z.png",
    "assets/zz-figures/chapter08/08_fig_03_mu_vs_z.png": "assets/zz-figures/chapter08/08_fig_03_mu_vs_z.png",
    "assets/zz-figures/chapter08/08_fig_05_residuals.png": "assets/zz-figures/chapter08/08_fig_05_residuals.png",
    "assets/zz-figures/chapter08/08_fig_06_normalized_residuals.png": "assets/zz-figures/chapter08/08_fig_06_normalized_residuals_distribution.png",
    "assets/zz-figures/chapter08/08_fig_07_chi2_profile.png": "assets/zz-figures/chapter08/08_fig_07_chi2_profile.png",
    "scripts/08_sound_horizon/utils/*.py": "",

    # CH09
    "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png": "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png",
    "assets/zz-figures/chapter09/09_fig_02_residual_phase.png": "assets/zz-figures/chapter09/09_fig_02_residual_phase.png",
    "assets/zz-figures/chapter09/p95_check_control.png": "",

    # CH10
    "assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png": "assets/zz-figures/chapter10/10_fig_01_iso_p95_maps.png",
    "assets/zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png": "assets/zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png",
    "assets/zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png": "assets/zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png",
    "assets/zz-figures/chapter10/10_fig_03_b_coverage_bootstrap_vs_n_hires.png": "assets/zz-figures/chapter10/10_fig_03_b_coverage_bootstrap_vs_n_hires.png",
    "assets/zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png": "assets/zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png",
    "assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png": "assets/zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png",
    "assets/zz-figures/chapter10/10_fig_06_heatmap_absdp95_m1m2.png": "assets/zz-figures/chapter10/10_fig_06_residual_map.png",
    "assets/zz-figures/chapter10/10_fig_07_summary_comparison.png": "assets/zz-figures/chapter10/10_fig_07_synthesis.png",
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
