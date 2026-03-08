#!/usr/bin/env bash
set -u

DEST_DIR="paper/figures"
mkdir -p "$DEST_DIR"

# Preferred source roots requested in the instructions.
SOURCE_ROOTS=(
  "plots/4_publication_ready"
  "output"
)

FILES=(
  "consistency_triple_bananas.png"
  "corner_triple_nobel.png"
  "matter_power_spectrum.png"
  "profile_likelihood_h0.png"
)

copied=0
missing=0

for f in "${FILES[@]}"; do
  found=""
  for root in "${SOURCE_ROOTS[@]}"; do
    if [ -f "$root/$f" ]; then
      found="$root/$f"
      break
    fi
  done

  if [ -z "$found" ]; then
    # Fallback recursive search inside requested roots.
    for root in "${SOURCE_ROOTS[@]}"; do
      if [ -d "$root" ]; then
        candidate="$(find "$root" -type f -name "$f" 2>/dev/null | head -n 1)"
        if [ -n "$candidate" ]; then
          found="$candidate"
          break
        fi
      fi
    done
  fi

  if [ -n "$found" ]; then
    cp "$found" "$DEST_DIR/$f"
    echo "Copied: $found -> $DEST_DIR/$f"
    copied=$((copied + 1))
  else
    echo "Warning: missing figure '$f' in plots/4_publication_ready or output"
    missing=$((missing + 1))
  fi
done

echo "Done. Copied=$copied Missing=$missing Destination=$DEST_DIR"
