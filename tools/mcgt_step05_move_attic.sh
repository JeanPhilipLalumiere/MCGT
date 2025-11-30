#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
cd "${ROOT_DIR}"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="zz-logs/step05_move_attic_${TS}.log"
mkdir -p zz-logs attic/figures attic/scripts

# Log complet (stdout+stderr) vers fichier + console
exec > >(tee "${LOG_FILE}") 2>&1

echo "=== MCGT Step 05 : déplacement des doublons vers attic/ ==="
echo "[INFO] Repo root : ${ROOT_DIR}"
echo "[INFO] Horodatage (UTC) : ${TS}"
echo

STEP04_LOG="$(ls -1t zz-logs/step04_cleanup_plan_*.log 2>/dev/null | head -n1 || true)"
if [[ -z "${STEP04_LOG}" || ! -f "${STEP04_LOG}" ]]; then
  echo "[ERREUR] Impossible de trouver un log Step04 (zz-logs/step04_cleanup_plan_*.log)."
  exit 1
fi

echo "[INFO] Rapport Step04 utilisé : ${STEP04_LOG}"
echo

# --- Extraction des listes depuis le log Step04 ---
mapfile -t DUP_FIGS < <(grep '^ATTIC_DUP_FIG ' "${STEP04_LOG}" | awk '{print $2}')
mapfile -t DUP_SCRIPTS < <(grep '^ATTIC_DUP_SCRIPT ' "${STEP04_LOG}" | awk '{print $2}')
mapfile -t LOW_DATA < <(grep '^LOW_PRIORITY_DATA ' "${STEP04_LOG}" | awk '{print $2}')

NB_FIGS=${#DUP_FIGS[@]}
NB_SCRIPTS=${#DUP_SCRIPTS[@]}
NB_LOW=${#LOW_DATA[@]}

echo "[INFO] Figures à déplacer (attic) : ${NB_FIGS}"
echo "[INFO] Scripts à déplacer (attic) : ${NB_SCRIPTS}"
echo "[INFO] Données faible priorité (NON déplacées à ce step) : ${NB_LOW}"
echo
echo "------------------------------------------------------------"
echo "[STEP] Déplacement des figures doublons vers attic/figures"

for src in "${DUP_FIGS[@]}"; do
  [[ -z "${src}" ]] && continue
  if [[ ! -f "${src}" ]]; then
    echo "[INFO] figure déjà déplacée ou absente : ${src}"
    continue
  fi

  chapter_dir="$(echo "${src}" | sed -E 's|^zz-figures/([^/]+)/.*|\1|')"
  dst_dir="attic/figures/${chapter_dir}"
  mkdir -p "${dst_dir}"

  if git ls-files --error-unmatch "${src}" >/dev/null 2>&1; then
    echo "[INFO] git mv \"${src}\" -> \"${dst_dir}/\""
    git mv "${src}" "${dst_dir}/"
  else
    echo "[INFO] mv (non versionné) \"${src}\" -> \"${dst_dir}/\""
    mv "${src}" "${dst_dir}/"
  fi
done

echo "------------------------------------------------------------"
echo "[STEP] Déplacement des scripts doublons vers attic/scripts"

for src in "${DUP_SCRIPTS[@]}"; do
  [[ -z "${src}" ]] && continue
  if [[ ! -f "${src}" ]]; then
    echo "[INFO] script déjà déplacé ou absent : ${src}"
    continue
  fi

  chapter_dir="$(echo "${src}" | sed -E 's|^zz-scripts/([^/]+)/.*|\1|')"
  dst_dir="attic/scripts/${chapter_dir}"
  mkdir -p "${dst_dir}"

  echo "git mv \"${src}\" \"${dst_dir}/\""
  git mv "${src}" "${dst_dir}/"
done

echo "------------------------------------------------------------"
echo "[INFO] Données LOW_PRIORITY_DATA conservées en place pour le moment :"
for path in "${LOW_DATA[@]}"; do
  [[ -z "${path}" ]] && continue
  echo "KEEP_LOW_PRIORITY_DATA ${path}"
done

echo "------------------------------------------------------------"
echo "[STEP] Mise à jour de zz-manifests/manifest_master.json (suppression entrées doublons)"

python - "${STEP04_LOG}" << 'PY'
import json
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("[ERREUR] Aucun chemin de log Step04 fourni à Python.")
    sys.exit(1)

step04_path = Path(sys.argv[1])
if not step04_path.is_file():
    print(f"[ERREUR] Log Step04 introuvable : {step04_path}")
    sys.exit(1)

dup_figs = []
dup_scripts = []

with step04_path.open("r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if line.startswith("ATTIC_DUP_FIG "):
            dup_figs.append(line.split(" ", 1)[1])
        elif line.startswith("ATTIC_DUP_SCRIPT "):
            dup_scripts.append(line.split(" ", 1)[1])

paths_to_remove = set(dup_figs + dup_scripts)
print(f"[INFO] Entrées à retirer du manifest : {len(paths_to_remove)}")

manifest_path = Path("zz-manifests/manifest_master.json")
if not manifest_path.is_file():
    print(f"[ERREUR] Manifest introuvable : {manifest_path}")
    sys.exit(1)

data = json.loads(manifest_path.read_text(encoding="utf-8"))
entries = data.get("entries", [])

before = len(entries)
entries = [e for e in entries if e.get("path") not in paths_to_remove]
after = len(entries)
removed = before - after

data["entries"] = entries
data["entries_updated"] = data.get("entries_updated", 0) + max(removed, 0)

manifest_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
print(f"[INFO] Manifest mis à jour : {removed} entrées supprimées (avant={before}, après={after})")
PY

echo
echo "[OK] Step 05 terminé (déplacement attic + manifest mis à jour)."
echo "[INFO] Log complet : ${LOG_FILE}"
