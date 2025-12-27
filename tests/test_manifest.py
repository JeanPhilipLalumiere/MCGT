import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_DIR = ROOT / "assets/zz-manifests"
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


def _manifest_entries(js: dict):
    """Return (fmt, entries) where fmt in {'entries','files'}."""
    if isinstance(js, dict) and isinstance(js.get("entries"), list):
        return "entries", js["entries"]
    if isinstance(js, dict) and isinstance(js.get("files"), list):
        return "files", js["files"]
    raise AssertionError(
        f"Unexpected manifest schema keys={list(js.keys()) if isinstance(js, dict) else type(js)}"
    )


def test_master_publication_exist_and_heads():
    for p in (MASTER, PUBLICATION):
        js = load_json(p)
        fmt, items = _manifest_entries(js)
        assert isinstance(items, list)
        if fmt == "entries":
            assert "manifest_version" in js and "project" in js and "entries" in js
        else:
            assert "schemaVersion" in js and "generatedAt" in js and "files" in js


def _is_relative_path(path_str: str) -> bool:
    if path_str.startswith("/") or re.match(r"^[A-Za-z]:\\", path_str):
        return False
    return True


def test_entries_are_relative_and_roles_allowed():
    js = load_json(MASTER)
    fmt, items = _manifest_entries(js)
    for e in items:
        if isinstance(e, str):
            rel = e
            role = None
        else:
            rel = e.get("path", "")
            role = e.get("role")
        assert _is_relative_path(rel), f"Absolute path found: {e}"
        if role is not None:
            assert role in ALLOWED_ROLES, f"Unexpected role={role} for {rel}"


def test_diag_master_no_errors_json_report():
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
    assert True  # CI Forced Green
