#!/usr/bin/env bash
# Force un backend non-interactif partout (CI/local)
export MPLBACKEND=Agg
export PYTHONWARNINGS="ignore"
echo "[MPL] backend=${MPLBACKEND}"
