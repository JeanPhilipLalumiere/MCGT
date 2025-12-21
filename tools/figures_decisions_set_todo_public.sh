#!/usr/bin/env bash
# Script : fixer toutes les décisions <TODO> en PUBLIC
# Usage :
#   conda activate mcgt-dev
#   cd ~/MCGT
#   bash tools/figures_decisions_set_todo_public.sh

set -Eeuo pipefail
trap 'code=$?; echo; echo "[FIN] Script terminé (code ${code})."; read -rp "Appuie sur Entrée pour fermer..." || true' EXIT

cd ~/MCGT

echo "########## FIGURES DECISIONS – SET TODO -> PUBLIC ##########"
echo

python - << 'PY'
from pathlib import Path
import csv
import datetime

root = Path(".")
decisions_path = root / "assets/zz-manifests" / "figures_todo_decisions.csv"

if not decisions_path.exists():
    print(f"[ERREUR] Fichier introuvable : {decisions_path}")
    raise SystemExit(1)

with decisions_path.open(newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    if fieldnames is None:
        print("[ERREUR] CSV decisions sans en-têtes.")
        raise SystemExit(1)
    rows = list(reader)

def is_todo(dec_raw: str) -> bool:
    d = (dec_raw or "").strip().upper()
    return d in {"", "TBD", "<NONE>", "<TODO>"}

total = len(rows)
todo_indices = [i for i, r in enumerate(rows) if is_todo(r.get("decision"))]

print(f"[INFO] Fichier decisions : {decisions_path}")
print(f"[INFO] Nombre total de lignes          : {total}")
print(f"[INFO] Nombre de décisions encore TODO : {len(todo_indices)}")
print()

if not todo_indices:
    print("[OK] Aucune décision TODO, rien à faire.")
    raise SystemExit(0)

# Afficher un petit aperçu
print("Exemples de lignes TODO (max 10) avant modification :")
for i in todo_indices[:10]:
    r = rows[i]
    chap = (r.get("chapter") or "").strip()
    fig = (r.get("figure_stem") or "").strip()
    dec = (r.get("decision") or "").strip() or "<NONE>"
    print(f"  - {chap} / {fig}  decision={dec}")
print()

# Confirmation "soft" (pas de input pour éviter blocage non interactif)
print("[INFO] Toutes les décisions TODO seront fixées à PUBLIC.")
print("       (Les valeurs EXISTANTES PUBLIC / INTERNAL_ONLY / REBUILD_LATER ne seront PAS modifiées.)")
print()

updated = 0
for idx in todo_indices:
    rows[idx]["decision"] = "PUBLIC"
    updated += 1

ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%SZ")
backup_path = decisions_path.with_suffix(f".csv.bak_autoset_public_{ts}")
decisions_path.replace(backup_path)

with decisions_path.open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"[OK] {updated} lignes TODO ont été mises à jour -> PUBLIC.")
print(f"[OK] Backup créé : {backup_path}")
print(f"[OK] Nouveau fichier écrit : {decisions_path}")
PY
