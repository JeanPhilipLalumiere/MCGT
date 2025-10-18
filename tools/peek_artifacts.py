#!/usr/bin/env python3
import json, csv
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
P_MANIFEST = ROOT/"zz-manifests/figure_manifest.json"
P_TABLE    = ROOT/"zz-figures/chapter10/10_fig_07_synthesis.table.csv"
P_SWEEP    = ROOT/"zz-manifests/audit_sweep.json"
P_FAILMD   = ROOT/"zz-manifests/compile_fail_context.md"
P_ARGSMD   = ROOT/"zz-manifests/args_missing_context.md"
P_ARGSMTX  = ROOT/"zz-manifests/args_matrix.csv"
P_SUMMARY  = ROOT/"zz-manifests/audit_summary.json"

def peek_manifest():
    out = {"exists": P_MANIFEST.exists()}
    if not out["exists"]: return out
    d = json.loads(P_MANIFEST.read_text(encoding="utf-8"))
    figs = d.get("figures", [])
    out.update({
        "results": d.get("results"),
        "fig_count": len(figs),
        "chapters": sorted({Path(x.get("path","")).parts[-2] for x in figs if x.get("path") and len(Path(x["path"]).parts)>=2})
    })
    return out

def peek_table():
    out = {"exists": P_TABLE.exists()}
    if not out["exists"]: return out
    with P_TABLE.open(encoding="utf-8", newline="") as f:
        rd = csv.reader(f); rows = list(rd)
    out.update({"rows": max(0, len(rows)-1), "cols": rows[0] if rows else []})
    return out

def peek_sweep():
    out = {"exists": P_SWEEP.exists()}
    if not out["exists"]: return out
    d = json.loads(P_SWEEP.read_text(encoding="utf-8"))
    files = d.get("files", [])
    errs  = [f for f in files if f.get("compile")!="OK"]
    out.update({
        "totals": {k:d.get(k) for k in ("total_files","compile_errors","args_missing","future_misordered")},
        "first_errors": [
            {"path":f["path"], **f.get("error",{})} for f in errs[:10]
        ],
        "first_args_missing": [
            {"path":f["path"], "missing":f.get("args_missing")} for f in files if f.get("args_missing")][:5]
    })
    return out

def peek_args_matrix():
    out = {"exists": P_ARGSMTX.exists()}
    if not out["exists"]: return out
    with P_ARGSMTX.open(encoding="utf-8", newline="") as f:
        rd = csv.reader(f); cols = next(rd)
        idx = {c:i for i,c in enumerate(cols)}
        miss = Counter(); file_miss = Counter()
        for row in rd:
            m = 0
            for c in cols[1:]:
                if row[idx[c]]=="MISSING":
                    miss[c]+=1; m += 1
            if m: file_miss[row[0]] = m
    out.update({
        "top_missing_args": miss.most_common(10),
        "top_most_broken_files": file_miss.most_common(10),
        "arg_columns": cols[1:]
    })
    return out

def main():
    manifest = peek_manifest()
    table    = peek_table()
    sweep    = peek_sweep()
    matrix   = peek_args_matrix()

    print("== Manifest =="); print(json.dumps(manifest, indent=2, ensure_ascii=False))
    print("\n== Fig07 table =="); print(json.dumps(table, indent=2, ensure_ascii=False))
    print("\n== Audit sweep =="); print(json.dumps(sweep, indent=2, ensure_ascii=False))
    print("\n== Args matrix =="); print(json.dumps(matrix, indent=2, ensure_ascii=False))

    summary = {"manifest":manifest, "table":table, "sweep":sweep, "matrix":matrix}
    P_SUMMARY.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n[OK] wrote {P_SUMMARY}")

if __name__ == "__main__":
    main()
