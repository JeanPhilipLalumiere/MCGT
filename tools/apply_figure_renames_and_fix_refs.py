#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Renomme les figures selon .ci-out/figures_rename_plan.tsv
et corrige automatiquement toutes les références dans le dépôt.

Usage:
  python tools/apply_figure_renames_and_fix_refs.py           # dry-run
  python tools/apply_figure_renames_and_fix_refs.py --apply   # applique
Options:
  --plan PATH     chemin du TSV (def: .ci-out/figures_rename_plan.tsv)
  --no-git        n'utilise pas git mv (fallback os.rename)
  --verbose       sortie détaillée
"""
from __future__ import annotations
import argparse, csv, fnmatch, io, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PLAN = ROOT / ".ci-out" / "figures_rename_plan.tsv"
LOGDIR = ROOT / ".ci-logs"

ALLOW_EXT = {
    ".md",".mdx",".rst",".tex",".py",".sh",".bash",
    ".yml",".yaml",".json",".toml",".ini",".txt",".ipynb",
}
EXCLUDE_DIRS = {
    ".git",".hg",".svn",".ci-archive",".ci-logs",".tmp-ci",".tmp-cleanup-logs",
    "dist","dist_from","build","site",".venv","venv","env","node_modules",
    "artifacts_","zz-figures",  # on évite de scanner les binaires/PNGs
}

def ts_now():
    return time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())

def is_binary_chunk(b: bytes) -> bool:
    return b"\x00" in b

def is_text_file(p: Path) -> bool:
    if p.suffix.lower() in ALLOW_EXT:
        try:
            with open(p, "rb") as fh:
                chunk = fh.read(4096)
            return not is_binary_chunk(chunk)
        except Exception:
            return False
    return False

def should_exclude(path: Path) -> bool:
    parts = path.relative_to(ROOT).parts
    for i, part in enumerate(parts):
        # exclude by exact or prefix (artifacts_, dist_from, etc.)
        if part in EXCLUDE_DIRS:
            return True
        if any(part.startswith(prefix) for prefix in EXCLUDE_DIRS if prefix.endswith("_")):
            return True
    return False

def detect_git() -> bool:
    return (ROOT / ".git").exists() and shutil.which("git") is not None

def git_mv(src: Path, dst: Path) -> subprocess.CompletedProcess | None:
    cmd = ["git", "mv", "-v", str(src), str(dst)]
    return subprocess.run(cmd, cwd=str(ROOT), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

def safe_rename(src: Path, dst: Path, use_git=True, verbose=False):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if use_git and detect_git():
        res = git_mv(src, dst)
        if verbose:
            sys.stdout.write(res.stdout)
            if res.stderr.strip():
                sys.stdout.write(res.stderr)
        if res.returncode != 0:
            raise RuntimeError(f"git mv failed: {res.stderr.strip()}")
    else:
        os.rename(src, dst)

def load_plan(plan_path: Path) -> list[tuple[Path, Path]]:
    if not plan_path.exists():
        raise FileNotFoundError(f"Plan introuvable: {plan_path}")
    mappings = []
    with open(plan_path, "r", encoding="utf-8") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            src = (ROOT / row["source"]).resolve()
            dst = (ROOT / row["proposed_target"]).resolve()
            mappings.append((src, dst))
    return mappings

def preflight(mappings: list[tuple[Path, Path]]) -> dict:
    seen_targets = set()
    diagnostics = {"missing_sources": [], "existing_targets": [], "ok": True}
    for src, dst in mappings:
        if not src.exists():
            diagnostics["missing_sources"].append(str(src.relative_to(ROOT)))
        if dst.exists():
            diagnostics["existing_targets"].append(str(dst.relative_to(ROOT)))
        key = str(dst).lower()
        if key in seen_targets:
            diagnostics["existing_targets"].append(f"DUPLICATE_TARGET:{str(dst.relative_to(ROOT))}")
        seen_targets.add(key)
    if diagnostics["missing_sources"] or diagnostics["existing_targets"]:
        diagnostics["ok"] = False
    return diagnostics

def collect_text_files() -> list[Path]:
    files = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dir_rel = Path(dirpath).resolve()
        # prune excluded dirs early
        pruned = []
        for d in list(dirnames):
            if should_exclude(dir_rel / d):
                pruned.append(d)
        for d in pruned:
            dirnames.remove(d)
        for fn in filenames:
            p = dir_rel / fn
            if is_text_file(p):
                files.append(p)
    return files

def replace_in_file(path: Path, replacements: list[tuple[str, str]]) -> int:
    """Return count of replacements done."""
    try:
        raw = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        # tente lecture tolérante pour ne pas bloquer
        raw = path.read_text(encoding="utf-8", errors="ignore")
    original = raw
    count = 0
    for old, new in replacements:
        c = raw.count(old)
        if c:
            raw = raw.replace(old, new)
            count += c
    if count and raw != original:
        path.write_text(raw, encoding="utf-8")
    return count

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plan", default=str(DEFAULT_PLAN))
    ap.add_argument("--apply", action="store_true", help="Applique réellement les changements")
    ap.add_argument("--no-git", action="store_true", help="N'utilise pas git mv")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    LOGDIR.mkdir(parents=True, exist_ok=True)
    stamp = ts_now()
    report = {
        "timestamp": stamp,
        "root": str(ROOT),
        "plan": args.plan,
        "apply": bool(args.apply),
        "use_git": (not args.no_git) and detect_git(),
        "renames": [],
        "ref_updates": {},
        "warnings": [],
    }

    mappings = load_plan(Path(args.plan))
    # tri DESC par longueur d'ancienne chaîne (pour la phase remplacement)
    str_map = []
    for src, dst in mappings:
        try:
            old = str(src.relative_to(ROOT)).replace("\\", "/")
            new = str(dst.relative_to(ROOT)).replace("\\", "/")
        except ValueError:
            old = str(src).replace("\\", "/")
            new = str(dst).replace("\\", "/")
        str_map.append((old, new))

    # Preflight
    pf = preflight(mappings)
    report["preflight"] = pf
    if not pf["ok"]:
        msg = []
        if pf["missing_sources"]:
            msg.append(f"Sources manquantes: {len(pf['missing_sources'])}")
        if pf["existing_targets"]:
            msg.append(f"Cibles déjà existantes/dupliquées: {len(pf['existing_targets'])}")
        summary = " / ".join(msg)
        report["warnings"].append(summary)
        if not args.apply:
            # En dry-run, on informe mais on continue pour montrer ce qui serait fait.
            pass
        else:
            # En mode applique, on refuse si préflight KO (sécurité)
            out = LOGDIR / f"figure_rename_report_{stamp}.json"
            out.write_text(json.dumps(report, indent=2, ensure_ascii=False))
            print(f"❌ Préflight invalide. Détails: {out}")
            sys.exit(2)

    # Renommage
    if args.apply:
        for src, dst in mappings:
            if not src.exists():
                continue
            if dst.exists():
                # éviter collision silencieuse
                report["warnings"].append(f"Target exists, skipping rename: {dst.relative_to(ROOT)}")
                continue
            if args.verbose:
                print(f"mv: {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")
            safe_rename(src, dst, use_git=(not args.no_git), verbose=args.verbose)
            report["renames"].append({
                "from": str(src.relative_to(ROOT)),
                "to": str(dst.relative_to(ROOT)),
            })
    else:
        for src, dst in mappings:
            exists = src.exists()
            report["renames"].append({
                "from": str(src.relative_to(ROOT)),
                "to": str(dst.relative_to(ROOT)),
                "would_rename": exists and not dst.exists()
            })

    # Réécriture des références
    # Important: trier par longueur décroissante de l'ancien chemin pour éviter remplacements partiels
    str_map.sort(key=lambda t: len(t[0]), reverse=True)
    replacements = str_map

    changed_files = 0
    total_repls = 0
    text_files = collect_text_files()
    for f in text_files:
        # Sécurité en dry-run: on ne touche pas le disque, mais on simule le nombre de matches
        try:
            data = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            data = f.read_text(encoding="utf-8", errors="ignore")
        would = 0
        for old, new in replacements:
            would += data.count(old)
        if would:
            if args.apply:
                n = replace_in_file(f, replacements)
            else:
                n = would
            changed_files += 1
            total_repls += n
            report["ref_updates"][str(f.relative_to(ROOT))] = n

    # Sauvegarde des rapports
    out_json = LOGDIR / f"figure_rename_report_{stamp}.json"
    out_txt = LOGDIR / f"figure_rename_report_{stamp}.log"

    out_json.write_text(json.dumps(report, indent=2, ensure_ascii=False))
    with open(out_txt, "w", encoding="utf-8") as fh:
        fh.write(f"[{stamp}] apply={args.apply} use_git={(not args.no_git) and detect_git()}\n")
        fh.write(f"Plan: {args.plan}\n")
        fh.write(f"Renames plan entries: {len(mappings)}\n")
        fh.write(f"Changed files (refs): {changed_files}\n")
        fh.write(f"Total replacements: {total_repls}\n")
        if report["warnings"]:
            fh.write("Warnings:\n")
            for w in report["warnings"]:
                fh.write(f"  - {w}\n")

    # Résumé console
    if args.apply:
        print(f"✅ Renommage + corrections appliqués.")
    else:
        print(f"🧪 Dry-run terminé (aucune modification écrite).")
    print(f"Fichiers texte modifiés (ou modifiables): {changed_files}")
    print(f"Nombre total de remplacements: {total_repls}")
    print(f"Rapport JSON : {out_json}")
    print(f"Rapport texte : {out_txt}")

if __name__ == "__main__":
    main()
