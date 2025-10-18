#!/usr/bin/env python3
import json, re, ast, sys
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
OUTDIR = ROOT / "zz-manifests"
OUTDIR.mkdir(parents=True, exist_ok=True)

PY_GLOB = [
    "zz-scripts/**/*.py",   # tous les scripts d’illustrations
    # ajoute d’autres répertoires si nécessaire
]

ARGS_ATTR_RE   = re.compile(r"\bargs\.([A-Za-z_]\w*)\b")
ADD_ARG_RE     = re.compile(r"\.add_argument\((?P<body>.*?)\)", re.S)
SET_DEFAULTS_RE= re.compile(r"\.set_defaults\((?P<body>.*?)\)", re.S)
DEST_RE        = re.compile(r"\bdest\s*=\s*['\"](?P<dest>[A-Za-z_]\w*)['\"]")
OPT_RE         = re.compile(r"['\"]--(?P<long>[A-Za-z0-9][\w\-]*)['\"]")
KW_RE          = re.compile(r"\b(?P<name>[A-Za-z_]\w*)\s*=")

def safe_read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""

def underscore(name: str) -> str:
    return name.replace("-", "_")

def line_index_map(text: str) -> List[int]:
    # renvoie les offsets de début de chaque ligne pour retrouver la ligne depuis une position
    offs = [0]
    for ch in text:
        if ch == "\n": offs.append(offs[-1] + 1)
        else: offs[-1] += 1
    # recalcul simple si la méthode ci-dessus ne convient pas :
    offs = []
    s = 0
    for line in text.splitlines(True):
        offs.append(s)
        s += len(line)
    return offs

def pos_to_line(offs: List[int], pos: int) -> int:
    # binaire simple
    lo, hi = 0, len(offs)-1
    while lo <= hi:
        mid = (lo+hi)//2
        if offs[mid] <= pos:
            lo = mid + 1
        else:
            hi = mid - 1
    return hi + 1  # 1-based

def parse_defined_args(text: str) -> Tuple[set, Dict[str, int]]:
    """
    Heuristique : récupère les dest via add_argument(...), et les noms via set_defaults(...)
    Retourne (set_definis, lignes_par_nom)
    """
    defined = set()
    where: Dict[str,int] = {}
    offs = line_index_map(text)

    for m in ADD_ARG_RE.finditer(text):
        body = m.group("body")
        destm = DEST_RE.search(body)
        if destm:
            dest = destm.group("dest")
            if dest not in defined:
                defined.add(dest)
                where[dest] = pos_to_line(offs, m.start())
            continue
        # sinon, on déduit du 1er long flag
        optm = OPT_RE.search(body)
        if optm:
            dest = underscore(optm.group("long"))
            if dest not in defined:
                defined.add(dest)
                where[dest] = pos_to_line(offs, m.start())

    for m in SET_DEFAULTS_RE.finditer(text):
        body = m.group("body")
        for km in KW_RE.finditer(body):
            name = km.group("name")
            if name not in defined:
                defined.add(name)
                where[name] = pos_to_line(offs, m.start())

    return defined, where

def parse_used_args(text: str) -> Tuple[set, Dict[str, List[int]]]:
    offs = line_index_map(text)
    used = set()
    locs: Dict[str, List[int]] = {}
    for m in ARGS_ATTR_RE.finditer(text):
        attr = m.group(1)
        used.add(attr)
        locs.setdefault(attr, []).append(pos_to_line(offs, m.start()))
    return used, locs

def future_misordered(text: str) -> bool:
    """
    Vérifie si un 'from __future__ import ...' apparaît après du code/autres imports.
    Autorise : shebang, lignes vides, commentaires, docstring de module.
    """
    lines = text.splitlines()
    i = 0
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # blancs/commentaires
    while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")):
        i += 1
    # docstring éventuelle
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '"""')):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines) and q not in lines[i]:
            i += 1
        if i < len(lines): i += 1
        while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")):
            i += 1

    # À partir d’ici, tout __future__ rencontré après autre chose => mal ordonné
    seen_nontrivial = False
    for ln in lines[i:]:
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        if re.match(r"\s*from __future__ import ", ln):
            if seen_nontrivial:
                return True
        else:
            # import classique ou code
            seen_nontrivial = True
    return False

