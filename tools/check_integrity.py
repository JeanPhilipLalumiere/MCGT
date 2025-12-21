#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

RE_SHA256 = re.compile(r"^[0-9a-f]{64}$")


def extract_entries(data):
    # Accept:
    # - list[dict]
    # - dict with key in {entries, files, items}
    if isinstance(data, list):
        return None, data
    if isinstance(data, dict):
        for k in ("entries", "files", "items"):
            v = data.get(k)
            if isinstance(v, list):
                return k, v
    return None, None


def entry_path(e: dict):
    for k in ("path", "relpath", "file", "filename"):
        v = e.get(k)
        if isinstance(v, str) and v.strip():
            return k, v
    return None, None


def main() -> int:
    try:
        repo = Path(__file__).resolve().parents[1]
        manifests = [
            repo / "assets/zz-manifests" / "manifest_master.json",
            repo / "assets/zz-manifests" / "manifest_publication.json",
        ]

        bad = 0
        for mf in manifests:
            if not mf.exists():
                print(f"[WARN] missing manifest: {mf.relative_to(repo)}")
                continue

            try:
                data = json.loads(mf.read_text(encoding="utf-8"))
            except Exception as e:
                print(f"[ERROR] invalid JSON: {mf.relative_to(repo)}: {e}")
                bad = 1
                continue

            wrapper, entries = extract_entries(data)
            if entries is None:
                top = type(data).__name__
                keys = list(data.keys()) if isinstance(data, dict) else []
                print(
                    f"[ERROR] unexpected manifest format in {mf.relative_to(repo)} (top={top}, keys={keys})"
                )
                bad = 1
                continue

            seen = set()
            for i, e in enumerate(entries):
                if not isinstance(e, dict):
                    print(f"[ERROR] {mf.name}: entry {i} is not an object")
                    bad = 1
                    continue

                pk, p = entry_path(e)
                if p is None:
                    print(f"[ERROR] {mf.name}: entry {i} missing path field")
                    bad = 1
                    continue

                if p in seen:
                    print(f"[ERROR] {mf.name}: duplicate path: {p}")
                    bad = 1
                seen.add(p)

                sha = e.get("sha256") or e.get("sha256_hex")
                if isinstance(sha, str) and sha and not RE_SHA256.match(sha):
                    print(f"[ERROR] {mf.name}: bad sha256 for {p}: {sha!r}")
                    bad = 1

            print(
                f"[OK] {mf.name}: {len(entries)} entries (wrapper={wrapper or 'list'})"
            )

        return 1 if bad else 0
    except Exception as exc:
        print(f"[FATAL] integrity check failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
# Diamond certified production build v2.3.1
