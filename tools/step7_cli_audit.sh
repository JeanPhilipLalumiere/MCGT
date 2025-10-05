#!/usr/bin/env bash
set -euo pipefail
: "${WAIT_ON_EXIT:=1}"
_pause(){ rc=$?; echo; if [ $rc -eq 0 ]; then echo "✅ CLI audit — exit $rc"; else echo "❌ CLI audit — exit $rc"; fi; if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then if [ -r /dev/tty ]; then printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty; IFS= read -r _ < /dev/tty; printf "\n" > /dev/tty; elif [ -t 0 ]; then read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _; echo; else echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."; tail -f /dev/null; fi; fi; }; trap _pause EXIT
cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

python3 - <<'PY'
from pathlib import Path
import re, json

root = Path(".")
targets = sorted((root/"zz-scripts").rglob("*.py"))

def safe_read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except Exception:
        try:
            return p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            return ""

def flag(rx: str, s: str, flags=0) -> bool:
    try:
        return re.search(rx, s, flags) is not None
    except re.error:
        return False

rows = []
for p in targets:
    s = safe_read(p)
    r = {
        "path": str(p),
        "has_argparse":   flag(r'\b(import\s+argparse|from\s+argparse\s+import)\b', s),
        "has_click":      flag(r'\b(import\s+click|from\s+click\s+import)\b', s),
        "defines_main":   flag(r'^\s*def\s+main\s*\(', s, flags=re.M),
        "has_main_guard": flag(r'if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:', s),
        "uses_sys_path":  flag(r'\bsys\.path\.(append|insert)\s*\(', s),
        "noqa_E402":      flag(r'ruff:\s*noqa:\s*E402', s) or flag(r'noqa:\s*E402', s),
        "std_opts":       flag(r'--outdir|--dry-?run|--seed|--force|--verbose', s),
        "uses_matplotlib":flag(r'\bmatplotlib\b', s),
        "uses_pyplot":    flag(r'\bmatplotlib\.pyplot\b', s),
        "writes_fig":     flag(r'\.savefig\s*\(', s),
        "writes_data":    flag(r'\.(to_csv|savetxt|save)\s*\(', s) or ("csv.writer(" in s),
    }
    score = 0
    score += 1 if (r["has_argparse"] or r["has_click"]) else 0
    score += 1 if r["defines_main"] else 0
    score += 1 if r["has_main_guard"] else 0
    score += 1 if r["std_opts"] else 0
    score += 1 if not r["uses_sys_path"] else 0
    r["score5"] = score
    rows.append(r)

rows.sort(key=lambda r: (r["score5"], not r["uses_sys_path"], r["path"]))

def b(v): return "✓" if v else "·"
print("\n=== CLI audit (zz-scripts) ===")
print("path | arg/click | main() | __main__ | std_opts | sys.path | E402 | mpl | savefig | data | score")
print("-"*120)
for r in rows:
    print(f'{r["path"]} | {b(r["has_argparse"] or r["has_click"])} | {b(r["defines_main"])} | '
          f'{b(r["has_main_guard"])} | {b(r["std_opts"])} | {b(not r["uses_sys_path"])} | '
          f'{b(not r["noqa_E402"])} | {b(r["uses_matplotlib"])} | {b(r["writes_fig"])} | '
          f'{b(r["writes_data"])} | {r["score5"]}/5')

Path(".ci-out/cli_audit.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
print("\nRapport JSON: .ci-out/cli_audit.json")
PY
