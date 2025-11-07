#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = sorted(
    p for p in (ROOT/"zz-scripts").rglob("*.py")
    if "/_common/" in str(p).replace("\\","/") or "/chapter" in str(p).replace("\\","/")
)
SKIP_PAT = re.compile(r"^(_attic_untracked|_autofix_sandbox|release_zenodo_codeonly)/")

RX_PARSER_LINE = re.compile(r'(^\s*)(\w+)\s*=\s*argparse\.ArgumentParser\(')
RX_BAD_DESC    = re.compile(r'ArgumentParser\(\s*description\s*=\s*"(.*?)",\s*--', re.S)
RX_BAD_OPT     = re.compile(r'--([a-zA-Z0-9_\-]+)"')   # guillemet collé à une option
RX_ADD_COMMON  = re.compile(r'^\s*add_common_plot_args\s*\(\s*(\w+)\s*\)\s*$', re.M)
RX_IMPORT_CLI  = re.compile(r'^\s*from\s+_common\.cli\s+import\s+add_common_plot_args\s*,\s*finalize_plot_from_args\s*,\s*init_logging\s*$', re.M)

def fix_file(path: Path) -> tuple[bool, str]:
    src = path.read_text(encoding="utf-8", errors="replace")
    orig = src

    # 0) inject import line once at top (après imports existants) si nécessaire
    if not RX_IMPORT_CLI.search(src):
        # place après derniers imports std
        lines = src.splitlines(True)
        insert_at = 0
        for i,l in enumerate(lines[:50]):
            if l.startswith("import ") or l.startswith("from "):
                insert_at = i+1
        lines.insert(insert_at, "from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging\n")
        src = "".join(lines)

    # 1) corriger les ArgumentParser(description=..., --opt") cassés
    def _fix_desc(m):
        # convertit  (... description="(autofix)",--results", required=True ...)
        s = m.group(0)
        s = s.replace('",--', '", ')  # sépare la description de l'option
        return s
    src = RX_BAD_DESC.sub(_fix_desc, src)
    src = RX_BAD_OPT.sub(lambda m: f'--{m.group(1)}', src)

    # 2) s'assurer que add_common_plot_args(parser) suit la création du parser
    m = RX_PARSER_LINE.search(src)
    if m:
        indent, var = m.group(1), m.group(2)
        # s'il existe un add_common... isolé ailleurs, on le retire et on le réinsère au bon endroit
        src_wo = RX_ADD_COMMON.sub("", src)
        # insérer juste après la première ligne qui crée le parser (en fin de bloc continu de config parser)
        lines = src_wo.splitlines(True)
        i_start = None
        for i,l in enumerate(lines):
            if RX_PARSER_LINE.match(l):
                i_start = i
                break
        if i_start is not None:
            i_end = i_start+1
            # étendre jusqu'au premier 'args =' ou 'return parser' ou ligne vide majeure
            RX_STOP = re.compile(r'^\s*(args\s*=|return\s+'+re.escape(var)+r'\b|if\s+__name__\s*==)')
            while i_end < len(lines) and not RX_STOP.match(lines[i_end]):
                i_end += 1
            lines.insert(i_end, f"{indent}add_common_plot_args({var})\n")
            src = "".join(lines)

    # 3) Si aucun parser trouvé & présence d’un appel add_common, encapsuler dans get_parser()
    if ('ArgumentParser(' not in src) and RX_ADD_COMMON.search(orig):
        wrapper = (
            "\n\ndef get_parser():\n"
            "    import argparse\n"
            "    p = argparse.ArgumentParser()\n"
            "    add_common_plot_args(p)\n"
            "    return p\n"
            "\nif __name__ == '__main__':\n"
            "    ap = get_parser(); args = ap.parse_args(); pass\n"
        )
        src = RX_ADD_COMMON.sub("", src) + wrapper

    changed = (src != orig)
    return changed, src

def main(dry=True):
    fixed = 0
    for p in TARGETS:
        rp = p.relative_to(ROOT).as_posix()
        if SKIP_PAT.match(rp):
            continue
        try:
            changed, new = fix_file(p)
            if changed:
                if dry:
                    print(f"PATCH {rp}")
                else:
                    p.write_text(new, encoding="utf-8")
                    print(f"WROTE {rp}")
                    fixed += 1
        except Exception as e:
            print(f"ERR   {rp} :: {e}")
    print(f"Done. {'(dry-run)' if dry else f'fixed={fixed}'}")

if __name__ == "__main__":
    dry = True
    if len(sys.argv) > 1 and sys.argv[1] == "--write":
        dry = False
    main(dry=dry)
