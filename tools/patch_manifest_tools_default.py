#!/usr/bin/env python3
from pathlib import Path
import re

FILES = [
    Path("zz-scripts/manifest_tools/populate_manifest.py"),
    Path("zz-scripts/manifest_tools/verify_manifest.py"),
]
DEFAULT_MAN = "zz-manifests/figure_manifest.json"

def patch_file(p: Path) -> bool:
    if not p.exists():
        return False
    src = p.read_text(encoding="utf-8")
    orig = src

    # Après args = parser.parse_args(...), injecter un garde sur args.manifest
    pat = re.compile(r"^(?P<indent>[ \t]*)args\s*=\s*parser\.parse_args\(.*?\)\s*$", re.M)
    def _inject(m):
        ind = m.group("indent")
        guard = (
            f"{m.group(0)}\n"
            f"{ind}# défaut de manifest si absent\n"
            f"{ind}import pathlib as _pl\n"
            f"{ind}if not hasattr(args, 'manifest') or not args.manifest:\n"
            f"{ind}    args.manifest = str(_pl.Path('{DEFAULT_MAN}'))\n"
        )
        return guard

    if not pat.search(src):
        return False  # rien à faire proprement
    src = pat.sub(_inject, src, count=1)

    # Si l'add_argument('--manifest'...) existe sans default=..., on ne touche pas (le garde suffit)
    if src != orig:
        p.with_suffix(p.suffix + ".bak_manifest_default").write_text(orig, encoding="utf-8")
        p.write_text(src, encoding="utf-8")
        return True
    return False

def main():
    changed = sum(patch_file(p) for p in FILES)
    print(f"[OK] manifest default guard applied in {changed} file(s)")

if __name__ == "__main__":
    main()