def compile_status(text: str) -> Tuple[str, Dict]:
    try:
        ast.parse(text)
        return "OK", {}
    except SyntaxError as e:
        return "ERROR", {"type":"SyntaxError","lineno":e.lineno,"offset":e.offset,"msg":e.msg}
    except Exception as e:
        return "ERROR", {"type":type(e).__name__,"msg":str(e)}

def sweep() -> Dict:
    files = []
    for pat in PY_GLOB:
        files.extend(ROOT.glob(pat))
    files = sorted(set(p for p in files if p.is_file()))

    report = {
        "root": str(ROOT),
        "files": [],
        "global_issues": [],
        "summary": {},
    }

    for p in files:
        text = safe_read(p)
        status, err = compile_status(text)
        defined, def_where = parse_defined_args(text)
        used, use_where = parse_used_args(text)
        missing = sorted([u for u in used if u not in defined])
        fut_mis = future_misordered(text)

        entry = {
            "path": str(p.relative_to(ROOT)),
            "compile": status,
            "error": err,
            "args_used": sorted(used),
            "args_defined": sorted(defined),
            "args_missing": missing,
            "where_defined": def_where,
            "where_used": use_where,
            "future_misordered": fut_mis,
        }
        report["files"].append(entry)

    # global : manifeste JSON pour fig07
    man_csv = ROOT / "zz-manifests/figure_manifest.csv"
    man_json = ROOT / "zz-manifests/figure_manifest.json"
    if man_json.exists():
        try:
            json.loads(man_json.read_text(encoding="utf-8"))
        except Exception as e:
            report["global_issues"].append(
                {"manifest_json":"invalid", "error": str(e)}
            )
    else:
        report["global_issues"].append({"manifest_json":"missing"})

    # résumé
    compile_fail = [f for f in report["files"] if f["compile"] != "OK"]
    args_miss    = [f for f in report["files"] if f["args_missing"]]
    fut_mis      = [f for f in report["files"] if f["future_misordered"]]
    report["summary"] = {
        "total_files": len(report["files"]),
        "compile_errors": len(compile_fail),
        "args_missing": len(args_miss),
        "future_misordered": len(fut_mis),
    }
    return report

def write_reports(rep: Dict):
    OUTJSON = OUTDIR / "audit_sweep.json"
    OUTTXT  = OUTDIR / "audit_sweep.txt"

    OUTJSON.write_text(json.dumps(rep, indent=2, ensure_ascii=False), encoding="utf-8")

    lines = []
    S = rep["summary"]
    lines.append(f"# MCGT sweep summary")
    lines.append(f"- total files: {S['total_files']}")
    lines.append(f"- compile errors: {S['compile_errors']}")
    lines.append(f"- args missing: {S['args_missing']}")
    lines.append(f"- future misordered: {S['future_misordered']}")
    if rep["global_issues"]:
        lines.append(f"- global issues: {rep['global_issues']}")
    lines.append("")

    if S["compile_errors"]:
        lines.append("## COMPILE_FAIL")
        for f in rep["files"]:
            if f["compile"] == "OK": continue
            e = f["error"]
            lines.append(f"- {f['path']} :: {e.get('type')} L{e.get('lineno')} C{e.get('offset')}: {e.get('msg')}")
        lines.append("")

    if S["args_missing"]:
        lines.append("## ARGS_MISSING (utilisés mais non définis)")
        for f in rep["files"]:
            if not f["args_missing"]: continue
            miss = ", ".join(f["args_missing"])
            lines.append(f"- {f['path']} :: {miss}")
        lines.append("")

    if S["future_misordered"]:
        lines.append("## FUTURE_IMPORT_MISORDERED")
        for f in rep["files"]:
            if f["future_misordered"]:
                lines.append(f"- {f['path']}")
        lines.append("")

    OUTTXT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(rep["summary"], ensure_ascii=False))

if __name__ == "__main__":
    rep = sweep()
    write_reports(rep)
