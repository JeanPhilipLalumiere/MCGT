#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "assets" / "zz-manifests" / "manuscript_artifact_manifest.json"
OUT_MD = ROOT / "assets" / "zz-manifests" / "manuscript_artifact_manifest.md"
AUTHOR_NAME = "Jean-Philip Lalumière"
RELEASE_VERSION = "v3.3.1"

PHASE1_LOG = ROOT / "stability_audit_log.txt"
PHASE2_LOG = ROOT / "phase2_observational_log.txt"
PHASE3_JSON = ROOT / "phase3_lss_geometry_report.json"
PHASE4_JSON = ROOT / "phase4_global_verdict_report.json"
PHASE4_PACKAGE_JSON = ROOT / "zz-zenodo" / "phase4_global_verdict_v3.3.1" / "phase4_zenodo_metadata.json"
FINAL_GOLD_JSON = ROOT / "final_synthesis_v3.3.1_GOLD.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return
    path.write_text(text, encoding="utf-8")


def git_head(short: bool = False) -> str:
    cmd = ["git", "rev-parse"]
    if short:
        cmd.append("--short")
    cmd.append("HEAD")
    return subprocess.check_output(cmd, cwd=ROOT, text=True).strip()


def parse_phase2_log(text: str) -> dict[str, object]:
    def grab(pattern: str) -> str:
        match = re.search(pattern, text)
        if not match:
            raise ValueError(f"Pattern not found in phase2 log: {pattern}")
        return match.group(1)

    return {
        "chi2_psitmg": float(grab(r"chi2\(PsiTMG\): ([0-9.]+)")),
        "chi2_lcdm": float(grab(r"chi2\(LambdaCDM\): ([0-9.]+)")),
        "delta_chi2": float(grab(r"delta chi2 \(PsiTMG - LambdaCDM\): ([\-0-9.]+)")),
        "fraction_lower_luminosity_distance": float(
            grab(r"Fraction with lower luminosity distance than LambdaCDM: ([0-9.]+)")
        ),
        "gr_convergence": grab(r"GR convergence at high temperature: (true|false)") == "true",
        "dh_within_bounds": grab(r"D/H within observational bounds: (true|false)") == "true",
        "yp_within_bounds": grab(r"Y_p within observational bounds: (true|false)") == "true",
        "source_log": str(PHASE2_LOG.relative_to(ROOT)),
    }


def parse_phase1_log(text: str) -> dict[str, object]:
    def grab(pattern: str) -> str:
        match = re.search(pattern, text)
        if not match:
            raise ValueError(f"Pattern not found in phase1 log: {pattern}")
        return match.group(1)

    return {
        "max_hubble_invariant": float(grab(r"max I_H on z in \[0, 67760\]: ([0-9.eE+\-]+)")),
        "hubble_invariant_pass": grab(r"Criterion max I_H < 1e-15: (PASS|FAIL)") == "PASS",
        "strict_sentinel_false_positives": int(grab(r"strict Sentinel false positives: ([0-9]+)")),
        "golden_match_pass": grab(r"Golden Match criterion \(alpha ~ 0.50 -> n_s ~ 0.96\): (PASS|FAIL)")
        == "PASS",
        "hamiltonian_pass": grab(r"Hamiltonian proxy strictly negative on trajectory: (PASS|FAIL)")
        == "PASS",
        "source_log": str(PHASE1_LOG.relative_to(ROOT)),
    }


def collect_file_record(path_str: str) -> dict[str, object]:
    path = ROOT / path_str
    return {
        "path": path_str,
        "exists": path.exists(),
        "size_bytes": path.stat().st_size if path.exists() else None,
        "sha256": sha256(path) if path.exists() else None,
    }


