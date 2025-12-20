#!/usr/bin/env python3
from __future__ import annotations

import argparse
import ast
import configparser
import math
import sys
from pathlib import Path


ALIASES = {
    "H0": "H0",
    "h0": "H0",
    "H0_km_s_Mpc": "H0",
    "ombh2": "ombh2",
    "omch2": "omch2",
    "tau": "tau",
    "mnu": "mnu",
    "As0": "As0",
    "A_s0": "As0",
    "A_S0": "As0",
    "ns0": "ns0",
    "NS0": "ns0",
    "Omega_m": "Omega_m",
    "Omega_m0": "Omega_m",
    "Om0": "Omega_m",
    "Omega_L": "Omega_lambda",
    "Omega_lambda": "Omega_lambda",
    "Omega_lambda0": "Omega_lambda",
    "Ol0": "Omega_lambda",
}

PRETTY_NAMES = {
    "H0": "H0",
    "ombh2": "ombh2",
    "omch2": "omch2",
    "tau": "tau",
    "mnu": "mnu",
    "As0": "As0",
    "ns0": "ns0",
    "Omega_m": "Ωm",
    "Omega_lambda": "ΩΛ",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sentinelle: vérifie la cohérence cosmologique des scripts."
    )
    parser.add_argument(
        "--config",
        default="zz-configuration/mcgt-global-config.ini",
        help="INI central pour les paramètres cosmologiques.",
    )
    parser.add_argument(
        "--scripts-root",
        default="zz-scripts",
        help="Répertoire racine des scripts chapitres.",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=1e-5,
        help="Tolérance absolue pour la divergence.",
    )
    return parser.parse_args()


def _getfloat(cfg: configparser.ConfigParser, section: str, key: str) -> float | None:
    if section not in cfg or key not in cfg[section]:
        return None
    try:
        return cfg.getfloat(section, key)
    except ValueError:
        return None


def load_best_fit(config_path: Path) -> dict[str, float]:
    if not config_path.exists():
        raise FileNotFoundError(f"INI introuvable: {config_path}")
    cfg = configparser.ConfigParser()
    if not cfg.read(config_path):
        raise ValueError(f"Lecture INI impossible: {config_path}")

    best_fit: dict[str, float] = {}
    for key in ("H0", "ombh2", "omch2", "tau", "mnu", "As0", "ns0"):
        value = _getfloat(cfg, "cmb", key)
        if value is None:
            value = _getfloat(cfg, "perturbations", key)
        if value is not None:
            best_fit[key] = value

    if all(k in best_fit for k in ("H0", "ombh2", "omch2")):
        h = best_fit["H0"] / 100.0
        omega_m = (best_fit["ombh2"] + best_fit["omch2"]) / (h * h)
        best_fit["Omega_m"] = omega_m
        best_fit["Omega_lambda"] = 1.0 - omega_m

    return best_fit


def _literal_number(node: ast.AST) -> float | None:
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return float(node.value)
    if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.UAdd, ast.USub)):
        value = _literal_number(node.operand)
        if value is None:
            return None
        return value if isinstance(node.op, ast.UAdd) else -value
    return None


def _extract_tuple_assignments(
    target: ast.Tuple, value: ast.AST
) -> list[tuple[str, float]]:
    if not isinstance(value, (ast.Tuple, ast.List)):
        return []
    if len(target.elts) != len(value.elts):
        return []
    pairs: list[tuple[str, float]] = []
    for name_node, value_node in zip(target.elts, value.elts):
        if not isinstance(name_node, ast.Name):
            continue
        number = _literal_number(value_node)
        if number is None:
            continue
        pairs.append((name_node.id, number))
    return pairs


def iter_global_literals(tree: ast.AST) -> list[tuple[str, float]]:
    results: list[tuple[str, float]] = []
    for node in getattr(tree, "body", []):
        if isinstance(node, ast.Assign):
            if isinstance(node.value, ast.Dict):
                for key, value in zip(node.value.keys, node.value.values):
                    if isinstance(key, ast.Constant) and isinstance(key.value, str):
                        number = _literal_number(value)
                        if number is not None:
                            results.append((key.value, number))
                continue
            for target in node.targets:
                if isinstance(target, ast.Name):
                    number = _literal_number(node.value)
                    if number is not None:
                        results.append((target.id, number))
                elif isinstance(target, ast.Tuple):
                    results.extend(_extract_tuple_assignments(target, node.value))
        elif isinstance(node, ast.AnnAssign):
            if isinstance(node.target, ast.Name) and node.value is not None:
                number = _literal_number(node.value)
                if number is not None:
                    results.append((node.target.id, number))
    return results


def format_value(value: float) -> str:
    return format(value, ".6g")


def script_paths(root: Path) -> list[Path]:
    roots = []
    for i in range(1, 11):
        chapter_dir = root / f"chapter{i:02d}"
        if chapter_dir.exists():
            roots.append(chapter_dir)
    paths: list[Path] = []
    for chapter_root in roots:
        paths.extend(sorted(chapter_root.rglob("*.py")))
    return paths


def chapter_from_path(path: Path) -> str:
    for part in path.parts:
        if part.startswith("chapter") and len(part) == len("chapter00"):
            return part.replace("chapter", "")
    return "??"


def main() -> int:
    args = parse_args()
    config_path = Path(args.config)
    scripts_root = Path(args.scripts_root)
    try:
        best_fit = load_best_fit(config_path)
    except (FileNotFoundError, ValueError) as exc:
        print(f"ERREUR DE COHÉRENCE : {exc}")
        return 1

    if not scripts_root.exists():
        print(f"ERREUR DE COHÉRENCE : scripts introuvables ({scripts_root}).")
        return 1

    for script_path in script_paths(scripts_root):
        try:
            tree = ast.parse(script_path.read_text(encoding="utf-8"))
        except SyntaxError as exc:
            print(
                f"ERREUR DE COHÉRENCE : "
                f"{script_path} illisible ({exc.msg})."
            )
            return 1
        for name, value in iter_global_literals(tree):
            canonical = ALIASES.get(name)
            if canonical is None:
                continue
            expected = best_fit.get(canonical)
            if expected is None:
                continue
            if not (math.isfinite(value) and math.isfinite(expected)):
                continue
            if abs(value - expected) > args.tolerance:
                chapter = chapter_from_path(script_path)
                script_name = script_path.name
                label = PRETTY_NAMES.get(canonical, canonical)
                print(
                    "ERREUR DE COHÉRENCE : "
                    f"Chapitre {chapter}, Script {script_name} "
                    f"utilise {label}={format_value(value)} "
                    f"au lieu de {format_value(expected)}."
                )
                return 1

    print("COHÉRENCE OK : paramètres cosmologiques alignés.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
