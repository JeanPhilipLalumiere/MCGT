#!/usr/bin/env bash
# Patch ciblé du step "Meta summary" pour éviter SC2129 (multiples >>).
# - Sauvegarde le YAML dans .ci-archive/
# - Remplace le bloc run: | de "Meta summary" par un bloc groupé { ... } >> "$GITHUB_STEP_SUMMARY"
# - Commit + push
# - Déclenche ci-pre-commit.yml et suit les logs utiles (si 'gh' présent)
set -Eeuo pipefail

cleanup() {
  local rc="$1"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
trap 'cleanup $?' EXIT

# --- Préambule
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

WF_FILE=".github/workflows/sanity-main.yml"
[[ -f "$WF_FILE" ]] || {
  echo "[ERREUR] Fichier introuvable: $WF_FILE" >&2
  exit 1
}

BACKUP_DIR="${BACKUP_DIR:-.ci-archive}"
mkdir -p "$BACKUP_DIR"
TS="$(date +%Y%m%dT%H%M%S)"
cp -v -- "$WF_FILE" "$BACKUP_DIR/$(basename "$WF_FILE").bak.${TS}"

# --- Patch Python : remplace le bloc run: | du step "- name: Meta summary"
python3 - "$WF_FILE" <<'PY'
import sys, re, pathlib

p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8").splitlines(keepends=True)

# 1) Trouver la ligne "- name: Meta summary"
meta_idx = None
for i, line in enumerate(text):
    if re.match(r'^\s*-\s*name:\s*Meta summary\s*$', line):
        meta_idx = i
        break

if meta_idx is None:
    print("[INFO] Step 'Meta summary' introuvable — aucun changement.", file=sys.stderr)
    sys.exit(0)

# 2) Chercher "run: |" (ou variantes) après ce step
run_idx = None
run_indent = None
for i in range(meta_idx + 1, len(text)):
    m = re.match(r'^(\s*)run:\s*(\||>\-?)\s*$', text[i])
    if m:
        run_idx = i
        run_indent = len(m.group(1))
        break
    if re.match(r'^\s*-\s*name:\s*', text[i]):
        break

if run_idx is None:
    print("[INFO] 'run:' introuvable sous 'Meta summary' — aucun changement.", file=sys.stderr)
    sys.exit(0)

# 3) Délimiter le bloc littéral du run (lignes strictement plus indentées)
block_start = run_idx + 1
j = block_start
def indent_len(s: str) -> int:
    return len(s) - len(s.lstrip(' '))

while j < len(text):
    line = text[j]
    if line.strip() == "":
        j += 1
        continue
    if indent_len(line) <= run_indent:
        break
    j += 1

block_end = j  # non inclus

# 4) Construire le bloc désiré
content_indent = " " * (run_indent + 2)
new_block_lines = [
    text[run_idx].split("run:")[0] + "run: |\n",
    f"{content_indent}{{\n",
    f'{content_indent}  echo "## Meta checks"\n',
    f'{content_indent}  echo "- actionlint: pinned v1.7.1 (skip si indisponible)"\n',
    f'{content_indent}  echo "- shellcheck: exécuté sur tools/*.sh (skip si absent)"\n',
    f"{content_indent}}} >> \"$GITHUB_STEP_SUMMARY\"\n",
]

current = text[run_idx:block_end]
proposed = new_block_lines
if current != proposed:
    text[run_idx:block_end] = proposed
    p.write_text("".join(text), encoding="utf-8")
    print("[PATCH] Bloc 'Meta summary' -> run: | groupé vers $GITHUB_STEP_SUMMARY", file=sys.stderr)
else:
    print("[INFO] Bloc 'Meta summary' déjà conforme — aucun changement.", file=sys.stderr)
PY

# --- Commit ciblé (uniquement si modifié)
if ! git diff --quiet -- "$WF_FILE"; then
  git add -- "$WF_FILE"
  # 👇 Double quotes + $ échappé => pas de SC2016
  msg="ci(sanity-main): SC2129 — regroupe les appends du step \"Meta summary\" vers \$GITHUB_STEP_SUMMARY"
  echo "=== COMMIT ==="
  pre-commit run -a || true
  git commit -m "$msg"
  echo "=== PUSH ==="
  git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
else
  echo "[INFO] Aucun changement à committer."
fi

# --- Déclenchement + suivi du workflow ci-pre-commit.yml (si gh dispo)
if command -v gh >/dev/null 2>&1; then
  echo "[INFO] Déclenchement ci-pre-commit.yml…"
  BR="$(git rev-parse --abbrev-ref HEAD)"
  gh workflow run ci-pre-commit.yml -r "$BR" >/dev/null || echo "[WARN] Impossible de déclencher le workflow (gh)."

  echo "[INFO] Recherche du run pour HEAD…"
  HEAD_SHA="$(git rev-parse HEAD)"
  RID=""
  for _ in $(seq 1 60); do
    RID="$(gh run list --workflow ci-pre-commit.yml --branch "$BR" \
      --json databaseId,headSha,createdAt \
      -q '[.[] | select(.headSha=="'"$HEAD_SHA"'")] | sort_by(.createdAt) | last | .databaseId' || true)"
    [[ -n "$RID" && "$RID" != "null" ]] && break
    sleep 2
  done

  if [[ -n "$RID" && "$RID" != "null" ]]; then
    echo "[INFO] RID=$RID — suivi des logs utiles…"
    if gh run watch "$RID" --exit-status --interval 3 | sed -n '/Run pre-commit (all files)/,$p'; then
      :
    else
      gh run view "$RID" --log || true
    fi
  else
    echo "[WARN] Run non trouvé; ouvrez l’onglet Actions."
  fi
else
  echo "[INFO] GitHub CLI 'gh' non détecté — patch/commit/push faits. Consultez l’onglet Actions pour la CI."
fi
