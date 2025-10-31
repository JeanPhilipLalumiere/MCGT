# repo_fix_ch09_fig03_replace_main_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_fix_ch09_fig03_main_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

_guard_pause() {
  code=$?
  echo
  echo "[GUARD] Script terminé (exit=$code) — log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"
  read -r _
}
trap _guard_pause EXIT

F="zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD || true

echo "== BACKUP =="
cp -a "$F" "${F}.bak_${TS}"
echo "[OK] ${F}.bak_${TS}"

python - <<'PY'
import re, sys
from pathlib import Path

F = Path("zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py")
s = F.read_text(encoding="utf-8")

def patch_subblock(src):
    m_main = re.search(r'(?m)^(\s*)def\s+main\s*\(\)\s*:\s*$', src)
    if not m_main:
        return None
    indent_main = m_main.group(1)
    indent1 = indent_main + "    "

    m_start = re.search(rf'(?m)^{re.escape(indent1)}if\s+not\s+\(has_diff\s+or\s+has_csv\)\s*:\s*$', src)
    m_end   = re.search(rf'(?m)^{re.escape(indent_main)}fmin,\s*fmax\s*=\s*sorted\(map\(float,\s*args\.window\)\)', src)
    if not (m_start and m_end and m_end.start() > m_start.start()):
        return None

    new_block = f"""{indent1}# --- Bloc réparé Round2 (sub-block) ---
{indent1}if not (has_diff or has_csv):
{indent1}    raise SystemExit(f"Aucun fichier d'entrée: {{getattr(args,'diff',None)}} / {{getattr(args,'csv',None)}}")
{indent1}
{indent1}if has_diff:
{indent1}    df = pd.read_csv(args.diff)
{indent1}    if {{'f_Hz','abs_dphi'}}.issubset(df.columns):
{indent1}        f = df['f_Hz'].to_numpy(float)
{indent1}        abs_dphi = df['abs_dphi'].to_numpy(float)
{indent1}        data_label = args.diff.name
{indent1}        log.info("Chargé diff CSV: %s (%d points).", args.diff, len(df))
{indent1}    else:
{indent1}        log.warning("%s existe mais colonnes manquantes -> fallback sur --csv", args.diff)
{indent1}        has_diff = False
{indent1}
{indent1}if not has_diff:
{indent1}    mc = pd.read_csv(args.csv).sort_values('f_Hz')
{indent1}    need = {{'f_Hz','phi_ref','phi_mcgt'}}
{indent1}    if not need.issubset(mc.columns):
{indent1}        manq = need - set(mc.columns)
{indent1}        raise SystemExit(f"Colonnes manquantes dans --csv: {manq}")
{indent1}    f = mc['f_Hz'].to_numpy(float)
{indent1}    abs_dphi = (mc['phi_mcgt'] - mc['phi_ref']).abs().to_numpy(float)
{indent1}    data_label = args.csv.name
"""
    start, end = m_start.start(), m_end.start()
    return src[:start] + new_block + src[end:]

