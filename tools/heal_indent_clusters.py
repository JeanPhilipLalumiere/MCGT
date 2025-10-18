#!/usr/bin/env python3
import argparse, json, re
from pathlib import Path

REPORT = Path("zz-manifests/indent_failures.json")

HEADERS = re.compile(r"^\s*(def |class |if |for |while |except|else:|elif |finally:)")
SAFE_LINE = re.compile(r"^\s*(try:|if\s+args[.\[]|args\s*=\s*parse_args\(|args\s*=\s*ensure_std_args\()")

def indent_of(s: str) -> int:
    s = s.replace("\t", "    ")
    return len(s) - len(s.lstrip(" "))

def set_indent(s: str, n: int) -> str:
    body = s.lstrip(" \t")
    return (" " * n) + body

def prev_sig(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def next_sig(lines, i):
    j = i + 1
    while j < len(lines) and lines[j].strip() == "":
        j += 1
    return j if j < len(lines) else None

def expand_block_until_boundary(lines, start_idx, base_indent):
    """
    Indente à base+4 la première ligne et poursuit sur les lignes contiguës
    tant que l’on ne rencontre pas une frontière claire (ligne vide, header,
    ou dé-dent à <= base_indent).
    """
    changed = 0
    i = start_idx
    while i < len(lines):
        s = lines[i]
        if s.strip() == "":
            break
        if HEADERS.match(s):
            break
        cur = indent_of(s)
        if cur <= base_indent:
            # Cette ligne appartient au parent → on s'arrête
            break
        # Sinon, on plaque à base+4 (multiple de 4)
        new = set_indent(s, base_indent + 4)
        if new != s:
            lines[i] = new
            changed += 1
        i += 1
    return changed

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", nargs="*", help="paths à cibler (sinon tous du report)")
    args = ap.parse_args()

    data = json.loads(REPORT.read_text(encoding="utf-8"))
    grouped = {}
    for r in data:
        grouped.setdefault(r["path"], []).append(r)
    total_changes = 0

    for path, errs in grouped.items():
        p = Path(path)
        if args.only and path not in args.only:
            continue
        try:
            lines = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)
        except Exception:
            continue

        changed_here = 0

        for r in errs:
            msg, lineno = r.get("msg",""), int(r["lineno"])
            i = lineno - 1
            if i < 0 or i >= len(lines):
                continue
            s = lines[i]

            # (1) unexpected indent → dé-dent à la base précédente si ligne "sûre"
            if r["type"] == "SyntaxError" and msg == "unexpected indent":
                if SAFE_LINE.match(s):
                    j = prev_sig(lines, i)
                    base = indent_of(lines[j]) if j is not None else 0
                    new = set_indent(s, base)
                    if new != s:
                        lines[i] = new
                        changed_here += 1
                        # si la ligne se termine par ":" → on s'assure que le bloc suivant est à base+4
                        if s.strip().endswith(":"):
                            k = next_sig(lines, i)
                            if k is not None:
                                changed_here += expand_block_until_boundary(lines, k, base)

            # (2) unindent mismatch → normalise en multiples de 4 ; si précédent finit par ":", plaque à base+4
            if r["type"] == "IndentationError" and "unindent does not match" in msg:
                j = prev_sig(lines, i)
                base = indent_of(lines[j]) if j is not None else 0
                prev_ends_colon = j is not None and lines[j].rstrip().endswith(":")
                target = base + 4 if prev_ends_colon else max(0, base)
                new = set_indent(s, target - (target % 4))
                if new != s:
                    lines[i] = new
                    changed_here += 1

            # (3) expected an indented block → indenter les lignes suivantes contiguës
            if r["type"] == "SyntaxError" and msg.startswith("expected an indented block"):
                base = indent_of(lines[i-1]) if i-1 >= 0 else 0
                k = next_sig(lines, i)
                if k is not None:
                    # on force la 1re ligne à base+4 puis on étend
                    lines[k] = set_indent(lines[k], base + 4)
                    changed_here += 1 + expand_block_until_boundary(lines, k+1, base)

        if changed_here:
            if not args.apply:
                print(f"[DRY] {p} changes={changed_here}")
            else:
                bak = p.with_suffix(p.suffix + ".bak_heal_indent")
                if not bak.exists():
                    bak.write_text("".join(lines), encoding="utf-8")  # backup pre-change
                # ATTENTION : on ré-écrit depuis le contenu modifié
                p.write_text("".join(lines), encoding="utf-8")
                print(f"[APPLY] {p} changes={changed_here}")
            total_changes += changed_here

    print(f"[SUMMARY] total_changes={total_changes} apply={args.apply}")

if __name__ == "__main__":
    main()
