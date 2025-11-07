#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

ROOT = Path(".")
CANDIDATES = [p for p in Path("zz-scripts").rglob("*.py") if p.is_file()]

# Détections
PAT_IMPORT_COMMON = re.compile(r'(?:from\s+_common\.cli\s+import\b|import\s+_common\.cli\b)', re.M)
PAT_CALL_COMMON   = re.compile(r'\badd_common_plot_args\s*\(', re.M)
PAT_MAIN_GUARD    = re.compile(r'if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:', re.M)
PAT_TOPLEVEL_SAVE = re.compile(r'(?m)^\s*plt\.savefig\(')

def has_arg_literal(s: str, name: str) -> bool:
    # Recherche d'un add_argument("--name") explicite (pour scripts non convertis)
    return re.search(rf'add_argument\(\s*["\']{re.escape(name)}["\']', s) is not None

REQ_ARGS = ["--outdir","--format","--dpi","--figsize","--style","--log-level"]

def check_file(p: Path) -> dict:
    try:
        s = p.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return {"path": str(p), "issues": [f"READ_ERROR:{e}"]}

    issues = []

    # 1) Garde main
    if not PAT_MAIN_GUARD.search(s):
        issues.append("MISS_MAIN_GUARD")

    # 2) Import/usage du noyau commun
    imp = PAT_IMPORT_COMMON.search(s) is not None
    call = PAT_CALL_COMMON.search(s) is not None
    if not imp:
        issues.append("MISS_IMPORT_COMMON")
    if not call:
        issues.append("MISS_CALL_COMMON")

    # 3) Args requis : OK si add_common_plot_args() est appelée, sinon on attend des add_argument explicites
    if not call:
        for a in REQ_ARGS:
            if not has_arg_literal(s, a):
                issues.append(f"MISS_ARG:{a}")

    # 4) Anti-pattern : plt.savefig au toplevel (doit passer par finalize_plot_from_args / save_figure)
    if PAT_TOPLEVEL_SAVE.search(s):
        issues.append("TOPLEVEL_SAVEFIG")

    return {"path": str(p), "issues": issues}

def main() -> int:
    report = [check_file(p) for p in sorted(CANDIDATES)]
    bad = [r for r in report if r["issues"]]
    print("# CLI Conformité — résumé")
    print(f"Total scripts: {len(report)}  |  Non conformes: {len(bad)}")
    buckets = {}
    for r in bad:
        for i in r["issues"]:
            buckets[i] = buckets.get(i, 0) + 1
    if buckets:
        print("# Compte par type d’écart")
        for k, v in sorted(buckets.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"  {k:>20s}: {v}")
    else:
        print("# Aucun écart détecté 🎉")

    print("\n# Détails (premiers 80)")
    for r in bad[:80]:
        print(f"- {r['path']}: {', '.join(r['issues'])}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
