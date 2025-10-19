#!/usr/bin/env python3
import subprocess, sys, re, pathlib, datetime
YEAR = "2025"
COPY = f"Copyright (c) {YEAR} MCGT Authors"
SPDX = "SPDX-License-Identifier: MIT"
TOP = [f"# {COPY}", f"# {SPDX}"]

def tracked(globs):
    out = subprocess.check_output(["git","ls-files","--"]+globs, text=True).splitlines()
    return [pathlib.Path(p) for p in out if p.strip()]

def has_header(txt):
    head = "\n".join(TOP)
    return head in txt or SPDX in txt

def apply_file(p: pathlib.Path):
    try:
        s = p.read_text(encoding="utf-8")
    except Exception:
        return
    if has_header(s):
        return
    if p.suffix==".py":
        new = "\n".join(TOP) + "\n" + s
    elif p.suffix==".sh":
        # Respect shebang sur la 1re ligne
        lines = s.splitlines()
        if lines and lines[0].startswith("#!"):
            new = lines[0] + "\n" + "\n".join(TOP) + "\n" + "\n".join(lines[1:]) + ("\n" if not s.endswith("\n") else "")
        else:
            new = "\n".join(TOP) + "\n" + s
    else:
        return
    p.write_text(new, encoding="utf-8")

def main():
    files = set(tracked(["*.py"])) | set(tracked(["tools/*.sh","*.sh"]))
    for p in files:
        apply_file(p)
    print(f"Processed {len(files)} files.")
if __name__=="__main__":
    main()
