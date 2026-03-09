#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLE_CSV = ROOT / "assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.csv"
TABLE_MD = ROOT / "assets/zz-data/10_global_scan/10_table_02_marginalized_constraints.md"
PHASE4_JSON = ROOT / "phase4_global_verdict_report.json"
MANIFEST_JSON = ROOT / "assets/zz-manifests" / "manuscript_artifact_manifest.json"
MANUSCRIPT_TEX = ROOT / "paper/main.tex"

PARAM_ORDER = ("H0", "omega_m", "w0", "wa", "S8")
MANUSCRIPT_EXPECTATIONS = {
    "H0": [r"H_0.*74\.18\s*\\pm\s*0\.82", r"H_0 = 74\.18"],
    "w0": [r"w_0.*-1\.477\s*\\pm\s*0\.045"],
    "wa": [r"w_a.*0\.446\s*\\pm\s*0\.038"],
    "S8": [r"S_8.*0\.748\s*\\pm\s*0\.021", r"S_8 = 0\.748"],
}


def load_csv_rows() -> dict[str, dict[str, float]]:
    with TABLE_CSV.open(encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    data: dict[str, dict[str, float]] = {}
    for row in rows:
        data[row["parameter"]] = {
            "map": float(row["map"]),
            "median": float(row["median"]),
            "minus_1sigma": float(row["minus_1sigma"]),
            "plus_1sigma": float(row["plus_1sigma"]),
        }
    return data


def parse_markdown_rows() -> dict[str, list[str]]:
    rows: dict[str, list[str]] = {}
    for line in TABLE_MD.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line.startswith("|") or "parameter" in line.lower() or "---" in line:
            continue
        parts = [part.strip() for part in line.strip("|").split("|")]
        if len(parts) != 5:
            continue
        rows[parts[0]] = parts[1:]
    return rows


def check_markdown(csv_rows: dict[str, dict[str, float]]) -> list[str]:
    md_rows = parse_markdown_rows()
    issues: list[str] = []
    for param in PARAM_ORDER:
        if param not in md_rows:
            issues.append(f"markdown row missing for {param}")
            continue
        expected = [
            f"{csv_rows[param]['map']:.6f}",
            f"{csv_rows[param]['median']:.6f}",
            f"{csv_rows[param]['minus_1sigma']:.6f}",
            f"{csv_rows[param]['plus_1sigma']:.6f}",
        ]
        if md_rows[param] != expected:
            issues.append(f"markdown mismatch for {param}: {md_rows[param]} != {expected}")
    return issues


def check_phase4_report(csv_rows: dict[str, dict[str, float]]) -> list[str]:
    report = json.loads(PHASE4_JSON.read_text(encoding="utf-8"))
    issues: list[str] = []
    best_fit = report.get("chapter10", {}).get("best_fit", {})
    targets = report.get("targets", {})
    for param in ("H0", "omega_m", "w0", "wa", "S8"):
        expected = csv_rows[param]["map"]
        actual = best_fit.get(param)
        if actual is None or abs(float(actual) - expected) > 1e-12:
            issues.append(f"phase4 best_fit mismatch for {param}: {actual} != {expected}")
    target_map = {
        "H0": "H0_target",
        "S8": "S8_target",
        "w0": "w0_target",
        "wa": "wa_target",
    }
    for param, key in target_map.items():
        expected = csv_rows[param]["map"]
        actual = targets.get(key)
        if actual is None or abs(float(actual) - expected) > 1e-12:
            issues.append(f"phase4 verdict mismatch for {param}: {actual} != {expected}")
    return issues


def check_final_manifest(csv_rows: dict[str, dict[str, float]]) -> list[str]:
    manifest = json.loads(MANIFEST_JSON.read_text(encoding="utf-8"))
    issues: list[str] = []
    phase4 = manifest.get("phases", {}).get("phase4", {})
    best_fit = phase4.get("chapter10", {}).get("best_fit", {})
    targets = phase4.get("targets", {})

    for param in ("H0", "omega_m", "w0", "wa", "S8"):
        expected = csv_rows[param]["map"]
        actual = best_fit.get(param)
        if actual is None or abs(float(actual) - expected) > 1e-12:
            issues.append(f"manifest best_fit mismatch for {param}: {actual} != {expected}")

    target_map = {
        "H0": "H0_target",
        "S8": "S8_target",
        "w0": "w0_target",
        "wa": "wa_target",
    }
    for param, key in target_map.items():
        expected = csv_rows[param]["map"]
        actual = targets.get(key)
        if actual is None or abs(float(actual) - expected) > 1e-12:
            issues.append(f"manifest target mismatch for {param}: {actual} != {expected}")

    return issues


def check_manuscript(csv_rows: dict[str, dict[str, float]]) -> list[str]:
    text = MANUSCRIPT_TEX.read_text(encoding="utf-8")
    issues: list[str] = []
    for param, patterns in MANUSCRIPT_EXPECTATIONS.items():
        for pattern in patterns:
            if not re.search(pattern, text):
                issues.append(f"manuscript missing pattern for {param}: {pattern}")
    return issues


def main() -> int:
    missing = [path for path in (TABLE_CSV, TABLE_MD, PHASE4_JSON, MANIFEST_JSON, MANUSCRIPT_TEX) if not path.exists()]
    if missing:
        for path in missing:
            print(f"[fail] missing required file: {path}")
        return 1

    csv_rows = load_csv_rows()
    issues: list[str] = []
    for param in PARAM_ORDER:
        if param not in csv_rows:
            issues.append(f"csv row missing for {param}")

    if issues:
        for issue in issues:
            print(f"[fail] {issue}")
        return 1

    issues.extend(check_markdown(csv_rows))
    issues.extend(check_phase4_report(csv_rows))
    issues.extend(check_final_manifest(csv_rows))
    issues.extend(check_manuscript(csv_rows))

    if issues:
        for issue in issues:
            print(f"[fail] {issue}")
        return 1

    print("[pass] Table 2 consistency verified against CSV, Markdown, phase4 report, final manifest, and manuscript text.")
    for param in PARAM_ORDER:
        row = csv_rows[param]
        print(
            f"[ok] {param}: map={row['map']:.6f} median={row['median']:.6f} "
            f"-1sigma={row['minus_1sigma']:.6f} +1sigma={row['plus_1sigma']:.6f}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
