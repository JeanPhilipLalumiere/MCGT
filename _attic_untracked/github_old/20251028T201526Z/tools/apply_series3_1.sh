#!/usr/bin/env bash
# Pas de -e : on continue même en cas d'erreur
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()

ts() { date +"%Y-%m-%d %H:%M:%S"; }
say() { echo -e "[$(ts)] $*"; }

run() {
  say "▶ $*"
  eval "$@" || {
    code=$?
    say "❌ Échec (code=$code): $*"
    ERRORS+=("$* [code=$code]")
    STATUS=1
  }
}

step() {
  echo
  say "────────────────────────────────────────────────────────"
  say "🚩 $*"
  say "────────────────────────────────────────────────────────"
}

trap 'say "⚠️  Erreur interceptée (continuation)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p .github/workflows zz-manifests tools"

step "1) (Re)créer scripts d’intégrité robustes (skip _legacy_conflicts/ + non lisibles)"
cat > tools/gen_integrity_manifest.py <<'PY'
#!/usr/bin/env python3
import hashlib, json, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = [
    "zz-figures/_legacy_conflicts/",
]
TARGETS = [
    ("zz-figures", {".png", ".jpg", ".jpeg", ".gif", ".svg"}),
    ("zz-data", {".csv.gz", ".npz", ".dat", ".json.gz", ".tsv.gz", ".csv"}),
]

def excluded(rel: str) -> bool:
    rp = rel.replace("\\", "/")
    return any(rp.startswith(pref) for pref in EXCLUDE_PREFIXES)

def is_accessible(p: Path) -> bool:
    # dossier "exécutable" + fichier lisible
    try:
        return os.access(p.parent, os.X_OK) and os.access(p, os.R_OK)
    except Exception:
        return False

entries = []
for base, exts in TARGETS:
    basep = ROOT / base
    if not basep.exists():
        continue
    for p in sorted(basep.rglob("*")):
        try:
            if not p.is_file():
                continue
        except PermissionError:
            # Impossible de stat() → ignorer
            continue
        rel = p.relative_to(ROOT).as_posix()
        if excluded(rel):
            continue
        if not any(rel.lower().endswith(e) for e in exts):
            continue
        if not is_accessible(p):
            # Non lisible → ignorer silencieusement
            continue
        # Hash robuste
        h = hashlib.sha256()
        try:
            with open(p, "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            entries.append({
                "path": rel,
                "sha256": h.hexdigest(),
                "bytes": p.stat().st_size,
            })
        except Exception:
            # Si lecture impossible, ignorer (ne bloque pas la CI locale)
            continue

manifest = {"version": 1, "entries": entries}
out = ROOT / "zz-manifests" / "integrity.json"
out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Wrote {out} with {len(entries)} entries")
PY
run "chmod +x tools/gen_integrity_manifest.py"

cat > tools/check_integrity.py <<'PY'
#!/usr/bin/env python3
import json, sys, hashlib, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = [
    "zz-figures/_legacy_conflicts/",
]
def excluded(rel: str) -> bool:
    rp = rel.replace("\\", "/")
    return any(rp.startswith(pref) for pref in EXCLUDE_PREFIXES)

mf = ROOT / "zz-manifests" / "integrity.json"
if not mf.exists():
    print("❌ Manifeste introuvable: zz-manifests/integrity.json", file=sys.stderr)
    sys.exit(2)

want = json.loads(mf.read_text(encoding="utf-8"))
want_entries = {e["path"]: e for e in want.get("entries", [])}
bad = 0

for rel, e in sorted(want_entries.items()):
    if excluded(rel):
        continue
    p = ROOT / rel
    if not p.exists():
        print(f"❌ Manquant: {rel}")
        bad = 1
        continue
    if not (os.access(p.parent, os.X_OK) and os.access(p, os.R_OK)):
        print(f"❌ Non lisible: {rel}")
        bad = 1
        continue
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    have_sha = h.hexdigest()
    have_bytes = p.stat().st_size
    if have_sha != e["sha256"] or have_bytes != e["bytes"]:
        print(f"❌ Divergence: {rel}\n   attendu: {e['sha256']} ({e['bytes']}o)\n   obtenu : {have_sha} ({have_bytes}o)")
        bad = 1

def collect_targets():
    paths = []
    for base in ("zz-figures", "zz-data"):
        bp = ROOT / base
        if not bp.exists(): continue
        for p in bp.rglob("*"):
            if p.is_file():
                rel = p.relative_to(ROOT).as_posix()
                if not excluded(rel):
                    paths.append(rel)
    return paths

have = set(collect_targets())
extra = sorted(have - set(want_entries.keys()))
for rel in extra:
    print(f"❌ Nouveau non listé: {rel}")
    bad = 1

if bad:
    print("\nConseil: mettez à jour le manifeste → make integrity-update", file=sys.stderr)
    sys.exit(1)
else:
    print("✅ Intégrité OK")
PY
run "chmod +x tools/check_integrity.py"

step "2) Générer (ou regénérer) le manifeste d’intégrité"
run "python3 tools/gen_integrity_manifest.py || true"

step "3) Mettre à jour le Makefile (targets integrity) — via sed, pas awk"
# Supprimer l'ancien bloc entre marqueurs si présent, puis injecter
if [ -f Makefile ]; then
  run "sed -i '/^# BEGIN INTEGRITY TARGETS$/,/^# END INTEGRITY TARGETS$/d' Makefile"
else
  : > Makefile
fi

cat >> Makefile <<'MAKE'

# BEGIN INTEGRITY TARGETS
.PHONY: integrity integrity-update
integrity:
	@python3 tools/check_integrity.py

integrity-update:
	@python3 tools/gen_integrity_manifest.py
	@git add zz-manifests/integrity.json || true
	@echo "Manifeste mis à jour. Pensez à committer."

# END INTEGRITY TARGETS
MAKE

step "4) Workflows CI (intégrité + PDF + release)"
cat > .github/workflows/integrity.yml <<'YML'
name: integrity
on: [push, pull_request]
jobs:
  integrity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Vérifier intégrité
        run: python3 tools/check_integrity.py
YML

cat > .github/workflows/pdf.yml <<'YML'
name: pdf
on: [push, pull_request]
jobs:
  build-pdf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build PDF (main.tex)
        uses: xu-cheng/latex-action@v3
        with:
          root_file: main.tex
          latexmk_use_xelatex: false
          texlive_version: 2023
      - name: Upload PDF
        uses: actions/upload-artifact@v4
        with:
          name: mcgt-preprint
          path: main.pdf
YML

cat > .github/workflows/release-assets.yml <<'YML'
name: release-assets
on:
  push:
    tags:
      - "v*.*.*"
jobs:
  attach-pdf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build PDF (main.tex)
        uses: xu-cheng/latex-action@v3
        with:
          root_file: main.tex
          latexmk_use_xelatex: false
          texlive_version: 2023
      - name: Créer/mettre à jour la release et attacher main.pdf
        uses: softprops/action-gh-release@v2
        with:
          files: |
            main.pdf
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
YML

step "5) Commit + push (jamais bloquant)"
run "git add Makefile tools/gen_integrity_manifest.py tools/check_integrity.py .github/workflows/integrity.yml .github/workflows/pdf.yml .github/workflows/release-assets.yml zz-manifests/integrity.json || true"
run "git commit -m 'ci(integrity,pdf): manifeste robuste (skip legacy+non lisibles); sed fix; pipelines' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Envoyez le log si besoin."
else
  say "✅ Toutes les étapes semblent OK."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0
