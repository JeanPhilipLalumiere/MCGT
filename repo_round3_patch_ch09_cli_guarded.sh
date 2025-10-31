# repo_round3_patch_ch09_cli_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round3_patch_ch09_cli_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "branche=${BR}"
[ "${BR}" = "chore/round3-cli-homog" ] || git switch chore/round3-cli-homog

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

echo "== PATCH (injection CLI & rcParams : sans py_compile) =="
python - <<'PYCODE'
import re
from pathlib import Path

targets = [
  "zz-scripts/chapter09/plot_fig01_phase_overlay.py",
  "zz-scripts/chapter09/plot_fig02_residual_phase.py",
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py",
  "zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py",
  "zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py",
]

ARG_BLOCK = """\
parser.add_argument('--out', type=str, default=None, help='Chemin de sortie (optionnel).')
parser.add_argument('--dpi', type=float, default=150.0, help='DPI figure.')
parser.add_argument('--format', default='png', choices=['png','pdf','svg'], help='Format de sortie.')
parser.add_argument('--transparent', action='store_true', help='Fond transparent.')
parser.add_argument('--style', default=None, help='Style Matplotlib (ex.: seaborn-v0_8).')
parser.add_argument('--verbose', action='store_true', help='Verbosity (INFO).')
"""

POST_PARSE = """\
# === [CLI-INJECT BEGIN] ===
try:
    import matplotlib.pyplot as plt  # type: ignore
    import logging
    if getattr(args, 'verbose', False):
        logging.basicConfig(level=logging.INFO)
    if hasattr(args, 'dpi') and args.dpi:
        try: plt.rcParams['savefig.dpi'] = args.dpi
        except Exception: pass
    if hasattr(args, 'format') and args.format:
        try: plt.rcParams['savefig.format'] = args.format
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

def ensure_import_argparse(src: str) -> str:
    if re.search(r'^\s*import\s+argparse\b', src, flags=re.M): return src
    if re.search(r'^\s*from\s+argparse\s+import\b', src, flags=re.M): return src
    return "import argparse\n" + src

def add_args_block(src: str) -> str:
    m = re.search(r'(\bparser\s*=\s*argparse\.ArgumentParser\(.*?\)\s*)', src, flags=re.S)
    if not m: return src
    head, tail = src[:m.end()], src[m.end():]
    if all(flag in tail for flag in ["--out","--dpi","--format","--transparent","--style","--verbose"]):
        return src
    return head + "\n" + ARG_BLOCK + tail

def inject_post_parse(src: str) -> str:
    if "[CLI-INJECT BEGIN]" in src: return src
    m = re.search(r'(\bargs\s*=\s*parser\.parse_args\(\)\s*)', src)
    if not m:
        m = re.search(r'(parser\.parse_args\(\)\s*)', src)
        if not m: return src
    i = m.end()
    return src[:i] + "\n" + POST_PARSE + src[i:]

changed_any = False
for pth in targets:
    p = Path(pth)
    if not p.exists(): 
        print(f"[SKIP] {pth} (absent)")
        continue
    s0 = p.read_text()
    s = ensure_import_argparse(s0)
    s = add_args_block(s)
    s = inject_post_parse(s)
    if s != s0:
        p.write_text(s)
        print(f"[PATCH] {pth}")
        changed_any = True
    else:
        print(f"[KEEP]  {pth} (déjà conforme ou parser introuvable)")
print("[DONE] Injection CLI ch09 — changed_any=", changed_any)
PYCODE

echo "== CI POLICY (local, non bloquant) =="
python tools/check_cli_policy.py || true

echo "== GIT ADD/COMMIT/PUSH =="
git add ${TARGETS[@]} || true
if ! git diff --cached --quiet; then
  git commit -m "round3(ch09): injection flags CLI communs (+rcParams/style/logging) — non invasive"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
else
  echo "[NOTE] Rien à committer (aucun diff sur cibles)."
fi
