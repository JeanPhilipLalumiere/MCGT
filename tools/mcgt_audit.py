#!/usr/bin/env python3
# tools/mcgt_audit.py
from __future__ import annotations
import re, os, sys, json, py_compile, subprocess, shlex
from pathlib import Path
from typing import Dict, List, Tuple, Set

ROOT = Path(__file__).resolve().parents[1] if (Path(__file__).resolve().parent.name == "tools") else Path.cwd()
SCRIPTS_GLOB = "zz-scripts/**/plot_*.py"
DATA_DIR = ROOT / "zz-data"
MANIFESTS_DIR = ROOT / "zz-manifests"
FIGS_DIR = ROOT / "zz-figures"

def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except Exception:
        try:
            return p.read_text(encoding="latin-1")
        except Exception as e:
            return f"__READ_ERROR__:{e}"

def first_non_comment_nonblank_lines(text: str, n=10) -> List[str]:
    out = []
    for line in text.splitlines():
        if line.strip() == "" or line.lstrip().startswith("#"):
            continue
        out.append(line.rstrip("\n"))
        if len(out) >= n: break
    return out

def future_at_top(text: str) -> Tuple[bool, List[int]]:
    lines = text.splitlines()
    first_code_idx = 0
    # shebang
    if lines and lines[0].startswith("#!"):
        first_code_idx = 1
    # skip blanks/comments
    while first_code_idx < len(lines) and (lines[first_code_idx].strip()=="" or lines[first_code_idx].lstrip().startswith("#")):
        first_code_idx += 1
    # optional module docstring
    if first_code_idx < len(lines) and lines[first_code_idx].lstrip().startswith(("'''",'"""')):
        q = lines[first_code_idx].lstrip()[:3]
        first_code_idx += 1
        while first_code_idx < len(lines):
            if lines[first_code_idx].strip().endswith(q):
                first_code_idx += 1
                break
            first_code_idx += 1
    offenders = []
    for i, line in enumerate(lines):
        if "from __future__ import" in line:
            if i < first_code_idx:
                continue
            if i != first_code_idx:
                offenders.append(i+1)  # 1-based
    return (len(offenders) == 0), offenders

ADD_ARG_START = re.compile(r'\.add_argument\s*\(', re.M)
SET_DEFAULTS_START = re.compile(r'\.set_defaults\s*\(', re.M)
ARGS_USED_RE = re.compile(r'\bargs\.([A-Za-z_]\w*)\b')

def _collect_paren_block(s: str, start_pos: int) -> Tuple[str, int]:
    """Collect text from '(' at start_pos to its matching ')', supports nesting and strings."""
    i = start_pos
    assert s[i] == '('
    depth = 0
    buf = []
    in_str = False
    str_q = ''
    esc = False
    while i < len(s):
        ch = s[i]
        buf.append(ch)
        if in_str:
            if esc:
                esc = False
            elif ch == '\\':
                esc = True
            elif ch == str_q:
                in_str = False
        else:
            if ch in ('"', "'"):
                in_str = True; str_q = ch
            elif ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return ''.join(buf), i+1
        i += 1
    return ''.join(buf), i

def parse_add_arguments(text: str) -> Set[str]:
    dests: Set[str] = set()
    i = 0
    while True:
        m = ADD_ARG_START.search(text, i)
        if not m: break
        i = m.end() - 1
        if i < 0 or text[i] != '(':
            # find first '(' after the match
            j = text.find('(', i-1)
            if j == -1: break
            i = j
        block, i2 = _collect_paren_block(text, i)
        i = i2
        inside = block[1:-1]  # drop leading '(' and trailing ')'
        # flags like '--p95-col'
        for flag in re.findall(r"(--[A-Za-z0-9_-]+)", inside):
            dests.add(flag.lstrip('-').replace('-', '_'))
        # explicit dest='name'
        m_dest = re.search(r"dest\s*=\s*['\"]([A-Za-z_]\w*)['\"]", inside)
        if m_dest:
            dests.add(m_dest.group(1))
    return dests

def parse_set_defaults(text: str) -> Set[str]:
    keys: Set[str] = set()
    i = 0
    while True:
        m = SET_DEFAULTS_START.search(text, i)
        if not m: break
        i = m.end() - 1
        if i < 0 or text[i] != '(':
            j = text.find('(', i-1)
            if j == -1: break
            i = j
        block, i2 = _collect_paren_block(text, i)
        i = i2
        inside = block[1:-1]
        keys.update(re.findall(r"([A-Za-z_]\w*)\s*=", inside))
    return keys

