#!/usr/bin/env python3
import sys, json, re, subprocess, shlex
from pathlib import Path

PAT = re.compile(r"\[\s*\d+/\d+\]\s*N=\s*(\d+)\s+coverage=([0-9.]+)\s+width_mean=([0-9.]+)")

def derive_manifest_path(argv):
    # cherche l'argument --out <png>
    out_png = None
    for i,a in enumerate(argv):
        if a == "--out" and i+1 < len(argv):
            out_png = argv[i+1]; break
        if a.startswith("--out="):
            out_png = a.split("=",1)[1]; break
    if not out_png:
        raise SystemExit("[ERR] Impossible de déterminer --out <png> (requis).")
    p = Path(out_png)
    return p.with_suffix(".manifest.json")

def main():
    if len(sys.argv) < 2:
        print("Usage: fig03b_manifest_harvester.py <script.py> [args for script...]")
        sys.exit(2)

    script = sys.argv[1]
    args   = sys.argv[2:]
    man_path = derive_manifest_path(args)

    print(f"[RUN] python {script} {' '.join(shlex.quote(a) for a in args)}")
    proc = subprocess.run(
        ["python3", script, *args],
        capture_output=True, text=True
    )
    # affiche la sortie du script pour transparence
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)

    if proc.returncode != 0:
        print(f"[ERR] Script a retourné {proc.returncode}; je n'écris pas le manifest.")
        sys.exit(proc.returncode)

    N_list, coverage, width = [], [], []
    for line in proc.stdout.splitlines():
        m = PAT.search(line)
        if not m: 
            continue
        n, cov, w = m.groups()
        N_list.append(int(n))
        coverage.append(float(cov))
        width.append(float(w))

    if not N_list:
        print("[WARN] Aucune ligne '[k/..] N= ... coverage= ... width_mean= ...' détectée.")
        print(f"[INFO] Manifest original laissé intact: {man_path}")
        sys.exit(0)

    # charge l'existant, merge, écrit
    d = {}
    if man_path.exists():
        try:
            d = json.loads(man_path.read_text(encoding="utf-8"))
        except Exception:
            d = {}
    d.update({
        "N_list": N_list,
        "coverage": coverage,
        "width_mean": width
    })
    man_path.write_text(json.dumps(d, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] Manifest mis à jour: {man_path}")

if __name__ == "__main__":
    main()
