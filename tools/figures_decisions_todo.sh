#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?; echo; echo "[FIN] Script terminé (code ${code})."; read -rp "Appuie sur Entrée pour fermer..." || true' EXIT

cd ~/MCGT

echo "########## FIGURES DECISIONS TODO (TBD + <NONE>) ##########"
echo

python - << 'PY'
from pathlib import Path
import csv
from collections import Counter, defaultdict

root = Path(".")
zzm = root / "zz-manifests"

cov_path = zzm / "coverage_fig_scripts_data.csv"
man_path = zzm / "figure_manifest.csv"

# On réutilise le backup de decisions comme pour les scripts précédents
decisions_candidates = sorted(zzm.glob("figures_todo_decisions.csv*"))
decisions_path = None
for p in decisions_candidates:
    if p.name.startswith("figures_todo_decisions.csv.bak_"):
        decisions_path = p
if decisions_path is None:
    print("[ERREUR] Aucun backup figures_todo_decisions.csv.* trouvé dans zz-manifests.")
    raise SystemExit(1)

print(f"[INFO] coverage : {cov_path}")
print(f"[INFO] manifest : {man_path}")
print(f"[INFO] decisions (backup) : {decisions_path}")
print()

if not cov_path.exists():
    print(f"[ERREUR] Fichier introuvable: {cov_path}")
    raise SystemExit(1)
if not man_path.exists():
    print(f"[ERREUR] Fichier introuvable: {man_path}")
    raise SystemExit(1)

# --- Helpers -------------------------------------------------

def truthy(val: str) -> bool:
    v = (val or "").strip().lower()
    return v in {"1", "true", "yes", "y", "t"}

def normalize_chapter(ch: str) -> str:
    ch = (ch or "").strip()
    if ch.isdigit():
        return f"chapter{int(ch):02d}"
    return ch

def figure_from_manifest_path(path: str) -> tuple[str, str]:
    """
    Ex: 'zz-figures/chapter09/09_fig_01_phase_overlay.png'
    -> ('chapter09', 'fig_01_phase_overlay')
    """
    path = (path or "").strip()
    parts = path.split("/")
    if len(parts) < 3:
        return "", ""
    chapter = parts[-2]
    stem = Path(parts[-1]).stem
    # enlève le préfixe '09_' si présent
    if "_" in stem:
        prefix, rest = stem.split("_", 1)
        if prefix.isdigit():
            stem = rest
    return chapter, stem

# --- Charger coverage ----------------------------------------

coverage_rows = []
with cov_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        row = dict(row)
        row["chapter"] = normalize_chapter(row.get("chapter"))
        row["figure_stem"] = (row.get("figure_stem") or "").strip()
        coverage_rows.append(row)

# --- Charger manifest des figures ----------------------------

manifest_by_key = {}
with man_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        row = dict(row)
        ch, stem = figure_from_manifest_path(row.get("path"))
        ch = normalize_chapter(ch)
        key = (ch, stem)
        manifest_by_key[key] = row

# --- Charger les décisions -----------------------------------

decisions_by_key = {}
with decisions_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    # On suppose qu'on a au moins columns: chapter, figure_stem, decision, issue, path_hint
    for row in reader:
        ch = normalize_chapter(row.get("chapter"))
        fig = (row.get("figure_stem") or "").strip()
        key = (ch, fig)
        decisions_by_key[key] = dict(row)

# --- Construire les lignes jointes ---------------------------

joined = []
for row in coverage_rows:
    ch = row["chapter"]
    fig = row["figure_stem"]
    key = (ch, fig)

    man = manifest_by_key.get(key)
    dec = decisions_by_key.get(key)

    decision = (dec.get("decision") or "").strip() if dec else ""
    issue = (dec.get("issue") or "").strip() if dec else ""
    path_hint = (dec.get("path_hint") or "").strip() if dec else ""

    joined.append({
        "chapter": ch,
        "figure_stem": fig,
        "has_script": truthy(row.get("has_script")),
        "has_data": truthy(row.get("has_data")),
        "script_example": (row.get("script_example") or "").strip(),
        "data_example": (row.get("data_example") or "").strip(),
        "decision": decision or "<NONE>",
        "issue": issue,
        "path_hint": path_hint,
        "in_manifest": man is not None,
    })

# --- Filtrer les TODO (TBD + <NONE>) -------------------------

todo = [
    r for r in joined
    if r["decision"] in {"TBD", "<NONE>"}
]

if not todo:
    print("[INFO] Aucune figure en TBD ou sans décision explicite. Rien à faire.")
    raise SystemExit(0)

# Stats par chapitre
per_chapter = defaultdict(Counter)
for r in todo:
    per_chapter[r["chapter"]][r["decision"]] += 1

total_todo = len(todo)
print(f"[INFO] Nombre total de figures à décider (TBD + <NONE>) : {total_todo}")
print()

print("=== Répartition par chapitre (TBD + <NONE>) ===")
for ch in sorted(per_chapter):
    counts = per_chapter[ch]
    subtotal = sum(counts.values())
    tbd = counts.get("TBD", 0)
    none = counts.get("<NONE>", 0)
    print(f"- {ch}: total={subtotal}  (TBD={tbd}, <NONE>={none})")
print()

# --- Écrire le CSV TODO dans /tmp ----------------------------

out_path = Path("/tmp") / "mcgt_figures_decisions_todo.csv"
fieldnames = [
    "chapter",
    "figure_stem",
    "decision",
    "issue",
    "has_script",
    "has_data",
    "script_example",
    "data_example",
    "path_hint",
    "in_manifest",
]

with out_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=fieldnames)
    w.writeheader()
    for r in todo:
        # Convert bools en 0/1 pour stabilité visuelle
        row = dict(r)
        row["has_script"] = "1" if r["has_script"] else "0"
        row["has_data"] = "1" if r["has_data"] else "0"
        row["in_manifest"] = "1" if r["in_manifest"] else "0"
        w.writerow(row)

print(f"[OK] CSV TODO écrit : {out_path}")
print("    -> Ouvre ce fichier dans ton éditeur/Excel pour poser les décisions.")
PY