def compile_script(p: Path) -> Tuple[bool, str]:
    try:
        py_compile.compile(str(p), doraise=True)
        return True, ""
    except py_compile.PyCompileError as e:
        return False, str(e)
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"

def check_tabs_and_crlf(text: str) -> Dict[str,int]:
    tabs = text.count('\t')
    crlf = text.count('\r\n')
    trailing = sum(1 for line in text.splitlines(True) if line.rstrip('\n').rstrip('\r').rstrip(' ') != line.rstrip('\n').rstrip('\r'))
    return {"tabs": tabs, "crlf_lines": crlf, "trailing_space_lines": trailing}

def discover_scripts() -> List[Path]:
    return sorted(ROOT.glob(SCRIPTS_GLOB))

def audit_scripts() -> List[Dict]:
    rows = []
    for p in discover_scripts():
        txt = read_text(p)
        ok_comp, comp_err = compile_script(p)
        fut_ok, fut_off = future_at_top(txt)
        a_used = set(ARGS_USED_RE.findall(txt))
        a_defs = parse_add_arguments(txt) | parse_set_defaults(txt)
        missing = sorted(a_used - a_defs)
        hygiene = check_tabs_and_crlf(txt)
        rows.append({
            "file": str(p),
            "compiles": ok_comp,
            "compile_error": comp_err,
            "future_at_top": fut_ok,
            "future_offenders": fut_off,
            "args_used": sorted(a_used),
            "args_defined": sorted(a_defs),
            "args_missing": missing,
            "hygiene": hygiene,
            "first_code_lines": first_non_comment_nonblank_lines(txt, 5),
        })
    return rows

def audit_manifests() -> Dict:
    out: Dict[str, object] = {}
    fm_csv = MANIFESTS_DIR / "figure_manifest.csv"
    mm_json = MANIFESTS_DIR / "manifest_master.json"

    def _file_status(p: Path) -> Dict:
        if not p.exists():
            return {"exists": False}
        try:
            b = p.read_bytes()
        except Exception as e:
            return {"exists": True, "error": f"read error: {e}"}
        size = len(b)
        kind = "unknown"
        head = b[:128].lstrip()
        if head.startswith(b"{") or head.startswith(b"["):
            kind = "json-like"
        elif b",".__class__ and b"\n" in b:
            kind = "text"
        return {"exists": True, "size": size, "kind_guess": kind, "is_empty": size == 0}

    out["figure_manifest_csv"] = _file_status(fm_csv)
    out["manifest_master_json"] = _file_status(mm_json)

    # Inspect fig07 to guess expected format
    fig07 = ROOT / "zz-scripts/chapter10/plot_fig07_synthesis.py"
    expects = None
    detail = ""
    if fig07.exists():
        t = read_text(fig07)
        # very rough heuristics
        uses_json = bool(re.search(r"json\.load\s*\(", t))
        uses_csv = bool(re.search(r"read_csv\s*\(", t)) or "csv" in t.lower()
        if uses_json and not uses_csv:
            expects = "json"
        elif uses_csv and not uses_json:
            expects = "csv"
        elif uses_json and uses_csv:
            expects = "both"
        detail = "uses_json=%s uses_csv=%s" % (uses_json, uses_csv)
    out["fig07_expectation"] = {"file": str(fig07), "expects": expects, "detail": detail}

    # quick probe: is figure_manifest.csv actually JSON?
    if out["figure_manifest_csv"].get("exists"):
        try:
            _ = json.loads(fm_csv.read_text(encoding="utf-8"))
            out["figure_manifest_csv_is_json_disguised"] = True
        except Exception:
            out["figure_manifest_csv_is_json_disguised"] = False

    # list per-figure manifests if any
    per_fig = []
    for m in FIGS_DIR.rglob("*.manifest.json"):
        try:
            d = json.loads(m.read_text(encoding="utf-8") or "null")
            ok = isinstance(d, dict)
        except Exception as e:
            ok = False
            d = {"error": str(e)}
        per_fig.append({"file": str(m), "ok_json": ok})
    out["per_figure_manifests"] = per_fig
    return out

def audit_data_columns() -> Dict:
    """Lightweight scan of CSV headers under zz-data to see available columns and common expectations."""
    want_cols = {"m1","m2","phi0","phi_ref_fpeak"}  # extend as needed
    report = {"checked": []}
    for csvp in DATA_DIR.rglob("*.csv"):
        try:
            with csvp.open("r", encoding="utf-8") as fh:
                first = fh.readline()
            hdr = [h.strip() for h in first.strip().split(",")] if first else []
        except Exception as e:
            hdr = []
        missing = sorted([c for c in want_cols if c not in hdr])
        report["checked"].append({"file": str(csvp), "has_header": bool(hdr), "columns": hdr[:50], "missing_common": missing})
    return report

