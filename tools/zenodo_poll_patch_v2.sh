#!/usr/bin/env bash
# ===== Bloc TAG+RELEASE + POLL ZENODO (SAFE, GARDE-FOU) =====
# Paramètres modifiables :
NEW_TAG="${NEW_TAG:-v0.3.7}"
TITLE="${TITLE:-MCGT ${NEW_TAG}}"
NOTES="${NOTES:-Release ${NEW_TAG} pour déclencher l’archivage Zenodo}"
ATTACH_DIST="${ATTACH_DIST:-1}"
DOI_CONCEPT="${DOI_CONCEPT:-10.5281/zenodo.15186836}"

# ---------- 0) GARDE-FOU ----------
for s in EXIT ERR INT HUP TERM; do trap - "$s" 2>/dev/null || true; done
unset PROMPT_COMMAND 2>/dev/null || true
set +e; set +o pipefail 2>/dev/null || true
mkdir -p _logs
BLOCK_NAME="tag_release_${NEW_TAG}_with_poll"
LOG="_logs/${BLOCK_NAME}_$(date +%Y%m%dT%H%M%S).log"
if command -v stdbuf >/dev/null 2>&1; then exec > >(stdbuf -o0 tee -a "$LOG") 2>&1; else exec > >(tee -a "$LOG") 2>&1; fi
run(){ echo; echo "\$ $*"; "$@"; rc=$?; echo "[rc=$rc] $*"; return $rc; }
_finish_guard(){ code=$?; echo; echo "=== FIN ${BLOCK_NAME} (code=$code) ===";
  if [ -z "${NOPAUSE:-}" ] && [ -t 0 ] && [ -t 1 ]; then read -rp "▶ Entrée pour laisser la fenêtre ouverte... " _ || true
  elif [ -n "${HOLD_ON_EXIT:-}" ]; then echo "[hold] shell interactif de secours (HOLD_ON_EXIT=1)"; exec "${SHELL:-bash}" -i; fi; }
trap _finish_guard EXIT

echo "[ctx] branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
python -V 2>/dev/null || true
echo "[log] $(date --iso=seconds) → $LOG"

# ---------- 1) Checks rapides (non bloquants, mais on s’arrête si erreurs>0) ----------
echo "[refresh] fix_manifest_missing.py --refresh"
run python tools/fix_manifest_missing.py --refresh

echo "[diag] capture JSON propres (sans run)"
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check \
  > "_logs/release_master_${NEW_TAG}.json" 2> "_logs/release_master_${NEW_TAG}.stderr" || true
python zz-manifests/diag_consistency.py zz-manifests/manifest_publication.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check \
  > "_logs/release_publ_${NEW_TAG}.json" 2> "_logs/release_publ_${NEW_TAG}.stderr" || true

# Compter les erreurs depuis les fichiers JSON (robuste aux erreurs d’E/S)
count_json_errors() {
  python - "$1" <<'PY'
import json,sys,Pathlib as P
from pathlib import Path
p=Path(sys.argv[1])
if not p.exists():
  print("ERR:file-missing"); sys.exit(0)
try:
  d=json.loads(p.read_text(encoding='utf-8'))
except Exception as e:
  print(f"ERR:{e}"); sys.exit(0)
errs=sum(1 for i in d.get("issues",[]) if i.get("severity")=="ERROR")
print(errs)
PY
}
M_ERRS="$(count_json_errors "_logs/release_master_${NEW_TAG}.json")"
P_ERRS="$(count_json_errors "_logs/release_publ_${NEW_TAG}.json")"
echo "[diag] master errors=${M_ERRS} ; publ errors=${P_ERRS}"

if [ "$M_ERRS" != "0" ] || [ "$P_ERRS" != "0" ]; then
  echo "❌ Diag non-verte — on n’exécute pas tag/release."
  echo "   Ouvre : _logs/release_master_${NEW_TAG}.json  et  _logs/release_publ_${NEW_TAG}.json"
  exit 0
fi

# ---------- 2) Tag + Release ----------
echo "[tag] création ${NEW_TAG}"
run git tag -a "${NEW_TAG}" -m "${TITLE}"
run git push origin "${NEW_TAG}"

echo "[release] création ${NEW_TAG}"
run gh release create "${NEW_TAG}" --title "${TITLE}" --notes "${NOTES}"

if [ "$ATTACH_DIST" = "1" ] && ls dist/* >/dev/null 2>&1; then
  echo "[release] upload dist/* → ${NEW_TAG}"
  # --clobber pour ré-upload si fichiers déjà présents
  run gh release upload "${NEW_TAG}" dist/* --clobber
else
  echo "[release] aucun artefact dist/* à uploader (ok si volontaire)."
fi

echo "[zenodo] Si GitHub↔Zenodo est actif, cette release déclenchera l’archivage."

# ---------- 3) Poll Zenodo en arrière-plan (nohup) ----------
cat > _tmp/zenodo_onecheck.sh <<'CHK'
#!/usr/bin/env bash
set +e; set +o pipefail 2>/dev/null || true
DOI_CONCEPT="$1"
curl -sS --get "https://zenodo.org/api/records" \
  --data-urlencode "q=conceptdoi:\"${DOI_CONCEPT}\"" \
  --data-urlencode "size=1" \
  --data-urlencode "sort=mostrecent" \
| jq -r --arg C "$DOI_CONCEPT" '
  (.hits.hits // []) as $h |
  ( $h | map(select(.conceptdoi==$C)) | .[0] ) as $r |
  if ($r == null) then "NONE"
  else
    "OK|" + ($r.metadata.title // "?") + "|" + ($r.doi // "?") + "|" + ($r.links.self_html // "?")
  end'
CHK
chmod +x _tmp/zenodo_onecheck.sh

PLOG="_logs/zenodo_poll_${NEW_TAG}_$(date +%Y%m%dT%H%M%S).log"
(
  echo "[poll] concept=${DOI_CONCEPT}  tag=${NEW_TAG}"
  tries="${TRIES:-40}"
  sleep_s="${SLEEP_S:-45}"
  max_sleep="${MAX_SLEEP:-240}"
  for i in $(seq 1 "$tries"); do
    echo "[poll] tentative $i/$tries"
    res="$(_tmp/zenodo_onecheck.sh "${DOI_CONCEPT}")"
    if [[ "$res" == OK* ]]; then
      IFS="|" read -r _ title doi url <<<"$res"
      echo "✅ Zenodo prêt: $doi"
      echo "    title: $title"
      echo "    url  : $url"
      exit 0
    fi
    echo "… pas encore disponible (attente=${sleep_s}s)."
    sleep "$sleep_s"
    # backoff simple avec plafond
    sleep_s=$(( sleep_s + sleep_s/2 ))
    if [ "$sleep_s" -gt "$max_sleep" ]; then sleep_s="$max_sleep"; fi
  done
  echo "⚠️  Poll terminé sans apparition de la version. Réessaie plus tard ou crée une nouvelle release si besoin."
) > "$PLOG" 2>&1 &

echo "[poll] lancé en arrière-plan. PID=$!  log=$PLOG"
echo "Astuce: tail -f \"$PLOG\""
# ===== Fin Bloc TAG+RELEASE + POLL ZENODO =====
