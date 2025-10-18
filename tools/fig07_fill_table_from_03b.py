#!/usr/bin/env python3
import json, csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
P_FIGMAN = ROOT/"zz-manifests/figure_manifest.json"
P_OUT    = ROOT/"zz-figures/chapter10/10_fig_07_synthesis.table.csv"

def find_ch10_fig03b(figman):
    for it in figman.get("figures", []):
        p = it.get("path") or ""
        if "/chapter10/" in p and "fig_03b_bootstrap_coverage_vs_n.png" in p:
            return ROOT/p
    return None

def main():
    d = json.loads(P_FIGMAN.read_text(encoding="utf-8"))
    png = find_ch10_fig03b(d)
    if not png:
        raise SystemExit("[ERR] 03b PNG chapter10 introuvable dans figure_manifest.json")
    man = png.with_suffix(".manifest.json")
    if not man.exists():
        raise SystemExit(f"[ERR] Manifest 03b introuvable: {man}")

    m = json.loads(man.read_text(encoding="utf-8"))
    N   = m.get("N_list")      or []
    cov = m.get("coverage")    or []
    wid = m.get("width_mean")  or []
    M     = m.get("M")
    outer = m.get("outer_B")
    inner = m.get("inner_B")
    alpha = m.get("alpha")

    if not (len(N)==len(cov)==len(wid)>0):
        raise SystemExit("[ERR] Manifest 03b ne contient pas des listes cohérentes (N/coverage/width_mean).")

    P_OUT.parent.mkdir(parents=True, exist_ok=True)
    with P_OUT.open("w", encoding="utf-8", newline="") as fo:
        wr = csv.writer(fo)
        wr.writerow(["series","N","coverage","err95_low","err95_high","width_mean","M","outer_B","inner_B","alpha"])
        for n,c,w in zip(N,cov,wid):
            wr.writerow(["Chapter 10", n, c, "", "", w, M, outer, inner, alpha])
    print(f"[OK] Table écrite: {P_OUT}  ({len(N)} lignes)")

if __name__=="__main__":
    main()
