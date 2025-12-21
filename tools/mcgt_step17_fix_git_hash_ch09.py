from __future__ import annotations

import json
import subprocess
from pathlib import Path


TARGET_PATHS = [
    "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png",
    "assets/zz-data/chapter09/09_metrics_phase.json",
]


def get_repo_root() -> Path:
    # Script attendu dans tools/, on remonte d'un niveau
    return Path(__file__).resolve().parent.parent


def get_git_hash(root: Path, rel_path: str) -> str:
    """
    Retourne le hash du dernier commit qui touche rel_path.
    """
    result = subprocess.run(
        ["git", "log", "-n", "1", "--format=%H", "--", rel_path],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True,
    )
    h = result.stdout.strip()
    if not h:
        raise SystemExit(f"[ERROR] Impossible de récupérer git hash pour {rel_path}")
    return h


def update_git_hashes_in_manifest(
    obj, path_to_hash: dict[str, str], updated_paths: set[str]
) -> None:
    """
    Parcours récursif de l'objet JSON.
    Dès qu'on trouve un dict avec 'path' ∈ path_to_hash, on met à jour 'git_hash'.
    """
    if isinstance(obj, dict):
        p = obj.get("path")
        if isinstance(p, str) and p in path_to_hash:
            new_hash = path_to_hash[p]
            old_hash = obj.get("git_hash")
            if old_hash != new_hash:
                obj["git_hash"] = new_hash
                updated_paths.add(p)
            # On continue quand même à descendre, au cas où il y ait d'autres sous-structures
        for v in obj.values():
            update_git_hashes_in_manifest(v, path_to_hash, updated_paths)

    elif isinstance(obj, list):
        for item in obj:
            update_git_hashes_in_manifest(item, path_to_hash, updated_paths)

    # autres types (str, int, etc.) -> rien à faire


def main() -> None:
    root = get_repo_root()
    manifest_path = root / "assets/zz-manifests" / "manifest_master.json"

    print(f"[INFO] Repo root           : {root}")
    print(f"[INFO] Manifest utilisé    : {manifest_path}")

    # 1) Préparer le mapping path -> git_hash (via git log)
    path_to_hash: dict[str, str] = {}
    for rel in TARGET_PATHS:
        gh = get_git_hash(root, rel)
        path_to_hash[rel] = gh
        print(f"[INFO] {rel} → git hash git = {gh}")

    # 2) Charger le manifest (peu importe sa structure interne)
    with manifest_path.open("r", encoding="utf-8") as f:
        manifest_obj = json.load(f)

    # 3) Parcours récursif et mise à jour des git_hash
    updated_paths: set[str] = set()
    update_git_hashes_in_manifest(manifest_obj, path_to_hash, updated_paths)

    if not updated_paths:
        print("[WARN] Aucun champ 'git_hash' mis à jour dans manifest_master.json.")
        return

    print("[INFO] Chemins mis à jour dans le manifest :")
    for p in sorted(updated_paths):
        print(f"  - {p}")

    # 4) Réécriture du manifest
    with manifest_path.open("w", encoding="utf-8") as f:
        json.dump(manifest_obj, f, indent=2, sort_keys=True)
        f.write("\n")

    print(f"[INFO] Manifest mis à jour : {manifest_path}")


if __name__ == "__main__":
    main()
