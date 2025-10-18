#!/usr/bin/env python3
from pathlib import Path
import json, re, sys

AUDIT = Path("zz-manifests/audit_sweep.json")
OUT_JSON = Path("zz-manifests/probe_first_errors.json")

TRIGS_SAFE_TOP = (
    "import ", "from ", "def ", "class ",
    "parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(", "parser = argparse.ArgumentParser("
)

def bracket_depth_upto(text: str) -> int:
    depth = 0; in_str = None; esc = False
    for ch in text:
        if in_str:
            if esc: esc = False
            elif ch == "\\": esc = True
            elif ch == in_str: in_str = None
            continue
        if ch in ("'", '"'): in_str = ch
        elif ch in "([{": depth += 1
        elif ch in ")]}": depth -= 1 if depth>0 else 0
    return depth

def prev_nonempty(lines, i):
    j=i-1
    while j>=0 and lines[j].strip()=="":
        j-=1
    return j

def classify_line(prev, raw, cum_depth):
    ls = raw.lstrip()
    prev_ends_colon = prev.rstrip().endswith(":") if prev is not None else False
    is_toplevel_candidate = any(ls.startswith(t) for t in TRIGS_SAFE_TOP)
    starts_decorator = ls.startswith("@")
    safe_recommend = (raw[:1].isspace() and not prev_ends_colon
                      and is_toplevel_candidate and cum_depth==0 and not starts_decorator)
    return {
        "prev_ends_colon": prev_ends_colon,
        "is_toplevel_candidate": is_toplevel_candidate,
        "starts_decorator": starts_decorator,
        "cum_bracket_depth": cum_depth,
        "recommend": "dedent" if safe_recommend else "skip"
    }

def probe_one(path: Path, lineno: int):
    src = path.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines(True)
    cum_depth = bracket_depth_upto("".join(lines[:max(0, lineno-1)]))
    i0 = max(0, lineno-1-10); i1 = min(len(lines), lineno-1+10+1)
    prev_i = prev_nonempty(lines, lineno-1)
    prev = lines[prev_i] if prev_i>=0 else ""
    info = classify_line(prev, lines[lineno-1], cum_depth)
    excerpt = "".join(f"{idx+1:>6} | {lines[idx]}" for idx in range(i0, i1))
    return {
        "path": str(path),
        "lineno": lineno,
        "analysis": info,
        "prev_line": prev.rstrip("\n"),
        "excerpt": excerpt
    }

def main():
    if not AUDIT.exists():
        print("[ERR] audit_sweep.json manquant.", file=sys.stderr); sys.exit(2)
    data = json.loads(AUDIT.read_text(encoding="utf-8"))
    first = data.get("first_errors") or []
    # garder seulement les 'unexpected indent'
    candidates = []
    for e in first:
        if e.get("type") != "SyntaxError": continue
        msg = (e.get("msg") or "").lower()
        if "unexpected indent" not in msg: continue
        p = Path(e["path"])
        if p.suffix==".py" and p.exists():
            candidates.append((p, int(e["lineno"])))
    results = [probe_one(p, ln) for (p, ln) in candidates]
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] écrit {OUT_JSON}  (items={len(results)})")
    for r in results:
        a = r["analysis"]
        print(f"\n==== {r['path']}:{r['lineno']} ====")
        print(f"- prev_ends_colon={a['prev_ends_colon']}  toplevel={a['is_toplevel_candidate']}  "
              f"decorator={a['starts_decorator']}  depth={a['cum_bracket_depth']}  -> {a['recommend']}")
        print(r["excerpt"], end="")

if __name__ == "__main__":
    main()
