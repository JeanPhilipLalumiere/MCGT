#!/usr/bin/env python3
"""
validate_csv_schema.py  (compat)

Validation rapide d'un CSV contre un schéma "csv-table/v1" (clé 'columns').
Pour une validation plus complète (typage, contraintes, PK), préférez:
    python assets/zz-schemas/validate_csv_table.py <schema.json> <data.csv>
"""

import json
import sys

import pandas as pd


def validate_table(csv_path: str, schema_path: str) -> int:
    df = pd.read_csv(csv_path, encoding="utf-8")
    with open(schema_path, encoding="utf-8") as f:
        schema = json.load(f)

    # Supporte deux formes:
    #  1) notre format csv-table/v1 avec 'columns'
    #  2) frictionless-like avec 'fields'
    columns = schema.get("columns")
    if not columns:
        fields = schema.get("fields")
        if fields:
            expected = [f["name"] for f in fields]
        else:
            # vieux format hybride
            tables = schema.get("tables", {})
            table_name = schema.get("table_name", "")
            expected = [f["name"] for f in tables.get(table_name, {}).get("fields", [])]
    else:
        expected = [c["name"] for c in columns]

    expected = [c for c in expected if c]  # nettoyage

    missing = [c for c in expected if c not in df.columns]
    extra = [c for c in df.columns if c not in expected]

    print(f"[{csv_path}]")
    if expected:
        print("  Expected columns:", expected)
    if missing:
        print("  MISSING:", missing)
    else:
        print("  All expected columns present.")
    if extra:
        print("  EXTRA (not in schema):", extra)
    return 1 if missing else 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            "Usage: python assets/zz-schemas/validate_csv_schema.py <schema.json> <file.csv>"
        )
        sys.exit(2)
    sys.exit(validate_table(sys.argv[2], sys.argv[1]))
