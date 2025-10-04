#!/usr/bin/env python3
import os
import pathlib

OUT = pathlib.Path(".ci-out/frontmatter_samples.txt")
OUT.parent.mkdir(parents=True, exist_ok=True)


def extract_fm(path: pathlib.Path):
    fm = []
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as f:
            first = f.readline()
            if not first.strip().startswith("---"):
                return None
            fm.append(first)
            for line in f:
                fm.append(line)
                if line.strip().startswith("---"):
                    break
    except Exception:
        return None
    return "".join(fm)


def main():
    roots = []
    for root, _, files in os.walk("."):
        for name in files:
            if name.lower().endswith(".md"):
                roots.append(pathlib.Path(root, name))
    roots.sort()
    count = 0
    with OUT.open("w", encoding="utf-8") as out:
        for p in roots:
            if count >= 3:
                break
            fm = extract_fm(p)
            if fm:
                out.write(f">>> {p.as_posix()}\n{fm}\n")
                count += 1
    print(f"[frontmatter] wrote samples to {OUT}")


if __name__ == "__main__":
    main()
