

# BEGIN INTEGRITY TARGETS
.PHONY: integrity integrity-update
integrity:
	@python3 tools/check_integrity.py

integrity-update:
	@python3 tools/gen_integrity_manifest.py
	@git add zz-manifests/integrity.json || true
	@echo "Manifeste mis à jour. Pensez à committer."

# END INTEGRITY TARGETS

# BEGIN BUDGET TARGETS
.PHONY: budgets ci-checks
budgets:
	@python3 tools/scan_assets_budget.py

ci-checks: integrity budgets
	@echo "CI local OK."
# END BUDGET TARGETS

# BEGIN DIST TARGETS
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
DATE    ?= $(shell date -u +%Y%m%dT%H%M%SZ)
DISTDIR ?= dist
ARTIFACT_BASENAME ?= mcgt-$(VERSION)-$(DATE)

.PHONY: dist-clean
dist-clean:
	@rm -rf $(DISTDIR)

.PHONY: dist-prepare
dist-prepare:
	@mkdir -p $(DISTDIR)

# Si tu as déjà un build PDF dans .github/workflows/pdf.yml qui dépose un PDF,
# on rejoue ici de manière best-effort (à adapter au besoin).
.PHONY: build-pdf
build-pdf:
	@echo "Build PDF local (optionnel) — adapte cette cible si nécessaire"
	@# Exemple : make -C legacy-tex pdf || true

.PHONY: dist
dist: dist-prepare build-pdf
	@echo "Rassemble les artefacts connus"
	@# Exemple : cp path/to/output.pdf $(DISTDIR)/$(ARTIFACT_BASENAME).pdf || true
	@# Ajoute ici d'autres artefacts si besoin (archives, datasets condensés, etc.)

.PHONY: checksums
checksums: dist
	@echo "Génère checksums dans $(DISTDIR)/$(ARTIFACT_BASENAME).sha256"
	@cd $(DISTDIR) && (shopt -s nullglob; \
	  rm -f $(ARTIFACT_BASENAME).sha256; \
	  for f in *; do \
	    [ "$$f" = "$(ARTIFACT_BASENAME).sha256" ] && continue; \
	    sha256sum "$$f" >> $(ARTIFACT_BASENAME).sha256; \
	  done)

.PHONY: sbom-local
sbom-local: dist
	@echo "SBOM local (si syft dispo)"
	@command -v syft >/dev/null 2>&1 || { echo "syft non trouvé — skip"; exit 0; }
	@syft packages dir:. -o cyclonedx-json > $(DISTDIR)/$(ARTIFACT_BASENAME).sbom.cdx.json

.PHONY: dist-all
dist-all: dist checksums sbom-local
	@echo "dist-all terminé."

# END DIST TARGETS

# BEGIN CI FAST TARGET
.PHONY: ci-fast
ci-fast:
	@echo "CI rapide locale : pre-commit + budgets"
	pre-commit run -a || true
# END CI FAST TARGET

# BEGIN PY DIST TARGETS
.PHONY: dist clean-dist twine-check
dist:
	@python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U build twine >/dev/null
	@python -m build
twine-check:
	@python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U twine >/dev/null
	@python -m twine check dist/*
clean-dist:
	@rm -rf dist build *.egg-info || true
# END PY DIST TARGETS

# BEGIN DOCS TARGETS
.PHONY: docs-serve docs-build docs-clean
docs-serve:
	\t@python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U mkdocs mkdocs-material >/dev/null
	\t@mkdocs serve -a 0.0.0.0:8000
docs-build:
	\t@python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U mkdocs mkdocs-material >/dev/null
	\t@mkdocs build --clean
docs-clean:
	\t@rm -rf site || true
# END DOCS TARGETS

.PHONY: smoke-ch09
# smoke-ch09:
# 	@echo "[SMOKE ch09] Prétraitement"
# 	python zz-scripts/chapter09/generate_data_chapter09.py --ref zz-data/chapter09/09_phases_imrphenom.csv \
# 		--out-prepoly zz-data/chapter09/09_phases_mcgt_prepoly.csv \
# 		--out-diff zz-data/chapter09/09_phase_diff.csv --log-level INFO || true
# 	@echo "[SMOKE ch09] Figures minimales"
# 	python zz-scripts/chapter09/plot_fig01_phase_overlay.py \
# 		--csv zz-data/chapter09/09_phases_mcgt.csv --meta zz-data/chapter09/09_metrics_phase.json \
# 		--out zz-figures/chapter09/fig_01_phase_overlay.png --dpi 150 || true
# 
.PHONY: smoke-ch10
# smoke-ch10:
# 	@echo "[SMOKE ch10] Échantillonnage réduit"
# 	python zz-scripts/chapter10/generate_data_chapter10.py \
# 		--config zz-data/chapter10/10_mc_config.json \
# 		--out-results zz-data/chapter10/10_mc_results.csv \
# 		--out-samples zz-data/chapter10/10_mc_samples.csv --log-level INFO || true
# 
.PHONY: smoke-all
# smoke-all: smoke-ch09 smoke-ch10
# 
-include make/smoke.mk
include make/smoke.mk
