# tools/triage_v5_exec_failures.py — ré-exécute chaque FAIL pour capturer l'exception réelle
#!/usr/bin/env python3
import os, sys, time, pathlib, subprocess, shlex, re

def last_report():
    reps = sorted([p for p in os.popen("ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null").read().splitlines()])
    return pathlib.Path(reps[-1]) if reps else None

rep = last_report()
if not rep or not rep.exists():
    print("[ERR] Pas de smoke récent. Lance d’abord: bash tools/smoke_help_repo.sh", file=sys.stderr); sys.exit(1)
logdir = rep.parent
fails = [l.split("\t",1)[1].strip() for l in rep.read_text(encoding="utf-8").splitlines() if l.startswith("FAIL\t")]
if not fails:
    print("[INFO] 0 FAIL — rien à faire."); sys.exit(0)

ts = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
outdir = pathlib.Path(f"_tmp/triage_v5_{ts}")
outdir.mkdir(parents=True, exist_ok=True)
summary = outdir/"summary.tsv"
summary.write_text("file\texit\texception\tframe\thint\n", encoding="utf-8")

def classify(exc_line:str, out:str, err:str):
    # Heuristiques compactes → hint d’autofix
    if "NameError: name 'sys' is not defined" in exc_line:
        return "Ajouter `import sys` (tête)."
    if re.search(r"NameError: name '(plt|fig|ax)' is not defined", exc_line):
        return "Déplacer toute init Matplotlib sous main() ou set `plt=None` + guards pour --help."
    if "TypeError: scatter() missing" in exc_line:
        return "Neutraliser appels plotting au module-scope pour --help (guard) / déplacer sous main()."
    if re.search(r"KeyError:\s*'T'", exc_line):
        return "Ne pas indexer colonnes au --help (guard de data ops ou colonnes manquantes)."
    if "FileNotFoundError" in exc_line or "No such file or directory" in exc_line:
        return "Bypass I/O au --help (early-return avant lecture des données)."
    if "ValueError: I/O operation on closed file" in exc_line:
        return "Éviter open/close au --help; déplacer I/O sous main()."
    if "argparse" in exc_line and "conflicting option" in exc_line:
        return "Déjà traité via conflict_handler='resolve' (vérifier fichier restant)."
    # Si rien de clair mais code !=0
    return "Mettre tout I/O/plot/log sous main() + early-return si '--help' détecté."

def run_one(fpath:str):
    cmd = [sys.executable, fpath, "--help"]
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=20, env={**os.environ, "PYTHONUNBUFFERED":"1"})
        out, err, rc = p.stdout, p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        return 124, "TimeoutExpired: --help exceeded 20s", "n/a", "Assurer que --help retourne immédiatement (argparse) sans exécuter la logique."
    # Cherche dernière ligne d’exception signifiante
    blob = (out or "") + "\n" + (err or "")
    exc_line = ""
    for line in reversed([x for x in blob.splitlines() if x.strip()]):
        if re.search(r"(Traceback|Error|Exception|SyntaxError|NameError|KeyError|TypeError|ValueError|FileNotFoundError)", line):
            exc_line = line.strip(); break
    frame = "n/a"
    m = re.search(r'File "([^"]+)", line (\d+), in <module>', blob)
    if m: frame = f"{os.path.relpath(m.group(1))}:{m.group(2)}"
    hint = classify(exc_line, out, err)
    # Sauvegarde raw
    (outdir/(pathlib.Path(fpath).name+".stdout.txt")).write_text(out or "", encoding="utf-8")
    (outdir/(pathlib.Path(fpath).name+".stderr.txt")).write_text(err or "", encoding="utf-8")
    return rc, exc_line or "(no exception text)", frame, hint

rows = []
for f in fails:
    rc, exc, frame, hint = run_one(f)
    rows.append((f, str(rc), exc, frame, hint))
    summary.write_text(summary.read_text(encoding="utf-8") + f"{f}\t{rc}\t{exc}\t{frame}\t{hint}\n", encoding="utf-8")

# Affichage aligné
w0 = max(len("file"), max(len(r[0]) for r in rows))
w1 = max(len("exit"), max(len(r[1]) for r in rows))
w2 = max(len("exception"), max(len(r[2]) for r in rows))
w3 = max(len("frame"), max(len(r[3]) for r in rows))
print(f"{'file':<{w0}}  {'exit':<{w1}}  {'exception':<{w2}}  {'frame':<{w3}}  hint")
print("-"*(w0+w1+w2+w3+8))
for r in rows:
    print(f"{r[0]:<{w0}}  {r[1]:<{w1}}  {r[2]:<{w2}}  {r[3]:<{w3}}  {r[4]}")
print(f"\n[OUT] Tableau complet : {summary}")
