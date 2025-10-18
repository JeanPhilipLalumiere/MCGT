#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Link/copy legacy figures from zz-figures/_legacy_conflicts/chapterNN/fig_XX_*.{png,svg,pdf}
to canonical destinations zz-figures/chapterNN/NN_fig_XX_*.{ext}.

Usage:
  python3 tools/link_legacy_figs.py [--dry] [--copy]
  python3 tools/link_legacy_figs.py --from-plan zz-manifests/report_legacy_to_canon_plan.json
  python3 tools/link_legacy_figs.py -v

Notes:
- Par défaut on crée des symlinks *relatifs* ; utilisez --copy pour copier.
- Les fichiers avec permissions bloquées sont ignorés (log "[SKIP] permission denied").
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from pathlib import Path
from typing import List, Dict

ROOT = Path(__file__).resolve().parents[1]
LEGACY_ROOT = ROOT / "zz-figures" / "_legacy_conflicts"
TARGET_ROOT = ROOT / "zz-figures"

FIG_RE = re.compile(r"^fig_([0-9]{2})_(.+)\.(png|svg|pdf)$", re.IGNORECASE)
CH_RE = re.compile(r"^chapter([0-9]{2})$")


def _safe_lstat(p: Path):
    try:
        return p.lstat()
    except PermissionError as e:
        print(f"[SKIP] permission denied: {p} ({e})")
        return None
    except FileNotFoundError:
        print(f"[SKIP] missing source: {p}")
        return None


def _build_plan_from_fs() -> List[Dict[str, str]]:
    """Construit le plan en *sans* faire de stat/is_file sur les fichiers (évite PermissionError)."""
    plan: List[Dict[str, str]] = []
    if not LEGACY_ROOT.exists():
        return plan

    for ch_dir in sorted(LEGACY_ROOT.glob("chapter??")):
        m_ch = CH_RE.match(ch_dir.name)
        if not m_ch:
            continue
        chapter = m_ch.group(1)
        try:
            entries = list(ch_dir.iterdir())
        except PermissionError as e:
            print(f"[SKIP] permission denied listing: {ch_dir} ({e})")
            continue

        for src in sorted(entries, key=lambda p: p.name):
            # N'appelez PAS src.is_file() ici -> cela déclenche stat() et peut lever PermissionError
            m = FIG_RE.match(src.name)
            if not m:
                continue
            fig = m.group(1)
            slug = m.group(2)
            ext = m.group(3).lower()
            dst = TARGET_ROOT / f"chapter{chapter}" / f"{chapter}_fig_{fig}_{slug}.{ext}"
            plan.append({"from": str(src.relative_to(ROOT)), "to": str(dst.relative_to(ROOT))})
    return plan


def _load_plan_from_json(path: Path) -> List[Dict[str, str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "plan" in data and isinstance(data["plan"], list):
        data = data["plan"]
    if not isinstance(data, list):
        raise ValueError(f"Invalid plan file format: {path}")
    out: List[Dict[str, str]] = []
    for item in data:
        if isinstance(item, dict) and "from" in item and "to" in item:
            out.append({"from": item["from"], "to": item["to"]})
    return out


def _ensure_parent(p: Path, dry: bool):
    if not p.parent.exists():
        print(f"[MKDIR] {p.parent}")
        if not dry:
            p.parent.mkdir(parents=True, exist_ok=True)


def _rel_symlink(dst: Path, src: Path, dry: bool) -> bool:
    rel = os.path.relpath(src, dst.parent)
    print(f"[LINK] {dst} -> {rel}")
    if dry:
        return True
    try:
        dst.symlink_to(rel)
        return True
    except FileExistsError:
        return True
    except PermissionError as e:
        print(f"[SKIP] cannot create symlink {dst}: {e}")
        return False
    except OSError as e:
        print(f"[SKIP] cannot create symlink {dst}: {e}")
        return False


def _copy(dst: Path, src: Path, dry: bool) -> bool:
    print(f"[COPY] {src} -> {dst}")
    if dry:
        return True
    try:
        shutil.copy2(src, dst)
        return True
    except PermissionError as e:
        print(f"[SKIP] cannot copy to {dst}: {e}")
        return False
    except OSError as e:
        print(f"[SKIP] cannot copy to {dst}: {e}")
        return False


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true", help="Dry-run (no filesystem changes).")
    ap.add_argument("--copy", action="store_true", help="Copy files instead of creating symlinks.")
    ap.add_argument("--from-plan", type=str, default="", help="Path to a JSON plan (report_legacy_to_canon_plan.json).")
    ap.add_argument("-v", "--verbose", action="count", default=0)
    args = ap.parse_args()

    plan: List[Dict[str, str]]
    if args.from_plan:
        plan_path = Path(args.from_plan)
        if not plan_path.is_absolute():
            plan_path = ROOT / plan_path
        plan = _load_plan_from_json(plan_path)
    else:
        plan = _build_plan_from_fs()

    created = 0
    skipped = 0
    exists = 0
    missing = 0

    if not plan:
        print("[INFO] no legacy items found.")
        return

    for item in plan:
        src = (ROOT / item["from"]).resolve()
        dst = (ROOT / item["to"]).resolve()

        st = _safe_lstat(src)
        if st is None:
            missing += 1
            continue

        _ensure_parent(dst, args.dry)

        # Si la cible existe déjà, on ne tente rien
        try:
            if dst.exists():
                if args.verbose:
                    print(f"[OK] exists: {dst}")
                exists += 1
                continue
        except PermissionError as e:
            print(f"[SKIP] cannot access destination {dst}: {e}")
            skipped += 1
            continue

        ok = _copy(dst, src, args.dry) if args.copy else _rel_symlink(dst, src, args.dry)
        if ok:
            created += 1
        else:
            skipped += 1

    summary = {
        "created": created,
        "already_exists": exists,
        "missing_sources": missing,
        "skipped": skipped,
        "mode": "copy" if args.copy else "symlink",
        "dry": args.dry,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
