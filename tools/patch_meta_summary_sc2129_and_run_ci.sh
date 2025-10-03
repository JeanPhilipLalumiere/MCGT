#!/usr/bin/env bash
# Patch le step "Meta summary" d'un workflow GitHub pour regrouper
# plusieurs appends ">> $GITHUB_STEP_SUMMARY" en un seul redirect,
# afin d'éviter SC2129. Le patch est conservateur : il ne modifie
# que si toutes les lignes qui appendent sont contiguës.
#
# Usage:
#   tools/patch_meta_summary_sc2129_and_run_ci.sh [options]
# Options:
#   -f, --file PATH        Fichier workflow à patcher (sinon essaye sanity-main.yml)
#       --no-commit        N'effectue pas de commit automatique
#       --no-push          N'effectue pas de push
#       --no-trigger       Ne déclenche pas ci-pre-commit.yml
#       --watch            Regarde l'exécution CI après trigger (si déclenchée)
#   -h, --help             Aide
#
# Dépendances : bash, awk, git (pour commit/push), gh (pour trigger/watch).

set -Eeuo pipefail

cleanup() {
  local rc="$?"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
trap cleanup EXIT

# --- Defaults ---
FILE=""
DO_COMMIT=1
DO_PUSH=1
DO_TRIGGER=1
WATCH=0

# --- Args ---
usage() {
  sed -n '1,40p' "$0" | sed 's/^# \{0,1\}//'
}

while (($#)); do
  case "$1" in
    -f | --file)
      shift
      FILE="${1:-}"
      [[ -n "${FILE}" ]] || {
        echo "[ERREUR] --file requiert un chemin" >&2
        exit 2
      }
      shift
      ;;
    --no-commit)
      DO_COMMIT=0
      shift
      ;;
    --no-push)
      DO_PUSH=0
      shift
      ;;
    --no-trigger)
      DO_TRIGGER=0
      shift
      ;;
    --watch)
      WATCH=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "[ERREUR] Argument inconnu: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# --- Choix du fichier ---
if [[ -z "$FILE" ]]; then
  if [[ -f ".github/workflows/sanity-main.yml" ]]; then
    FILE=".github/workflows/sanity-main.yml"
  else
    echo "[ERREUR] Aucun fichier indiqué et .github/workflows/sanity-main.yml introuvable." >&2
    echo "        Spécifiez un fichier avec --file PATH." >&2
    exit 1
  fi
fi
[[ -f "$FILE" ]] || {
  echo "[ERREUR] Fichier introuvable: $FILE" >&2
  exit 1
}

# --- Sauvegarde ---
ts="$(date +%Y%m%dT%H%M%S)"
bak_dir=".ci-archive/workflows"
mkdir -p "$bak_dir"
bak_path="$bak_dir/$(basename "$FILE").bak.$ts"
cp -f -- "$FILE" "$bak_path"
echo "[INFO] Backup: $bak_path"

