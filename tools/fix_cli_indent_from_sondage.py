#!/usr/bin/env python3
import argparse, json, sys
from pathlib import Path

SONDAGE = Path("zz-manifests/sondage_summary.json")
TRIGS_SAFE_TOP = (
    "import ", "from ", "def ", "class ",
    "parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(", "parser = argparse.ArgumentParser("
)

def prev_nonempty(lines, i):
    j=i-1
    while j>=0 and lines[j].strip()=="":
        j-=1
    return j

def line_opens_block(s: str) -> bool:
    s = s.rstrip()
    return s.endswith(":") and not s.lstrip().startswith("#")

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
        elif ch in ")]}":
            if depth>0: depth -= 1
    return depth

def safe_to_dedent(lines, i) -> bool:
    raw = lines[i]
    if not raw[:1].isspace(): return False
    ls = raw.lstrip()
    if ls.startswith("@"): return False
    if not any(ls.startswith(t) for t in TRIGS_SAFE_TOP): return False
    j = prev_nonempty(lines, i)
    prev = lines[j] if j>=0 else ""
    if line_opens_block(prev): return False
    # profondeur de parenthèses jusqu'à la fin de la ligne précédente
    depth = bracket_depth_upto("".join(lines[:max(0, i)]))
    if depth != 0: return False
    return True

def process_file(path: Path, suspects_1based, apply=False) -> dict:
    txt = path.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    changed_idx = []
    for ln in sorted(set(suspects_1based)):
        i = ln-1
        if i<0 or i>=len(lines): continue
        if safe_to_dedent(lines, i):
            lines[i] = lines[i].lstrip()
            changed_idx.append(ln)
    if apply and changed_idx:
        bak = path.with_suffix(path.suffix + ".bak_cli_dedent")
        bak.write_text(txt, encoding="utf-8")
        path.write_text("".join(lines), encoding="utf-8")
    return {"path": str(path), "changed": changed_idx}

def main():
    ap = argparse.ArgumentParser(description="Dé-dente prudemment les lignes CLI/defs/imports au toplevel.")
    ap.add_argument("--apply", action="store_true", help="Écrire les modifications (crée *.bak_cli_dedent)")
    args = ap.parse_args()

    if not SONDAGE.exists():
        print("[ERR] sondage_summary.json manquant. Lance tools/sonde_repo_for_risks.py d'abord.", file=sys.stderr)
        sys.exit(2)

    data = json.loads(SONDAGE.read_text(encoding="utf-8"))
    targets = [r for r in data if r.get("indent_suspects_count",0)>0]
    total_changed = 0
    report = []

    for r in targets:
        p = Path(r["path"])
        sus = r.get("indent_suspects") or []
        if not p.exists(): continue
        res = process_file(p, sus, apply=args.apply)
        if res["changed"]:
            total_changed += len(res["changed"])
        report.append(res)

    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[{mode}] fichiers ciblés: {len(targets)} ; lignes modifiées: {total_changed}")
    for res in report:
        if res["changed"]:
            print(f"- {res['path']}: {len(res['changed'])} ligne(s) → {res['changed']}")
    if not args.apply:
        print("\nAstuce: si la prévisualisation te convient, relance avec --apply")

if __name__ == "__main__":
    main()
