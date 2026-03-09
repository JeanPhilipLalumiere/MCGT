from __future__ import annotations

import json
import re
from pathlib import Path


def get_repo_root() -> Path:
    # Script attendu dans tools/, on remonte d'un niveau
    return Path(__file__).resolve().parent.parent


def find_latest_manual_diag(root: Path) -> Path:
    logs_dir = root / "zz-logs"
    candidates = sorted(logs_dir.glob("manual_diag_consistency_*.log"))
    if not candidates:
        raise SystemExit(
            "[ERROR] Aucun fichier manual_diag_consistency_*.log trouvé dans zz-logs/"
        )
    return candidates[-1]


def extract_git_hashes_from_diag(log_path: Path) -> dict[str, str]:
    """
    Parse les lignes du type :

    - [WARN] GIT_HASH_DIFFERS (#158:assets/zz-figures/09_dark_energy_cpl/09_fig_01_phase_overlay.png): git_hash diffère (manifest=5ab6..., git=64b8...)

    et retourne un mapping:
        path -> git  (la valeur de droite, celle à adopter dans le manifest).
    """
    pattern = re.compile(
        r"GIT_HASH_DIFFERS \(#\d+:(?P<path>[^)]+)\): git_hash diffère "
        r"\(manifest=(?P<manifest>[0-9a-fA-F]+), git=(?P<git>[0-9a-fA-F]+)\)"
    )

    path_to_git: dict[str, str] = {}

    with log_path.open("r", encoding="utf-8") as f:
        for line in f:
            m = pattern.search(line)
            if not m:
                continue
            rel_path = m.group("path").strip()
            git_hash = m.group("git").strip()
            path_to_git[rel_path] = git_hash

    return path_to_git


def update_git_hashes_in_manifest(
    obj, path_to_git: dict[str, str], updated_paths: set[str]
) -> None:
    """
    Parcours récursif de l'objet JSON.
    Dès qu'on trouve un dict avec 'path' ∈ path_to_git, on met à jour 'git_hash'
    avec la valeur correspondante (celle issue de diag_consistency).
    """
    if isinstance(obj, dict):
        p = obj.get("path")
        if isinstance(p, str) and p in path_to_git:
            new_hash = path_to_git[p]
            old_hash = obj.get("git_hash")
            if old_hash != new_hash:
                obj["git_hash"] = new_hash
                updated_paths.add(p)
        # Descente récursive
        for v in obj.values():
            update_git_hashes_in_manifest(v, path_to_git, updated_paths)

    elif isinstance(obj, list):
        for item in obj:
            update_git_hashes_in_manifest(item, path_to_git, updated_paths)

    # autres types (str, int, float, None) : rien à faire


def main() -> None:
    root = get_repo_root()
    manifest_path = root / "assets/zz-manifests" / "manifest_master.json"

    print(f"[INFO] Repo root           : {root}")
    print(f"[INFO] Manifest utilisé    : {manifest_path}")

    diag_log = find_latest_manual_diag(root)
    print(f"[INFO] Dernier manual_diag_consistency : {diag_log}")

    path_to_git = extract_git_hashes_from_diag(diag_log)
    if not path_to_git:
        print(
            "[WARN] Aucun GIT_HASH_DIFFERS trouvé dans le dernier diag. Rien à faire."
        )
        return

    print("[INFO] git_hash attendus (selon diag_consistency) :")
    for p, h in sorted(path_to_git.items()):
        print(f"  - {p} -> {h}")

    with manifest_path.open("r", encoding="utf-8") as f:
        manifest_obj = json.load(f)

    updated_paths: set[str] = set()
    update_git_hashes_in_manifest(manifest_obj, path_to_git, updated_paths)

    if not updated_paths:
        print("[WARN] Aucun champ 'git_hash' mis à jour dans manifest_master.json.")
        return

    print("[INFO] Chemins effectivement mis à jour dans le manifest :")
    for p in sorted(updated_paths):
        print(f"  - {p}")

    with manifest_path.open("w", encoding="utf-8") as f:
        json.dump(manifest_obj, f, indent=2, sort_keys=True)
        f.write("\n")

    print(f"[INFO] Manifest mis à jour : {manifest_path}")


if __name__ == "__main__":
    main()
