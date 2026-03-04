#!/usr/bin/env python3
"""Minimal PDF text-sanity checker for release artifacts.

This script validates that a release PDF still exposes a searchable text layer
for a few expected phrases. It prefers real text extractors when available and
falls back to `strings` as a coarse sanity check in minimal environments.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


DEFAULT_NEEDLES = [
    "72.97",
    "0.718",
    "Planck compressed prior",
    "95th percentile",
    "phase dephasing",
]


def extract_with_pdftotext(pdf: Path) -> str | None:
    tool = shutil.which("pdftotext")
    if not tool:
        return None
    proc = subprocess.run(
        [tool, str(pdf), "-"],
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout


def extract_with_mutool(pdf: Path) -> str | None:
    tool = shutil.which("mutool")
    if not tool:
        return None
    proc = subprocess.run(
        [tool, "draw", "-F", "text", "-o", "-", str(pdf)],
        check=True,
        capture_output=True,
        text=True,
        errors="ignore",
    )
    return proc.stdout


def extract_with_pypdf(pdf: Path) -> str | None:
    try:
        from pypdf import PdfReader  # type: ignore
    except Exception:
        return None
    reader = PdfReader(str(pdf))
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def extract_with_fitz(pdf: Path) -> str | None:
    try:
        import fitz  # type: ignore
    except Exception:
        return None
    doc = fitz.open(str(pdf))
    return "\n".join(page.get_text() for page in doc)


def extract_with_strings(pdf: Path) -> str | None:
    tool = shutil.which("strings")
    if not tool:
        return None
    proc = subprocess.run(
        [tool, str(pdf)],
        check=True,
        capture_output=True,
        text=True,
        errors="ignore",
    )
    return proc.stdout


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path)
    parser.add_argument(
        "--needle",
        action="append",
        default=[],
        help="Expected phrase that should appear in extracted text.",
    )
    args = parser.parse_args()

    pdf = args.pdf
    if not pdf.exists():
        print(f"[fail] missing PDF: {pdf}")
        return 1

    extractors = [
        ("pdftotext", extract_with_pdftotext),
        ("mutool", extract_with_mutool),
        ("pypdf", extract_with_pypdf),
        ("fitz", extract_with_fitz),
        ("strings", extract_with_strings),
    ]

    text = None
    extractor_name = None
    for name, extractor in extractors:
        try:
            text = extractor(pdf)
        except Exception as exc:
            print(f"[warn] extractor {name} failed: {exc}")
            continue
        if text:
            extractor_name = name
            break

    if not text or not extractor_name:
        print("[fail] no extractor available for PDF text sanity check")
        return 1

    needles = args.needle or DEFAULT_NEEDLES
    print(f"[info] extractor: {extractor_name}")

    missing = [needle for needle in needles if needle not in text]
    if missing:
        print("[fail] missing expected phrases:")
        for needle in missing:
            print(f"  - {needle}")
        return 1

    print("[pass] PDF text sanity check passed")
    for needle in needles:
        print(f"[ok] {needle}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
