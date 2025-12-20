#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def update_manifest(path: Path, name: str, version: str) -> None:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    project = data.get("project", {})
    if name:
        project["name"] = name
    project["version"] = version
    data["project"] = project

    # On ne touche pas aux autres champs (manifest_version, entries, etc.)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(
        f"[OK] Mis à jour {path} → project.name={project.get('name')}, project.version={project.get('version')}"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--version", required=True, help="Nouvelle version de projet (ex: 0.2.99)"
    )
    parser.add_argument(
        "--name",
        default=None,
        help="Nom du projet (ex: mcgt-core). Laisse vide pour ne pas changer.",
    )
    args = parser.parse_args()

    root = Path(".")
    targets = [
        root / "zz-manifests" / "manifest_master.json",
        root / "zz-manifests" / "manifest_publication.json",
    ]

    for path in targets:
        if path.exists():
            update_manifest(path, args.name, args.version)
        else:
            print(f"[WARN] Fichier manquant, ignoré: {path}")


if __name__ == "__main__":
    main()
