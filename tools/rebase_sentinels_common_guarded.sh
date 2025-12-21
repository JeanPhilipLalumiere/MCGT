#!/usr/bin/env bash
# rebase_sentinels_common_guarded.sh
# Homogénéise 4 scripts sentinelles vers _common/cli + garde-fou (anti-fermeture)
# Idempotent, journalisé, avec sauvegardes et mini-smoke si disponible.

# ─────────────────────────────────────────────────────────────────────────────
set -u  # pas de -e → on n'abandonne pas sur RC!=0
TS="$(date +%Y-%m-%dT%H%M%S)"
LOG=".ci-out/rebase_sentinels_common_${TS}.log"
BK="_autofix_sandbox/${TS}_sentinels_backup"
mkdir -p .ci-out "$BK"

say(){ printf "%s %s\n" "[$(date +%H:%M:%S)]" "$*" | tee -a "$LOG"; }
run(){ say "\$ $*"; ( eval "$@" ) >>"$LOG" 2>&1; local RC=$?; [ $RC -ne 0 ] && say "→ RC=$RC (continue)"; return 0; }

S1="scripts/chapter07/plot_fig04_dcs2_vs_k.py"
S2="scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
S3="scripts/chapter04/plot_fig02_invariants_histogram.py"
S4="scripts/chapter03/plot_fig01_fR_stability_domain.py"

for f in "$S1" "$S2" "$S3" "$S4"; do
  if [ -f "$f" ]; then run "cp -a '$f' '$BK/'"; else say "AVERTISSEMENT: manquant: $f"; fi
done

# ── Chapitre 07 ──────────────────────────────────────────────────────────────
cat > "$S1" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys, pathlib
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DEF_CSV  = "assets/zz-data/chapter07/07_dcs2_dk.csv"
DEF_META = "assets/zz-data/chapter07/07_meta.json"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap7 Δc_s^2(k) vs k (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV)
    p.add_argument("--meta", default=DEF_META)
    p.add_argument("--kmin", type=float, default=None)
    p.add_argument("--kmax", type=float, default=None)
    p.add_argument("--k-split", type=float, default=2e-2)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter07_fig04_dcs2_vs_k"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize, constrained_layout=True)

    if not os.path.isfile(args.data):
        log.warning("Données absentes → %s", args.data)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data, comment="#")
    cols = {c.lower(): c for c in df.columns}
    kcol = cols.get("k") or cols.get("k_hmpc") or list(df.columns)[0]
    vcol = cols.get("dcs2") or cols.get("delta_cs2") or list(df.columns)[1]

    s = df[[kcol, vcol]].dropna()
    if args.kmin is not None: s = s[s[kcol] >= args.kmin]
    if args.kmax is not None: s = s[s[kcol] <= args.kmax]
    s = s.sort_values(kcol)

    ax.plot(s[kcol].values, s[vcol].values, linestyle="-", marker="", label=vcol)
    if args.k_split and args.k_split>0: ax.axvline(args.k_split, linestyle="--", linewidth=0.9)
    ax.set_xscale("log"); ax.set_xlabel("k [h/Mpc]"); ax.set_ylabel(r"$\Delta c_s^2(k)$")
    ax.grid(True, linestyle=":", linewidth=0.5); ax.legend(fontsize=9); ax.set_title("Chapitre 7 — Δc_s^2(k)")
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
PY

# ── Chapitre 10 ──────────────────────────────────────────────────────────────
cat > "$S2" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys, pathlib
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DEF_RESULTS = "assets/zz-data/chapter10/10_metrics_primary.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap10 Hist & CDF des métriques (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--results", default=DEF_RESULTS, help="CSV des métriques")
    p.add_argument("--metrics", nargs="*", default=None, help="Colonnes à tracer (auto si vide)")
    p.add_argument("--bins", type=int, default=50)
    return p

def select_numeric_columns(df: pd.DataFrame, user_cols: list[str] | None) -> list[str]:
    if user_cols: return [c for c in user_cols if c in df.columns]
    num = df.select_dtypes(include=[np.number]).columns.tolist()
    blacklist = {"idx","id","run","seed"}
    return [c for c in num if c.lower() not in blacklist]

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter10_fig05_hist_cdf"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)

    fig = plt.figure(figsize=figsize)
    ax_hist = fig.add_subplot(1,2,1)
    ax_cdf  = fig.add_subplot(1,2,2)

    if not os.path.isfile(args.results):
        log.warning("CSV manquant → %s", args.results)
        ax_hist.text(0.5, 0.5, "Fichier résultats manquant", ha="center", va="center", transform=ax_hist.transAxes)
        ax_cdf.text(0.5, 0.5, args.results, ha="center", va="center", transform=ax_cdf.transAxes)
        ax_hist.set_axis_off(); ax_cdf.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.results)
    metrics = select_numeric_columns(df, args.metrics)
    if not metrics:
        log.error("Aucune colonne numérique détectée (ou métriques inconnues).")
        ax_hist.text(0.5,0.5,"Aucune métrique à tracer",ha="center",va="center",transform=ax_hist.transAxes)
        ax_cdf.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    for col in metrics:
        s = df[col].dropna().values
        if s.size == 0: continue
        ax_hist.hist(s, bins=args.bins, alpha=0.45, label=col, density=True)
        x = np.sort(s); y = np.linspace(0.0, 1.0, x.size, endpoint=True)
        ax_cdf.plot(x, y, label=col)

    ax_hist.set_xlabel("Valeur"); ax_hist.set_ylabel("Densité (normée)"); ax_hist.grid(True, linestyle=":", linewidth=0.5)
    ax_cdf.set_xlabel("Valeur");  ax_cdf.set_ylabel("CDF empirique");     ax_cdf.grid(True, linestyle=":", linewidth=0.5)
    ax_hist.legend(fontsize=8); ax_cdf.legend(fontsize=8)
    fig.suptitle("Chapitre 10 — Histogrammes & CDF des métriques", y=0.98)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
