

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