def replace_whole_main(src):
    m_main = re.search(r'(?m)^(\s*)def\s+main\s*\(\)\s*:\s*$', src)
    if not m_main:
        raise SystemExit("def main() introuvable — abandon")
    indent_main = m_main.group(1)
    # Chercher la fin de main(): prochain def/class/if __name__ top-level OU EOF
    m_next = re.search(r'(?m)^(def\s+|class\s+|if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:)', src[m_main.end():])
    end_main = m_main.end() + (m_next.start() if m_next else (len(src)-m_main.end()))

    head = src[:m_main.end()]
    tail = src[end_main:]

    body = f"""
{indent_main}    # === Corps de main() reconstruit Round2 (idempotent) ===
{indent_main}    import numpy as np, pandas as pd, matplotlib.pyplot as plt
{indent_main}    from pathlib import Path
{indent_main}
{indent_main}    args = parse_args()
{indent_main}    log = setup_logger(getattr(args, "log_level", "INFO"))
{indent_main}
{indent_main}    # Préférence: --diff (f_Hz, abs_dphi) ; fallback --csv (phi_ref, phi_mcgt)
{indent_main}    f = None
{indent_main}    abs_dphi = None
{indent_main}    data_label = None
{indent_main}
{indent_main}    has_diff = bool(getattr(args, "diff", None)) and Path(args.diff).exists()
{indent_main}    has_csv  = bool(getattr(args, "csv", None))  and Path(args.csv).exists()
{indent_main}
{indent_main}    if not (has_diff or has_csv):
{indent_main}        raise SystemExit(f"Aucun fichier d'entrée: {{getattr(args,'diff',None)}} / {{getattr(args,'csv',None)}}")
{indent_main}
{indent_main}    if has_diff:
{indent_main}        df = pd.read_csv(args.diff)
{indent_main}        if {{'f_Hz','abs_dphi'}}.issubset(df.columns):
{indent_main}            f = df['f_Hz'].to_numpy(float)
{indent_main}            abs_dphi = df['abs_dphi'].to_numpy(float)
{indent_main}            data_label = Path(args.diff).name
{indent_main}            log.info("Chargé diff CSV: %s (%d points).", args.diff, len(df))
{indent_main}        else:
{indent_main}            log.warning("%s existe mais colonnes manquantes -> fallback sur --csv", args.diff)
{indent_main}            has_diff = False
{indent_main}
{indent_main}    if not has_diff:
{indent_main}        mc = pd.read_csv(args.csv).sort_values('f_Hz')
{indent_main}        need = {{'f_Hz','phi_ref','phi_mcgt'}}
{indent_main}        if not need.issubset(mc.columns):
{indent_main}            manq = need - set(mc.columns)
{indent_main}            raise SystemExit(f"Colonnes manquantes dans --csv: {{manq}}")
{indent_main}        f = mc['f_Hz'].to_numpy(float)
{indent_main}        abs_dphi = (mc['phi_mcgt'] - mc['phi_ref']).abs().to_numpy(float)
{indent_main}        data_label = Path(args.csv).name
{indent_main}
{indent_main}    # Fenêtre
{indent_main}    win = getattr(args, "window", (20.0, 300.0))
{indent_main}    try:
{indent_main}        fmin, fmax = sorted(map(float, win))
{indent_main}    except Exception:
{indent_main}        fmin, fmax = 20.0, 300.0
{indent_main}
{indent_main}    sel = (f >= fmin) & (f <= fmax) & np.isfinite(abs_dphi)
{indent_main}    if not np.any(sel):
{indent_main}        raise SystemExit(f"Aucun point dans la fenêtre {{fmin}}-{{fmax}} Hz")
{indent_main}
{indent_main}    vals = abs_dphi[sel]
{indent_main}
{indent_main}    # Plot
{indent_main}    fig = plt.figure()
{indent_main}    plt.hist(vals, bins=getattr(args, "bins", 80))
{indent_main}    plt.xscale("log")
{indent_main}    plt.xlabel("|Δφ| (rad)")
{indent_main}    plt.ylabel("Counts")
{indent_main}    plt.title("Histogramme |Δφ| — bande {{:.0f}}–{{:.0f}} Hz".format(fmin, fmax))
{indent_main}
{indent_main}    out = getattr(args, "out", "zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png")
{indent_main}    Path(out).parent.mkdir(parents=True, exist_ok=True)
{indent_main}    fig.savefig(out, dpi=getattr(args, "dpi", 150), bbox_inches="tight")
{indent_main}    print(f"Wrote: {{out}}")
"""
    return head + body + tail

# 1) Tentative “sub-block”
patched = patch_subblock(s)
mode = "sub-block"
if patched is None:
    # 2) Remplacement complet de main()
    patched = replace_whole_main(s)
    mode = "whole-main"

Path(F).write_text(patched, encoding="utf-8")
print(f"Patch appliqué en mode: {mode}")
PY

echo "== SANITY =="
if python -m py_compile "$F"; then
  echo "[OK] py_compile"
else
  echo "[FAIL] py_compile — restauration…"
  cp -a "${F}.bak_${TS}" "$F"
  exit 1
fi

python "$F" --help | sed -n '1,80p' || true

echo "== DRY-RUN (optionnel) =="
OUT="/tmp/mcgt_ch09_fig03_${TS}"
mkdir -p "$OUT"
if [ -f "zz-data/chapter09/09_phase_diff.csv" ]; then
  python "$F" --diff zz-data/chapter09/09_phase_diff.csv --out "$OUT/09_fig_03_hist_absdphi_20_300.png" --dpi 150 || true
  ls -lh "$OUT" || true
else
  echo "[NOTE] zz-data/chapter09/09_phase_diff.csv introuvable — dry-run sauté."
fi

echo "== DONE =="
