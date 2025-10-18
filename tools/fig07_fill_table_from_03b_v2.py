#!/usr/bin/env python3
import json, csv, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
P_FIGMAN = ROOT/"zz-manifests/figure_manifest.json"
P_OUT    = ROOT/"zz-figures/chapter10/10_fig_07_synthesis.table.csv"

CAND_PNG  = ROOT/"zz-figures/chapter10/10_fig_03b_bootstrap_coverage_vs_n.png"
CAND_MAN  = CAND_PNG.with_suffix(".manifest.json")

def find_manifest_path():
    # 1) via figure_manifest.json
    if P_FIGMAN.exists():
        try:
            d = json.loads(P_FIGMAN.read_text(encoding="utf-8"))
            for it in d.get("figures", []):
                p = it.get("path") or ""
                if "/chapter10/" in p and "fig_03b_bootstrap_coverage_vs_n.png" in p:
                    return (ROOT/p).with_suffix(".manifest.json")
        except Exception:
            pass
    # 2) chemin "connu"
    if CAND_MAN.exists():
        return CAND_MAN
    # 3) recherche globale
    for p in ROOT.glob("zz-figures/**/10_fig_03b_*bootstrap_coverage_vs_n*.manifest.json"):
        return p
    for p in ROOT.glob("zz-figures/**/fig_03b_*coverage_vs_n*.manifest.json"):
        return p
    return None

def main():
    man = find_manifest_path()
    if not man:
        sys.exit("[ERR] Manifest 03b introuvable. Pense à régénérer figure_manifest.json ou vérifie que le PNG 03b existe.")
    m = json.loads(man.read_text(encoding="utf-8"))
    N   = m.get("N_list")      or []
    cov = m.get("coverage")    or []
    wid = m.get("width_mean")  or []
    M     = m.get("M")
    outer = m.get("outer_B")
    inner = m.get("inner_B")
    alpha = m.get("alpha")

    if not (len(N)==len(cov)==len(wid)>0):
        sys.exit("[ERR] Manifest 03b ne contient pas des listes N/coverage/width_mean valides.")

    P_OUT.parent.mkdir(parents=True, exist_ok=True)
    with P_OUT.open("w", encoding="utf-8", newline="") as fo:
        wr = csv.writer(fo)
        wr.writerow(["series","N","coverage","err95_low","err95_high","width_mean","M","outer_B","inner_B","alpha"])
        for n,c,w in zip(N,cov,wid):
            wr.writerow(["Chapter 10", n, c, "", "", w, M, outer, inner, alpha])
    print(f"[OK] Table écrite: {P_OUT}  ({len(N)} lignes)")

if __name__ == "__main__":
    main()
