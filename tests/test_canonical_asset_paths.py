from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TARGET_DIRS = (ROOT / "scripts", ROOT / "src" / "mcgt")
TARGET_SUFFIXES = {".py", ".sh", ".bat"}
FORBIDDEN_PATTERNS = {
    "legacy data path": re.compile(r"assets/zz-data/chapter\d{2}"),
    "legacy figure path": re.compile(r"assets/zz-figures/chapter\d{2}"),
    "legacy script chapter alias": re.compile(r"scripts[/\\\\]chapter\d{2}"),
}


def iter_target_files():
    for base in TARGET_DIRS:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path.suffix in TARGET_SUFFIXES and path.is_file():
                yield path


def test_no_legacy_chapter_aliases_in_runtime_paths():
    violations: list[str] = []

    for path in iter_target_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        for label, pattern in FORBIDDEN_PATTERNS.items():
            if pattern.search(text):
                violations.append(f"{path.relative_to(ROOT)}: {label}")

    assert not violations, "Legacy chapter aliases detected:\n" + "\n".join(
        sorted(violations)
    )
