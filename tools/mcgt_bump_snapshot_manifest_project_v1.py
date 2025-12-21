#!/usr/bin/env python3
from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import shutil


ROOT = Path(__file__).resolve().parent.parent


@dataclass
class ProjectMeta:
    name: str
    version: str
    homepage: str | None = None


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def extract_project(path: Path) -> ProjectMeta:
    data = load_json(path)
    proj = data.get("project")
    if not isinstance(proj, dict):
        raise SystemExit(f"[ERROR] Pas de bloc 'project' dans {path}")
    name = proj.get("name")
    version = proj.get("version")
    homepage = proj.get("homepage", "")
    if not name or not version:
        raise SystemExit(f"[ERROR] project.name/project.version manquant dans {path}")
    return ProjectMeta(name=name, version=version, homepage=homepage)


def bump_snapshot_project(root_manifest: Path, targets: list[Path]) -> None:
    meta = extract_project(root_manifest)
    print(
        f"[INFO] project (root manifest_master) = "
        f"name={meta.name!r}, version={meta.version!r}, homepage={meta.homepage!r}"
    )

    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")

    for t in targets:
        if not t.exists():
            print(f"[WARN] snapshot manifest absent, ignoré: {t}")
            continue

        data = load_json(t)
        before = data.get("project", {})
        before_name = before.get("name")
        before_version = before.get("version")

        data["project"] = {
            "name": meta.name,
            "version": meta.version,
            "homepage": meta.homepage or "",
        }

        backup = t.with_suffix(t.suffix + ".bak_bump_snapshot_" + stamp)
        shutil.copy2(t, backup)
        print(f"[BACKUP] {t} -> {backup}")
        save_json(t, data)
        print(
            f"[OK] {t}: project.name {before_name!r} -> {meta.name!r}, "
            f"project.version {before_version!r} -> {meta.version!r}"
        )


def main() -> None:
    root_manifest = ROOT / "assets/zz-manifests" / "manifest_master.json"
    snapshot_dir = ROOT / "release_zenodo_codeonly" / "v0.3.x" / "assets/zz-manifests"

    targets = [
        snapshot_dir / "manifest_master.json",
        snapshot_dir / "manifest_publication.json",
    ]

    if not root_manifest.exists():
        raise SystemExit(f"[ERROR] Manifeste racine introuvable: {root_manifest}")
    if not snapshot_dir.exists():
        raise SystemExit(f"[ERROR] Dossier snapshot introuvable: {snapshot_dir}")

    bump_snapshot_project(root_manifest, targets)
    print("[INFO] mcgt_bump_snapshot_manifest_project_v1 terminé.")


if __name__ == "__main__":
    main()