# --- Patcher (awk) ---
tmp_out="$(mktemp)"
awk -v target_step="Meta summary" '
function lspace(s,    n) { n=match(s,/^[ ]*/); return RLENGTH }
function process_block(arr, n, base_ind,    i, cnt, first, last, nonredir, content_ind, line) {
  cnt=0; first=-1; last=-1
  for (i=1;i<=n;i++){
    if (arr[i] ~ />>[[:space:]]*"?\$GITHUB_STEP_SUMMARY"?[[:space:]]*$/){
      cnt++
      if (first<0) first=i
      last=i
    }
  }
  if (cnt<=1) {
    for (i=1;i<=n;i++) print arr[i]
    return 0
  }
  nonredir=0
  for (i=first;i<=last;i++){
    if (arr[i] ~ /^[[:space:]]*$/) continue
    if (arr[i] !~ />>[[:space:]]*"?\$GITHUB_STEP_SUMMARY"?[[:space:]]*$/){ nonredir=1; break }
  }
  if (nonredir){
    # Trop risqué: on laisse tel quel
    for (i=1;i<=n;i++) print arr[i]
    return 0
  }
  content_ind=""
  for (i=1;i<=n;i++){
    if (arr[i] ~ /^[[:space:]]*$/) continue
    match(arr[i],/^[ ]*/)
    content_ind=substr(arr[i],1,RLENGTH)
    break
  }
  # avant le premier
  for (i=1;i<first;i++) print arr[i]
  print content_ind "{"
  for (i=first;i<=last;i++){
    line=arr[i]
    sub(/[[:space:]]*>>[[:space:]]*"?\$GITHUB_STEP_SUMMARY"?[[:space:]]*$/,"", line)
    print line
  }
  print content_ind "} >> \"$GITHUB_STEP_SUMMARY\""
  for (i=last+1;i<=n;i++) print arr[i]
  return 1
}
BEGIN{
  in_run=0; changed=0; step_name=""; run_base=0
  bcount=0
}
{
  if (!in_run) {
    # garde le dernier "name:" rencontré
    if ($0 ~ /^[[:space:]]*name:[[:space:]]*/) {
      sub(/^[[:space:]]*name:[[:space:]]*/,"")
      step_name=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",step_name)
    }
    # detect run: |
    if ($0 ~ /^[[:space:]]*run:[[:space:]]*\|[[:space:]]*$/) {
      # nactive uniquement si on est dans le bon step
      if (step_name == target_step) {
        print $0
        in_run=1
        run_base=lspace($0)
        bcount=0
        next
      }
    }
    print $0
    next
  } else {
    # dans un bloc run: |
    if ($0 ~ /^[[:space:]]*$/) {
      block[++bcount]=$0
      next
    }
    cur=lspace($0)
    if (cur > run_base) {
      block[++bcount]=$0
      next
    }
    # fin du bloc
    if (process_block(block, bcount, run_base)) changed=1
    # reset
    split("", block); bcount=0; in_run=0
    # traiter la ligne courante hors bloc
    print $0
    next
  }
}
END{
  if (in_run) {
    # fin de fichier au milieu du bloc
    if (process_block(block, bcount, run_base)) changed=1
  }
  if (changed) {
    # marqueur pour debug si nécessaire (stdout propre autrement)
    # print "#__SC2129_PATCH_APPLIED__" > "/dev/stderr"
    ;
  }
}
' "$FILE" >"$tmp_out"

# Détermine si des changements ont été appliqués
PATCHED=0
if cmp -s -- "$FILE" "$tmp_out"; then
  echo "[INFO] Aucun changement nécessaire (déjà SC2129-safe)."
else
  mv -- "$tmp_out" "$FILE"
  PATCHED=1
  echo "[OK] Patch appliqué: $FILE"
fi
rm -f -- "$tmp_out" || true

# --- Git ops ---
if ((PATCHED)) && ((DO_COMMIT)); then
  git add -- "$FILE" || true
  if git check-ignore -q -- "$bak_path"; then
    echo "[INFO] Backup ignoré par .gitignore (non ajouté): $bak_path"
  else
    git add -- "$bak_path" || true
  fi
  msg="ci(sanity-main): SC2129 - regroupe les appends du step \"Meta summary\" vers \$GITHUB_STEP_SUMMARY"
  git commit -m "$msg" || { echo "[INFO] Rien à commit (peut-être déjà en place)."; }
else
  if ((!DO_COMMIT)); then
    echo "[INFO] --no-commit : aucun commit créé."
  fi
fi

if ((PATCHED)) && ((DO_COMMIT)) && ((DO_PUSH)); then
  echo "[INFO] Push sur main…"
  git push -u origin HEAD:main || true
else
  if ((!DO_PUSH)); then
    echo "[INFO] --no-push : aucun push effectué."
  fi
fi

# --- CI trigger / watch ---
if ((DO_TRIGGER)); then
  if command -v gh >/dev/null 2>&1; then
    echo "[INFO] Déclenchement du workflow ci-pre-commit.yml…"
    gh workflow run ci-pre-commit.yml || true
    if ((WATCH)); then
      if [[ -x tools/watch_head_ci.sh ]]; then
        echo "[INFO] Suivi du run en temps réel via tools/watch_head_ci.sh…"
        tools/watch_head_ci.sh || true
      else
        echo "[WARN] tools/watch_head_ci.sh introuvable ou non exécutable ; pas de suivi."
      fi
    fi
  else
    echo "[WARN] gh (GitHub CLI) non disponible: impossible de déclencher/observer la CI."
  fi
else
  echo "[INFO] --no-trigger : aucun déclenchement CI."
fi

echo "[OK] Terminé."
