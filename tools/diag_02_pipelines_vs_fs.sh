#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Le log complet est visible ci-dessus.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== DIAG 02 – CH*_PIPELINE_MINIMAL*.md vs système de fichiers =="
echo

python - << 'EOF'
import pathlib
import re

docs_dir = pathlib.Path("docs")
if not docs_dir.exists():
    print("Dossier docs introuvable.")
    raise SystemExit(0)

pattern = re.compile(r'(zz-(?:data|figures|scripts)/[^\s)`"]+)')
per_doc = {}

for md_path in sorted(docs_dir.glob("CH*_PIPELINE_MINIMAL*.md")):
    text = md_path.read_text(encoding="utf-8")
    paths = set()
    for m in pattern.finditer(text):
        p = m.group(1).rstrip("`.,)")
        paths.add(p)
    per_doc[md_path] = sorted(paths)

for md_path, paths in per_doc.items():
    print("=" * 70)
    print(f"Doc : {md_path}")
    if not paths:
        print("  (aucun chemin assets/zz-data/assets/zz-figures/scripts détecté)")
        continue
    for p in paths:
        path = pathlib.Path(p)
        status = "OK" if path.exists() else "MISSING"
        print(f"  [{status:7}] {p}")
EOF

echo
read -rp "Terminé (diag_02_pipelines_vs_fs). Appuie sur Entrée pour revenir au shell..." _
