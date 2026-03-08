# Reproducibility

This repository includes an explicit cold-run reproducibility path for the validated v4.0.0 workflow.

The Python package identity of the project is now `psitmg`, as declared in [pyproject.toml](pyproject.toml). Infrastructure helpers that are not part of the scientific runtime have been moved under [infrastructure](infrastructure).

## Cold Run

Use [check_reproducibility.sh](check_reproducibility.sh) from the project root:

```bash
bash check_reproducibility.sh
```

The script performs these steps:

- creates a fresh virtual environment in `.repro-venv`
- reuses the sealed local scientific stack through `--system-site-packages` so the run remains fully offline
- verifies the installed package set against [requirements.lock](requirements.lock)
- exposes the repository root through `PYTHONPATH` so the local `psitmg` source tree is imported directly without network access
- scans the codebase for hard-coded user paths such as home-directory paths or user-specific Windows profile paths
- runs [reproduce_final_verdict.sh](reproduce_final_verdict.sh), which regenerates Figure 09 and Table 2 from the validated pipelines
- runs a light smoke execution for Phases 1 through 5
- runs [verify_table_consistency.py](scripts/verify_table_consistency.py) as part of the Phase 4 checks

The script exports these environment variables during the cold run:

- `MCGT_USE_TEX=0`
- `MPLBACKEND=Agg`
- `PYTHONUNBUFFERED=1`
- `MPLCONFIGDIR=.repro-mplconfig`
- `XDG_CACHE_HOME=.repro-mplconfig`
- `PYTHONPATH=<project root>`

`MCGT_USE_TEX=0` is intentional. It keeps the cold run focused on code and path reproducibility rather than on local TeX availability.

`requirements.lock` is the authoritative offline dependency lock for this audit path. [requirements.txt](requirements.txt) remains the lighter human-facing dependency list, but the cold-run gate resolves exclusively against the lock.

## Typography

Manuscript-style plotting is centralized in [style.py](scripts/_common/style.py).

- `apply_manuscript_defaults()` enforces serif fonts and LaTeX rendering when `latex` is available
- [sitecustomize.py](sitecustomize.py) applies the manuscript defaults automatically for Python entrypoints launched from the repository
- scripts that intentionally call `plt.style.use("classic")` must reapply `apply_manuscript_defaults()` immediately afterward

This guard is enforced by [test_manuscript_style_guard.py](tests/test_manuscript_style_guard.py).

## Table/Data Cross-Check

Use [verify_table_consistency.py](scripts/verify_table_consistency.py):

```bash
python scripts/verify_table_consistency.py
```

The validator cross-checks:

- [10_table_02_marginalized_constraints.csv](assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv)
- [10_table_02_marginalized_constraints.md](assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.md)
- [phase4_global_verdict_report.json](phase4_global_verdict_report.json)
- [main.tex](manuscript/main.tex)

This is intended to catch transcription drift between the numerical outputs, the manuscript tables, and the reported Phase 4 summary values.

## Output Provenance

The canonical Phase 4 posterior products are:

- [10_mcmc_affine_chain.csv.gz](assets/zz-data/10_global_scan/10_mcmc_affine_chain.csv.gz)
- [phase4_global_verdict_report.json](phase4_global_verdict_report.json)

The synchronized presentation exports under `output/` are derived from those canonical files:

- [ptmg_corner_plot.pdf](output/ptmg_corner_plot.pdf)
- [ptmg_corner_summary.json](output/ptmg_corner_summary.json)
- [ptmg_predictions_z0_to_z20.csv](output/ptmg_predictions_z0_to_z20.csv)

[ptmg_chains.h5](output/ptmg_chains.h5) is retained only for legacy tooling compatibility. It is not the authoritative source for the published Phase 4 posterior summary.

## CI Gates

The CI workflows now include dedicated reproducibility gates in:

- [ci.yml](.github/workflows/ci.yml)
- [ci-tests.yml](.github/workflows/ci-tests.yml)

These gates cover:

- stability audit regression checks
- canonical asset path checks
- Phase 4 package integrity checks
- Phase 5 geometric solution checks
- Table/Data consistency validation
- full cold-run reproducibility on the main workflow
