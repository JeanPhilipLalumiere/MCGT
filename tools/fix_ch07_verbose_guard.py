#!/usr/bin/env python3
from pathlib import Path

P = Path("zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py")
needle = "if args.verbose >= 2:"

def indent(s): return len(s.expandtabs(4)) - len(s.lstrip(" "))

def main():
    lines = P.read_text(encoding="utf-8", errors="ignore").splitlines(True)
    for i, s in enumerate(lines):
        if s.lstrip().startswith(needle):
            # recale au même niveau que la ligne non vide précédente
            j = i - 1
            while j >= 0 and lines[j].strip() == "":
                j -= 1
            base = 0 if j < 0 else indent(lines[j])
            fixed = (" " * base) + s.lstrip()
            if fixed != s:
                lines[i] = fixed
                P.write_text("".join(lines), encoding="utf-8")
                print(f"[FIX] {P}:{i+1} -> indent {base}")
            else:
                print(f"[OK] already aligned at {P}:{i+1}")
            break

if __name__ == "__main__":
    main()
