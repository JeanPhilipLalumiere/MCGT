#!/usr/bin/env python3
import argparse, json
from pathlib import Path

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", default="zz-manifests/figure_manifest.json")
    ap.add_argument("--root", default="zz-figures")
    args = ap.parse_args()

    root = Path(args.root)
    man = Path(args.manifest)
    if not man.exists():
        print(f"[WARN] manifest absent: {man}")
        # fallback: simple scan
        pngs = list(root.rglob("*.png"))
        print(f"[SCAN] {len(pngs)} PNG trouvés sous {root}")
        print("[OK]" if pngs else "[KO] aucune figure")
        return

    data = json.loads(man.read_text(encoding="utf-8"))
    # Structure libre: on vérifie présence des PNG référencés si possible
    missing = 0; total = 0
    def _check(p):
        nonlocal total, missing
        total += 1
        f = Path(p)
        if not f.exists() or f.stat().st_size == 0:
            print("[MISS]", f)
            missing += 1

    # cas typiques
    if isinstance(data, dict):
        for k, v in data.items():
            if isinstance(v, str) and v.endswith((".png",".pdf",".svg")):
                _check(v)
            elif isinstance(v, list):
                for x in v:
                    if isinstance(x, str) and x.endswith((".png",".pdf",".svg")):
                        _check(x)
    elif isinstance(data, list):
        for v in data:
            if isinstance(v, str) and v.endswith((".png",".pdf",".svg")):
                _check(v)

    print(f"[SUMMARY] referenced={total} missing={missing}")
    print("[OK]" if missing == 0 else "[KO] des figures manquent")

if __name__ == "__main__":
    main()
