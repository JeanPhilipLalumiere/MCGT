.PHONY: lint fmt ci-local
lint:
	pre-commit run -a

fmt:
	if command -v shfmt >/dev/null 2>&1; then shfmt -w -i 2 -ci tools/*.sh; fi

ci-local: fmt lint

check:
	pre-commit run -a --show-diff-on-failure

hooks:
	pre-commit install
ci:
	@command -v gh >/dev/null 2>&1 || { echo "gh (GitHub CLI) non installé"; exit 0; }
	gh workflow run ci-pre-commit.yml || true

.PHONY: status policies locks
status:
	@echo "== MCGT status =="
	@bash tools/ci_step1_policies_guard.sh || true
	@echo "-- data locks --"
	@find zz-data -type f -name '*.lock.json' | wc -l | xargs echo "locks:"
	@echo "done."

policies:
	bash tools/ci_step1_policies_guard.sh

locks:
	bash tools/generate_data_locks.sh
