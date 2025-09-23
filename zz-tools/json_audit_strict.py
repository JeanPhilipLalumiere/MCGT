import os
import json
import re
import sys

bad = 0
html = re.compile(r"<[A-Za-z][^>]*>")
for root, _, files in os.walk("."):
    for fn in files:
        if not fn.endswith(".json"):
            continue
        p = os.path.join(root, fn)
        try:
            txt = open(p, "r", encoding="utf-8").read()
            obj = json.loads(txt)
            if not txt.strip() or obj in ({}, []):
                print("WARN empty-ish:", p)
                bad += 1
            if html.search(txt):
                print("WARN html-like:", p)
                bad += 1
        except Exception as e:
            print("ERR invalid JSON:", p, "->", e)
            bad += 1
sys.exit(1 if bad else 0)
