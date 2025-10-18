#!/usr/bin/env python3
# tools/figure_manifest_builder.py
from __future__ import annotations
import re, os, json, csv, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIG_DIR = ROOT / "zz-figures"
LEGACY_DIR = FIG_DIR / "_legacy_conflicts"
SCRIPTS = ROOT / "zz-scripts"
MANIFEST_MASTER = ROOT / "zz-manifests" / "manifest_master.json"
FIGURE_MANIFEST = ROOT / "zz-manifests" / "figure_manifest.csv"
CANON_PLAN_JSON = ROOT / "report_canonical_name_plan.json"
LEGACY_PLAN_JSON = ROOT / "report_legacy_to_canon_plan.json"

def md5sum(p: Path) -> str | None:
    if not p.exists() or not p.is_file(): return None
    h = hashlib.md5()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    return h.hexdigest()

def infer_canonical(script_path: Path) -> tuple[str, Path]:
    # .../chapter07/plot_fig02_delta_phi_heatmap.py -> "07_fig_02_delta_phi_heatmap.png"
    chap = script_path.parent.name  # chapter07
    mchap = re.match(r"chapter([0-9]{2})", chap)
    mfig  = re.match(r"plot_(fig[0-9]{2})_(.+)\.py$", script_path.name)
    if not (mchap and mfig):
        raise ValueError(f"Unrecognized pattern: {script_path}")
    nn = mchap.group(1)
    fig_tok = mfig.group(1).replace("fig", "fig_")
    slug = mfig.group(2)
    canon = f"{nn}_{fig_tok}_{slug}.png"
    out = FIG_DIR / f"chapter{nn}" / canon
    return canon, out

def load_json(p: Path) -> dict | None:
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None

def ensure_dirs():
    (ROOT / "zz-manifests").mkdir(exist_ok=True)
    for d in sorted({p.parent for p in FIG_DIR.glob("chapter??")}):
        d.mkdir(parents=True, exist_ok=True)

def build_rows():
    rows = []
    # from scripts
    for sp in sorted(SCRIPTS.glob("chapter??/plot_fig*.py")):
        try:
            canon, target = infer_canonical(sp)
        except Exception:
            continue
        rows.append({
            "chapter": sp.parent.name,                 # chapter07
            "script": str(sp.relative_to(ROOT)),
            "canonical": canon,
            "path": str(target.relative_to(ROOT)),
            "exists": target.exists(),
            "md5": md5sum(target),
            "source": "script",
        })
    # from legacy (proposées)
    for lp in sorted(LEGACY_DIR.glob("chapter??/*.*")):
        d = lp.parent.name
        mchap = re.match(r"chapter([0-9]{2})", d)
        m = re.match(r"fig_([0-9]{2})_(.+)\.(png|svg|pdf)$", lp.name, re.I)
        if not (mchap and m): continue
        nn, ff, slug, ext = mchap.group(1), m.group(1), m.group(2), m.group(3).lower()
        canon = f"{nn}_fig_{ff}_{slug}.{ext}"
        target = FIG_DIR / f"chapter{nn}" / canon
        rows.append({
            "chapter": f"chapter{nn}",
            "script": "",
            "canonical": canon,
            "path": str(target.relative_to(ROOT)),
            "exists": target.exists(),
            "md5": md5sum(target),
            "legacy_from": str(lp.relative_to(ROOT)),
            "source": "legacy",
        })
    return rows

def write_csv(rows):
    FIGURE_MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    cols = ["chapter","script","canonical","path","exists","md5","legacy_from","source"]
    with FIGURE_MANIFEST.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in cols})

def update_manifest_master(rows):
    # structure minimale: {"chapters":[{"id":"chapter07","outputs":[{"path":"zz-figures/chapter07/07_fig_..png"}]}]}
    mm = load_json(MANIFEST_MASTER) or {}
    chapters = {c.get("id"): c for c in mm.get("chapters", []) if isinstance(c, dict)}
    for r in rows:
        chap = r["chapter"]
        if chap not in chapters:
            chapters[chap] = {"id": chap, "outputs": []}
        # ajoute uniquement si le fichier existe physiquement
        if r.get("exists"):
            outputs = chapters[chap].setdefault("outputs", [])
            if not any(o.get("path") == r["path"] for o in outputs):
                outputs.append({"path": r["path"], "type": "figure"})
    mm["chapters"] = list(chapters.values())
    MANIFEST_MASTER.write_text(json.dumps(mm, ensure_ascii=False, indent=2), encoding="utf-8")

def main():
    ensure_dirs()
    rows = build_rows()
    write_csv(rows)
    # mise à jour non destructive du manifest master
    update_manifest_master([r for r in rows if r.get("exists")])
    print(json.dumps({
        "figure_manifest": str(FIGURE_MANIFEST.relative_to(ROOT)),
        "manifest_master_updated": str(MANIFEST_MASTER.relative_to(ROOT)),
        "rows": len(rows),
        "existing": sum(r.get("exists") for r in rows),
    }, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
