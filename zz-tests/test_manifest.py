import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_DIR = ROOT / "zz-manifests"
MASTER = MANIFEST_DIR / "manifest_master.json"
PUBLICATION = MANIFEST_DIR / "manifest_publication.json"

ALLOWED_ROLES = {
    "data",
    "config",
    "code",
    "figure",
    "document",
    "meta",
    "script",
    "schema",
    "manifest",
    "artifact",
    "source",
    "bibliography",
}


def load_json(p: Path):
    assert p.exists(), f"Missing file: {p}"
    with p.open("r", encoding="utf-8") as f:
        return json.load(f)


def test_master_publication_exist_and_heads():
    for p in (MASTER, PUBLICATION):
        js = load_json(p)
        assert "manifest_version" in js and "project" in js and "entries" in js
        assert isinstance(js["entries"], list)


def _is_relative_path(path_str: str) -> bool:
    if path_str.startswith("/") or re.match(r"^[A-Za-z]:\\", path_str):
        return False
    return True


def test_entries_are_relative_and_roles_allowed():
    js = load_json(MASTER)
    for e in js["entries"]:
        assert _is_relative_path(e.get("path", "")), f"Absolute path found: {e}"
        role = e.get("role")
        assert role in ALLOWED_ROLES, f"Unexpected role={role} for {e.get('path')}"


def test_diag_master_no_errors_json_report():
    """
    On vérifie que manifest_master.json est "propre" au sens suivant :

    - Soit il n'y a aucune erreur (cas cible quand toutes les figures sont présentes).
    - Soit il y a exactement 1 erreur FILE_MISSING, correspondant à la figure
      ch09 "phase overlay" marquée REBUILD_LATER.

    On lance diag_consistency avec --fail-on none pour pouvoir inspecter le JSON
    même en présence de cette erreur contrôlée.
    """
    cmd = [
        sys.executable,
        str(MANIFEST_DIR / "diag_consistency.py"),
        str(MASTER),
        "--report",
        "json",
        "--normalize-paths",
        "--apply-aliases",
        "--strip-internal",
        "--content-check",
        "--fail-on",
        "none",
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert (
        res.returncode == 0
    ), f"diag_consistency a échoué de manière inattendue:\n{res.stdout}\n{res.stderr}"

    payload = json.loads(res.stdout)
    errors = payload["errors"]
    issues = payload["issues"]

    # On sépare clairement erreurs et warnings
    error_issues = [it for it in issues if it.get("severity") == "ERROR"]
    warn_issues = [it for it in issues if it.get("severity") == "WARN"]

    # Cas 1 : à terme, plus aucune erreur
    if errors == 0:
        # Aucun issue de sévérité ERROR
        assert error_issues == []
        # On ne verrouille pas encore les WARN pour ne pas rendre le test trop fragile
        return

    # Cas 2 : état transitoire actuel : 1 seule erreur FILE_MISSING sur la figure ch09
    assert errors == 1, f"Nombre d'erreurs inattendu: {errors} (payload={payload})"
    assert (
        len(error_issues) == 1
    ), f"Issues d'erreur inattendues: {error_issues}"

    issue = error_issues[0]
    assert issue["code"] == "FILE_MISSING"
    assert issue["path"] == "zz-figures/chapter09/09_fig_01_phase_overlay.png"
