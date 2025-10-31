# repo_make_figure_manifest_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_fig_manifest_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "${BR}"

MAN_DIR="zz-manifests"; MAN_CSV="${MAN_DIR}/figure_manifest.csv"
mkdir -p "${MAN_DIR}"

python - <<'PY'
import csv, hashlib, os, shlex
from pathlib import Path
from datetime import datetime, timezone

root = Path(".")
figs = [
    # chapter, slug, path, producer, default_args, inputs
    ("09","09_fig_03_hist_absdphi_20_300",
     Path("zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"),
     Path("zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"),
     "--diff zz-data/chapter09/09_phase_diff.csv --dpi 150 --bins 80",
     ["zz-data/chapter09/09_phase_diff.csv"]),

    ("10","10_fig_01_iso_p95_maps",
     Path("zz-figures/chapter10/10_fig_01_iso_p95_maps.png"),
     Path("zz-scripts/chapter10/plot_fig01_iso_p95_maps.py"),
     "--results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz",
     ["zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"]),

    ("10","10_fig_02_scatter_phi_at_fpeak",
     Path("zz-figures/chapter10/10_fig_02_scatter_phi_at_fpeak.png"),
     Path("zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"),
     "--results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz",
     ["zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"]),

    ("10","10_fig_03_convergence_p95_vs_n",
     Path("zz-figures/chapter10/10_fig_03_convergence_p95_vs_n.png"),
     Path("zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"),
     "--results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz",
     ["zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"]),

    ("10","10_fig_04_scatter_p95_recalc_vs_orig",
     Path("zz-figures/chapter10/10_fig_04_scatter_p95_recalc_vs_orig.png"),
     Path("zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"),
     "--results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz",
     ["zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"]),

    ("10","10_fig_05_hist_cdf_metrics",
     Path("zz-figures/chapter10/10_fig_05_hist_cdf_metrics.png"),
     Path("zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"),
     "--results zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz",
     ["zz-data/chapter10/10_mc_results.circ.with_fpeak.csv.gz"]),
]

def sha256_of(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

rows = []
now = datetime.now(timezone.utc).isoformat(timespec="seconds")
for chap, slug, fpath, prod, args, inputs in figs:
    if not fpath.exists():
        # On enregistre quand même une ligne signalant l'absence (sha vide)
        rows.append({
            "chapter": chap,
            "figure": slug,
            "path": str(fpath),
            "exists": "0",
            "bytes": "0",
            "sha256": "",
            "producer": str(prod),
            "args": args,
            "inputs": " ".join(shlex.quote(i) for i in inputs),
            "generated_at_utc": now,
        })
        continue
    rows.append({
        "chapter": chap,
        "figure": slug,
        "path": str(fpath),
        "exists": "1",
        "bytes": str(fpath.stat().st_size),
        "sha256": sha256_of(fpath),
        "producer": str(prod),
        "args": args,
        "inputs": " ".join(shlex.quote(i) for i in inputs),
        "generated_at_utc": now,
    })

out = Path("zz-manifests/figure_manifest.csv")
out.parent.mkdir(parents=True, exist_ok=True)
with out.open("w", newline="", encoding="utf-8") as fo:
    w = csv.DictWriter(fo, fieldnames=[
        "chapter","figure","path","exists","bytes","sha256",
        "producer","args","inputs","generated_at_utc"
    ])
    w.writeheader()
    w.writerows(rows)

print(f"[OK] Wrote: {out}")
PY

echo "== DIFF =="
git --no-pager diff --stat -- "${MAN_CSV}" || true

echo "== STAGE & COMMIT =="
git add "${MAN_CSV}" || true
if git diff --cached --quiet; then
  echo "[NOTE] Rien à committer (manifeste inchangé)."
else
  git commit -m "round2: ajoute zz-manifests/figure_manifest.csv (SHA256, producteurs, inputs, args, UTC timestamp)"
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
fi

echo "== RÉCAP =="
sed -n '1,20p' "${MAN_CSV}" || true

