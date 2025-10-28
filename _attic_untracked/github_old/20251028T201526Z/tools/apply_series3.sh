#!/usr/bin/env bash
# Pas de -e : on n'abandonne jamais sur erreur
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()

ts() { date +"%Y-%m-%d %H:%M:%S"; }
say() { echo -e "[$(ts)] $*"; }

run() {
  say "▶ $*"
  # On exécute la commande; si elle échoue, on enregistre mais on continue
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

trap 'say "⚠️  Une erreur a été interceptée mais l’exécution continue."' ERR

step "0) Préparation dossiers"
run "mkdir -p .github/workflows zz-manifests tools"

step "1) Scripts manifeste d’intégrité (SHA256/size)"
cat > tools/gen_integrity_manifest.py <<'PY'
#!/usr/bin/env python3
import hashlib, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGETS = [
    ("zz-figures", {".png", ".jpg", ".jpeg", ".gif", ".svg"}),
    ("zz-data", {".csv.gz", ".npz", ".dat", ".json.gz", ".tsv.gz"}),
]
entries = []
for base, exts in TARGETS:
    basep = ROOT / base
    if not basep.exists():
        continue
    for p in sorted(basep.rglob("*")):
        if p.is_file() and any(str(p).lower().endswith(e) for e in exts):
            h = hashlib.sha256()
            with open(p, "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            rel = p.relative_to(ROOT).as_posix()
            entries.append({
                "path": rel,
                "sha256": h.hexdigest(),
                "bytes": p.stat().st_size,
            })
manifest = {"version": 1, "entries": entries}
out = ROOT / "zz-manifests" / "integrity.json"
out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Wrote {out}")
PY
run "chmod +x tools/gen_integrity_manifest.py"

cat > tools/check_integrity.py <<'PY'
#!/usr/bin/env python3
import json, sys, hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
mf = ROOT / "zz-manifests" / "integrity.json"
if not mf.exists():
    print("❌ Manifeste zz-manifests/integrity.json introuvable. Lancez: make integrity-update", file=sys.stderr)
    sys.exit(2)

want = json.loads(mf.read_text(encoding="utf-8"))
want_entries = {e["path"]: e for e in want.get("entries", [])}

bad = 0
for rel, e in sorted(want_entries.items()):
    p = ROOT / rel
    if not p.exists():
        print(f"❌ Manquant: {rel}")
        bad = 1
        continue
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    have = {"sha256": h.hexdigest(), "bytes": p.stat().st_size}
    if have["sha256"] != e["sha256"] or have["bytes"] != e["bytes"]:
        print(f"❌ Divergence: {rel}\n   attendu: {e['sha256']} ({e['bytes']}o)\n   obtenu : {have['sha256']} ({have['bytes']}o)")
        bad = 1

def is_target(rel: str):
    s = rel.lower()
    return s.startswith("zz-figures/") or s.startswith("zz-data/")

have_paths = []
for base in ("zz-figures", "zz-data"):
    bp = ROOT / base
    if bp.exists():
        for p in bp.rglob("*"):
            if p.is_file() and is_target(p.relative_to(ROOT).as_posix()):
                have_paths.append(p.relative_to(ROOT).as_posix())

extras = sorted(set(have_paths) - set(want_entries.keys()))
for rel in extras:
    print(f"❌ Nouveau non listé: {rel}")
    bad = 1

if bad:
    print("\nConseil: mettez à jour le manifeste → make integrity-update", file=sys.stderr)
    sys.exit(1)
else:
    print("✅ Intégrité OK")
PY
run "chmod +x tools/check_integrity.py"

step "2) Première génération/MAJ du manifeste"
run "python3 tools/gen_integrity_manifest.py || true"

step "3) Cibles Makefile (integrity / integrity-update)"
# Nettoyer ancien bloc puis réécrire
if [ -f Makefile ]; then
  awk 'BEGIN{skip=0}
       /^# BEGIN INTEGRITY TARGETS/{skip=1}
       { if(!skip) print \$0 }
       /^# END INTEGRITY TARGETS/{skip=0}' Makefile > Makefile.__tmp__ || true
  mv -f Makefile.__tmp__ Makefile
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

step "4) Workflows CI: integrity + pdf + release-assets"
cat > .github/workflows/integrity.yml <<'YML'
name: integrity
on: [push, pull_request]
jobs:
  integrity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Vérifier intégrité (zz-data, zz-figures)
        run: |
          python3 tools/check_integrity.py
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
run "git add tools/gen_integrity_manifest.py tools/check_integrity.py zz-manifests/integrity.json Makefile .github/workflows/integrity.yml .github/workflows/pdf.yml .github/workflows/release-assets.yml"
run "git commit -m 'ci(pdf,integrity): manifeste SHA256 + garde CI; build PDF artefact + attache release' || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do
    say "  - $e"
  done
  say "→ Fournissez le log pour diagnostic si besoin."
else
  say "✅ Toutes les étapes semblent OK."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (la fenêtre restera ouverte)…'
exit 0
