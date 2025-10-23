#!/usr/bin/env bash
# ===== Bloc ZENODO-POLL+PATCH (SAFE, GARDE-FOU) =====
# Objectif : attendre le DOI de version pour le concept DOI, puis patcher CITATION.cff et README.md
# Vars : DOI_CONCEPT="10.5281/zenodo.15186836"  TRIES=20  SLEEP_S=30

# --- 0) Garde-fou minimal (si ton v5 n'est pas sourcé) ---
if [ ! -f ./garde_fou_universal_v5.sh ]; then
  for s in EXIT ERR INT HUP TERM; do trap - "$s" 2>/dev/null || true; done
  unset PROMPT_COMMAND 2>/dev/null || true
  set +e; set +o pipefail 2>/dev/null || true
  mkdir -p _logs
  BLOCK_NAME="zenodo_poll_patch"
  LOG="_logs/${BLOCK_NAME}_$(date +%Y%m%dT%H%M%S).log"
  if command -v stdbuf >/dev/null 2>&1; then exec > >(stdbuf -o0 tee -a "$LOG") 2>&1; else exec > >(tee -a "$LOG") 2>&1; fi
  run(){ echo; echo "\$ $*"; "$@"; rc=$?; echo "[rc=$rc] $*"; return $rc; }
  _finish_guard(){ code=$?; echo; echo "=== FIN ${BLOCK_NAME} (code=$code) ==="; echo "Log : $LOG";
    if [ -z "${NOPAUSE:-}" ] && [ -t 0 ] && [ -t 1 ]; then read -rp "▶ Entrée pour laisser la fenêtre ouverte... " _ || true
    elif [ -n "${HOLD_ON_EXIT:-}" ]; then echo "[hold] bash interactif (HOLD_ON_EXIT=1) — 'exit' pour quitter"; bash --noprofile --norc -i </dev/tty >/dev/tty 2>&1; fi; }
  trap _finish_guard EXIT
else
  BLOCK_NAME="zenodo_poll_patch" source ./garde_fou_universal_v5.sh
fi

echo "[ctx] branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
python -V 2>/dev/null || true

# --- 1) Paramètres ---
DOI_CONCEPT="${DOI_CONCEPT:-10.5281/zenodo.15186836}"
TRIES="${TRIES:-20}"
SLEEP_S="${SLEEP_S:-30}"

echo "[cfg] concept DOI = $DOI_CONCEPT ; tries=$TRIES ; sleep=${SLEEP_S}s"

# --- 2) Fonction de requête (sans token) ---
zen_query() {
  local q enc url
  q="conceptdoi:\"${DOI_CONCEPT}\""
  enc="$(python - <<'PY'
import os,urllib.parse,sys
q=os.environ.get("Q_IN","")
print(urllib.parse.quote(q))
PY
  )"
  url="https://zenodo.org/api/records?q=${enc}&size=1&sort=mostrecent"
  echo "$url"
}

# --- 3) Polling jusqu'au DOI de version ---
record_doi=""
record_url=""
for i in $(seq 1 "$TRIES"); do
  URL="$(Q_IN="conceptdoi:\"${DOI_CONCEPT}\"" zen_query)"
  echo "[zenodo] tentative $i/$TRIES → $URL"

  payload="$(curl -sS "$URL")"
  # Essayer avec jq si dispo (plus robuste)
  if command -v jq >/dev/null 2>&1; then
    record_doi="$(printf '%s' "$payload" | jq -r '.hits.hits[0].doi // empty')"
    record_url="$(printf '%s' "$payload" | jq -r '.hits.hits[0].links.self_html // empty')"
  else
    # Fallback Python
    read -r record_doi record_url <<EOF
$(python - <<'PY'
import json,sys
d=json.loads(sys.stdin.read() or "{}")
h=(d.get("hits",{}) or {}).get("hits",[]) or []
if h:
  r=h[0]
  print((r.get("doi") or "") + " " + (r.get("links",{}).get("self_html") or ""))
else:
  print(" ")
PY
    <<<"$payload")"
  fi

  if [ -n "$record_doi" ] && [ "$record_doi" != "null" ]; then
    echo "✅ DOI de version détecté: $record_doi"
    echo "   URL: $record_url"
    break
  fi

  echo "… pas encore disponible, on réessaie dans ${SLEEP_S}s"
  sleep "$SLEEP_S"
done

if [ -z "$record_doi" ] || [ "$record_doi" = "null" ]; then
  echo "⚠️  Aucun DOI de version trouvé pour le moment. Réessaie plus tard."
  return 0 2>/dev/null || exit 0
fi

# --- 4) Patcher CITATION.cff (champ doi:) ---
if [ -f CITATION.cff ]; then
  python - <<'PY'
import os,re,pathlib
doi=os.environ["REC_DOI"]
p=pathlib.Path("CITATION.cff")
t=p.read_text(encoding="utf-8")
if re.search(r'^doi:\s*', t, flags=re.M):
    t2=re.sub(r'^doi:\s*.*$', f'doi: {doi}', t, count=1, flags=re.M)
else:
    if not t.endswith("\n"): t+="\n"
    t2=t+f"doi: {doi}\n"
if t2!=t:
    p.write_text(t2,encoding="utf-8")
    print(f"[CITATION.cff] doi -> {doi}")
else:
    print("[CITATION.cff] déjà à jour")
PY
else
  echo "❌ CITATION.cff introuvable (skip patch)"
fi

# --- 5) Patcher le badge DOI dans README.md (version au lieu du concept) ---
if [ -f README.md ]; then
  python - <<'PY'
import os,re,pathlib
doi=os.environ["REC_DOI"]
url="https://doi.org/"+doi
badge=f"[![DOI]({ 'https://zenodo.org/badge/DOI/' + doi + '.svg' })]({url})"
p=pathlib.Path("README.md")
txt=p.read_text(encoding="utf-8")
pat=r'\[!\[DOI\]\(https://zenodo\.org/badge/DOI/.*?\.svg\)\]\(https://doi\.org/.*?\)'
if re.search(pat, txt):
    new=re.sub(pat, badge, txt, count=1)
else:
    # insérer sous le premier H1 si pas trouvé
    lines=txt.splitlines(True)
    ins=0
    for i,L in enumerate(lines):
        if L.startswith("# "): ins=i+1; break
    block=("\n" if ins else "")+badge+"\n\n"
    new="".join(lines[:ins])+block+"".join(lines[ins:])
if new!=txt:
    p.write_text(new,encoding="utf-8"); print("[README] badge DOI (version) mis à jour")
else:
    print("[README] badge déjà à jour")
PY
else
  echo "❌ README.md introuvable (skip patch)"
fi

# --- 6) Commit & push (si modifs) ---
git add CITATION.cff README.md 2>/dev/null || true
if ! git diff --cached --quiet; then
  run git commit -m "docs: mettre à jour DOI de version Zenodo (${record_doi}) dans CITATION.cff et README"
  run git push
else
  echo "[commit] rien à committer"
fi

# Export pour info
export REC_DOI="$record_doi" REC_URL="$record_url"
echo "[done] DOI version = $REC_DOI"
# ===== FIN Bloc ZENODO-POLL+PATCH =====
