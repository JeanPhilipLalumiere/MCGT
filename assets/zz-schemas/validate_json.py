#!/usr/bin/env python3
import json
import sys

from jsonschema import Draft202012Validator


def validate_instance(schema_path: str, instance_path: str) -> int:
    with open(schema_path, encoding="utf-8") as f:
        schema = json.load(f)
    with open(instance_path, encoding="utf-8") as f:
        inst = json.load(f)

    validator = Draft202012Validator(schema)
    errors = sorted(
        validator.iter_errors(inst), key=lambda e: (list(e.path), e.message)
    )

    if not errors:
        print(f"OK: {instance_path} matches {schema_path}")
        return 0

    print(f"ERRORS for {instance_path} vs {schema_path}:")
    for e in errors:
        path = ".".join(map(str, e.path)) or "<root>"
        # Ajout du contexte (schéma) si disponible
        what = e.schema.get("title") if isinstance(e.schema, dict) else None
        ctx = f" ({what})" if what else ""
        print(f" - at {path}{ctx}: {e.message}")
    return 1


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python assets/zz-schemas/validate_json.py <schema.json> <instance.json>")
        sys.exit(2)
    sys.exit(validate_instance(sys.argv[1], sys.argv[2]))
