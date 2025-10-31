import csv, sys, hashlib
from pathlib import Path

manifest = Path("zz-manifests/figure_manifest.csv")
if not manifest.exists():
    print(f"[ERR] Manifeste absent: {manifest}", file=sys.stderr)
    sys.exit(2)

def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

errs = 0
with manifest.open("r", encoding="utf-8", newline="") as fo:
    rd = csv.DictReader(fo)
    for row in rd:
        fig = Path(row["path"])
        exp_sha = (row.get("sha256") or "").strip().lower()
        exp_exists = row.get("exists","").strip()
        if exp_exists not in {"0","1"}:
            print(f"[ERR] exists invalide pour {fig}: {exp_exists}")
            errs += 1
            continue
        if exp_exists == "0":
            if fig.exists():
                print(f"[ERR] attendu absent mais présent: {fig}")
                errs += 1
            else:
                print(f"[OK] absent (conforme manifeste): {fig}")
            continue
        # exists == "1"
        if not fig.exists():
            print(f"[ERR] figure manquante: {fig}")
            errs += 1
            continue
        got_sha = sha256(fig)
        if exp_sha and got_sha != exp_sha:
            print(f"[ERR] SHA256 diff: {fig}\n  exp={exp_sha}\n  got={got_sha}")
            errs += 1
        else:
            size = fig.stat().st_size
            print(f"[OK] {fig}  bytes={size}  sha256={got_sha[:12]}…")

if errs:
    print(f"[FAIL] {errs} écart(s) détecté(s).", file=sys.stderr)
    sys.exit(1)
print("[PASS] Manifeste figures conforme.")
