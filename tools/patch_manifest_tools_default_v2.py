#!/usr/bin/env python3
from pathlib import Path
import re

FILES = [
    Path("zz-scripts/manifest_tools/populate_manifest.py"),
    Path("zz-scripts/manifest_tools/verify_manifest.py"),
]
DEFAULT_MAN = "zz-manifests/figure_manifest.json"

def ensure_manifest_default(src: str) -> str:
    orig = src

    # (A) Si --manifest est déjà déclaré mais sans "default=", injecter le default
    pat_add = re.compile(
        r"(parser\.add_argument\(\s*(?:[^#\n]*?)(?:['\"]--manifest['\"][^)]*))\)",
        re.S
    )
    def _add_default(m):
        chunk = m.group(1)
        if "default=" in chunk:
            return m.group(0)  # déjà un default
        return chunk + f", default=\"{DEFAULT_MAN}\")"

    src = pat_add.sub(_add_default, src)

    # (B) Si --manifest n'existe pas, l'ajouter après le dernier add_argument(...)
    if "--manifest" not in src:
        # point d'insertion : dernière occurrence d'add_argument(...) ou création du parser
        last_add = [m.end() for m in re.finditer(r"parser\.add_argument\([^)]*\)\s*", src)]
        insert_at = last_add[-1] if last_add else None
        if insert_at is None:
            m = re.search(r"parser\s*=\s*argparse\.ArgumentParser\([^)]*\)\s*", src)
            insert_at = m.end() if m else 0
        line = f'\nparser.add_argument("--manifest", default="{DEFAULT_MAN}")\n'
        src = src[:insert_at] + line + src[insert_at:]

    # (C) Garde post-parse (au cas où argparse ignore default via wrapper)
    # Trouver un args = parser.parse_args(…)
    pat_parse = re.compile(r"^(?P<ind>[ \t]*)args\s*=\s*parser\.parse_args\([^)]*\)\s*$", re.M)
    def _inject_guard(m):
        ind = m.group("ind")
        guard = (
            m.group(0) + "\n" +
            f"{ind}# défaut de manifest si absent\n"
            f"{ind}if not getattr(args, 'manifest', None):\n"
            f"{ind}    args.manifest = '{DEFAULT_MAN}'\n"
        )
        return guard
    src = pat_parse.sub(_inject_guard, src, count=1)

    return src if src != orig else src

def main():
    changed = 0
    for p in FILES:
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="ignore")
        new = ensure_manifest_default(txt)
        if new != txt:
            p.with_suffix(p.suffix + ".bak_manifest_default").write_text(txt, encoding="utf-8")
            p.write_text(new, encoding="utf-8")
            changed += 1
    print(f"[OK] manifest default enforced in {changed} file(s)")

if __name__ == "__main__":
    main()
