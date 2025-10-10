# Utilise '>' comme préfixe de recette pour éviter les TABs obligatoires
.RECIPEPREFIX := >
# IMPORTANT: GNU Make exige un chemin *nu* vers le shell (pas d'arguments)
SHELL := /bin/bash
# Options de bash pour que les erreurs fassent échouer la cible
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null || pwd)

# Dossier des figures (surcharge: make FIGDIR=mon-dossier figures-manifest)
FIGDIR ?= zz-figures

.PHONY: figures-norm figures-manifest figures-guard all-figures

figures-norm:
> bash tools/fig_naming_normalize.sh

figures-manifest:
> FIGDIR=$(FIGDIR) bash tools/rebuild_figures_sha256.sh

figures-guard:
> bash tools/ci_step2_figures_guard.sh

all-figures: figures-norm figures-manifest figures-guard

guard-local:
> bash tools/guard_local_run.sh || true

figures-index:
> bash tools/build_figures_index.sh

index-guard:
> bash tools/check_figures_index.sh
