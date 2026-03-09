# GitHub Configuration

This directory contains active repository automation and governance files.

Normalization rules:
- Keep only active workflows in `.github/workflows/*.yml`.
- Archive local/disabled workflow variants under `archives/cleanup_YYYYMMDD/`.
- Do not keep runtime caches or temporary CI artifacts in this tree.
