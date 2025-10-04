#!/usr/bin/env python3
"""
validate_csv_table.py

Validation d'un CSV contre un schéma "csv-table/v1" (voir zz-schemas/*_table_schema.json).

Usage:
    python zz-schemas/validate_csv_table.py <schema.json> <data.csv> [--max-errors N]

Sortie:
    - "OK: <csv> matches <schema>" et code 0 si tout est valide
    - Détail des erreurs et code 1 sinon
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from typing import Any

# ----------------------------
# Utilitaires de parsing/typage
# ----------------------------

_NULL_TOKENS = {"", "na", "nan", "none", "null", "n/a", "."}


def is_null_token(s: str | None) -> bool:
    if s is None:
        return True
    return s.strip().lower() in _NULL_TOKENS


def parse_integer(s: str) -> int | None:
    try:
        return int(s)
    except ValueError:
        try:
            f = float(s)
            if math.isfinite(f) and f.is_integer():
                return int(f)
        except ValueError:
            pass
    return None


def parse_number(s: str) -> float | None:
    try:
        f = float(s)
        if not math.isfinite(f):
            return None
        return f
    except ValueError:
        return None


def cast_value(s: str | None, typ: str) -> tuple[bool, Any, str]:
    """
    Retourne (ok, value, err_msg)
    """
    if s is None:
        return False, None, "missing field"
    if typ == "string":
        return True, s, ""
    if typ == "integer":
        v = parse_integer(s)
        if v is None:
            return False, None, f"not an integer: {s!r}"
        return True, v, ""
    if typ == "number":
        v = parse_number(s)
        if v is None:
            return False, None, f"not a number: {s!r}"
        return True, v, ""
    if typ == "boolean":
        s2 = s.strip().lower()
        if s2 in ("true", "1", "yes", "y"):
            return True, True, ""
        if s2 in ("false", "0", "no", "n"):
            return True, False, ""
        return False, None, f"not a boolean: {s!r}"
    # fallback: treat as string
    return True, s, ""


# ----------------------------
# Validation principale
# ----------------------------


class CSVTableValidator:
    def __init__(self, schema: dict[str, Any], data_path: str, max_errors: int = 50):
        self.schema = schema
        self.data_path = data_path
        self.max_errors = max_errors
        self.errors: list[str] = []

        # Paramètres généraux
        self.delimiter: str = schema.get("delimiter", ",")
        self.header: bool = schema.get("header", True)
        self.allow_extra_columns: bool = schema.get("allow_extra_columns", True)

        # Colonnes déclarées
        self.columns: list[dict[str, Any]] = schema.get("columns", [])
        self.col_index_by_name: dict[str, int] = {}

        # Clé primaire optionnelle
        self.primary_key: list[str] = schema.get("primary_key", [])
        self.pk_seen: set = set()

        # Contraintes optionnelles
        self.constraints: list[dict[str, Any]] = schema.get("constraints", [])

        # Vérifications simples du schéma
        self._check_schema_minimal()

    def _check_schema_minimal(self) -> None:
        if not isinstance(self.columns, list) or not self.columns:
            self._fatal("Schema error: 'columns' doit être une liste non vide.")
        names = [c.get("name") for c in self.columns]
        if any(not isinstance(n, str) or not n for n in names):
            self._fatal(
                "Schema error: chaque colonne doit avoir un champ 'name' non vide."
            )
        if len(set(names)) != len(names):
            self._fatal("Schema error: noms de colonnes dupliqués.")
        for c in self.columns:
            if "type" not in c:
                self._fatal(f"Schema error: colonne {c.get('name')!r} sans 'type'.")

    def _fatal(self, msg: str) -> None:
        print(msg, file=sys.stderr)
        sys.exit(2)

    def add_error(self, msg: str) -> None:
        if len(self.errors) < self.max_errors:
            self.errors.append(msg)

    def _read_rows(self) -> tuple[list[str], list[dict[str, str]]]:
        rows: list[dict[str, str]] = []
        with open(self.data_path, encoding="utf-8", newline="") as f:
            if self.header:
                reader = csv.DictReader(f, delimiter=self.delimiter)
                headers = reader.fieldnames or []
                for row in reader:
                    # ignorer complètement les lignes vides
                    if all((v is None or str(v).strip() == "") for v in row.values()):
                        continue
                    rows.append(
                        {k: (v if v is not None else "") for k, v in row.items()}
                    )
            else:
                reader = csv.reader(f, delimiter=self.delimiter)
                headers = [c["name"] for c in self.columns]
                for raw in reader:
                    if not raw or all(str(x).strip() == "" for x in raw):
                        continue
                    row = {}
                    for i, name in enumerate(headers):
                        row[name] = raw[i] if i < len(raw) else ""
                    rows.append(row)
        return headers, rows

    def _check_headers(self, headers: list[str]) -> None:
        required_columns = [c["name"] for c in self.columns if c.get("required", True)]
        missing = [c for c in required_columns if c not in headers]
        if missing:
            self.add_error(f"Missing required column(s): {missing}")

        if not self.allow_extra_columns:
            extras = [h for h in headers if h not in [c["name"] for c in self.columns]]
            if extras:
                self.add_error(f"Unexpected extra column(s): {extras}")

        # Map pour accès rapide (si header)
        self.col_index_by_name = {name: i for i, name in enumerate(headers)}

    def _get_cell(self, row: dict[str, str], colname: str) -> str | None:
        return row.get(colname)

    def _validate_row_values(self, row: dict[str, str], rownum: int) -> dict[str, Any]:
        typed: dict[str, Any] = {}
        for col in self.columns:
            name = col["name"]
            typ = col.get("type", "string")
            required = col.get("required", True)
            nullable = col.get("nullable", False)
            enum = col.get("enum")
            pattern = col.get("pattern")
            minv = col.get("min", None)
            maxv = col.get("max", None)

            raw = self._get_cell(row, name)
            # Présence de colonne
            if raw is None:
                if required:
                    self.add_error(
                        f"[row {rownum}] column '{name}': missing required column"
                    )
                continue

            # Null handling
            if is_null_token(raw):
                if not nullable:
                    self.add_error(
                        f"[row {rownum}] column '{name}': null/empty not allowed"
                    )
                typed[name] = None
                continue

            # Typage
            ok, val, err = cast_value(raw, typ)
            if not ok:
                self.add_error(f"[row {rownum}] column '{name}': {err}")
                continue

            # Enum
            if enum is not None:
                if val not in enum:
                    self.add_error(
                        f"[row {rownum}] column '{name}': value {val!r} not in enum {enum}"
                    )

            # Pattern (pour strings)
            if pattern and isinstance(val, str):
                if not re.fullmatch(pattern, val):
                    self.add_error(
                        f"[row {rownum}] column '{name}': value {val!r} does not match pattern {pattern!r}"
                    )

            # Min/Max (pour nombres/entiers)
            if isinstance(val, (int, float)):
                if minv is not None and val < minv:
                    self.add_error(
                        f"[row {rownum}] column '{name}': value {val} < min {minv}"
                    )
                if maxv is not None and val > maxv:
                    self.add_error(
                        f"[row {rownum}] column '{name}': value {val} > max {maxv}"
                    )

            typed[name] = val
        return typed

    def _validate_primary_key(self, typed: dict[str, Any], rownum: int) -> None:
        if not self.primary_key:
            return
        key_vals = []
        for k in self.primary_key:
            v = typed.get(k)
            if v is None:
                self.add_error(f"[row {rownum}] primary_key '{k}' is null")
                return
            key_vals.append(v)
        tup = tuple(key_vals)
        if tup in self.pk_seen:
            self.add_error(
                f"[row {rownum}] duplicate primary_key {self.primary_key}={tup}"
            )
        else:
            self.pk_seen.add(tup)

    def _get_value_for_constraint(
        self, typed: dict[str, Any], spec: dict[str, Any]
    ) -> tuple[bool, Any]:
        """
        Retourne (present, value) où value peut venir de:
          - spec["left"]/spec["right"] (colonne)
          - spec["left_value"]/spec["right_value"] (constante)
        """
        if "column" in spec:
            col = spec["column"]
            return (col in typed and typed[col] is not None), typed.get(col)
        if "left_value" in spec:
            return True, spec["left_value"]
        if "right_value" in spec:
            return True, spec["right_value"]
        if "equals" in spec:
            return True, spec["equals"]
        return False, None

    def _apply_constraints(self, typed: dict[str, Any], rownum: int) -> None:
        for c in self.constraints:
            ctype = c.get("type")
            if ctype == "compare":
                left_present, left_val = self._get_value_for_constraint(
                    typed,
                    (
                        {"column": c["left"]}
                        if "left" in c
                        else {"left_value": c.get("left_value")}
                    ),
                )
                if "right" in c:
                    right_present, right_val = self._get_value_for_constraint(
                        typed, {"column": c["right"]}
                    )
                else:
                    right_present, right_val = self._get_value_for_constraint(
                        typed, {"right_value": c.get("right_value")}
                    )

                if (
                    not left_present
                    or left_val is None
                    or not right_present
                    or right_val is None
                ):
                    continue

                op = c.get("op")
                ok = True
                try:
                    if op == "<":
                        ok = left_val < right_val
                    elif op == "<=":
                        ok = left_val <= right_val
                    elif op == ">":
                        ok = left_val > right_val
                    elif op == ">=":
                        ok = left_val >= right_val
                    elif op == "==":
                        ok = left_val == right_val
                    elif op == "!=":
                        ok = left_val != right_val
                    else:
                        self.add_error(
                            f"[row {rownum}] constraint 'compare': unknown operator {op!r}"
                        )
                        continue
                except Exception as e:
                    self.add_error(
                        f"[row {rownum}] constraint 'compare' failed to evaluate: {e}"
                    )
                    continue

                if not ok:
                    self.add_error(
                        f"[row {rownum}] compare failed: {c.get('left','left_value')} {op} {c.get('right','right_value')} "
                        f"(values: {left_val} {op} {right_val})"
                    )

            elif ctype == "implies":
                cond_if = c.get("if", {})
                cond_then = c.get("then", {})

                if_col = cond_if.get("column")
                if_equals = cond_if.get("equals", None)
                if_present = if_col in typed
                if_val = typed.get(if_col) if if_present else None

                if_match = False
                if if_present:
                    if if_equals is None:
                        if_match = if_val is not None
                    else:
                        if_match = if_val == if_equals

                if not if_match:
                    continue

                then_col = cond_then.get("column")
                if then_col is None:
                    self.add_error(
                        f"[row {rownum}] constraint 'implies' missing 'then.column'"
                    )
                    continue

                then_val = typed.get(then_col)

                if cond_then.get("is_null", False):
                    if then_val is not None:
                        self.add_error(
                            f"[row {rownum}] implies failed: expected '{then_col}' to be null"
                        )
                if cond_then.get("not_null", False):
                    if then_val is None:
                        self.add_error(
                            f"[row {rownum}] implies failed: expected '{then_col}' to be not null"
                        )
                if "equals" in cond_then:
                    if then_val != cond_then["equals"]:
                        self.add_error(
                            f"[row {rownum}] implies failed: expected '{then_col}' == {cond_then['equals']!r}, got {then_val!r}"
                        )

            else:
                self.add_error(f"[row {rownum}] unknown constraint type: {ctype!r}")

    def validate(self) -> int:
        headers, rows = self._read_rows()
        self._check_headers(headers)

        for idx, row in enumerate(rows, start=2 if self.header else 1):
            typed = self._validate_row_values(row, idx)
            self._validate_primary_key(typed, idx)
            self._apply_constraints(typed, idx)
            if len(self.errors) >= self.max_errors:
                break

        if self.errors:
            print(
                f"Found {len(self.errors)} error(s) (showing up to {self.max_errors}):",
                file=sys.stderr,
            )
            for e in self.errors:
                print(f"  - {e}", file=sys.stderr)
            return 1

        print(f"OK: {self.data_path} matches {self.schema.get('$id', '<schema>')}")
        return 0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Validate CSV against a csv-table schema.")
    ap.add_argument("schema", help="Path to schema JSON")
    ap.add_argument("csv", help="Path to CSV to validate")
    ap.add_argument(
        "--max-errors", type=int, default=50, help="Max errors to display (default: 50)"
    )
    args = ap.parse_args(argv)

    try:
        with open(args.schema, encoding="utf-8") as f:
            schema = json.load(f)
    except FileNotFoundError:
        print(f"Schema file not found: {args.schema}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as e:
        print(f"Invalid JSON schema ({args.schema}): {e}", file=sys.stderr)
        return 2

    validator = CSVTableValidator(
        schema=schema, data_path=args.csv, max_errors=args.max_errors
    )
    try:
        return validator.validate()
    except FileNotFoundError:
        print(f"CSV file not found: {args.csv}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
