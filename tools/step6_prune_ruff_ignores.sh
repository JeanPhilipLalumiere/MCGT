#!/usr/bin/env bash
set -euo pipefail

# === PSX : empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [ "$rc" -eq 0 ]; then
    echo "✅ Étape 6 — Prune per-file-ignores OK (exit: $rc)"
  else
    echo "❌ Étape 6 — Prune per-file-ignores KO (exit: $rc)"
  fi
  if [ "${WAIT_ON_EXIT}" = "1" ] && [ -z "${CI:-}" ]; then
    if [ -r /dev/tty ]; then
      printf "PSX — Appuie sur Entrée pour fermer cette fenêtre…" > /dev/tty
      IFS= read -r _ < /dev/tty
      printf "
" > /dev/tty
    elif [ -t 0 ]; then
      read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
      echo
    else
      echo "PSX — Aucun TTY détecté; la fenêtre restera ouverte (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

# S’auto-marquer exécutable (évite un futur échec du hook)
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

# Backup pyproject.toml
ts="$(date -u +%Y%m%dT%H%M%SZ)"
backup="pyproject.toml.before_prune_ruff_${ts}"
[ -e "$backup" ] || cp pyproject.toml "$backup"

python3 - <<'PY'
import tomllib, subprocess, sys, re
from pathlib import Path

p = Path("pyproject.toml")
text = p.read_text(encoding="utf-8")

cfg = tomllib.loads(text)
section = cfg.get("tool", {}).get("ruff", {}).get("lint", {}).get("per-file-ignores")
if not section:
    print("Aucun per-file-ignores dans pyproject.toml — rien à faire.")
    sys.exit(0)

header = "[tool.ruff.lint.per-file-ignores]"
start = text.find(header)
if start == -1:
    print("Bloc per-file-ignores introuvable — rien à faire.")
    sys.exit(0)

# Fin du bloc = prochaine section TOML
m = re.search(r'(?m)^\[.*\]', text[start+len(header):])
end = start + len(header) + (m.start() if m else len(text)-start-len(header))
body = text[start+len(header):end]

def parse_body(body: str):
    out = {}
    for line in body.splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, rest = s.split("=", 1)
        key = k.strip().strip('"').strip("'")
        codes = [c.strip().strip('"').strip("'") for c in rest.strip().strip("[]").split(",") if c.strip()]
        out[key] = codes
    return out

def build_body(entries: dict[str, list[str]]) -> str:
    lines = []
    for k in sorted(entries):
        v = entries[k]
        if not v:
            continue
        arr = "[" + ", ".join(f'"{c}"' for c in v) + "]"
        lines.append(f'"{k}" = {arr}')
    return ("\n" + "\n".join(lines) + ("\n" if lines else ""))

def write_toml(new_text: str):
    p.write_text(new_text, encoding="utf-8")

def ruff_ok(path: Path) -> bool:
    # Ruff 0.13.x : sous-commande "check"
    res = subprocess.run(["ruff", "check", str(path)], capture_output=True, text=True)
    return res.returncode == 0

entries = parse_body(body)
initial_total = sum(len(v) for v in entries.values())
removed: list[tuple[str, str]] = []
changed = False

# Retirer les codes un par un, en validant à chaque fois sur le fichier concerné
for path, codes in list(entries.items()):
    file_path = Path(path)
    if not file_path.exists():
        entries[path] = []
        removed.append((path, "ALL(stale)"))
        changed = True
        continue
    for code in list(codes):
        test_entries = {k: list(v) for k, v in entries.items()}
        test_entries[path] = [c for c in test_entries[path] if c != code]
        new_body = build_body(test_entries)
        candidate = text[:start+len(header)] + new_body + text[end:]
        write_toml(candidate)
        if ruff_ok(file_path):
            entries[path].remove(code)
            text = candidate
            end = start + len(header) + len(new_body)
            removed.append((path, code))
            changed = True
        else:
            write_toml(text)

# Nettoyage des clés vides
new_body = build_body(entries)
final_text = text[:start+len(header)] + new_body + text[end:]
if final_text != text:
    write_toml(final_text)
    changed = True

print(f"Per-file-ignores initial: {initial_total}  | supprimés: {len(removed)}")
for k, c in removed:
    print(f"  - {k}: {c}")
PY

echo "==> Ruff + pre-commit (tolérant)"
ruff check || true
pre-commit run --all-files || true

echo "==> Commit/push si diff"
git add -A
if ! git diff --staged --quiet; then
  git commit -m "style(ruff): prune redundant per-file-ignores (auto)"
  git push
else
  echo "Aucun changement à committer."
fi
