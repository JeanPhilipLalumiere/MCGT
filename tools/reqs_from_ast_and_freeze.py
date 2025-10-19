#!/usr/bin/env python3
import json, re
from collections import Counter, defaultdict
from pathlib import Path

AST_JSON = Path(".ci-out/scan/ast_scan_summary.json")
FREEZE   = Path(".ci-out/scan/pip_freeze.txt")
OUT_MAIN = Path(".ci-out/scan/requirements-deduced-v2.txt")
OUT_UNM  = Path(".ci-out/scan/requirements-unmatched.txt")
OUT_RPT  = Path(".ci-out/scan/requirements-report.txt")

if not AST_JSON.exists():
    raise SystemExit(f"Missing {AST_JSON}")
if not FREEZE.exists():
    raise SystemExit(f"Missing {FREEZE} (run your env export / pip freeze first)")

data = json.loads(AST_JSON.read_text(encoding="utf-8"))

# 1) Collecte des imports (racines)
freq = Counter()
for f in data.get("files", []):
    for m in f.get("imports", []):
        freq[m.split(".")[0]] += 1
    for m in f.get("froms", []):
        freq[m.split(".")[0]] += 1

# 2) Liste stdlib (blacklist grossie)
stdlib = set("""
__future__ abc argparse array ast asynchat asyncore base64 binascii bisect builtins
bz2 calendar collections concurrent contextlib copy csv dataclasses datetime dbm decimal
difflib dis enum errno faulthandler fnmatch functools gc getopt getpass gettext glob gzip
hashlib heapq hmac html http imaplib importlib inspect io ipaddress itertools json
keyword linecache locale logging lzma math mmap multiprocessing numbers operator os
pathlib pdb pickle pkgutil platform plistlib poplib posix pprint profile pstats pty pwd
queue random re readline resource sched secrets select shelve shlex shutil signal site
smtplib socket sqlite3 sre_compile sre_parse stat statistics string struct subprocess
sys tempfile textwrap threading time timeit traceback types typing unicodedata urllib
uuid warnings wave weakref webbrowser xml zipfile zlib email xmlrpc ssl
""".split())

# 3) Nuisances/Faux-positifs fréquents (noms génériques, internes, etc.)
noise = set("""
util utils base core models packages compat common _common _compat _internal_utils
console style text table api control live status screen palette theme syntax
structs structs2 segment measure align cells panel color colorsys pretty padding
terminal_theme highlighter mpl_toolkits _parser _implementation _types _version
""".split())

# 4) Mapping import_root -> package PyPI
MAP = {
    "yaml":"PyYAML", "PIL":"Pillow", "sklearn":"scikit-learn", "cv2":"opencv-python",
    "bs4":"beautifulsoup4", "IPython":"ipython", "matplotlib":"matplotlib",
    "numpy":"numpy", "pandas":"pandas", "scipy":"scipy", "pytest":"pytest",
    "jupyter":"jupyter", "notebook":"notebook", "json5":"json5", "httpx":"httpx",
    "httpcore":"httpcore", "black":"black", "nbformat":"nbformat", "nbconvert":"nbconvert",
    "tqdm":"tqdm", "click":"click", "jinja2":"Jinja2", "sqlalchemy":"SQLAlchemy",
    "h5py":"h5py", "matplotlib_inline":"matplotlib-inline", "dateutil":"python-dateutil",
    "importlib_metadata":"importlib-metadata", "lxml":"lxml", "ujson":"ujson",
    "OpenSSL":"pyOpenSSL",
    # Projets/domaines vus dans ton repo:
    "lalsimulation":"lalsuite", "lal":"lalsuite", "pycbc":"pycbc",
    "zz_tools":"zz-tools", "mcgt":"mcgt",  # si packagés
}

# 5) Normalisation freezenames -> canon
def norm_name(s: str) -> str:
    s = s.strip()
    s = re.split(r"==|@|;| \(|\[", s, maxsplit=1)[0]  # avant extras/versions
    return s.strip().lower().replace("_","-")

freeze_names = {}
for line in FREEZE.read_text(encoding="utf-8").splitlines():
    line=line.strip()
    if not line or line.startswith(("#","-e ")): 
        # garde les -e <path> aussi: essaye d'en extraire le nom si forme egg
        if line.startswith("-e ") and "#egg=" in line:
            name = line.split("#egg=",1)[1].strip()
            freeze_names[norm_name(name)] = name
        continue
    name = norm_name(line)
    # conserve la forme originale la plus lisible
    freeze_names.setdefault(name, line.split("==")[0])

# 6) Filtrage + mapping
cand = []
for root, count in freq.most_common():
    if not root or len(root)<=1: 
        continue
    if root in stdlib or root in noise:
        continue
    pkg = MAP.get(root, root)
    cand.append((pkg, count, root))

# agrège par package PyPI cible
agg = defaultdict(lambda: {"count":0,"roots":set()})
for pkg, count, root in cand:
    agg[pkg]["count"] += count
    agg[pkg]["roots"].add(root)

# 7) Intersecte avec pip_freeze
present = []
missing = []
freeze_set = set(freeze_names.keys())
for pkg, info in agg.items():
    key = norm_name(pkg)
    if key in freeze_set:
        present.append((pkg, info["count"], sorted(info["roots"])))
    else:
        missing.append((pkg, info["count"], sorted(info["roots"])))

# 8) Sorties
present.sort(key=lambda t: (-t[1], t[0].lower()))
missing.sort(key=lambda t: (-t[1], t[0].lower()))

# fichier principal: un par ligne (trié par usage)
OUT_MAIN.parent.mkdir(parents=True, exist_ok=True)
OUT_MAIN.write_text("\n".join([p for p,_,_ in present]) + "\n", encoding="utf-8")

# unmatched
OUT_UNM.write_text(
    "\n".join([f"{p}  # from imports: {','.join(r)} (freq={c})" for p,c,r in missing]) + "\n",
    encoding="utf-8"
)

# petit rapport
def fmt(lst):
    return "\n".join([f"{p:30s}  freq={c:4d}  roots={','.join(r)}" for p,c,r in lst]) or "(none)"

OUT_RPT.write_text(
    "== Present in freeze ==\n" + fmt(present) + 
    "\n\n== Missing from freeze ==\n" + fmt(missing) + "\n",
    encoding="utf-8"
)

print(f"Wrote {OUT_MAIN}")
print(f"Wrote {OUT_UNM}")
print(f"Wrote {OUT_RPT}")
print("\nTop present:\n" + "\n".join([p for p,_,_ in present[:40]]))
