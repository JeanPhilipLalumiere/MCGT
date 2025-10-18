#!/usr/bin/env python3
import csv, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT  = ROOT / "zz-manifests/figure_manifest.json"
CSV1 = ROOT / "zz-manifests/figure_manifest.csv"

def discover_figs():
    items = []
    for p in sorted((ROOT / "zz-figures").rglob("*.png")):
        items.append({
            "path": str(p.relative_to(ROOT)),
            "chapter": p.parts[-2] if len(p.parts) >= 2 else "",
            "name": p.stem,
            "exists": True,
        })
    return items

def from_csv():
    if not CSV1.exists():
        return None
    rows = []
    with CSV1.open("r", encoding="utf-8", newline="") as f:
        rd = csv.DictReader(f)
        if not rd.fieldnames:
            return []
        for r in rd:
            path = r.get("path") or r.get("file") or r.get("figure") or r.get("png") or ""
            if not path:
                chap = r.get("chapter") or r.get("dir") or ""
                name = r.get("name") or r.get("stem") or ""
                if chap and name:
                    path = f"zz-figures/{chap}/{name}.png"
            if path:
                p = ROOT / path
                rows.append({
                    "path": str(Path(path)),
                    "chapter": r.get("chapter") or "",
                    "name": Path(path).stem,
                    "exists": p.exists(),
                    **{k:v for k,v in r.items() if k not in {"path","file","figure","png","chapter","name"}}
                })
    return rows

def main():
    # --results <fichier CSV> peut être passé en ligne de commande
    # sinon on prend le CSV principal déjà utilisé dans le chapitre 10
    results = None
    if len(sys.argv) >= 3 and sys.argv[1] == "--results":
        results = sys.argv[2]
    if results is None:
        # défaut sensé pour ch10
        cand = ROOT / "zz-data/chapter10/10_mc_results.circ.with_fpeak.csv"
        results = str(cand) if cand.exists() else ""

    items = from_csv() or discover_figs()
    data = {
        "results": results,     # <- clé exigée par fig07
        "figures": items
    }
    OUT.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] wrote {OUT} with {len(items)} figures; results='{results}'")

if __name__ == "__main__":
    main()
