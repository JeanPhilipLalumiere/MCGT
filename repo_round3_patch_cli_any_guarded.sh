# repo_round3_patch_cli_any_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round3_patch_cli_any_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd
BR="$(git rev-parse --abbrev-ref HEAD)"
echo "branche=${BR}"

TARGETS=(
  "zz-scripts/chapter09/plot_fig01_phase_overlay.py"
  "zz-scripts/chapter09/plot_fig02_residual_phase.py"
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"
  "zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py"
  "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py"
)

echo "== BACKUP =="
for f in "${TARGETS[@]}"; do
  [ -f "$f" ] || { echo "[SKIP] ${f} (absent)"; continue; }
  cp -a "$f" "${f}.bak_${TS}"
  echo "[OK] ${f}.bak_${TS}"
done

echo "== PATCH (agnostique du nom de parser) =="
python - <<'PYCODE'
import re, io
from pathlib import Path

targets = [
  "zz-scripts/chapter09/plot_fig01_phase_overlay.py",
  "zz-scripts/chapter09/plot_fig02_residual_phase.py",
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py",
  "zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py",
  "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py",
]

FLAGS = ["--out","--dpi","--format","--transparent","--style","--verbose"]

ARG_BLOCK_FMT = """{p}.add_argument('--out', type=str, default=None, help='Chemin de sortie (optionnel).')
{p}.add_argument('--dpi', type=float, default=150.0, help='DPI figure.')
{p}.add_argument('--format', default='png', choices=['png','pdf','svg'], help='Format de sortie.')
{p}.add_argument('--transparent', action='store_true', help='Fond transparent.')
{p}.add_argument('--style', default=None, help='Style Matplotlib (ex.: seaborn-v0_8).')
{p}.add_argument('--verbose', action='store_true', help='Verbosity (INFO).')
"""

POST_PARSE_BLOCK = """\
# === [CLI-INJECT BEGIN] ===
try:
    import matplotlib.pyplot as plt  # type: ignore
    import logging
    if 'args' not in globals():
        args = None  # fallback si parse_args() n'assigne pas
    if args is None:
        pass
    else:
        if getattr(args, 'verbose', False):
            logging.basicConfig(level=logging.INFO)
        try: plt.rcParams['savefig.dpi'] = getattr(args, 'dpi', 150.0)
        except Exception: pass
        try: plt.rcParams['savefig.format'] = getattr(args, 'format', 'png')
        except Exception: pass
        try: plt.rcParams['savefig.transparent'] = bool(getattr(args, 'transparent', False))
        except Exception: pass
        st = getattr(args, 'style', None)
        if st:
            try: plt.style.use(st)
            except Exception: pass
except Exception:
    pass
# === [CLI-INJECT END] ===
"""

def read(p: Path) -> str:
    try:
        return p.read_text()
    except UnicodeDecodeError:
        return p.read_text(encoding="utf-8", errors="ignore")

def already_has_flags(src: str) -> bool:
    return all(flag in src for flag in FLAGS)

def ensure_import_argparse(src: str) -> str:
    if re.search(r'^\s*(import argparse|from argparse import)', src, flags=re.M):
        return src
    return "import argparse\n" + src

def find_parser_name(src: str):
    # Capture X in "X = argparse.ArgumentParser(..."
    m = re.search(r'^\s*([A-Za-z_]\w*)\s*=\s*argparse\.ArgumentParser\s*\(', src, flags=re.M)
    if m:
        return m.group(1), m.end()
    return None, None

def insert_args_after_parser(src: str, parser_name: str, insert_pos: int) -> str:
    # Insère bloc si au moins un flag manque
    if already_has_flags(src):
        return src
    block = ARG_BLOCK_FMT.format(p=parser_name)
    return src[:insert_pos] + "\n" + block + src[insert_pos:]

def ensure_args_binding(src: str, parser_name: str) -> (str, int, str):
    """
    Retourne (src', pos_apres_parse, args_name)
    - si on trouve "VAR = parser.parse_args()", capture VAR comme args_name et renvoie pos après cette ligne
    - sinon si on trouve "parser.parse_args()" tout seul, on crée "args = parser.parse_args()" et renvoie pos
    - sinon, pos=-1
    """
    # cas assigné: Y = X.parse_args()
    pat_assign = rf'^\s*([A-Za-z_]\w*)\s*=\s*{re.escape(parser_name)}\.parse_args\s*\(\s*\)\s*$'
    m = re.search(pat_assign, src, flags=re.M)
    if m:
        y = m.group(1)
        line_end = m.end()
        return src, line_end, y
    # cas non assigné: X.parse_args()
    pat_call = rf'^\s*{re.escape(parser_name)}\.parse_args\s*\(\s*\)\s*$'
    m2 = re.search(pat_call, src, flags=re.M)
    if m2:
        # Remplacer par "args = X.parse_args()"
        start, end = m2.span()
        newline = f"args = {parser_name}.parse_args()"
        src2 = src[:start] + newline + src[end:]
        return src2, start + len(newline), "args"
    return src, -1, "args"

def inject_post_parse(src: str, after_pos: int) -> str:
    if "[CLI-INJECT BEGIN]" in src:
        return src
    if after_pos < 0:
        return src
    return src[:after_pos] + "\n" + POST_PARSE_BLOCK + src[after_pos:]

changed_any = False
for pth in targets:
    p = Path(pth)
    if not p.exists():
        print(f"[SKIP] {pth} (absent)")
        continue
    s0 = read(p)

    # 1) s’assurer de argparse
    s = ensure_import_argparse(s0)

    # 2) trouver le nom du parser
    parser_name, insert_pos = find_parser_name(s)
    if not parser_name:
        print(f"[KEEP] {pth} (parser introuvable)")
        continue

    # 3) insérer les flags si manquants
    s2 = insert_args_after_parser(s, parser_name, insert_pos)

    # 4) s'assurer d'une variable args et injecter post-parse
    s3, pos_after, args_name = ensure_args_binding(s2, parser_name)
    s4 = inject_post_parse(s3, pos_after)

    if s4 != s0:
        p.write_text(s4)
        print(f"[PATCH] {pth} (parser={parser_name}, args={args_name})")
        changed_any = True
    else:
        print(f"[KEEP] {pth} (déjà conforme)")
print("[DONE] Injection CLI (agnostique du nom) — changed_any=", changed_any)
PYCODE

echo "== GIT ADD/COMMIT/PUSH =="
git add ${TARGETS[@]} || true
if ! git diff --cached --quiet; then
  git commit -m "round3(ch09): injection CLI universelle (--out/--dpi/--format/--transparent/--style/--verbose) + post-parse rcParams"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
else
  echo "[NOTE] Rien à committer (aucun diff)."
fi
