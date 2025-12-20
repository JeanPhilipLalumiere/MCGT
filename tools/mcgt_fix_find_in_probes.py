#!/usr/bin/env python3
from pathlib import Path

TARGETS = [
    Path("tools/mcgt_probe_packages_v1.sh"),
    Path("tools/mcgt_probe_manifests_v1.sh"),
]


def rewrite_line(line: str):
    # On préserve l'indentation
    stripped = line.lstrip()
    indent = line[: len(line) - len(stripped)]

    if not stripped.startswith("find "):
        return line, False

    tokens = stripped.split()
    # Si pas de -maxdepth/-mindepth, on ne touche pas
    if "-maxdepth" not in tokens and "-mindepth" not in tokens:
        return line, False

    # Schéma: find <paths...> <options...>
    # On considère que tout ce qui suit "find" jusqu'au premier "-..." est un chemin.
    paths = []
    i = 1
    n = len(tokens)
    while i < n and not tokens[i].startswith("-"):
        paths.append(tokens[i])
        i += 1

    global_opts = []
    rest = []
    while i < n:
        t = tokens[i]
        if t in ("-maxdepth", "-mindepth") and i + 1 < n:
            # On regroupe option + valeur comme "global option"
            global_opts.extend([t, tokens[i + 1]])
            i += 2
        else:
            rest.append(t)
            i += 1

    new_tokens = ["find"] + paths + global_opts + rest
    new_line = indent + " ".join(new_tokens) + "\n"

    changed = new_line != line
    return new_line, changed


def fix_file(path: Path):
    if not path.exists():
        print(f"[WARN] Fichier introuvable, ignoré: {path}")
        return

    original_lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    new_lines = []
    changed_any = False

    for line in original_lines:
        new_line, changed = rewrite_line(line)
        if changed:
            changed_any = True
        new_lines.append(new_line)

    if not changed_any:
        print(f"[OK] Aucun changement nécessaire dans {path}")
        return

    backup = path.with_suffix(path.suffix + ".bak_autofix_find")
    backup.write_text("".join(original_lines), encoding="utf-8")
    path.write_text("".join(new_lines), encoding="utf-8")
    print(f"[OK] {path} corrigé (backup: {backup})")


def main():
    for p in TARGETS:
        fix_file(p)


if __name__ == "__main__":
    main()
