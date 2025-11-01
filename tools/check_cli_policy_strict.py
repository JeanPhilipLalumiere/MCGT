#!/usr/bin/env python3
import re, sys, glob

ROOTS = [
    "zz-scripts/chapter%02d/*.py" % i for i in range(1,11)
]

RE_BEGIN_COL1 = re.compile(r'^# === MCGT:CLI-SHIM-BEGIN ===\s*$', re.M)
RE_END_COL1   = re.compile(r'^# === MCGT:CLI-SHIM-END ===\s*$',   re.M)
RE_PARSE_KNOWN= re.compile(r'parse_known_args\s*\(', re.M)
RE_EXPORT     = re.compile(r'^\s*MCGT_CLI\s*=\s*_mcgt_cli_shim_parse_known\(\)', re.M)

def check(path):
    txt = open(path, 'r', encoding='utf-8', errors='ignore').read()
    probs = []
    if "MCGT:CLI-SHIM-BEGIN" in txt:
        if not RE_BEGIN_COL1.search(txt):
            probs.append("shim_begin_not_col1")
        if not RE_END_COL1.search(txt):
            probs.append("shim_end_missing_or_not_col1")
        if not RE_PARSE_KNOWN.search(txt):
            probs.append("parse_known_args_missing")
        if not RE_EXPORT.search(txt):
            probs.append("MCGT_CLI_export_missing")
    else:
        # Pas de shim -> on force la policy: doit exposer les 6 flags via un shim
        probs.append("shim_missing")
    return probs

def main():
    files = []
    for pat in ROOTS:
        files.extend(glob.glob(pat))
    files = sorted(set(files))
    bad = []
    for f in files:
        p = check(f)
        if p:
            bad.append((f, p))
    if bad:
        print("CLI strict policy violations:")
        for f, tags in bad:
            print(f" - {f}: " + ", ".join(tags))
        sys.exit(1)
    print("[OK] CLI strict policy (colonne 1 + parse_known + export)")

if __name__ == "__main__":
    main()
