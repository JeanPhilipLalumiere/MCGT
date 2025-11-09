from _common import cli as C
# fichier : zz-scripts/chapter03/utils/convert_milestones.py
# répertoire : zz-scripts/chapter03/utils
# zz-scripts/chapter03/utils/convert_jalons.py
import argparse
from pathlib import Path

import pandas as pd
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging


def main():
    p = argparse.ArgumentParser(
        description="(autofix)",
    )
    p.add_argument(
        "--src", required=True, help="Path to 03_ricci_fR_milestones_enriched.csv"
    )
    p.add_argument(
        "--dst",         default="zz-data/chapter03/03_ricci_fR_milestones.csv",
        help="Output path for the raw CSV",
    )
# [autofix] disabled top-level parse: args = p.parse_args()
    src_path = Path(args.src)
    if not src_path.exists():
        print(f"Error: source file not found: {src_path}")
        return

    df = pd.read_csv(src_path)
    df[["R_over_R0", "f_R", "f_RR"]].to_csv(args.dst, index=False)
    print(f"Raw file generated: {args.dst}")


if __name__ == "__main__":
    main()
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p
