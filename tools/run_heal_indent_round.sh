#!/usr/bin/env bash
set -euo pipefail
echo "[1/3] Audit initial…"
python3 tools/mcgt_sweeper.py
python3 tools/mcgt_blockers_extract.py
python3 tools/peek_artifacts.py

echo "[2/3] Heal 'unexpected indent' guidé par first_errors…"
python3 tools/heal_unexpected_indent_from_first.py || true

echo "[3/3] Audit après heal…"
python3 tools/mcgt_sweeper.py
python3 tools/mcgt_blockers_extract.py
python3 tools/peek_artifacts.py
