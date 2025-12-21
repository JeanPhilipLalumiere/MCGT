#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

MANIFEST_MASTER = ROOT / "assets/zz-manifests" / "manifest_master.json"
CITATION_ROOT = ROOT / "CITATION.cff"
CITATION_RELEASE = ROOT / "release_zenodo_codeonly" / "v0.3.x" / "CITATION.cff"
TODO_PATH = ROOT / "TODO_CLEANUP.md"


def get_project_version() -> str | None:
    if not MANIFEST_MASTER.exists():
        print(
            f"[WARN] {MANIFEST_MASTER} introuvable, impossible de récupérer project.version"
        )
        return None
    try:
        data = json.loads(MANIFEST_MASTER.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[ERROR] JSON error dans manifest_master.json : {e}")
        return None
    proj = data.get("project") or {}
    version = proj.get("version")
    if not version:
        print("[WARN] project.version absent dans manifest_master.json")
    else:
        print(f"[INFO] project.version (manifest_master) = {version!r}")
    return version


_version_line_re = re.compile(r"^(\s*)version\s*:(.*)$")


def update_citation_lines(lines: list[str], version: str) -> list[str]:
    """Retours : nouvelles lignes avec version: "X.Y.Z" inséré / remplacé."""
    new_lines = []
    found = False

    for line in lines:
        m = _version_line_re.match(line)
        if m and not found:
            indent = m.group(1)
            new_lines.append(f'{indent}version: "{version}"\n')
            found = True
        else:
            new_lines.append(line)

    if found:
        return new_lines

    # Pas de ligne version: → on en insère une après cff-version: si possible
    insert_pos = None
    for i, line in enumerate(new_lines):
        stripped = line.lstrip()
        if stripped.startswith("cff-version:"):
            insert_pos = i + 1
            break

    if insert_pos is None:
        # fallback: insérer en début de fichier (après éventuel shebang/---)
        insert_pos = 0
        while insert_pos < len(new_lines):
            stripped = new_lines[insert_pos].strip()
            if stripped and not stripped.startswith("#"):
                break
            insert_pos += 1

    version_line = f'version: "{version}"\n'
    new_lines.insert(insert_pos, version_line)
    return new_lines


def bump_one_citation(path: Path, version: str) -> bool:
    if not path.exists():
        print(f"[INFO] {path} absent, ignoré.")
        return False

    print(f"[INFO] Mise à jour de {path} → version: {version}")
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    updated_lines = update_citation_lines(lines, version)

    if updated_lines == lines:
        print(f"[INFO] Aucun changement nécessaire pour {path}")
        return False

    stamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    backup = path.with_name(path.name + f".bak_mcgt_bump_citation_{stamp}")
    backup.write_text(text, encoding="utf-8")
    print(f"[INFO] Backup écrit : {backup}")

    path.write_text("".join(updated_lines), encoding="utf-8")
    print(f"[OK] {path} mis à jour.")
    return True


def log_todo(version: str, root_changed: bool, rel_changed: bool) -> None:
    if not TODO_PATH.exists():
        print(f"[INFO] {TODO_PATH} absent, aucun log ajouté.")
        return

    stamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    with TODO_PATH.open("a", encoding="utf-8") as f:
        f.write(f"\n## [{stamp}] mcgt_bump_citation_version_v1\n")
        f.write(
            f"- Version de référence (manifest_master.project.version) : {version}\n"
        )
        if root_changed:
            f.write("- CITATION.cff (racine) : champ version mis à jour.\n")
        else:
            f.write("- CITATION.cff (racine) : aucun changement.\n")
        if rel_changed:
            f.write(
                "- CITATION.cff (release_zenodo_codeonly/v0.3.x) : champ version mis à jour.\n"
            )
        else:
            f.write(
                "- CITATION.cff (release_zenodo_codeonly/v0.3.x) : aucun changement.\n"
            )


def main() -> None:
    print("=== MCGT: bump citation version v1 ===")
    print(f"Root: {ROOT}")
    print()

    version = get_project_version()
    if not version:
        print("[ERROR] Impossible de déterminer une version cible, arrêt.")
        return

    root_changed = bump_one_citation(CITATION_ROOT, version)
    rel_changed = bump_one_citation(CITATION_RELEASE, version)

    log_todo(version, root_changed, rel_changed)

    print()
    print("[INFO] mcgt_bump_citation_version_v1 terminé.")


if __name__ == "__main__":
    main()
