#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_orchestrator.py

Orchestrateur pour scripts de tracé MCGT (zz-scripts/chapterNN/plot_figXX_*.py).

Fonctions clés :
- Nom canonique de sortie : zz-figures/chapterNN/NN_fig_XX_<slug>.<ext>
- Sonde du script via `--help` :
  * détecte la présence de `--out`
  * tente de repérer les options *requises* (ex: `--results`) et avertit si absentes
- Fallbacks d’exécution :
  A) avec --out (+ --dpi si fourni)
  B) sans --out (+ --dpi)
  C) sans --out ni --dpi
- Renommage post-exécution si le script n’accepte pas --out : détecte le nouveau fichier créé et le renomme vers le nom canonique
- Vérification d’existence des fichiers passés à des flags connus: --results/--csv/--input/--in/--data/--file
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple, Optional, Set, Dict

ROOT = Path(__file__).resolve().parents[1]  # racine du dépôt
PYTHON = sys.executable
FIG_ROOT = ROOT / "zz-figures"


# ----------------------------- Helpers ---------------------------------- #

def _chapter_from_path(p: Path) -> Optional[str]:
    for part in p.parts:
        m = re.match(r"chapter(\d{2})$", part)
        if m:
            return m.group(1)
    return None


def _fig_token_from_filename(p: Path) -> Optional[Tuple[str, str]]:
    m = re.match(r"plot_(fig(\d{2}))_(.+)\.py$", p.name)
    if not m:
        return None
    fig_num = m.group(2)     # '02'
    slug = m.group(3)        # 'something'
    return f"fig_{fig_num}", slug


def _build_canonical(script: Path, fmt: str) -> Path:
    chap = _chapter_from_path(script)
    ft = _fig_token_from_filename(script)
    if not chap or not ft:
        raise ValueError(f"Impossible d'inférer chapter/fig depuis {script}")
    fig_token, slug = ft
    out_dir = FIG_ROOT / f"chapter{chap}"
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir / f"{chap}_{fig_token}_{slug}.{fmt}"


def _print_run(cmd: List[str]) -> None:
    print("[RUN]", " ".join(cmd))


def _short_tail(text: str, n: int = 1200) -> str:
    text = text or ""
    return text[-n:]


