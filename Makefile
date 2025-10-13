.SHELLFLAGS := -eu -o pipefail -c
.PHONY: help setup dev-install precommit test smoke smoke-ch09 figs-index prepub clean

help:
	@echo "Cibles disponibles:"
	@echo "  setup        - Crée venv .venv et installe toutes les deps"
	@echo "  dev-install  - Installe toutes les requirements (hors venv)"
	@echo "  precommit    - pre-commit run -a"
	@echo "  test         - pytest (si répertoires de tests présents)"
	@echo "  smoke        - zz-tools/smoke_all.sh si présent"
	@echo "  smoke-ch09   - zz-tools/smoke_ch09_fast.sh si présent"
	@echo "  figs-index   - tools/build_figures_index.sh si présent"
	@echo "  prepub       - tools/build_prepub_bundle.sh si présent"
	@echo "  clean        - git clean -fdX sur sorties générées"

setup:
	@test -d .venv || python3 -m venv .venv
	@. .venv/bin/activate && pip install --upgrade pip
	@. .venv/bin/activate && find . -name "requirements.txt" -maxdepth 4 -print0 | xargs -0 -r -I{} bash -lc '. .venv/bin/activate && pip install -r "{}"'
	@. .venv/bin/activate && pip install pre-commit pytest

dev-install:
	@python3 -m pip install --upgrade pip
	@find . -name "requirements.txt" -maxdepth 4 -print0 | xargs -0 -r -I{} bash -lc 'pip install -r "{}"'
	@pip install pre-commit pytest

precommit:
	@pre-commit run -a

test:
	@if ls tests 1>/dev/null 2>&1 || ls zz-scripts/**/tests 1>/dev/null 2>&1; then pytest -q; else echo "Aucun tests/ détecté — skip"; fi

smoke:
	@bash -lc 'test -x zz-tools/smoke_all.sh && zz-tools/smoke_all.sh || { echo "zz-tools/smoke_all.sh introuvable — skip"; exit 0; }'

smoke-ch09:
	@bash -lc 'test -x zz-tools/smoke_ch09_fast.sh && zz-tools/smoke_ch09_fast.sh || { echo "zz-tools/smoke_ch09_fast.sh introuvable — skip"; exit 0; }'

figs-index:
	@bash -lc 'test -x tools/build_figures_index.sh && tools/build_figures_index.sh || { echo "tools/build_figures_index.sh introuvable — skip"; exit 0; }'

prepub:
	@bash -lc 'test -x tools/build_prepub_bundle.sh && tools/build_prepub_bundle.sh || { echo "tools/build_prepub_bundle.sh introuvable — skip"; exit 0; }'

clean:
	@git ls-files | grep -E '^(zz-out|\.ci-out|_tmp-figs|\.ci-logs)/' && echo "Rien à nettoyer (non suivis)" || true
	@git clean -fdX zz-out .ci-out _tmp-figs .ci-logs || true
