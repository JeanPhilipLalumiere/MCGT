# tools/triage_plot_fig04_help.sh
#!/usr/bin/env bash
set -Eeuo pipefail
F="zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py"
echo "== TRIAGE: $F =="
python - <<'PY' "$F"
import subprocess, sys, shlex, textwrap, os
f=sys.argv[1]
cmd=["python", f, "--help"]
p=subprocess.run(cmd, capture_output=True, text=True)
print("EXIT:", p.returncode)
print("---- STDERR ----")
print(p.stderr.strip())
print("---- STDOUT ----")
print(p.stdout.strip())
PY
