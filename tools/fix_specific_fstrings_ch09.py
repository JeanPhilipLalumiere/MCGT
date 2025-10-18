#!/usr/bin/env python3
import re, sys
from pathlib import Path

def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore")
    # Target the French message with empty placeholder
    new = re.sub(r'f(\")Aucun fichier d\'entrée:\s*\{\}(\")',
                 r'f\1Aucun fichier d\'entrée: {args.csv}\2', L)
    new = re.sub(r"f(\')Aucun fichier d'entrée:\s*\{\}(\')",
                 r"f\1Aucun fichier d'entrée: {args.csv}\2", new)
    if new != L:
        p.write_text(new, encoding="utf-8")
        print("[FIX] inserted {args.csv} in French f-string for", p)
        return True
    print("[OK] French f-string already fine in", p)
    return False

if __name__ == "__main__":
    for a in sys.argv[1:]: process(Path(a))
