#!/usr/bin/env bash
# Script : construire un figure_manifest_candidate.csv à partir de
#          coverage_fig_scripts_data.csv + figures_todo_decisions.csv + figure_manifest.csv
# Usage :
#   conda activate mcgt-dev
#   cd ~/MCGT
#   bash tools/figures_build_manifest_candidate.sh

set -Eeuo pipefail
trap 'code=$?; echo; echo "[FIN] Script terminé (code ${code})."; read -rp "Appuie sur Entrée pour fermer..." || true' EXIT

cd ~/MCGT

echo "########## FIGURES MANIFEST CANDIDATE – BUILD ##########"
echo

python - << 'PY'
from pathlib import Path
import csv

root = Path(".")
cov_path = root / "assets/zz-manifests" / "coverage_fig_scripts_data.csv"
dec_path = root / "assets/zz-manifests" / "figures_todo_decisions.csv"
man_path = root / "assets/zz-manifests" / "figure_manifest.csv"
out_path = root / "assets/zz-manifests" / "figure_manifest_candidate.csv"

for p in (cov_path, dec_path, man_path):
    if not p.exists():
        print(f"[ERREUR] Fichier introuvable : {p}")
        raise SystemExit(1)

print(f"[INFO] coverage  : {cov_path}")
print(f"[INFO] decisions : {dec_path}")
print(f"[INFO] manifest  : {man_path}")
print()

# ---------- helpers ----------
CHAPTER_DIRS = {
    "01": "01_invariants_stability",
    "02": "02_primordial_spectrum",
    "03": "03_stability_domain",
    "04": "04_expansion_supernovae",
    "05": "05_primordial_bbn",
    "06": "06_early_growth_jwst",
    "07": "07_bao_geometry",
    "08": "08_sound_horizon",
    "09": "09_dark_energy_cpl",
    "10": "10_global_scan",
    "11": "11_lss_s8_tension",
    "12": "12_cmb_verdict",
}

def norm_chapter(ch: str) -> str:
    ch = (ch or "").strip()
    if not ch:
        return ""
    low = ch.lower()
    if low.startswith("chapter"):
        # ex: "chapter9" -> "chapter09"
        suffix = low[len("chapter"):]
        if suffix.isdigit():
            return f"chapter{suffix.zfill(2)}"
        return low
    if low.isdigit():
        return f"chapter{low.zfill(2)}"
    return low

def stem_from_path(path: str) -> str:
    """
    Ex: assets/zz-figures/09_dark_energy_cpl/09_fig_01_phase_overlay.png
        -> fig_01_phase_overlay
    """
    if not path:
        return ""
    p = Path(path)
    stem = p.stem  # 09_fig_01_phase_overlay
    idx = stem.find("fig_")
    if idx == -1:
        return ""
    return stem[idx:]  # fig_01_phase_overlay

# ---------- charger coverage ----------

coverage_rows = []
with cov_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    cov_fields = reader.fieldnames or []
    required = {"chapter", "figure_stem"}
    if not required.issubset(cov_fields):
        print(f"[ERREUR] Colonnes manquantes dans coverage : {required - set(cov_fields)}")
        raise SystemExit(1)
    for row in reader:
        chap = norm_chapter(row.get("chapter"))
        fig = (row.get("figure_stem") or "").strip()
        if not chap or not fig:
            continue
        key = (chap, fig)
        coverage_rows.append((key, row))

print(f"[INFO] Lignes coverage chargées : {len(coverage_rows)}")

# ---------- charger decisions ----------

decisions = {}
with dec_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    dec_fields = reader.fieldnames or []
    if "chapter" not in dec_fields or "figure_stem" not in dec_fields or "decision" not in dec_fields:
        print("[ERREUR] figures_todo_decisions.csv doit contenir chapter, figure_stem, decision.")
        raise SystemExit(1)
    for row in reader:
        chap = norm_chapter(row.get("chapter"))
        fig = (row.get("figure_stem") or "").strip()
        if not chap or not fig:
            continue
        key = (chap, fig)
        decisions[key] = (row.get("decision") or "").strip().upper() or "<MISSING>"

print(f"[INFO] Lignes decisions chargées : {len(decisions)}")

# ---------- charger figure_manifest existant ----------

manifest_by_key = {}
with man_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    man_fields = reader.fieldnames or []
    for row in reader:
        chap_raw = row.get("chapter")
        chap = norm_chapter(chap_raw)
        fig_stem = stem_from_path(row.get("path") or "")
        if not chap or not fig_stem:
            continue
        key = (chap, fig_stem)
        manifest_by_key[key] = row

print(f"[INFO] Lignes figure_manifest existant : {len(manifest_by_key)}")
print()

# ---------- construire le candidat ----------

out_fields = [
    "chapter",
    "figure_stem",
    "decision",
    "has_script",
    "script_example",
    "has_data",
    "data_example",
    "path_guess",
    "manifest_path",
    "manifest_role",
    "manifest_kind",
    "manifest_tags",
    "in_manifest",
]

out_rows = []
missing_decisions = 0

for (chap, fig), cov_row in coverage_rows:
    key = (chap, fig)
    decision = decisions.get(key, "<MISSING>")
    if decision == "<MISSING>":
        missing_decisions += 1

    has_script = (cov_row.get("has_script") or "").strip()
    has_data = (cov_row.get("has_data") or "").strip()

    # path_guess : assets/zz-figures/NN_chapter_name/NN_<figure_stem>.png
    path_guess = ""
    if chap.startswith("chapter"):
        suffix = chap[len("chapter"):]
        if suffix.isdigit():
            nn = suffix.zfill(2)
            dir_name = CHAPTER_DIRS.get(nn)
            if dir_name:
                path_guess = f"assets/zz-figures/{dir_name}/{nn}_{fig}.png"

    man_row = manifest_by_key.get(key)
    if man_row:
        manifest_path = (man_row.get("path") or "").strip()
        manifest_role = (man_row.get("role") or "").strip()
        manifest_kind = (man_row.get("kind") or "").strip()
        manifest_tags = (man_row.get("tags") or "").strip()
        in_manifest = "yes"
    else:
        manifest_path = ""
        manifest_role = ""
        manifest_kind = ""
        manifest_tags = ""
        in_manifest = "no"

    out_rows.append({
        "chapter": chap,
        "figure_stem": fig,
        "decision": decision,
        "has_script": has_script,
        "script_example": (cov_row.get("script_example") or "").strip(),
        "has_data": has_data,
        "data_example": (cov_row.get("data_example") or "").strip(),
        "path_guess": path_guess,
        "manifest_path": manifest_path,
        "manifest_role": manifest_role,
        "manifest_kind": manifest_kind,
        "manifest_tags": manifest_tags,
        "in_manifest": in_manifest,
    })

out_rows.sort(key=lambda r: (r["chapter"], r["figure_stem"]))

with out_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=out_fields)
    writer.writeheader()
    writer.writerows(out_rows)

print(f"[OK] Candidate manifest écrit : {out_path}")
print(f"     Nombre de lignes        : {len(out_rows)}")
print(f"     Décisions manquantes    : {missing_decisions} (devrait être 0)")
PY
