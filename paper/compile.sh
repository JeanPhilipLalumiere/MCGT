#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
IMAGE_TAG="psitmg-latex:local"

cd "$SCRIPT_DIR"

if [[ ! -d figures ]]; then
  echo "Error: missing figures directory at $SCRIPT_DIR/figures" >&2
  exit 1
fi

if [[ ! -f figures/corner_triple_nobel.png ]]; then
  echo "Error: missing required image figures/corner_triple_nobel.png" >&2
  exit 1
fi

if [[ ! -f figures/profile_likelihood_h0.png ]]; then
  echo "Error: missing required image figures/profile_likelihood_h0.png" >&2
  exit 1
fi

echo "[1/4] Building LaTeX Docker image..."
docker build -f Dockerfile.latex -t "$IMAGE_TAG" .

echo "[2/4] Compiling manuscript inside container..."
docker run --rm \
  -v "$SCRIPT_DIR":/work \
  "$IMAGE_TAG" \
  bash -c "cd /work && pdflatex main.tex && bibtex main && pdflatex main.tex && pdflatex main.tex"

echo "[3/4] Cleaning LaTeX auxiliary files..."
find "$SCRIPT_DIR" -maxdepth 1 -type f \
  \( -name "*.log" -o -name "*.aux" -o -name "*.out" -o -name "*.bbl" -o -name "*.blg" \
     -o -name "*.fls" -o -name "*.fdb_latexmk" -o -name "*.synctex.gz" -o -name "*.toc" \
     -o -name "mainNotes.bib" \) \
  -delete

echo "[4/4] Done. PDF available at $SCRIPT_DIR/main.pdf."
echo "Compilation complete: $SCRIPT_DIR/main.pdf"
