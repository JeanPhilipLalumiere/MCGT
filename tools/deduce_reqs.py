#!/usr/bin/env python3
import json,sys
from collections import Counter, defaultdict
from pathlib import Path

AST_JSON = Path(".ci-out/scan/ast_scan_summary.json")
OUT = Path(".ci-out/scan/requirements-deduced.txt")
if not AST_JSON.exists():
    print("Missing", AST_JSON)
    sys.exit(1)

data = json.loads(AST_JSON.read_text(encoding='utf-8'))
imports_counter = Counter()
for p in data.get("files",[]):
    for m in p.get("imports",[]):
        imports_counter[m]+=1
    for m in p.get("froms",[]):
        imports_counter[m]+=1

# small heuristic mapping import_name -> pypi_name (extend as needed)
MAPPING = {
    "yaml":"PyYAML",
    "PIL":"Pillow",
    "sklearn":"scikit-learn",
    "cv2":"opencv-python",
    "bs4":"beautifulsoup4",
    "IPython":"ipython",
    "matplotlib":"matplotlib",
    "numpy":"numpy",
    "pandas":"pandas",
    "scipy":"scipy",
    "pytest":"pytest",
    "jupyter":"jupyter",
    "notebook":"notebook",
    "json5":"json5",
    "httpx":"httpx",
    "httpcore":"httpcore",
    "black":"black",
    "nbformat":"nbformat",
    "nbconvert":"nbconvert",
    "tqdm":"tqdm",
    "click":"click",
    "jinja2":"Jinja2",
    "sqlalchemy":"SQLAlchemy",
    "h5py":"h5py",
    "matplotlib_inline":"matplotlib-inline",
    "dateutil":"python-dateutil",
    "importlib_metadata":"importlib-metadata",
    "PIL.Image":"Pillow",
    "lxml":"lxml",
    "zipp":"zipp",
}

reqs = []
for name,count in imports_counter.most_common():
    if name in ("__future__","typing","types","builtins","os","sys","io","math","pathlib","json","re","functools","itertools","collections","logging","subprocess","time","datetime","csv","gzip","shutil","tempfile","stat","pickle","base64"):
        continue
    pkg = MAPPING.get(name, name)
    reqs.append((count,pkg))

# collapse duplicates by pkg and sum counts
agg = {}
for c,pkg in reqs:
    agg[pkg]=agg.get(pkg,0)+c

out_lines = []
for pkg,count in sorted(agg.items(), key=lambda t: -t[1]):
    out_lines.append(pkg)

OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text("\n".join(out_lines)+"\n", encoding='utf-8')
print("Wrote deduced requirements to", OUT)
print("Top 40 deduced:")
print("\n".join(out_lines[:40]))
