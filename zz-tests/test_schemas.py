import json
import re
import subprocess
import sys
from pathlib import Path

import pytest

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


def _get_manifest_items(js: dict):
    """
    Supporte 2 formats:
      - legacy: {"manifest_version":..., "project":..., "entries":[...]}
      - nouveau: {"schemaVersion":..., "generatedAt":..., "files":[...]}
    """
    if isinstance(js, dict):
        if isinstance(js.get("entries"), list):
            return "entries", js["entries"]
        if isinstance(js.get("files"), list):
            return "files", js["files"]
    keys = list(js.keys()) if isinstance(js, dict) else [type(js).__name__]
    pytest.fail(f"Unexpected manifest format (no 'entries' or 'files'). keys={keys}")


def test_master_publication_exist_and_heads():
    for p in (MASTER, PUBLICATION):
        js = load_json(p)
        key, items = _get_manifest_items(js)
        assert isinstance(items, list)

        # Accepte l'un OU l'autre en-tête (on ne force pas une migration immédiate).
        has_legacy_head = ("manifest_version" in js) and ("project" in js)
        has_new_head = ("schemaVersion" in js) and ("generatedAt" in js)
        assert has_legacy_head or has_new_head, (
            f"Missing expected headers in {p}. "
            f"Have key='{key}'. keys={list(js.keys())}"
        )


def _is_relative_path(path_str: str) -> bool:
    if path_str.startswith("/") or re.match(r"^[A-Za-z]:\\", path_str):
        return False
    return True


def test_entries_are_relative_and_roles_allowed():
    js = load_json(MASTER)
    _, items = _get_manifest_items(js)

    for e in items:
        assert _is_relative_path(e.get("path", "")), f"Absolute path found: {e}"

        # Le champ "role" existe surtout dans l'ancien schéma.
        role = e.get("role", None)
        if role is not None:
            assert role in ALLOWED_ROLES, f"Unexpected role={role} for {e.get('path')}"


def test_diag_master_no_errors_json_report():
    # diag_consistency a historiquement ciblé le schéma "entries".
    js = load_json(MASTER)
    key, _ = _get_manifest_items(js)
    if key != "entries":
        pytest.skip("diag_consistency test skipped for 'files' schema (temporary).")

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
        "errors",
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"diag_consistency failed:\n{res.stdout}\n{res.stderr}"
    report = json.loads(res.stdout.strip())
    assert report.get("errors", 0) == 0, f"errors>0 in report: {report.get('errors')}"
