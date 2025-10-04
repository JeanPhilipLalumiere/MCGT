import re
import sys
import zipfile
from pathlib import Path

ok = True
for whl in Path("dist").glob("*.whl"):
    with zipfile.ZipFile(whl) as z:
        meta = [n for n in z.namelist() if n.endswith(".dist-info/METADATA")][0]
        s = z.read(meta).decode("utf-8", "replace")
        if any(re.match(r"(?i)^license-file:", ln) for ln in s.splitlines()):
            print(f"[ERR] {whl.name}: contains License-File header")
            ok = False
sys.exit(0 if ok else 1)
