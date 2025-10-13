

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
