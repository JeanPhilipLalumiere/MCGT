#!/usr/bin/env python3
import csv, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT  = ROOT / "zz-manifests/figure_manifest.json"
CSV1 = ROOT / "zz-manifests/figure_manifest.csv"

def discover_figs():
    figs = []
    for p in sorted((ROOT/"zz-figures").rglob("*.png")):
        figs.append({
            "path": str(p.relative_to(ROOT)),
            "chapter": p.parts[-2] if len(p.parts)>=2 else "",
            "name": p.stem,
            "exists": True,
        })
    return figs

def from_csv():
    if not CSV1.exists(): return None
    rows = []
    with CSV1.open("r", encoding="utf-8", newline="") as f:
        rd = csv.DictReader(f)
        if not rd.fieldnames:
            return []
        for r in rd:
            # essaie de détecter une colonne de chemin
            path = r.get("path") or r.get("file") or r.get("figure") or r.get("png") or ""
            if not path:
                # fallback: reconstruit depuis colonnes chapter/name si présentes
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
    data = from_csv()
    if not data:
        data = discover_figs()
    OUT.write_text(json.dumps({"figures": data}, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] wrote {OUT} with {len(data)} entries")

if __name__ == "__main__":
    main()
