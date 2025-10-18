#!/usr/bin/env python3
import argparse, subprocess, sys, shlex
from pathlib import Path

EXTRAS = {
    "plot_fig07_synthesis.py": ["--manifest-a", "zz-manifests/figure_manifest.json"],
}
NO_STD_ARGS = {"plot_fig07_synthesis.py"}  # ces scripts ne prennent pas --fmt/--outdir

def iter_plot_scripts():
    yield from Path("zz-scripts").glob("chapter*/plot_*.py")

def main():
    ap = argparse.ArgumentParser(description="Smoketest non destructif des scripts de tracé.")
    ap.add_argument("--per-chapter", type=int, default=1)
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--dpi", type=int, default=120)
    ap.add_argument("--outbase", type=str, default="zz-figures/_smoke")
    ap.add_argument("--continue-on-error", action="store_true")
    args = ap.parse_args()

    outbase = Path(args.outbase)
    picks = {}
    for p in iter_plot_scripts():
        ch = p.parts[1]
        picks.setdefault(ch, [])
        if len(picks[ch]) < args.per_chapter:
            picks[ch].append(p)

    plan = []
    for ch, files in sorted(picks.items()):
        outdir = outbase / ch
        for f in files:
            cmd = ["python3", str(f), "--dpi", str(args.dpi)]
            if f.name not in NO_STD_ARGS:
                cmd += ["--fmt", "png", "--outdir", str(outdir)]
            if f.name in EXTRAS:
                cmd += EXTRAS[f.name]
            plan.append(cmd)

    if not args.run:
        print("[PLAN]")
        for cmd in plan:
            print(" ", " ".join(shlex.quote(x) for x in cmd))
        print(f"[SUMMARY] chapters={len(picks)} scripts={len(plan)}")
        return

    ok = 0; ko = 0; fails = []
    for cmd in plan:
        print("[RUN]", " ".join(shlex.quote(x) for x in cmd))
        try:
            if "--outdir" in cmd:
                Path(cmd[cmd.index("--outdir")+1]).mkdir(parents=True, exist_ok=True)
        except Exception:
            pass
        try:
            subprocess.run(cmd, check=True)
            ok += 1
        except subprocess.CalledProcessError as e:
            print("[ERR]", e, file=sys.stderr)
            ko += 1
            fails.append(" ".join(shlex.quote(x) for x in cmd))
            if not args.continue_on_error:
                break

    print(f"[RESULT] ok={ok} ko={ko}")
    if fails:
        print("[FAILED COMMANDS]")
        for c in fails:
            print("  ", c)

if __name__ == "__main__":
    main()
