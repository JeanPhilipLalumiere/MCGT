#!/usr/bin/env bash
# fichier : mcgt_audit_round3_step2_cli.sh
# répertoire : ~/MCGT

set -Eeuo pipefail
_ts="$(date -u +%Y%m%dT%H%M%SZ)"
_log="/tmp/mcgt_audit_round3_step2_${_ts}.log"
exec > >(tee -a "${_log}") 2>&1
trap 'echo; echo "[ERROR] Voir le log : ${_log}"; echo "Session intacte pour inspection.";' ERR

echo ">>> START audit step2 @ ${_ts}"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "repo-root: ${root}"
cd "${root}"

echo "## A) Détection d'arguments collés (')        parser.add_argument')"
grep -RIn --include='*.py' -E '\)\s+parser\.add_argument' zz-scripts || echo "[OK] Aucun argument collé détecté"

echo
echo "## B) En-têtes manquants (# fichier:/# répertoire:) en tête de .py et .sh sous zz-scripts/"
python3 - <<'PY'
import pathlib,re,sys
base=pathlib.Path("zz-scripts")
missing=[]
for p in base.rglob("*"):
    if p.suffix in (".py",".sh") and p.is_file():
        try:
            head=p.read_text(encoding="utf-8",errors="ignore").splitlines()[:5]
        except Exception:
            continue
        text="\n".join(head)
        if "# fichier :" not in text or "# répertoire :" not in text:
            missing.append(str(p))
if missing:
    print("\n".join(missing))
else:
    print("[OK] Tous les fichiers ont déjà l'en-tête requis (ou aucun .py/.sh).")
PY

echo
echo "## C) Usages de find mal ordonnés (-type avant -maxdepth)"
grep -RIn --include='*.sh' -E 'find .* -type .* -maxdepth' . || echo "[OK] Aucun motif mal ordonné trouvé"

echo
echo "## D) Panorama des defaults CLI (outdir/format/dpi/transparent/verbose)"
python3 - <<'PY'
import pathlib,re,collections
paths=list(pathlib.Path("zz-scripts").rglob("*.py"))
outdir=collections.Counter()
fmt=collections.Counter()
dpi=collections.Counter()
transparent=collections.Counter()
verbose=collections.Counter()
for p in paths:
    txt=p.read_text(encoding="utf-8",errors="ignore")
    for m in re.finditer(r'add_argument\(\s*["\']--outdir["\']\s*,[^)]*default\s*=\s*([^,)]+)',txt):
        outdir[m.group(1).strip()]+=1
    for m in re.finditer(r'add_argument\(\s*["\']--format["\']\s*,[^)]*default\s*=\s*["\'](\w+)["\']',txt):
        fmt[m.group(1)]+=1
    for m in re.finditer(r'add_argument\(\s*["\']--dpi["\']\s*,[^)]*default\s*=\s*(\d+)',txt):
        dpi[m.group(1)]+=1
    for m in re.finditer(r'add_argument\(\s*["\']--transparent["\']\s*,[^)]*action\s*=\s*["\']store_true["\']',txt):
        transparent["present"]+=1
    for m in re.finditer(r'add_argument\(\s*["\']-v["\']\s*,\s*["\']--verbose["\']\s*,[^)]*action\s*=\s*["\']count["\']\s*,[^)]*default\s*=\s*(\d+)',txt):
        verbose[m.group(1)]+=1
print("outdir defaults:", dict(outdir))
print("format defaults:", dict(fmt))
print("dpi defaults:", dict(dpi))
print("transparent flags count:", dict(transparent))
print("verbose defaults:", dict(verbose))
PY

echo
echo ">>> END. Log: ${_log}"
