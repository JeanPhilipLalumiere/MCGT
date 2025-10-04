import json
import os
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
    "data","config","code","figure","document","meta",
    "script","schema","manifest","artifact","source","bibliography"
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
        assert _is_relative_path(e.get("path","")), f"Absolute path found: {e}"
        role = e.get("role")
        assert role in ALLOWED_ROLES, f"Unexpected role={role} for {e.get('path')}"
def test_diag_master_no_errors_json_report():
    cmd = [
        sys.executable, str(MANIFEST_DIR / "diag_consistency.py"),
        str(MASTER),
        "--report", "json",
        "--normalize-paths", "--apply-aliases", "--strip-internal",
        "--content-check", "--fail-on", "errors"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"diag_consistency failed:\n{res.stdout}\n{res.stderr}"
    # parse JSON report from stdout
    report = json.loads(res.stdout.strip())
    assert report.get("errors", 0) == 0, f"errors>0 in report: {report.get('errors')}"
