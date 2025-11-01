# tools/triage_v4_current_failures.py
#!/usr/bin/env python3
import os, sys, pathlib, time, re

def last_report():
    reps = sorted([p for p in os.popen("ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null").read().splitlines()])
    return pathlib.Path(reps[-1]) if reps else None

rep = last_report()
if not rep or not rep.exists():
    print("[ERR] Pas de smoke récent. Lance d’abord: bash tools/smoke_help_repo.sh", file=sys.stderr); sys.exit(1)
log = rep.parent / "run.log"
if not log.exists():
    print(f"[ERR] Log introuvable: {log}", file=sys.stderr); sys.exit(1)

fails = [l.split("\t",1)[1].strip() for l in rep.read_text(encoding="utf-8").splitlines() if l.startswith("FAIL\t")]
if not fails:
    print("[INFO] 0 FAIL — rien à faire."); sys.exit(0)

def extract_block(fpath:str)->str:
    lines = log.read_text(encoding="utf-8", errors="replace").splitlines()
    out=[]; hit=False
    key = f"TEST --help: {fpath}"
    for i,l in enumerate(lines):
        if l.strip()==key:
            hit=True; continue
        if hit and l.startswith("[") and "TEST --help:" in l:   # next test begins
            break
        if hit: out.append(l)
    return "\n".join(out).strip()

def summarize_exception(block:str):
    # take last non-empty line that looks like an exception message
    lines=[x for x in block.splitlines() if x.strip()]
    exc_line=""
    for l in reversed(lines):
        if re.search(r"(Error|Exception|Traceback|SyntaxError|NameError|KeyError|TypeError|ValueError|FileNotFoundError)", l):
            exc_line=l; break
    # normalize
    exc = re.sub(r'.*Traceback.*','',exc_line).strip()
    # classify + hint
    hint="inspect"
    if "NameError: name 'sys' is not defined" in exc:
        hint="Ajouter `import sys` en tête (après bloc d’imports)."
    elif re.search(r"NameError: name '(plt|fig|ax)' is not defined", exc):
        hint="Garder `plt/fig/ax=None` au module-scope ou déplacer toute init plot sous `if __name__=='__main__':`."
    elif "TypeError: scatter() missing" in exc:
        hint="Neutraliser les appels Matplotlib au module-scope pour `--help` (guard ou déplacement sous main)."
    elif re.search(r"KeyError:\s*'T'", exc):
        hint="Au `--help`, ne pas indexer colonnes: ajouter guard (ex. `if '--help' in sys.argv: skip data ops`)."
    elif "FileNotFoundError" in exc:
        hint="Au `--help`, ne pas charger les données: retourner tôt avant I/O (guard)."
    elif "ValueError: I/O operation on closed file" in exc:
        hint="Ne pas ouvrir/fermer de fichier au `--help` (déplacer I/O sous main)."
    else:
        hint="Mettre tout I/O/plot/sidelog sous `if __name__=='__main__':` et early-return si `--help`."
    return exc or "exception inconnue", hint

rows=[]
for f in fails:
    block = extract_block(f)
    exc, hint = summarize_exception(block)
    # first frame (when present)
    m = re.search(r'File "([^"]+)", line (\d+), in <module>', block)
    frame = f"{m.group(1)}:{m.group(2)}" if m else "n/a"
    rows.append((f, exc, frame, hint))

# Pretty print
w = [max(len(x[i]) for x in rows+[("file","exception","frame","hint")]) for i in range(4)]
hdr = ["file","exception","frame","hint"]
print(f"{hdr[0]:<{w[0]}}  {hdr[1]:<{w[1]}}  {hdr[2]:<{w[2]}}  {hdr[3]}")
print("-"*(sum(w)+6))
for r in rows:
    print(f"{r[0]:<{w[0]}}  {r[1]:<{w[1]}}  {r[2]:<{w[2]}}  {r[3]}")
