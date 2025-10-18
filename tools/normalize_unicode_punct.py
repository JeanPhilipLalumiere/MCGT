#!/usr/bin/env python3
from pathlib import Path
import sys, re
MAP = {
    "\u2013":"-", "\u2014":"-", "\u2212":"-",
    "\u2018":"'","\u2019":"'","\u201C":'"',"\u201D":'"',
    "\u00A0":" ", "\u2009":" ", "\u202F":" ",
}
def norm_text(s): 
    for a,b in MAP.items(): s=s.replace(a,b)
    return s
def main():
    roots = ["zz-scripts"]
    changed=0
    for r in roots:
        for p in Path(r).rglob("*.py"):
            txt = p.read_text(encoding="utf-8", errors="ignore")
            new = norm_text(txt)
            if new!=txt:
                bak = p.with_suffix(p.suffix+".bak_unicode")
                if not bak.exists(): bak.write_text(txt, encoding="utf-8")
                p.write_text(new, encoding="utf-8"); changed+=1
    print(f"[OK] normalized unicode in {changed} file(s)")
if __name__=="__main__": main()
