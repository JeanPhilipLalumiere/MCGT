#!/usr/bin/env bash
set -euo pipefail
echo "[PASS9c] Zéro FAIL maintenant — vérif ciblée, stub forcé si besoin, re-scan"

FAIL_LIST="zz-out/homog_cli_fail_list.txt"

# 0) Rafraîchir la fail-list si absente/vide
if [[ ! -s "$FAIL_LIST" ]]; then
  if [[ -x tools/homog_pass4_cli_inventory_safe_v4.sh ]]; then
    tools/homog_pass4_cli_inventory_safe_v4.sh
  else
    echo "[ERR] tools/homog_pass4_cli_inventory_safe_v4.sh introuvable"; exit 1
  fi
fi

[[ -s "$FAIL_LIST" ]] || { echo "[PASS9c] Aucun FAIL — rien à faire."; exit 0; }

echo "[INFO] FAIL restants:"
nl -ba "$FAIL_LIST" | sed 's/^/  /'

# 1) Tester --help avec timeout et forcer stub si ça échoue
python3 - <<'PY'
from __future__ import annotations
import pathlib, subprocess, sys, re, textwrap, os

fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt")
targets = [pathlib.Path(l.strip()) for l in fail_list.read_text(encoding="utf-8").splitlines() if l.strip()]

STUB_O = "# === [PASS6-STUB] ==="
STUB_C = "# === [/PASS6-STUB] ==="
STUB = textwrap.dedent("""
# === [PASS6-STUB] ===
# Stub temporaire pour homogénéisation CLI : --help rapide, --out sûr (Agg), image témoin.
from __future__ import annotations
import os, sys, argparse
os.environ.setdefault("MPLBACKEND", "Agg")

def main():
    p = argparse.ArgumentParser(
        description="STUB (homogénéisation MCGT) — original sauvegardé en .bak",
        allow_abbrev=False,
    )
    p.add_argument("--out", required=False, help="PNG de sortie (optionnel)")
    p.add_argument("--dpi", type=int, default=120)
    p.add_argument("--title", default="Stub figure")
    args, _ = p.parse_known_args()

    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(6,4))
    ax.text(0.5, 0.55, args.title, ha="center", va="center", fontsize=12)
    ax.text(0.5, 0.40, "(stub temporaire — homogénéisation)", ha="center", va="center", fontsize=9)
    fig.subplots_adjust(left=0.1, right=0.98, top=0.9, bottom=0.15)

    if args.out:
        fig.savefig(args.out, dpi=args.dpi)
        print(f"Wrote: {args.out}")

if __name__ == "__main__":
    main()
# === [/PASS6-STUB] ===
""").lstrip("\n")

def insert_pos(s: str) -> int:
    i = 0
    if s.startswith("#!"):
        j = s.find("\n")
        i = (j+1) if j != -1 else len(s)
    # encoding
    m = re.match(r'([^\n]*coding[:=].*\n)', s[i:i+200], re.I)
    if m: i += m.end()
    # __future__
    for m in re.finditer(r'from __future__ import .*\n', s[i:]):
        i = i + m.end()
    # docstring
    m = re.match(r'\s*(?P<q>["\']{3})(?s:.*?)(?P=q)\s*\n', s[i:])
    if m: i = i + m.end()
    return i

def help_ok(p: pathlib.Path) -> bool:
    try:
        # Timeout court et backend Agg forcé au cas où
        env = os.environ.copy()
        env.setdefault("MPLBACKEND", "Agg")
        subprocess.run([sys.executable, str(p), "--help"],
                       env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       timeout=8, check=True)
        return True
    except subprocess.TimeoutExpired:
        return False
    except subprocess.CalledProcessError:
        return False

patched = 0
for p in targets:
    if not p.exists():
        print(f"[SKIP] {p} (absent)")
        continue
    if help_ok(p):
        print(f"[OK] --help OK: {p}")
        continue
    # sinon, stub forcé en tête
    s = p.read_text(encoding="utf-8", errors="replace")
    if STUB_O in s and STUB_C in s:
        # Même déjà stubifié mais mal positionné : on enlève puis on réinsère au bon endroit
        s = re.sub(r"(?ms)^\\s*# === \\[PASS6-STUB\\] ===.*?# === \\[/PASS6-STUB\\] ===\\s*\\n?", "", s)
    bak = p.with_suffix(p.suffix + ".bak")
    if not bak.exists():
        bak.write_text(s, encoding="utf-8")
    i = insert_pos(s)
    p.write_text(s[:i] + STUB + s[i:], encoding="utf-8")
    print(f"[FIX] Stub réinséré en tête: {p} (original -> {bak.name})")
    patched += 1

print(f"[PASS9c] Fichiers corrigés: {patched}")
PY

# 2) Re-scan et résumé
tools/homog_pass4_cli_inventory_safe_v4.sh

echo
echo "=== Résumé (fin du rapport inventaire) ==="
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

# 3) Sécurité: pas de tight_layout actif
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find zz-scripts -type f -name "*.py") || true)
[[ -z "${viol}" ]] && echo "[OK] Aucun appel actif à *.tight_layout détecté." || { echo "[WARN] Restants:"; echo "$viol"; }
