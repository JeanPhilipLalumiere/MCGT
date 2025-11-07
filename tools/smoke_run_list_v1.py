#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys, os, time
from pathlib import Path

SCRIPTS = [
    "zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py",
    "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py",
    "zz-scripts/chapter04/plot_fig02_invariants_histogram.py",
    "zz-scripts/chapter03/plot_fig01_fR_stability_domain.py",
]
OUTDIR = Path(".ci-out/smoke_v1"); OUTDIR.mkdir(parents=True, exist_ok=True)
PYEXE = sys.executable
TIMEOUT = 90

def run_one(p: str):
    cmd = [PYEXE, p, "--outdir", str(OUTDIR), "--format", "png", "--dpi", "120", "--style", "classic"]
    env = os.environ.copy()
    env.setdefault("MCGT_NO_SHOW", "1")
    # Clé : rendre _common importable sans toucher tes imports
    env["PYTHONPATH"] = os.pathsep.join([
        str(Path.cwd() / "zz-scripts"),
        env.get("PYTHONPATH","")
    ])
    t0 = time.time()
    try:
        cp = subprocess.run(cmd, env=env, check=True, timeout=TIMEOUT,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        status = "OK"; out = cp.stdout
    except subprocess.TimeoutExpired as e:
        status = "TIMEOUT"; out = (e.stdout or "") + "\n[TIMEOUT]"
    except subprocess.CalledProcessError as e:
        status = f"FAIL({e.returncode})"; out = e.stdout or ""
    dt = time.time() - t0
    print(f"[{status:7s}] {p}  ({dt:4.1f}s)")
    if out:
        # On imprime un extrait utile (premières 80 lignes du log)
        lines = out.splitlines()
        head = "\n".join(lines[:80])
        print(head)
        if len(lines) > 80:
            print("… [log tronqué]")
    print("-"*80)

def main():
    for s in SCRIPTS:
        if Path(s).exists():
            run_one(s)
        else:
            print(f"[SKIP  ] {s} (absent)")
            print("-"*80)

if __name__ == "__main__":
    main()
