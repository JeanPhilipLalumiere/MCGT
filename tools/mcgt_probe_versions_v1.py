#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load_manifest_project(path: Path):
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return {"error": f"JSON error: {e}", "_path": str(path)}
    proj = data.get("project") or {}
    return {
        "name": proj.get("name"),
        "version": proj.get("version"),
        "homepage": proj.get("homepage"),
        "_path": str(path),
    }


def parse_citation_version(path: Path):
    if not path.exists():
        return None
    version = None
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            stripped = line.lstrip()
            if stripped.startswith("version:"):
                value = stripped.split(":", 1)[1].strip()
                value = value.strip('"').strip("'")
                version = value
                break
    except Exception:
        return {"error": "read error", "_path": str(path)}
    return {"version": version, "_path": str(path)}


def parse_pyproject(path: Path):
    if not path.exists():
        return None
    try:
        try:
            import tomllib  # Python 3.11+
        except ImportError:  # pragma: no cover
            import tomli as tomllib  # type: ignore[assignment]
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        return {"error": f"toml error: {e}", "_path": str(path)}
    proj = data.get("project") or {}
    return {
        "name": proj.get("name"),
        "version": proj.get("version"),
        "_path": str(path),
    }


_version_re = re.compile(r"__version__\s*=\s*['\"]([^'\"]+)['\"]")


def parse_init_version(path: Path):
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    matches = _version_re.findall(text)
    if not matches:
        return {"version": None, "_path": str(path)}
    unique = []
    for m in matches:
        if m not in unique:
            unique.append(m)
    return {"version": ", ".join(unique), "_path": str(path)}


def print_block(title: str):
    print()
    print(f"### {title}")
    print("-" * (4 + len(title)))


def show_manifest_block(label_prefix: str, master_path: Path, pub_path: Path):
    mm = load_manifest_project(master_path)
    mp = load_manifest_project(pub_path)

    for label, info in (
        (f"{label_prefix}.manifest_master", mm),
        (f"{label_prefix}.manifest_publication", mp),
    ):
        if info is None:
            print(f"{label:45} : (absent)")
        elif "error" in info:
            print(f"{label:45} : ERROR {info['error']} ({info.get('_path')})")
        else:
            print(
                f"{label:45} : "
                f"name={info.get('name')!r}, "
                f"version={info.get('version')!r}, "
                f"homepage={info.get('homepage')!r}"
            )


def main():
    print("=== MCGT: probe versions v1 ===")
    print(f"Root: {ROOT}")
    print()

    # 1) Manifestes (root + snapshot release)
    print_block("Manifestes (root)")
    show_manifest_block(
        "root",
        ROOT / "zz-manifests" / "manifest_master.json",
        ROOT / "zz-manifests" / "manifest_publication.json",
    )

    print_block("Manifestes (release_zenodo_codeonly/v0.3.x)")
    show_manifest_block(
        "snapshot",
        ROOT
        / "release_zenodo_codeonly"
        / "v0.3.x"
        / "zz-manifests"
        / "manifest_master.json",
        ROOT
        / "release_zenodo_codeonly"
        / "v0.3.x"
        / "zz-manifests"
        / "manifest_publication.json",
    )

    # 2) Pyproject(s)
    print_block("pyproject.toml")
    root_pp = parse_pyproject(ROOT / "pyproject.toml")
    rel_pp = parse_pyproject(
        ROOT / "release_zenodo_codeonly" / "v0.3.x" / "pyproject.toml"
    )

    for label, info in (
        ("root.pyproject", root_pp),
        ("release_zenodo_codeonly/v0.3.x", rel_pp),
    ):
        if info is None:
            print(f"{label:45} : (absent)")
        elif "error" in info:
            print(f"{label:45} : ERROR {info['error']} ({info.get('_path')})")
        else:
            print(
                f"{label:45} : "
                f"name={info.get('name')!r}, "
                f"version={info.get('version')!r}"
            )

    # 3) __init__ versions
    print_block("__init__ (__version__)")
    mcgt_init = parse_init_version(ROOT / "mcgt" / "__init__.py")
    zz_init = parse_init_version(ROOT / "zz_tools" / "__init__.py")

    for label, info in (
        ("mcgt.__init__", mcgt_init),
        ("zz_tools.__init__", zz_init),
    ):
        if info is None:
            print(f"{label:45} : (absent)")
        elif "error" in info:
            print(f"{label:45} : ERROR {info['error']} ({info.get('_path')})")
        else:
            print(f"{label:45} : version={info.get('version')!r} ({info.get('_path')})")

    # 4) CITATION
    print_block("CITATION.cff")
    cit_root = parse_citation_version(ROOT / "CITATION.cff")
    cit_rel = parse_citation_version(
        ROOT / "release_zenodo_codeonly" / "v0.3.x" / "CITATION.cff"
    )

    for label, info in (
        ("root CITATION.cff", cit_root),
        ("release_zenodo_codeonly CITATION.cff", cit_rel),
    ):
        if info is None:
            print(f"{label:45} : (absent)")
        elif "error" in info:
            print(f"{label:45} : ERROR {info['error']} ({info.get('_path')})")
        else:
            print(f"{label:45} : version={info.get('version')!r} ({info.get('_path')})")

    print()
    print("[INFO] mcgt_probe_versions_v1 terminé.")


if __name__ == "__main__":
    main()