def _run_command(cmd: List[str], cwd: Path) -> Tuple[int, str, str]:
    p = subprocess.Popen(
        cmd,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    out, err = p.communicate()
    return p.returncode, out, err


def _ls_figdir(dirpath: Path) -> Set[Path]:
    exts = (".png", ".pdf", ".svg")
    return {p for p in dirpath.glob("*") if p.suffix.lower() in exts and p.is_file()}


def _parse_required_from_usage(usage_text: str) -> Set[str]:
    """
    Heuristique : dans la/les ligne(s) 'usage:', tout ce qui est '--flag ...'
    en dehors des crochets [] est considéré 'requis'.
    """
    req: Set[str] = set()
    lines = [ln.strip() for ln in usage_text.splitlines() if ln.strip().startswith("usage:")]
    if not lines:
        return req

    # Colle toutes les lignes usage pour simplifier
    usage = " ".join(lines)

    # Remplacer les blocs optionnels [ ... ] par un token placeholder
    usage_no_opt = re.sub(r"\[[^\]]*\]", " ", usage)

    # Extraire les --flags restants (hors blocs optionnels donc supposés requis)
    for m in re.finditer(r"--[A-Za-z0-9][A-Za-z0-9_-]*", usage_no_opt):
        req.add(m.group(0))
    return req


def _probe_help_and_required(script: Path) -> Tuple[bool, Set[str], str]:
    """
    Retourne:
      (supports_out, required_flags, usage_text)
    - supports_out: True si '--out' apparaît dans `--help`
    - required_flags: heuristique des flags requis (depuis 'usage:')
    - usage_text: concat stdout/stderr du --help
    """
    rc, out, err = _run_command([PYTHON, str(script), "--help"], ROOT)
    help_text = (out or "") + "\n" + (err or "")
    supports_out = ("--out" in help_text)

    # Essaye d'attraper des flags explicitement requis depuis 'usage:'
    required_flags = _parse_required_from_usage(help_text)

    # Si rien n'a été trouvé, tente une exécution 'à vide' pour déclencher argparse (rc=2)
    if not required_flags:
        rc2, out2, err2 = _run_command([PYTHON, str(script)], ROOT)
        if rc2 == 2 and err2:
            # argparse imprime souvent: "the following arguments are required: --results, ..."
            m = re.search(r"the following arguments are required:\s*(.+)", err2)
            if m:
                required_flags |= set(re.findall(r"--[A-Za-z0-9][A-Za-z0-9_-]*", m.group(1)))

            # Et complète via la/les ligne(s) 'usage:'
            required_flags |= _parse_required_from_usage(out2 + "\n" + err2)

            help_text += "\n" + (out2 or "") + (err2 or "")

    return supports_out, required_flags, help_text


def _split_flags_from_user_args(user_args: List[str]) -> Dict[str, str]:
    """
    Transforme [..., '--results', 'path.csv', '--alpha', '0.5', '--flag-only', ...]
    en dict { '--results': 'path.csv', '--alpha': '0.5', '--flag-only': '' }.
    Gère aussi --foo=bar.
    """
    res: Dict[str, str] = {}
    i = 0
    while i < len(user_args):
        tok = user_args[i]
        if tok.startswith("--"):
            if "=" in tok:
                k, v = tok.split("=", 1)
                res[k] = v
                i += 1
                continue
            # peek next
            if i + 1 < len(user_args) and not user_args[i + 1].startswith("-"):
                res[tok] = user_args[i + 1]
                i += 2
            else:
                res[tok] = ""
                i += 1
        else:
            i += 1
    return res


def _check_known_file_flags(flag_map: Dict[str, str]) -> Optional[str]:
    """
    Vérifie l’existence des chemins fournis à certains flags connus.
    Retourne un message d’erreur si un fichier est manquant, sinon None.
    """
    known = {"--results", "--csv", "--input", "--in", "--data", "--file"}
    for k in known:
        if k in flag_map:
            v = flag_map[k]
            if v:
                p = (ROOT / v) if not os.path.isabs(v) else Path(v)
                if not p.exists():
                    return f"Chemin fourni à {k} introuvable: {p}"
    return None


# ----------------------------- Orchestrator ------------------------------ #

def main() -> None:
    ap = argparse.ArgumentParser(
        description="Orchestrateur pour scripts plot_figXX_*.py (MCGT).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    ap.add_argument("script", type=str, help="Chemin du script de tracé (plot_figXX_*.py)")
    ap.add_argument("--dpi", type=int, default=None, help="DPI à transmettre au script (si supporté)")
    ap.add_argument("--format", default="png", choices=["png", "pdf", "svg"], help="Format canonique de la sortie")
    ap.add_argument("--dry-run", action="store_true", help="Afficher les commandes sans exécuter")
    ap.add_argument("-v", "--verbose", action="count", default=0, help="Verbosité cumulable")
    # Tous les args restants (après ceux ci-dessus) sont passés tels quels au script cible.
    ap.add_argument("script_args", nargs=argparse.REMAINDER, help="Arguments pour le script cible (utilisez `--` pour séparer)")
    args = ap.parse_args()

    script = Path(args.script).resolve()
    if not script.exists():
        ap.error(f"Script introuvable: {script}")
    if script.suffix != ".py":
        ap.error("Le script cible doit être un .py")

    # Nettoie les éventuels séparateurs `--` dans les args utilisateurs
    user_args = [a for a in (args.script_args or []) if a not in ("--", "—")]

    # Sonde le script pour savoir s'il accepte --out et lister les flags requis
    supports_out, required_flags, help_text = _probe_help_and_required(script)

    # Vérifie que les flags requis (si détectés) sont bien fournis
    if required_flags:
        provided = set()
        # flags présents dans user_args, ex: '--results', ou '--results=...'
        for tok in user_args:
            if tok.startswith("--"):
                key = tok.split("=", 1)[0]
                provided.add(key)
        missing = sorted([f for f in required_flags if f not in provided])
        if missing:
            print("[ERR] Le script signale des options requises manquantes:", ", ".join(missing))
            # Affiche la ligne usage la plus parlante
            usage_lines = [ln for ln in help_text.splitlines() if ln.strip().startswith("usage:")]
            if usage_lines:
                print(">>>", usage_lines[0].strip())
            print("Astuce: passez-les après `--`, ex.:")
            print(f"  python3 tools/plot_orchestrator.py {script} --dpi 300 -- {' '.join(missing)} <valeur>")
            sys.exit(2)

    # Vérifie existence de fichiers pour quelques flags connus
    fm = _split_flags_from_user_args(user_args)
    file_err = _check_known_file_flags(fm)
    if file_err:
        print(f"[ERR] {file_err}")
        sys.exit(2)

    # Construit le chemin canonique de sortie
    try:
        out_path = _build_canonical(script, args.format)
    except Exception as e:
        print(f"[ERR] Canonical name error: {e}", file=sys.stderr)
        sys.exit(2)

    fig_dir = out_path.parent
    before = _ls_figdir(fig_dir)

    # Construit les 3 variantes
    base = [PYTHON, str(script)]
    cmd_A = list(base)
    if supports_out:
        cmd_A += ["--out", str(out_path)]
    if args.dpi is not None:
        cmd_A += ["--dpi", str(args.dpi)]
    cmd_A += user_args

    cmd_B = list(base)
    if args.dpi is not None:
        cmd_B += ["--dpi", str(args.dpi)]
    cmd_B += user_args

    cmd_C = list(base) + user_args  # ni --out ni --dpi

    # Dry-run ?
    if args.dry_run:
        if supports_out:
            _print_run(cmd_A)
        _print_run(cmd_B)
        _print_run(cmd_C)
        print("[DRY] Fin (aucune exécution).")
        return

    # Exécution avec fallbacks
    # A) (si --out supporté)
    if supports_out:
        _print_run(cmd_A)
        rc, out, err = _run_command(cmd_A, ROOT)
        if rc == 0:
            produced_rc = 0
        else:
            print(f"[WARN] return code {rc}; retrying without --out")
            if err:
                print("[STDERR first run]")
                print(_short_tail(err))
            # B)
            _print_run(cmd_B)
            rc2, out2, err2 = _run_command(cmd_B, ROOT)
            if rc2 == 0:
                produced_rc = 0
                out, err = out2, err2
            else:
                print("[ERR] script failed again; retrying without --out and without --dpi")
                if err2:
                    print("[STDERR second run]")
                    print(_short_tail(err2))
                # C)
                _print_run(cmd_C)
                rc3, out3, err3 = _run_command(cmd_C, ROOT)
                produced_rc = rc3
                out, err = out3, err3
                if rc3 != 0:
                    print("[ERR] script failed third time; aborting")
                    if err3:
                        print("[STDERR third run]")
                        print(_short_tail(err3))
                    sys.exit(rc3)
    else:
        # pas de --out : commence directement par B)
        _print_run(cmd_B)
        rc2, out2, err2 = _run_command(cmd_B, ROOT)
        if rc2 == 0:
            produced_rc = 0
            out, err = out2, err2
        else:
            print("[WARN] return code", rc2, "; retrying without --dpi")
            if err2:
                print("[STDERR first run]")
                print(_short_tail(err2))
            _print_run(cmd_C)
            rc3, out3, err3 = _run_command(cmd_C, ROOT)
            produced_rc = rc3
            out, err = out3, err3
            if rc3 != 0:
                print("[ERR] script failed again; aborting")
                if err3:
                    print("[STDERR second run]")
                    print(_short_tail(err3))
                sys.exit(rc3)

    # Post-traitement (renommage si nécessaire)
    produced = out_path.exists()
    if not produced:
        after = _ls_figdir(fig_dir)
        new_files = sorted(after - before)
        if len(new_files) == 1:
            src = new_files[0]
            if src != out_path:
                # Ajuste l'extension si besoin
                if out_path.suffix.lower() != src.suffix.lower():
                    out_path = out_path.with_suffix(src.suffix)
                try:
                    shutil.move(str(src), str(out_path))
                    produced = True
                    print(f"[INFO] Renamed {src.name} -> {out_path.name}")
                except Exception as e:
                    print(f"[WARN] Impossible de renommer {src} -> {out_path} : {e}")
        elif len(new_files) > 1:
            # Essaie une heuristique : choisir un nom qui commence par 'fig_XX_' ou contient le slug
            ft = _fig_token_from_filename(script)
            slug = ft[1] if ft else ""
            candidates = [p for p in new_files if re.match(r"fig_\d{2}_", p.name) or slug in p.stem]
            if len(candidates) == 1:
                src = candidates[0]
                if out_path.suffix.lower() != src.suffix.lower():
                    out_path = out_path.with_suffix(src.suffix)
                try:
                    shutil.move(str(src), str(out_path))
                    produced = True
                    print(f"[INFO] Renamed {src.name} -> {out_path.name}")
                except Exception as e:
                    print(f"[WARN] Impossible de renommer {src} -> {out_path} : {e}")
            else:
                print(f"[WARN] Plusieurs nouveaux fichiers détectés : {[p.name for p in new_files]}")
                print("[WARN] Renommage automatique abandonné.")

    if produced and produced_rc == 0:
        print(f"[OK] Figure produite → {out_path}")
        sys.exit(0)
    else:
        print(f"[WARN] Sortie attendue introuvable : {out_path}")
        sys.exit(1)


if __name__ == "__main__":
    main()
