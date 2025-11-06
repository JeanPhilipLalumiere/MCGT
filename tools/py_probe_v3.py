# ==== MCGT — py_probe_v3.py (AST/argparse/mapping), lecture-seule + pause ====
# Recommandé : sauvegarder comme tools/py_probe_v3.py puis:  python tools/py_probe_v3.py
from __future__ import annotations
import ast, json, re, sys
from pathlib import Path
from datetime import datetime, timezone

ROOT=Path(".").resolve()
STAMP=datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
OUT=Path(f"/tmp/mcgt_pyprobe_{STAMP}"); (OUT/"ctx").mkdir(parents=True, exist_ok=True)

def safe_read(p: Path)->str:
    try: return p.read_text(encoding="utf-8", errors="replace")
    except Exception as e: return f"<READ-ERR {e}>"

def ctx_lines(p: Path, a:int, b:int):
    txt=safe_read(p).splitlines()
    a=max(1,a); b=min(len(txt),b)
    return "\n".join(f"{i+1:5d}: {txt[i]}" for i in range(a-1,b))

report={"generated_utc": datetime.now(timezone.utc).isoformat()+"Z"}

# A) AST parse ciblé — détecter bloc manquant/indent ch09
p09 = ROOT/"zz-scripts/chapter09/plot_fig01_phase_overlay.py"
if p09.exists():
    src=safe_read(p09)
    try:
        ast.parse(src)
        report["ch09_ast_ok"]=True
    except SyntaxError as e:
        report["ch09_ast_ok"]=False
        report["ch09_syntaxerror"]={"lineno":e.lineno,"offset":e.offset,"text":e.text}
        (OUT/"ctx/ch09_near_error.txt").write_text(ctx_lines(p09, max(1,(e.lineno or 1)-15), (e.lineno or 1)+15), encoding="utf-8")
        report["ch09_error_ctx"]=str(OUT/"ctx/ch09_near_error.txt")

# B) Argparse signature — récolter toutes les options pour chaque plot_fig*.py
req = {"--out","--outdir","--format","--dpi","--figsize","--transparent","--style","--log-level","--seed","--save-pdf","--save-svg","--show"}
cli_matrix=[]
for p in sorted(ROOT.rglob("zz-scripts/**/plot_fig*.py")):
    txt=safe_read(p)
    opts=set(m.group(0) for m in re.finditer(r'--[a-zA-Z0-9\-]+', txt))
    missing=sorted(req - opts)
    cli_matrix.append({"path": str(p.relative_to(ROOT)), "present": sorted(opts), "missing": missing})
report["cli_matrix"]=cli_matrix[:200]

# C) Mapping script→inputs (pd.read_csv/json.load/configparser)
mapping=[]
pat = re.compile(r'pd\.read_csv\((?P<arg>[^)]*)\)|json\.load\(|configparser\.ConfigParser', re.S)
for p in sorted(ROOT.rglob("zz-scripts/**/plot_fig*.py")):
    txt=safe_read(p)
    refs=[]
    for m in re.finditer(r'pd\.read_csv\(\s*([^\)]+)\)', txt):
        refs.append(("csv", m.group(1)[:200]))
    for m in re.finditer(r'json\.load\(\s*([^\)]+)\)', txt):
        refs.append(("json", m.group(1)[:200]))
    if "configparser.ConfigParser" in txt:
        refs.append(("ini","ConfigParser(...)"))
    if refs:
        mapping.append({"path": str(p.relative_to(ROOT)), "refs": refs[:10]})
report["mapping_refs"]=mapping[:200]

# D) sys.exit usages & plt.* usages (synthèse)
def grep(pat):
    res=[]
    cre=re.compile(pat)
    for p in sorted(ROOT.rglob("zz-scripts/**/*.py")):
        txt=safe_read(p).splitlines()
        for i,s in enumerate(txt,1):
            if cre.search(s):
                res.append({"path": str(p.relative_to(ROOT)), "line": i, "text": s.strip()[:200]})
    return res
report["sys_exit"]=grep(r'\bsys\.exit\(')[:200]
report["plt_usage"]=grep(r'\bplt\.')[:200]

# E) Écrire rapport
rp=OUT/"py_probe_report.json"
rp.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"[OK] Rapport: {rp}")
if report.get("ch09_syntaxerror"):
    print("[FOCUS] ch09 SyntaxError:", report["ch09_syntaxerror"])
    print("[CTX]   :", report["ch09_error_ctx"])
input("➡️  Appuie sur Entrée pour terminer (le terminal ne se fermera pas)… ")
