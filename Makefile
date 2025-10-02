.PHONY: lint fmt ci-local
lint:
	pre-commit run -a

fmt:
	if command -v shfmt >/dev/null 2>&1; then shfmt -w -i 2 -ci tools/*.sh; fi

ci-local: fmt lint
