#!/usr/bin/env python
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assets/zz-manifests" / "manifest_master.json"

# Fichiers basculés dans attic à retirer du manifest master
PATHS_TO_DROP = {
    "assets/zz-data/chapter01/01_optimized_grid_data.dat",
    "assets/zz-data/chapter01/01_initial_grid_data.dat",
    "assets/zz-data/chapter01/01_P_derivative_initial.csv",
}


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, data) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def cleanup_list(entries: list[object]) -> tuple[list[object], int, int]:
    """Retourne (new_entries, before, removed) pour une liste d'objets JSON."""
    before = len(entries)
    new_entries: list[object] = []
    removed = 0

    for e in entries:
        if isinstance(e, dict) and e.get("path") in PATHS_TO_DROP:
            removed += 1
            continue
        new_entries.append(e)

    return new_entries, before, removed


def main() -> None:
    if not MANIFEST_PATH.is_file():
        print(f"[ERROR] Manifest introuvable: {MANIFEST_PATH}", file=sys.stderr)
        sys.exit(1)

    # Backup avant modif
    backup = MANIFEST_PATH.with_suffix(".json.bak_before_ch01_attic_cleanup")
    shutil.copy2(MANIFEST_PATH, backup)
    print(f"[BACKUP] Copie sauvegarde -> {backup}")

    manifest = load_json(MANIFEST_PATH)

    total_before = 0
    total_removed = 0
    lists_touched = 0

    if isinstance(manifest, list):
        # Cas simple: manifest = [ {path: ...}, ... ]
        new_list, before, removed = cleanup_list(manifest)
        manifest = new_list
        total_before += before
        total_removed += removed
        lists_touched += 1
    elif isinstance(manifest, dict):
        # Cas plus général: manifest = {"files": [...], "meta": {...}} ou autre
        for key, value in list(manifest.items()):
            if isinstance(value, list) and any(
                isinstance(e, dict) and "path" in e for e in value
            ):
                new_list, before, removed = cleanup_list(value)
                manifest[key] = new_list
                total_before += before
                total_removed += removed
                lists_touched += 1
    else:
        print(
            "[ERROR] Type de manifest non supporté (ni dict ni list).", file=sys.stderr
        )
        sys.exit(1)

    if lists_touched == 0:
        print(
            "[WARN] Aucune liste d'entrées avec clé 'path' n'a été trouvée dans le manifest.",
            file=sys.stderr,
        )

    if total_before == 0:
        print(
            "[WARN] Manifest vide ou non exploitable pour ce cleanup.", file=sys.stderr
        )
    else:
        total_after = total_before - total_removed
        print("[UPDATE] manifest_master.json :")
        print(f"         - listes touchées   : {lists_touched}")
        print(f"         - entrées avant     : {total_before}")
        print(f"         - entrées retirées  : {total_removed}")
        print(f"         - entrées après     : {total_after}")

    if total_removed == 0:
        print(
            "[WARN] Aucune entrée correspondant aux chemins ciblés n'a été trouvée.",
            file=sys.stderr,
        )

    save_json(MANIFEST_PATH, manifest)
    print("[DONE] cleanup_manifest_master_ch01_attic terminé.")


if __name__ == "__main__":
    main()
