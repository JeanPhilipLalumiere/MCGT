#!/usr/bin/env python3
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
ppy = root / "pyproject.toml"
backup = root / "pyproject.toml.before_series9.bak"


def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def write_text(p: Path, s: str):
    p.write_text(s, encoding="utf-8")


content = read_text(ppy)
original = content


def ensure_block(s: str, header: str, body_lines: list[str]) -> str:
    if re.search(rf"^\s*\[{re.escape(header)}\]\s*$", s, flags=re.M):
        return s
    addition = "\n\n[" + header + "]\n" + "\n".join(body_lines) + "\n"
    return s + addition


if not content:
    content = """# pyproject généré par Série 9 (idempotent)
[build-system]
requires = ["hatchling>=1.23"]
build-backend = "hatchling.build"

[project]
name = "mcgt"
version = "0.0.0"
description = "MCGT: outils et données (builds, figures, CI)."
readme = "README.md"
requires-python = ">=3.10"
authors = [{name="MCGT maintainers"}]
license = {text = "MIT"}
dependencies = []

[project.urls]
Homepage = "https://github.com/JeanPhilipLalumiere/MCGT"
Repository = "https://github.com/JeanPhilipLalumiere/MCGT"
"""
else:
    # S'assurer d'un build-system présent
    if not re.search(r"^\s*\[build-system\]\s*$", content, flags=re.M):
        content += """
[build-system]
requires = ["hatchling>=1.23"]
build-backend = "hatchling.build"
"""
    # S'assurer que [project] existe
    if not re.search(r"^\s*\[project\]\s*$", content, flags=re.M):
        content += """
[project]
name = "mcgt"
version = "0.0.0"
description = "MCGT package"
readme = "README.md"
requires-python = ">=3.10"
authors = [{name="MCGT maintainers"}]
license = {text = "MIT"}
dependencies = []
"""
    # Ajouter quelques URLs si absentes (non intrusif)
    content = ensure_block(
        content,
        "project.urls",
        [
            'Homepage = "https://github.com/JeanPhilipLalumiere/MCGT"',
            'Repository = "https://github.com/JeanPhilipLalumiere/MCGT"',
        ],
    )

# S’assurer d’un layout acceptable (src/ ou paquet plat) via hatchling include
if "[tool.hatch.build]" not in content:
    content += """
[tool.hatch.build]
include = [
  "/**/*.py",
  "/zz-data/**/*",
  "/zz-figures/**/*",
  "/README.md",
  "/LICENSE*",
]
exclude = [
  "/.ci-logs/**/*",
  "/.ci-out/**/*",
  "/_tmp-figs/**/*",
  "/zz-out/**/*",
  "/.github/**/*",
]
"""

# Éviter d’écraser silencieusement
if original != content:
    if original:
        backup.write_text(original, encoding="utf-8")
    write_text(ppy, content)
    print("UPDATED: pyproject.toml (backup: pyproject.toml.before_series9.bak)")
else:
    print("OK: pyproject.toml déjà conforme")
