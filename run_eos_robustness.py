#!/usr/bin/env python3
"""Launch dedicated MCMC runs for EoS robustness tests without touching CPL chains."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RUN_MCMC = ROOT / "run_mcmc.py"

N_WALKERS = 40
N_STEPS = 3000
SEED = 42

RUNS = (
    {
        "model": "jbp",
        "output": ROOT / "chains_jbp.h5",
        "chain_name": "jbp_chain",
    },
    {
        "model": "wcdm",
        "output": ROOT / "chains_wcdm.h5",
        "chain_name": "wcdm_chain",
    },
)


def run_one(model: str, output: Path, chain_name: str) -> None:
    cmd = [
        sys.executable,
        str(RUN_MCMC),
        "--model",
        model,
        "--n-walkers",
        str(N_WALKERS),
        "--n-steps",
        str(N_STEPS),
        "--seed",
        str(SEED),
        "--output",
        str(output),
        "--chain-name",
        chain_name,
    ]
    print(f"[run] model={model} output={output} chain_name={chain_name}")
    subprocess.run(cmd, check=True, cwd=ROOT)


def main() -> int:
    if not RUN_MCMC.exists():
        raise FileNotFoundError(f"Missing runner: {RUN_MCMC}")

    for run in RUNS:
        run_one(run["model"], run["output"], run["chain_name"])

    print("[ok] EoS robustness runs completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
