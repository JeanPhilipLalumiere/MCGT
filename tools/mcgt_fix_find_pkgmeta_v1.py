#!/usr/bin/env python3
import datetime
import pathlib
import shutil
import sys


def main() -> int:
    root = pathlib.Path(".").resolve()
    target = root / "tools" / "mcgt_probe_packages_v1.sh"

    if not target.exists():
        print(f"[ERREUR] Fichier introuvable: {target}", file=sys.stderr)
        return 1

    text = target.read_text(encoding="utf-8").splitlines(keepends=True)

    pattern_fragment = 'find "$d" -maxdepth 2 -mindepth 1 -maxdepth 2 -mindepth 1 -type d -o -type f | sort'
    replacement_fragment = 'find "$d" -maxdepth 2 -mindepth 1 -print | sort'

    changed = False
    new_lines = []

    for line in text:
        stripped = line.lstrip()
        if pattern_fragment in stripped:
            indent = line[: len(line) - len(stripped)]
            new_line = indent + replacement_fragment + "\n"
            print("[INFO] Ligne trouvée et corrigée dans mcgt_probe_packages_v1.sh :")
            print("  OLD:", stripped.rstrip())
            print("  NEW:", replacement_fragment)
            new_lines.append(new_line)
            changed = True
        else:
            new_lines.append(line)

    if not changed:
        print("[OK] Aucun changement à appliquer dans tools/mcgt_probe_packages_v1.sh")
        return 0

    stamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%SZ")
    backup = target.with_suffix(target.suffix + f".bak_fixfind_{stamp}")
    shutil.copy2(target, backup)
    print(f"[INFO] Sauvegarde créée : {backup}")

    target.write_text("".join(new_lines), encoding="utf-8")
    print("[OK] tools/mcgt_probe_packages_v1.sh mis à jour.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
