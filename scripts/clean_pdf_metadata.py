#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_PDF = ROOT / "manuscript" / "Thesis_MCGT_Lalumiere_v4.0.0_GOLD.pdf"
DEFAULT_OUTPUT_PDF = ROOT / "manuscript" / "Thesis_MCGT_Lalumiere_v4.0.0_GOLD.pdf"
DEFAULT_TITLE = "Ψ-Time Metric Gravity v4.0.0 GOLD"
DEFAULT_AUTHOR = "Jean-Philip Lalumière"


def utf16be_hex(value: str) -> str:
    return "FEFF" + value.encode("utf-16-be").hex().upper()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Rewrite PDF metadata with clean title/author fields.")
    parser.add_argument("--pdf", type=Path, default=DEFAULT_SOURCE_PDF, help="Source PDF file.")
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PDF,
        help="Output PDF file with cleaned metadata.",
    )
    parser.add_argument("--title", type=str, default=DEFAULT_TITLE, help="Final PDF title.")
    parser.add_argument("--author", type=str, default=DEFAULT_AUTHOR, help="Final PDF author.")
    return parser


def run_ghostscript(pdf: Path, output: Path, title: str, author: str) -> None:
    gs = shutil.which("gs")
    if gs is None:
        raise SystemExit("Ghostscript (gs) is required but not available.")
    if not pdf.exists():
        raise SystemExit(f"Missing PDF: {pdf}")

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        out_pdf = tmpdir_path / output.name
        pdfmark = tmpdir_path / "metadata.pdfmark"
        pdfmark.write_text(
            (
                "[\n"
                f"/Title <{utf16be_hex(title)}>\n"
                f"/Author <{utf16be_hex(author)}>\n"
                f"/Subject <{utf16be_hex(title)}>\n"
                f"/Creator <{utf16be_hex('MCGT v4.0.0 GOLD')}>\n"
                f"/Keywords <{utf16be_hex('PsiTMG, MCGT, cosmology, modified gravity')}>\n"
                "/DOCINFO pdfmark\n"
            ),
            encoding="ascii",
        )
        cmd = [
            gs,
            "-q",
            "-dBATCH",
            "-dNOPAUSE",
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.7",
            f"-sOutputFile={out_pdf}",
            str(pdf),
            str(pdfmark),
        ]
        subprocess.run(cmd, check=True)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(out_pdf.read_bytes())


def main() -> None:
    args = build_parser().parse_args()
    run_ghostscript(args.pdf.resolve(), args.output.resolve(), args.title, args.author)
    print(f"[ok] source PDF: {args.pdf}")
    print(f"[ok] cleaned PDF metadata: {args.output}")
    print(f"[ok] title: {args.title}")
    print(f"[ok] author: {args.author}")


if __name__ == "__main__":
    main()
