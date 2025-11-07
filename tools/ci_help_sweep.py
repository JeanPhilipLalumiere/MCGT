import os, subprocess, sys
from pathlib import Path

ROOT = Path(".")
def is_cli_candidate(p: Path) -> bool:
    rp = str(p).replace("\\","/")
    if not rp.startswith("zz-scripts/"): return False
    if "/_common/" in rp or "/utils/" in rp or "/tests/" in rp: return False
    if p.name == "__init__.py": return False
    try:
        txt = p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return False
    return ("argparse" in txt) or ("add_argument(" in txt) or ("parse_args(" in txt)

cands = sorted([p for p in ROOT.rglob("zz-scripts/**/*.py")
                if p.is_file() and is_cli_candidate(p)],
               key=lambda x: str(x))

env = os.environ.copy()
env.setdefault("MPLBACKEND", "Agg")
env.setdefault("PYTHONWARNINGS", "ignore")

bad = []
for p in cands:
    try:
        cp = subprocess.run([sys.executable, str(p), "--help"],
                            env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            timeout=20)
        if cp.returncode != 0:
            head = (cp.stderr or cp.stdout).strip().splitlines()[:6]
            bad.append((str(p), cp.returncode, head))
    except subprocess.TimeoutExpired:
        bad.append((str(p), "TIMEOUT", ["(timeout 20s)"]))
    except Exception as e:
        bad.append((str(p), "EXC", [repr(e)]))

if bad:
    print(f"[cli-help-sweep] FAIL: {len(bad)} script(s) KO sur {len(cands)}")
    for path, rc, head in bad:
        print(f" - {path} :: RC={rc}")
        for line in head:
            print("   ", line)
    sys.exit(1)
else:
    print(f"[cli-help-sweep] OK: {len(cands)}/{len(cands)} scripts")
    sys.exit(0)
