#!/usr/bin/env bash
# TOLÉRANT : on n'abandonne jamais, tout est lisible
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts(){ date +"%Y-%m-%d %H:%M:%S"; }
say(){ echo -e "[$(ts)] $*"; }
run(){ say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p tools dist .github/workflows"

# 1) Makefile : cibles dist/ + checksums + paquetage
step "1) Makefile : cibles dist/, checksums, versionnage"
if ! grep -q '^# BEGIN DIST TARGETS$' Makefile 2>/dev/null; then
  cat >> Makefile <<'MK'

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
MK
fi

# 2) .gitignore : ignorer dist/
step "2) .gitignore : ignorer dist/"
if ! grep -qxF "dist/" .gitignore 2>/dev/null; then
  echo "dist/" >> .gitignore
fi

# 3) Workflow Release sur tag + SBOM + checksums + provenance
step "3) CI : release sur tag v* (build, SBOM, checksums, attestation, upload release)"
cat > .github/workflows/release-publish.yml <<'YML'
name: release-publish
on:
  push:
    tags:
      - "v*"
concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: write
  attestations: write
  id-token: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Setup Python (cache pip si besoin)
        uses: actions/setup-python@v5
        with: { python-version: "3.12" }

      - name: Cache pip (best-effort)
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-

      - name: Install deps (best-effort)
        run: |
          set -e
          if ls requirements*.txt >/dev/null 2>&1; then
            python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip
            PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -r requirements.txt || true
          fi

      - name: Build artifacts (dist-all)
        run: |
          make dist-all || make dist || true
          ls -l dist || true

      - name: Generate SBOM via Anchore (CycloneDX)
        uses: anchore/sbom-action@v0
        with:
          path: .
          format: cyclonedx-json
          output-file: dist/sbom.cdx.repo.json

      - name: Compute checksums (fallback si Makefile incomplet)
        run: |
          set -e
          cd dist || exit 0
          if [ ! -f *.sha256 ] 2>/dev/null; then
            rm -f ALL.sha256
            for f in *; do [ "$f" = "ALL.sha256" ] && continue; sha256sum "$f" >> ALL.sha256; done
          fi
          ls -l

      - name: Upload Release (assets)
        uses: softprops/action-gh-release@v2
        with:
          files: |
            dist/**
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Attest build provenance (DSSE)
        uses: actions/attest-build-provenance@v1
        with:
          subject-path: "dist/**"
YML

# 4) Bonus : workflow nightly (optionnel) pour artefacts datés
step "4) CI optionnelle : nightly (programme) — peut être supprimée si non désirée"
cat > .github/workflows/nightly.yml <<'YML'
name: nightly-artifacts
on:
  schedule:
    - cron: "33 2 * * *"   # toutes les nuits 02:33 UTC
  workflow_dispatch:
concurrency:
  group: nightly
  cancel-in-progress: true

permissions:
  contents: write
  attestations: write
  id-token: write

jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - name: Build artifacts
        run: |
          make dist-all || make dist || true
          ls -l dist || true
      - name: Upload artifacts (nightly)
        uses: actions/upload-artifact@v4
        with:
          name: nightly-dist
          path: dist/**
          if-no-files-found: ignore
YML

# 5) Commit + push (jamais bloquant)
step "5) Commit + push"
run "git add Makefile .gitignore .github/workflows/release-publish.yml .github/workflows/nightly.yml || true"
run "git commit -m 'ci(release): release auto sur tag (artefacts+SBOM+checksums+attestation); nightly optionnelle' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Envoie-moi la fin du log pour patch ciblé."
else
  say "✅ Série 7 appliquée côté script. Déclenche la release en poussant un tag v*."
  say "   Exemple :  git tag -a v0.1.0 -m 'v0.1.0' && git push origin v0.1.0"
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
