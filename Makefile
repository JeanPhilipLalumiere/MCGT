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