PY

# ── Chapitre 04 ──────────────────────────────────────────────────────────────
cat > "$S3" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, sys, pathlib
import numpy as np, pandas as pd
import matplotlib.pyplot as plt
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DEF_CSV = "assets/zz-data/chapter04/04_dimensionless_invariants.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap4 Histogramme invariants (homogène)")
    C.add_common_plot_args(p)
    p.add_argument("--data", default=DEF_CSV)
    p.add_argument("--bins", type=int, default=40)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter04_fig02_invariants_hist"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)
    fig, ax = plt.subplots(figsize=figsize)

    if not os.path.isfile(args.data):
        log.warning("Données absentes → %s", args.data)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,args.data,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(args.data)
    if not {"I2","I3"}.issubset(df.columns):
        ax.text(0.5,0.5,"Colonnes I2/I3 absentes",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    logI2 = np.log10(df["I2"].replace(0, np.nan).dropna())
    logI3 = np.log10(np.abs(df["I3"].replace(0, np.nan).dropna()))
    rng = (min(logI2.min(), logI3.min()), max(logI2.max(), logI3.max()))
    bins = np.linspace(rng[0], rng[1], args.bins)

    ax.hist(logI2, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} I_2$")
    ax.hist(logI3, bins=bins, density=True, alpha=0.7, label=r"$\log_{10} |I_3|$")
    ax.set_xlabel(r"$\log_{10}(\mathrm{invariant})$")
    ax.set_ylabel("Densité normalisée")
    ax.set_title("Fig. 02 – Histogramme des invariants adimensionnels")
    ax.legend(fontsize="small"); ax.grid(True, which="both", linestyle=":", linewidth=0.5)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
PY

# ── Chapitre 03 ──────────────────────────────────────────────────────────────
cat > "$S4" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, sys, os, pathlib
import matplotlib.pyplot as plt
import pandas as pd
try:
    from _common import cli as C
except Exception:
    sys.path.append(str(pathlib.Path(__file__).resolve().parents[1]))
    from _common import cli as C

DATA_FILE = "assets/zz-data/chapter03/03_fR_stability_domain.csv"

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Chap3 Domaine de stabilité f(R) (homogène)")
    C.add_common_plot_args(p)
    return p

def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    args._stem = "chapter03_fig01_fr_stability"
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    figsize = C.parse_figsize(args.figsize)

    fig, ax = plt.subplots(figsize=figsize, dpi=args.dpi)
    if not os.path.isfile(DATA_FILE):
        log.error("Fichier manquant : %s", DATA_FILE)
        ax.text(0.5,0.55,"Fichier de données manquant",ha="center",va="center",transform=ax.transAxes)
        ax.text(0.5,0.45,DATA_FILE,ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 0

    df = pd.read_csv(DATA_FILE)
    required = {"beta", "gamma_min", "gamma_max"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes : %s", missing)
        ax.text(0.5,0.5,"Colonnes manquantes",ha="center",va="center",transform=ax.transAxes)
        ax.set_axis_off()
        C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
        return 2

    ax.fill_between(df["beta"], df["gamma_min"], df["gamma_max"], alpha=0.5, linewidth=0)
    ax.set_xlabel(r"$\beta$"); ax.set_ylabel(r"$\gamma$")
    ax.set_title("Chapitre 3 — Domaine de stabilité de f(R)")
    ax.grid(True, linestyle=":", linewidth=0.5)
    C.save_figure(fig, out, args.format, args.dpi, args.transparent, args.save_pdf, args.save_svg)
    if args.show: plt.show()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
PY

# ── Compile & mini-smoke ─────────────────────────────────────────────────────
run "python -m py_compile '$S1' '$S2' '$S3' '$S4' || true"
if [ -x tools/smoke_batch_v2.sh ]; then
  run "tools/smoke_batch_v2.sh | tee '.ci-out/smoke_batch_v2.rebased_${TS}.log'"
  run "ls -lh .ci-out/smoke_v2 | sed -n '1,200p'"
else
  run "python '$S1' --outdir .ci-out/smoke_v2 --format png --dpi 120 --style classic || true"
  run "python '$S2' --outdir .ci-out/smoke_v2 --format png --dpi 120 --style classic || true"
  run "python '$S3' --outdir .ci-out/smoke_v2 --format png --dpi 120 --style classic || true"
  run "python '$S4' --outdir .ci-out/smoke_v2 --format png --dpi 120 --style classic || true"
  run "ls -lh .ci-out/smoke_v2 | sed -n '1,200p'"
fi

say "=== DONE (log: $LOG) ==="

# ── Garde-fou : pause finale (désactivable avec NO_PAUSE=1) ──────────────────
if [ -t 0 ] && [ "${NO_PAUSE:-0}" != "1" ]; then
  echo
  echo "Garde-fou actif : appuie sur ENTRÉE pour fermer cette fenêtre."
  read _ || true
fi
exit 0
