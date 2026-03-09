#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$SCRIPT_DIR"

# Default image for containerized revtex4-2 builds.
DEFAULT_IMAGE="texlive/texlive:latest"
IMAGE="${LATEX_IMAGE:-$DEFAULT_IMAGE}"
LOCAL_IMAGE_TAG="psitmg-latex:local"

usage() {
  cat <<'USAGE'
Usage: ./compile.sh [--engine docker|podman] [--local-image] [--no-pull] [--local-only]

Options:
  --engine <name>  Force container engine (docker or podman).
  --local-image    Build and use local image from Dockerfile.latex (psitmg-latex:local).
  --no-pull        Do not pull remote image when missing locally.
  --local-only     Skip container flow and compile with local TeX tools.
  -h, --help       Show this help.

Environment variables:
  LATEX_IMAGE      Override remote image (default: texlive/texlive:latest).
USAGE
}

ENGINE=""
USE_LOCAL_IMAGE=0
ALLOW_PULL=1
FORCE_LOCAL_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      ENGINE="${2:-}"
      shift 2
      ;;
    --local-image)
      USE_LOCAL_IMAGE=1
      shift
      ;;
    --no-pull)
      ALLOW_PULL=0
      shift
      ;;
    --local-only)
      FORCE_LOCAL_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Error: missing required file $path" >&2
    exit 1
  fi
}

if [[ ! -d figures ]]; then
  echo "Error: missing figures directory at $SCRIPT_DIR/figures" >&2
  exit 1
fi
require_file "figures/01_fig_corner.pdf"
require_file "figures/02_fig_likelihood.pdf"
require_file "figures/03_fig_tensions_summary.pdf"
require_file "main.tex"
require_file "references.bib"

clean_aux() {
  find "$SCRIPT_DIR" -maxdepth 1 -type f \
    \( -name "*.log" -o -name "*.aux" -o -name "*.out" -o -name "*.bbl" -o -name "*.blg" \
       -o -name "*.fls" -o -name "*.fdb_latexmk" -o -name "*.synctex.gz" -o -name "*.toc" \
       -o -name "mainNotes.bib" \) \
    -delete
}

ensure_pdf_writable() {
  local pdf_path="$SCRIPT_DIR/main.pdf"
  if [[ -e "$pdf_path" && ! -w "$pdf_path" ]]; then
    echo "Error: $pdf_path exists but is not writable by $(id -un)." >&2
    echo "Fix ownership/permissions or remove the file before recompiling." >&2
    return 1
  fi
}

detect_engine() {
  if [[ -n "$ENGINE" ]]; then
    echo "$ENGINE"
    return 0
  fi
  if command -v docker >/dev/null 2>&1; then
    echo "docker"
    return 0
  fi
  if command -v podman >/dev/null 2>&1; then
    echo "podman"
    return 0
  fi
  return 1
}

engine_usable() {
  local eng="$1"
  if ! command -v "$eng" >/dev/null 2>&1; then
    return 1
  fi
  "$eng" info >/dev/null 2>&1
}

compile_with_local_tools() {
  echo "[local] Trying local TeX toolchain..."

  ensure_pdf_writable || return 1

  if command -v latexmk >/dev/null 2>&1 && command -v pdflatex >/dev/null 2>&1 && command -v bibtex >/dev/null 2>&1; then
    echo "[local] Using latexmk + pdflatex/bibtex"
    latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
    clean_aux
    return 0
  fi

  if command -v pdflatex >/dev/null 2>&1 && command -v bibtex >/dev/null 2>&1; then
    echo "[local] Using pdflatex + bibtex"
    pdflatex -interaction=nonstopmode -halt-on-error main.tex
    bibtex main
    pdflatex -interaction=nonstopmode -halt-on-error main.tex
    pdflatex -interaction=nonstopmode -halt-on-error main.tex
    clean_aux
    return 0
  fi

  if command -v tectonic >/dev/null 2>&1; then
    echo "[local] Using tectonic"
    tectonic --keep-logs main.tex
    tectonic --keep-logs main.tex
    clean_aux
    return 0
  fi

  return 1
}

compile_in_container() {
  local eng="$1"
  local image_ref="$IMAGE"

  ensure_pdf_writable || return 1

  if [[ "$USE_LOCAL_IMAGE" -eq 1 ]]; then
    echo "[1/4] Building local LaTeX image via $eng..."
    if ! "$eng" build -f Dockerfile.latex -t "$LOCAL_IMAGE_TAG" .; then
      echo "Error: failed to build local LaTeX image $LOCAL_IMAGE_TAG." >&2
      return 1
    fi
    image_ref="$LOCAL_IMAGE_TAG"
  else
    if ! "$eng" image inspect "$image_ref" >/dev/null 2>&1; then
      if [[ "$ALLOW_PULL" -eq 1 ]]; then
        echo "[1/4] Pulling pinned image $image_ref via $eng..."
        if ! "$eng" pull "$image_ref"; then
          echo "Error: failed to pull LaTeX image $image_ref." >&2
          return 1
        fi
      else
        echo "Error: image not found locally and --no-pull was set: $image_ref" >&2
        return 1
      fi
    else
      echo "[1/4] Using existing local image $image_ref"
    fi
  fi

  echo "[2/4] Compiling manuscript inside container ($eng)..."
  if ! "$eng" run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$SCRIPT_DIR":/work \
    -w /work \
    "$image_ref" \
    bash -lc "latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex || (pdflatex -interaction=nonstopmode -halt-on-error main.tex && bibtex main && pdflatex -interaction=nonstopmode -halt-on-error main.tex && pdflatex -interaction=nonstopmode -halt-on-error main.tex)"; then
    echo "Error: containerized LaTeX compilation failed." >&2
    return 1
  fi

  echo "[3/4] Cleaning LaTeX auxiliary files..."
  clean_aux

  echo "[4/4] Done. PDF available at $SCRIPT_DIR/main.pdf"
  return 0
}

if [[ "$FORCE_LOCAL_ONLY" -eq 1 ]]; then
  if compile_with_local_tools; then
    echo "Compilation complete: $SCRIPT_DIR/main.pdf"
    exit 0
  fi
  echo "Error: local TeX toolchain not available." >&2
  exit 1
fi

ENG=""
if ENG=$(detect_engine); then
  if engine_usable "$ENG"; then
    if compile_in_container "$ENG"; then
      echo "Compilation complete: $SCRIPT_DIR/main.pdf"
      exit 0
    fi
  else
    echo "Warning: container engine '$ENG' found but not usable (daemon/permissions)." >&2
  fi
fi

echo "Warning: falling back to local TeX toolchain." >&2
if compile_with_local_tools; then
  echo "Compilation complete: $SCRIPT_DIR/main.pdf"
  exit 0
fi

echo "Error: no usable container engine and no local TeX toolchain available." >&2
echo "Tips:" >&2
echo "  1) Ensure Docker/Podman daemon is running and accessible." >&2
echo "  2) Retry with: ./compile.sh --engine podman" >&2
echo "  3) Or install latexmk/pdflatex+bibtex (or tectonic) and use --local-only." >&2
exit 1
