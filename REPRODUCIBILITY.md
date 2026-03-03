# Reproducibility

This repository includes an explicit cold-run reproducibility path for the validated v3.3.1 GOLD workflow.

## Cold Run

Use [check_reproducibility.sh](check_reproducibility.sh) from the project root:

```bash
bash check_reproducibility.sh
```

The script performs these steps:

- creates a fresh virtual environment in `.repro-venv`
- upgrades `pip`
- installs `requirements.txt`
- installs the project in editable mode with `pip install -e .`
- scans the codebase for hard-coded user paths such as home-directory paths or user-specific Windows profile paths
- runs a light smoke execution for Phases 1 through 5
- runs [verify_table_consistency.py](scripts/verify_table_consistency.py) as part of the Phase 4 checks

The script exports these environment variables during the cold run:

- `MCGT_USE_TEX=0`
- `MPLBACKEND=Agg`
- `PYTHONUNBUFFERED=1`

`MCGT_USE_TEX=0` is intentional. It keeps the cold run focused on code and path reproducibility rather than on local TeX availability.

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
