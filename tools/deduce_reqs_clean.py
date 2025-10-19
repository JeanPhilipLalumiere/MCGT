#!/usr/bin/env python3
import json
from collections import Counter
from pathlib import Path
AST_JSON = Path(".ci-out/scan/ast_scan_summary.json")
OUT = Path(".ci-out/scan/requirements-deduced-clean.txt")
if not AST_JSON.exists():
    print("Missing", AST_JSON); raise SystemExit(1)
data = json.loads(AST_JSON.read_text(encoding='utf-8'))
imports = Counter()
for p in data.get("files",[]):
    for m in p.get("imports",[]):
        imports[m.split(".")[0]] += 1
    for m in p.get("froms",[]):
        imports[m.split(".")[0]] += 1

# stdlib blacklist (non-exhaustive but broad)
stdlib = set("""
__future__ abc argparse array ast asynchat asyncore base64 binascii bisect builtins
bz2 calendar collections concurrent contextlib copy csv dataclasses datetime dbm decimal
difflib dis enum errno faulthandler fnmatch functools gc getopt getpass gettext glob gzip
hashlib heapq hmac html http imaplib importlib inspect io ipaddress itertools json
keyword linecache locale logging lzma math mmap mmap multiprocessing numbers operator os
pathlib pdb pickle pkgutil platform plistlib poplib posix pprint profile pstats pty pwd
queue random re readline resource sched secrets select shelve shlex shutil signal site
smtplib socket sqlite3 sre_compile sre_parse stat statistics string struct subprocess
sys tempfile textwrap threading time timeit traceback types typing unicodedata urllib
uuid warnings wave weakref webbrowser xml zipfile zlib
""".split())

# mapping for common libraries -> pypi names
M = {
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
    "lxml":"lxml",
    "ujson":"ujson",
    "PIL":"Pillow",
}

out = []
for name,count in imports.most_common():
    if name in stdlib:
        continue
    pkg = M.get(name, name)
    # skip single-letter or clearly wrong names
    if len(name) <= 2:
        continue
    out.append((count,pkg))

# collapse duplicates
agg = {}
for c,pkg in out:
    agg[pkg]=agg.get(pkg,0)+c

lines = [pkg for pkg,_ in sorted(agg.items(), key=lambda t:-t[1])]
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_text("\n".join(lines)+"\n", encoding='utf-8')
print("Wrote cleaned deduced requirements to", OUT)
print("\n".join(lines[:50]))
