

# BEGIN INTEGRITY TARGETS
.PHONY: integrity integrity-update
integrity:
	@python3 tools/check_integrity.py

integrity-update:
	@python3 tools/gen_integrity_manifest.py
	@git add zz-manifests/integrity.json || true
	@echo "Manifeste mis à jour. Pensez à committer."

# END INTEGRITY TARGETS
