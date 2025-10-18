#!/usr/bin/env python3
import json, re, argparse
from pathlib import Path

REPORT = Path("zz-manifests/indent_failures.json")
TARGETS = {
    "zz-scripts/chapter01/plot_fig05_I1_vs_T.py",
    "zz-scripts/chapter04/plot_fig04_relative_deviations.py",
    "zz-scripts/chapter05/plot_fig04_chi2_vs_T.py",
    "zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py",
    "zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py",
    "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py",
}

def indent_of(s: str) -> int:
    s = s.expandtabs(4)
    return len(s) - len(s.lstrip(" "))

def set_indent(s: str, n: int) -> str:
    return (" " * n) + s.lstrip(" \t")

def prev_nonempty(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def find_prev_colon_line(lines, i):
    j = i - 1
    while j >= 0:
        t = lines[j].strip()
        if t.endswith(":") and not t.startswith("#"):
            return j
        j -= 1
    return None

def opens_block(s: str) -> bool:
    s = s.strip()
    return s.endswith(":") and not s.startswith("#")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    data = json.loads(REPORT.read_text(encoding="utf-8"))
    changed = 0
    for r in data:
        path = r["path"]
        if path not in TARGETS:
            continue
        p = Path(path)
        lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
        i = r["lineno"] - 1
        if not (0 <= i < len(lines)):
            continue
        # normaliser tabs->spaces pour la ligne fautive
        lines[i] = lines[i].expandtabs(4)

        j = prev_nonempty(lines, i)
        desired = 0
        if j is None:
            desired = 0
        else:
            prev = lines[j]
            if prev.strip() == "pass":
                k = find_prev_colon_line(lines, j)
                desired = 0 if k is None else indent_of(lines[k])
            elif opens_block(prev):
                desired = indent_of(prev) + 4
            else:
                desired = indent_of(prev)

        # borne à multiples de 4
        desired = max(0, desired - (desired % 4) + (0 if desired % 4 == 0 else 0))

        before = lines[i]
        after = set_indent(before, desired)
        if before != after:
            if args.apply:
                # sauvegarde une fois par fichier
                bak = p.with_suffix(p.suffix + ".bak_smartindent")
                if not bak.exists():
                    bak.write_text("".join(lines), encoding="utf-8")
                lines[i] = after
                p.write_text("".join(lines), encoding="utf-8")
            changed += 1
            print(f"[FIX] {p}:{i+1} -> indent {desired}")
    print(f"[SUMMARY] changed={changed} apply={args.apply}")

if __name__ == "__main__":
    main()
