#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Le log complet est visible ci-dessus.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== DIAG 01 – chapter_manifest_* vs système de fichiers =="
echo

python - << 'EOF'
import json
import pathlib

root = pathlib.Path("assets/zz-manifests/chapters")
if not root.exists():
    print("Dossier assets/zz-manifests/chapters introuvable.")
    raise SystemExit(0)

def check_group(label, paths):
    print(f"  [{label}]")
    if not paths:
        print("    (aucun)")
        return
    for p in paths:
        path = pathlib.Path(p)
        status = "OK" if path.exists() else "MISSING"
        print(f"    [{status:7}] {p}")
    print()

for manifest_path in sorted(root.glob("chapter_manifest_*.json")):
    print("=" * 70)
    print(f"Manifest : {manifest_path}")
    obj = json.loads(manifest_path.read_text(encoding="utf-8"))
    chap = obj.get("chapter")
    title = obj.get("title")
    print(f"  Chapter : {chap} – {title}")
    files = obj.get("files", {})

    check_group("data_inputs",  files.get("data_inputs",  []))
    check_group("data_outputs", files.get("data_outputs", []))
    check_group("figures",      files.get("figures",      []))
    check_group("scripts",      files.get("scripts",      []))
    print()
EOF

echo
read -rp "Terminé (diag_01_manifest_vs_fs). Appuie sur Entrée pour revenir au shell..." _
