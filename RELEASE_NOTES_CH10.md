# Chapter 10 Release Notes

## Highlights
- Visualisation: dynamic data spread and outlier-aware scaling for parameter maps (Fig 01, Fig 06).
- Aesthetics: consistent serif styling, removal of redundant insets, and optimized legend placement.
- Language: English-only titles, labels, and tables (standard MCGT).
- Structure: unified `10_fig_XX` naming and removal of legacy duplicates.

## Technical Integrity Fix
- Manifest metadata synchronized to eliminate drift and guard failures.
- Naming and quality guards cleaned (invalid backup filenames removed; scripts standardized with python3 shebangs and executable permissions).

## Figure Updates
- Fig 01: cleaned legend usage with colorbar-only explanation.
- Fig 03: removed zoom inset and consolidated a single stats legend (lower left).
- Fig 06/07: increased jitter for fuller occupancy; adjusted histogram stats placement and Y-scale.