def main() -> None:
    phase1 = parse_phase1_log(PHASE1_LOG.read_text(encoding="utf-8"))
    phase2 = parse_phase2_log(PHASE2_LOG.read_text(encoding="utf-8"))
    phase3 = json.loads(PHASE3_JSON.read_text(encoding="utf-8"))
    phase4 = json.loads(PHASE4_JSON.read_text(encoding="utf-8"))
    phase4_package = json.loads(PHASE4_PACKAGE_JSON.read_text(encoding="utf-8"))
    phase5 = json.loads(FINAL_GOLD_JSON.read_text(encoding="utf-8"))

    tracked_files = [
        "LICENSE",
        "CITATION.cff",
        "CHANGELOG.md",
        "README.md",
        "REPRODUCIBILITY.md",
        "CERTIFICATE_OF_INTEGRITY.txt",
        "stability_audit_log.txt",
        "phase2_observational_log.txt",
        "phase3_lss_geometry_report.txt",
        "phase3_lss_geometry_report.json",
        "phase4_global_verdict_report.json",
        "final_synthesis_v3.3.1_GOLD.json",
        "assets/zz-figures/stability_audit/figure_2_ch01_numerical_drift.png",
        "assets/zz-figures/stability_audit/figure_3_ch02_alpha_ns_mapping.png",
        "assets/zz-figures/stability_audit/figure_5_ch03_phase_stability.png",
        "assets/zz-figures/04_expansion_supernovae/04_fig_06_pantheon_residuals.png",
        "assets/zz-figures/04_expansion_supernovae/04_fig_06_pantheon_residuals.pdf",
        "assets/zz-figures/04_expansion_supernovae/04_fig_06_pantheon_residuals.svg",
        "assets/zz-figures/05_primordial_bbn/05_fig_05_bbn_3min_summary.png",
        "assets/zz-figures/05_primordial_bbn/05_fig_05_bbn_3min_summary.pdf",
        "assets/zz-figures/06_early_growth_jwst/06_fig_09_structure_growth_factor.png",
        "assets/zz-figures/07_bao_geometry/07_fig_10_bao_hubble_diagram.png",
        "assets/zz-figures/08_sound_horizon/08_fig_11_sound_horizon_near_decoupling.png",
        "assets/zz-data/11_lss_s8_tension/11_scale_conflict_summary.csv",
        "assets/zz-data/11_lss_s8_tension/11_scale_conflict_summary.json",
        "assets/zz-data/12_cmb_verdict/12_step_transition_law.csv",
        "assets/zz-data/12_cmb_verdict/12_step_transition_summary.json",
        "assets/zz-figures/11_lss_s8_tension/11_fig_19_screening_failures.png",
        "assets/zz-figures/12_cmb_verdict/12_fig_21_perfect_k_transition_law.png",
        phase4["chapter09"]["figure_12"],
        phase4["chapter09"]["figure_13"],
        phase4["chapter10"]["figure_17"],
        phase4["chapter10"]["table_2_csv"],
        phase4["chapter10"]["table_2_md"],
        phase4["chapter10"]["chain_csv_gz"],
        "zz-zenodo/ptmg_predictions_z0_to_z20.csv",
        "zz-zenodo/ptmg_growth_comparison_GR_vs_k0.csv",
        "zz-zenodo/phase4_global_verdict_v3.3.1/README.txt",
        "zz-zenodo/phase4_global_verdict_v3.3.1/phase4_zenodo_inventory.csv",
        "zz-zenodo/phase4_global_verdict_v3.3.1/phase4_zenodo_metadata.json",
        "zz-zenodo/phase4_global_verdict_v3.3.1/phase4_zenodo_inventory.json",
        "zz-zenodo/phase4_global_verdict_v3.3.1/phase4_zenodo_checksums.txt",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/phase4_global_verdict_report.json",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-data/10_global_scan/10_mcmc_affine_chain.csv.gz",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-data/10_global_scan/10_mcmc_global_summary.json",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.md",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-figures/09_dark_energy_cpl/09_fig_12_equation_of_state_evolution.png",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-figures/09_dark_energy_cpl/09_fig_13_cpl_constraints_contours.png",
        "zz-zenodo/phase4_global_verdict_v3.3.1/files/assets/zz-figures/10_global_scan/10_fig_17_5d_corner_plot.png",
        "zz-zenodo/phase4_global_verdict_v3.3.1.tar.gz",
    ]

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "release_version": RELEASE_VERSION,
        "git_head_short": git_head(short=True),
        "git_head_full": git_head(short=False),
        "scope": "manuscript_artifacts_phase1_to_phase5",
        "author": AUTHOR_NAME,
        "phases": {
            "phase1": phase1,
            "phase2": phase2,
            "phase3": phase3,
            "phase4": phase4,
            "phase5": phase5,
        },
        "phase4_local_package": phase4_package,
        "tracked_files": [collect_file_record(path_str) for path_str in tracked_files],
    }

    safe_write_text(OUT_JSON, json.dumps(manifest, indent=2))

    md_lines = [
        "# Manuscript Artifact Manifest",
        "",
        f"- Release version: {RELEASE_VERSION}",
        f"- Git head (short): {manifest['git_head_short']}",
        f"- Author: {AUTHOR_NAME}",
        f"- Generated at (UTC): {manifest['generated_at_utc']}",
        "- Scope: phases 1, 2, 3, 4 and 5",
        "- Reproducibility guide: REPRODUCIBILITY.md",
        "",
        "## Phase 1",
        f"- Max modified-Friedmann invariant: {phase1['max_hubble_invariant']:.6e}",
        f"- Hubble invariant gate: {str(phase1['hubble_invariant_pass']).lower()}",
        f"- Strict Sentinel false positives: {phase1['strict_sentinel_false_positives']}",
        f"- Golden Match: {str(phase1['golden_match_pass']).lower()}",
        f"- Hamiltonian stability gate: {str(phase1['hamiltonian_pass']).lower()}",
        "",
        "## Phase 2",
        f"- Pantheon+ chi2(PsiTMG): {phase2['chi2_psitmg']}",
        f"- Pantheon+ chi2(LambdaCDM): {phase2['chi2_lcdm']}",
        f"- Fraction mu(PsiTMG) < mu(LambdaCDM): {phase2['fraction_lower_luminosity_distance']:.4f}",
        f"- BBN GR convergence: {str(phase2['gr_convergence']).lower()}",
        "",
        "## Phase 3",
        f"- JWST mean growth boost z>10: {phase3['chapter06']['mean_growth_boost_percent_z_gt_10']:.4f}%",
        f"- BAO chi2: {phase3['chapter07']['chi2_bao_hubble']:.6f}",
        f"- Sound horizon reduction: {phase3['chapter08']['delta_rs_Mpc']:.6f} Mpc",
        "",
        "## Phase 4",
        f"- CPL MAP: w0={phase4['chapter09']['map']['w0']}, wa={phase4['chapter09']['map']['wa']}",
        f"- MCMC diagnostics: Rhat_max={phase4['chapter10']['diagnostics']['rhat_max']:.6f}, ESS_min={phase4['chapter10']['diagnostics']['ess_min']:.2f}",
        f"- Selection: delta_chi2={phase4['selection_criteria']['delta_chi2']}, delta_aic={phase4['selection_criteria']['delta_aic']}, delta_bic={phase4['selection_criteria']['delta_bic']:.6f}",
        "",
        "## Phase 5",
        f"- Universal conflict factor: {phase5['chapters']['chapter11']['conflict_factor_branch']:.1f}",
        f"- Step-law S8 cosmological branch: {phase5['chapters']['chapter12']['s8_lss']:.6f}",
        f"- GW transition proxy: {phase5['chapters']['chapter12']['gw_transition_phase_shift_proxy']:.1e}",
        f"- LIGO compliance fraction: {phase5['ligo_compliance']['compliance_fraction']:.1f}",
        "",
        "## Local Package",
        f"- Package name: {phase4_package['package_name']}",
        f"- Files staged: {phase4_package['files_staged']}",
        f"- Publish to Zenodo: {str(phase4_package['publish_to_zenodo']).lower()}",
        f"- Prediction export: zz-zenodo/ptmg_predictions_z0_to_z20.csv",
    ]
    safe_write_text(OUT_MD, "\n".join(md_lines) + "\n")
    print(f"Wrote manifest -> {OUT_JSON}")
    print(f"Wrote manifest -> {OUT_MD}")


if __name__ == "__main__":
    main()
