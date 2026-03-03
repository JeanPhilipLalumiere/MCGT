from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TARGET_DIRS = (ROOT / "scripts", ROOT / "mcgt", ROOT / "tools")
TARGET_FILES = (ROOT / "README.md", ROOT / "REPRODUCIBILITY.md")
TARGET_DOCS = tuple(ROOT.glob("docs/CH*_PIPELINE*.md"))
TARGET_SUFFIXES = {".py", ".sh", ".bat", ".md"}
USER_PATH_PATTERN = re.compile(r"/home/|/Users/|[A-Za-z]:\\\\Users\\\\")


def iter_target_files():
    for base in TARGET_DIRS:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if path.is_file() and path.suffix in TARGET_SUFFIXES:
                yield path
    for path in TARGET_FILES + TARGET_DOCS:
        if path.exists() and path.is_file():
            yield path


def test_no_hardcoded_user_paths_in_operational_files():
    violations: list[str] = []

    for path in iter_target_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        if USER_PATH_PATTERN.search(text):
            violations.append(str(path.relative_to(ROOT)))

    assert not violations, "Hard-coded user paths detected:\n" + "\n".join(sorted(set(violations)))
