# tools/diag_fig02_input.py
from pathlib import Path
import pandas as pd

p = Path("zz-out/chapter09/fig02_input.csv")
if not p.exists():
    print("[INFO] zz-out/chapter09/fig02_input.csv absent")
    raise SystemExit(0)
df = pd.read_csv(p)
print("[INFO] Colonnes:", list(df.columns))
print(df.head(5).to_string(index=False))
