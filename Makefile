# Utilise '>' comme préfixe de recette pour éviter les TABs obligatoires
.RECIPEPREFIX := >
SHELL := /usr/bin/env bash
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
