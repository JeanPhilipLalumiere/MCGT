#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import hashlib

EXCLUDES = (
    ".git/",
    ".ci-out/",
    "__pycache__/",
    ".github/",
    ".venv/",
    ".mypy_cache/",
    ".pytest_cache/",
)


def is_excluded(p):
    ps = p.replace("\\", "/") + ("/" if os.path.isdir(p) else "")
    return any(x in ps for x in EXCLUDES)


def git_ls_files(roots):
    try:
        cmd = ["git", "ls-files"] + roots
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
        return [l.strip() for l in out.splitlines() if l.strip()]
    except Exception:
        return None


def walk_files(roots):
    out = []
    for root in roots:
        for r, dnames, fnames in os.walk(root):
            dnames[:] = [d for d in dnames if not is_excluded(os.path.join(r, d))]
            for fn in fnames:
                p = os.path.join(r, fn)
                if not is_excluded(p):
                    out.append(os.path.relpath(p))
    return out


def sha256_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="zz-manifests/manifest_master.json")
    ap.add_argument(
        "--roots",
        nargs="*",
        default=[
            "zz-data",
            "zz-figures",
            "zz-scripts",
            "chapters",
            "chapter01",
            "chapter02",
            "chapter03",
            "chapter04",
            "chapter05",
            "chapter06",
            "chapter07",
            "chapter08",
            "chapter09",
            "chapter10",
            "tools",
        ],
    )
    ap.add_argument("--sha", action="store_true", help="inclure sha256")
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    files = git_ls_files(args.roots)
    if files is None:
        files = walk_files(args.roots)
    files = [f for f in files if os.path.exists(f)]

    entries = []
    for p in files:
        ent = {"path": p}
        if args.sha:
            try:
                ent["sha256"] = sha256_of(p)
            except Exception:
                # ignore errors de lecture
                pass
        entries.append(ent)

    doc = {"schemaVersion": 1, "generatedAt": "__LOCAL__", "files": entries}
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
    print(f"[OK] manifest écrit: {args.out} ({len(entries)} fichiers)")


if __name__ == "__main__":
    main()
