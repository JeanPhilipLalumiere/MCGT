#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] Script interrompu avec code $code";
  echo "[ASTUCE] Le log complet est visible ci-dessus.";
  read -rp "Appuie sur Entrée pour revenir au shell..." _' ERR

echo "== Résumé de assets/zz-manifests/manifest_publication.json =="
echo

python - << 'EOF'
import json
import pathlib
import re

mp = pathlib.Path("assets/zz-manifests/manifest_publication.json")
if not mp.exists():
    print("manifest_publication.json introuvable")
    raise SystemExit(0)

data = json.loads(mp.read_text(encoding="utf-8"))

if isinstance(data, dict):
    entries = data.get("entries") or data.get("files") or data.get("items") or []
else:
    entries = data

print(f"Type racine : {type(data).__name__}")
if isinstance(data, dict):
    print("Clés racine :", ", ".join(sorted(data.keys())))
print(f"Nombre total d'entrées : {len(entries)}")
print()

chap_buckets = {f"chapter{str(i).zfill(2)}": 0 for i in range(1, 11)}
chap_buckets["other"] = 0
role_counts = {}

for e in entries:
    path = str(e.get("path", ""))
    role = e.get("role", "(none)")
    role_counts[role] = role_counts.get(role, 0) + 1

    bucket = "other"
    m = re.search(r"chapter([0-9]{2})", path)
    if m:
        bucket = f"chapter{m.group(1)}"
    chap_buckets[bucket] = chap_buckets.get(bucket, 0) + 1

print("Entrées par chapitre (d'après le chemin) :")
for k in sorted(chap_buckets):
    print(f"  {k}: {chap_buckets[k]}")
print()

print("Entrées par rôle :")
for k in sorted(role_counts):
    print(f"  {k}: {role_counts[k]}")
print()

if entries:
    sample = entries[0]
    print("Exemple d'entrée :")
    for key in sorted(sample.keys()):
        print(f"  {key}: {sample[key]}")
EOF

echo
echo "== Manifests par chapitre dans assets/zz-manifests/chapters =="
echo

if [ -d assets/zz-manifests/chapters ]; then
  echo "-- Liste des fichiers dans assets/zz-manifests/chapters --"
  ls -1 assets/zz-manifests/chapters
  echo

  for f in assets/zz-manifests/chapters/*.json; do
    [ -e "$f" ] || continue
    echo "----------------------------------------"
    echo "-- $(basename "$f") --"
    echo "Chemin : $f"
    echo "Prévisualisation (20 premières lignes) :"
    echo
    head -n 20 "$f" || echo "(impossible de lire le fichier)"
    echo
  done
else
  echo "(dossier assets/zz-manifests/chapters absent)"
fi

read -rp "Terminé (extract_03_manifests_summary). Appuie sur Entrée pour revenir au shell..." _