def try_help(script: Path) -> Dict:
    """Non-invasive runtime check: script --help should exit(0) or at least not crash with import errors."""
    try:
        proc = subprocess.run([sys.executable, str(script), "--help"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=25)
        return {"rc": proc.returncode, "stdout": proc.stdout.decode("utf-8", "ignore")[-500:], "stderr": proc.stderr.decode("utf-8", "ignore")[-500:]}
    except Exception as e:
        return {"rc": None, "error": str(e)}

def main():
    print(f"[INFO] Root: {ROOT}")
    scripts = discover_scripts()
    print(f"[INFO] Found {len(scripts)} plotting scripts.")
    scripts_audit = audit_scripts()
    # add a minimal --help probe only for fig07
    fig07 = ROOT / "zz-scripts/chapter10/plot_fig07_synthesis.py"
    help_probe = try_help(fig07) if fig07.exists() else {"rc": None}

    manifests = audit_manifests()
    try:
        data_cols = audit_data_columns()
    except Exception:
        data_cols = {"checked": []}

    # Summaries
    blocking = []
    for row in scripts_audit:
        if not row["compiles"]:
            blocking.append({"type":"compile", "file": row["file"], "detail": row["compile_error"]})
        if row["args_missing"]:
            blocking.append({"type":"arg-missing", "file": row["file"], "detail": {"missing": row["args_missing"], "defined": row["args_defined"]}})
        if not row["future_at_top"] and row["future_offenders"]:
            blocking.append({"type":"future-import", "file": row["file"], "detail": {"offenders": row["future_offenders"]}})

    # fig07 mismatch detector
    fig07_exp = manifests.get("fig07_expectation", {}).get("expects")
    fm_csv_stat = manifests.get("figure_manifest_csv", {})
    fm_csv_exists = fm_csv_stat.get("exists")
    fm_csv_empty = fm_csv_stat.get("is_empty")
    fm_csv_is_json = manifests.get("figure_manifest_csv_is_json_disguised", False)

    if fm_csv_exists and (fm_csv_empty or fig07_exp == "json" or fm_csv_is_json):
        reason = []
        if fm_csv_empty:
            reason.append("figure_manifest.csv est vide")
        if fig07_exp == "json":
            reason.append("fig07 attend un manifest JSON, pas CSV")
        if fm_csv_is_json:
            reason.append("figure_manifest.csv contient du JSON (mauvaise extension)")
        blocking.append({"type":"fig07-manifest", "file": str(fig07), "detail": reason})

    report = {
        "root": str(ROOT),
        "scripts_audit": scripts_audit,
        "blocking": blocking,
        "manifests": manifests,
        "data_columns": data_cols,
        "fig07_help_probe": help_probe,
    }

    MANIFESTS_DIR.mkdir(parents=True, exist_ok=True)
    out_json = MANIFESTS_DIR / "audit_report.json"
    out_txt  = MANIFESTS_DIR / "audit_report.txt"
    out_json.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    # Human-readable short summary
    lines = []
    lines.append("# MCGT Audit Report (summary)\n")
    lines.append(f"- scripts: {len(scripts_audit)} scanned")
    lines.append(f"- blocking findings: {len(blocking)}\n")
    for b in blocking:
        lines.append(f"* {b['type']}: {b['file']}")
        lines.append(f"    -> {b['detail']}\n")
    # top 5 files with missing args
    for row in scripts_audit:
        if row["args_missing"]:
            lines.append(f"- Missing args in {row['file']}: {', '.join(row['args_missing'])}")
    out_txt.write_text("\n".join(lines), encoding="utf-8")

    print(json.dumps({"audit_json": str(out_json), "audit_txt": str(out_txt)}, indent=2))

if __name__ == "__main__":
    main()

# --- injected override ---
def _collect_paren_block(s: str, start_pos: int):
    """Collect text from '(' starting at or after start_pos, with nesting and quotes."""
    i = start_pos
    if i > 0 and i < len(s) and s[i] != '(' and s[i-1] == '(': i -= 1
    if i >= len(s) or s[i] != '(':
        j = s.find('(', i)
        if j == -1:
            return '', i
        i = j
    depth, j, out = 0, i, []
    in_s, in_d = False, False
    while j < len(s):
        ch = s[j]
        out.append(ch)
        if ch == "'" and not in_d and (j == 0 or s[j-1] != '\\'):
            in_s = not in_s
        elif ch == '"' and not in_s and (j == 0 or s[j-1] != '\\'):
            in_d = not in_d
        elif not in_s and not in_d:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    break
        j += 1
    return ''.join(out), j+1

# --- end override ---
