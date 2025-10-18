#!/usr/bin/env python3
from pathlib import Path
import re

TARGETS = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

# Attributs requis et leurs défauts
REQ = {
    "plot_fig03b_bootstrap_coverage_vs_n.py": [("p95_col", "None")],
    "plot_fig06_residual_map.py": [("m1_col", "'phi0'"), ("m2_col", "'phi_ref_fpeak'")],
}

# Repères des anciens blocs v2 (à supprimer proprement)
TAG_START = "# --- cli post-parse backfill (auto v2) ---"
TAG_END   = "# --- end cli post-parse backfill (auto v2) ---"

# parse patterns
RE_PARSE_ARGS  = re.compile(r'^\s*([A-Za-z_]\w*)\s*=\s*.+?\.parse_args\s*\(', re.M)
RE_PARSE_KNOWN = re.compile(r'^\s*([A-Za-z_]\w*)\s*,\s*[A-Za-z_]\w*\s*=\s*.+?\.parse_known_args\s*\(', re.M)

def strip_old_backfills(lines):
    out, i, changed = [], 0, False
    while i < len(lines):
        if lines[i].lstrip().startswith(TAG_START):
            j = i + 1
            while j < len(lines) and not lines[j].lstrip().startswith(TAG_END):
                j += 1
            if j < len(lines):
                j += 1  # inclure la ligne TAG_END
                changed = True
                i = j
                continue
        out.append(lines[i]); i += 1
    return out, changed

def byte_offsets(lines):
    offs = [0]
    total = 0
    for s in lines:
        total += len(s)
        offs.append(total)
    return offs

def pos_to_line(offs, pos):
    # recherche binaire simple
    lo, hi = 0, len(offs)-1
    while lo < hi:
        mid = (lo+hi)//2
        if offs[mid] <= pos < offs[mid+1]:
            return mid
        if pos < offs[mid]:
            hi = mid
        else:
            lo = mid + 1
    return max(0, min(len(offs)-2, lo))

def build_block(indent, args_var, attrs):
    # Bloc **indenté comme la ligne parse** et lisant sys.argv si présent
    lines = []
    ind = indent
    ind2 = indent + "    "
    ind3 = ind2 + "    "

    lines.append(ind + TAG_START + "\n")
    lines.append(ind + "import sys as _sys  # backfill\n")
    for (attr, pyval) in attrs:
        flag = "--" + attr.replace("_", "-")
        lines.append(ind + "try:\n")
        lines.append(ind2 + f"{args_var}.{attr}\n")
        lines.append(ind + "except AttributeError:\n")
        lines.append(ind2 + "_val = None\n")
        lines.append(ind2 + "for _j, _a in enumerate(_sys.argv):\n")
        lines.append(ind3 + f"if _a == '{flag}' and _j + 1 < len(_sys.argv):\n")
        lines.append(ind3 + "    _val = _sys.argv[_j + 1]\n")
        lines.append(ind3 + "    break\n")
        lines.append(ind2 + "if _val is None:\n")
        lines.append(ind3 + f"{args_var}.{attr} = {pyval}\n")
        lines.append(ind2 + "else:\n")
        lines.append(ind3 + f"{args_var}.{attr} = _val\n")
    lines.append(ind + TAG_END + "\n")
    return lines

def process_file(p: Path):
    src = p.read_text(encoding="utf-8")
    lines = src.splitlines(True)

    # 1) enlever nos anciens backfills v2 si présents
    lines, _ = strip_old_backfills(lines)
    text = "".join(lines)

    # 2) repérer toutes les lignes parse_* et préparer insertion
    matches = []
    for m in RE_PARSE_ARGS.finditer(text):
        matches.append((m.start(), m.group(1)))
    for m in RE_PARSE_KNOWN.finditer(text):
        matches.append((m.start(), m.group(1)))
    matches.sort()

    # 3) si on n'a rien trouvé, on laisse le fichier tel quel (on ne re-changera pas la structure globale)
    if not matches:
        print(f"[SKIP] {p.name}: aucun parse_args/parse_known_args détecté (rien fait).")
        return

    # 4) construire offsets pour convertir byte->ligne
    offs = byte_offsets(lines)

    # 5) insérer (du bas vers le haut pour garder des indices valides)
    req = REQ.get(p.name, [])
    changed = False
    for pos, args_var in reversed(matches):
        li = pos_to_line(offs, pos)
        # indentation de la ligne parse
        leading = lines[li][:len(lines[li]) - len(lines[li].lstrip())]
        block = build_block(leading, args_var, req)
        # idempotence locale : si tout de suite après on a déjà notre TAG, on saute
        if li + 1 < len(lines) and lines[li+1].lstrip().startswith(TAG_START):
            continue
        lines[li+1:li+1] = block
        changed = True

    if changed:
        bak = p.with_suffix(p.suffix + ".bak_cli_v2_fix")
        if not bak.exists():
            bak.write_text(src, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
        print(f"[FIXED] {p.name}: backfill ré-inséré avec indentation correcte.")
    else:
        print(f"[OK] {p.name}: rien à changer (déjà corrigé).")

def main():
    for f in TARGETS:
        if f.exists():
            process_file(f)
        else:
            print(f"[MISS] {f}")

if __name__ == "__main__":
    main()
