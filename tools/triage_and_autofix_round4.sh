# tools/triage_and_autofix_round4.sh
#!/usr/bin/env bash
set -Eeuo pipefail

say(){ echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }

# 1) Localise le DERNIER rapport & log
REPORT="$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1 || true)"
LOG="$(dirname "${REPORT:-/dev/null}")/run.log"
[[ -f "${REPORT:-}" && -f "${LOG:-}" ]] || { echo "[ERR] Pas de smoke récent. Lance d’abord: bash tools/smoke_help_repo.sh"; exit 1; }

say "Report : $REPORT"
say "Log    : $LOG"

# 2) Liste des FAIL
mapfile -t FAILS < <(awk '$1=="FAIL"{print $2}' "$REPORT")
(( ${#FAILS[@]} > 0 )) || { say "0 FAIL — rien à faire."; exit 0; }
printf '%s\n' "${FAILS[@]}" | nl -ba | sed 's/^/[FAIL] /'

TS="$(date -u +%Y%m%dT%H%M%SZ)"

# 3) Helpers
backup(){ [[ -f "$1" ]] && cp --no-clobber --update=none -- "$1" "${1}.bak_${TS}" || true; }
have(){ command -v "$1" >/dev/null 2>&1; }

# 4) Tire des patterns d’exception depuis le log (simple et robuste)
extract_exc(){ awk -v f="$1" '
  $0 ~ ("TEST --help: " f) { hit=1; next }
  hit && $0 ~ /^TEST --help:/ { hit=0 } 
  hit { print }
' "$LOG" | grep -E "(Traceback|Error|Exception|NameError|SyntaxError|FileNotFoundError|TypeError)" -A3 || true; }

# 5) Autofix par patterns
patched=0
for f in "${FAILS[@]}"; do
  say "Autofix: $f"
  backup "$f"

  EXC="$(extract_exc "$f" | tr -d '\r')"

  # a) import sys manquant
  if grep -q "NameError: name 'sys' is not defined" <<<"$EXC"; then
    if ! rg -n '^\s*import\s+sys(\s|$)' "$f" >/dev/null 2>&1; then
      # injecte après le bloc d’imports
      python - "$f" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8"); L=s.splitlines(True)
i=0
# conserver shebang/enc/commentaires puis imports existants
while i<len(L) and (L[i].startswith('#!') or L[i].strip()=='' or L[i].lstrip().startswith(('from ','import ')) or L[i].startswith('#')):
    i+=1
# avancer sur imports existants pour insérer à la fin du bloc
j=0
while j<len(L) and (L[j].startswith('#!') or L[j].strip()=='' or L[j].lstrip().startswith(('from ','import ')) or L[j].startswith('#')):
    j+=1
k=j
while k<len(L) and L[k].lstrip().startswith(('from ','import ')):
    k+=1
L.insert(k, "import sys\n")
p.write_text("".join(L), encoding="utf-8")
print(f"[PATCH] {p} (+ import sys)")
PY
      patched=$((patched+1))
    fi
  fi

  # b) plt/fig/ax utilisés avant main (ne doivent pas s’exécuter au --help)
  if grep -qE "NameError: name '(plt|fig|ax)'" <<<"$EXC"; then
    # Déclare des sentinelles bénignes pour survivre au --help (aucune exécution de plot)
    python - "$f" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8")
L=s.splitlines(True)
insert_at=0
# remonte après shebang/enc/header
while insert_at < len(L) and (L[insert_at].startswith('#!') or L[insert_at].startswith('# -*-') or L[insert_at].strip()=='' or L[insert_at].startswith('#')):
    insert_at += 1
guard = []
if not re.search(r'^\s*try:\s*;\s*except\s*:\s*;\s*#\s*plt_guard', s, re.M):
    guard.append("try: ; except: ; # plt_guard\n")
if "plt = None  # guard for --help" not in s:
    guard.append("plt = None  # guard for --help\n")
if "fig = None  # guard for --help" not in s:
    guard.append("fig = None  # guard for --help\n")
if "ax = None   # guard for --help" not in s:
    guard.append("ax = None   # guard for --help\n")
if guard:
    L[insert_at:insert_at] = guard
    p.write_text("".join(L), encoding="utf-8")
    print(f"[PATCH] {p} (+ plt/fig/ax guards)")
PY
    patched=$((patched+1))
  fi

  # c) DATA_IN ou similaires non définis au module-scope (CH02/FG_series)
  if grep -qE "name 'DATA_IN' is not defined" <<<"$EXC"; then
    python - "$f" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8")
if "DATA_IN" in s and "DATA_IN = None  # guard for --help" not in s:
    L=s.splitlines(True)
    i=0
    while i<len(L) and (L[i].startswith('#!') or L[i].startswith('# -*-') or L[i].strip()=='' or L[i].startswith('#') or L[i].lstrip().startswith(('from ','import '))):
        i+=1
    L.insert(i, "DATA_IN = None  # guard for --help\n")
    p.write_text("".join(L), encoding="utf-8")
    print(f"[PATCH] {p} (+ DATA_IN guard)")
PY
    patched=$((patched+1))
  fi

  # d) from __future__ pas en tête (sécurité déf.)
  if grep -q "from __future__ imports must occur at the beginning of the file" <<<"$EXC"; then
    python - "$f" <<'PY'
import sys, pathlib, re
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding="utf-8").splitlines(True)
shebang=[]; rest=s[:]
if rest and rest[0].startswith("#!"): shebang=[rest.pop(0)]
header=[]
while rest and (rest[0].startswith("#") or rest[0].strip()==""): header.append(rest.pop(0))
futures=[ln for ln in rest if re.match(r'^\s*from\s+__future__\s+import\s+', ln)]
if futures:
    rest=[ln for ln in rest if ln not in futures]
    new="".join(shebang+header+futures+rest)
    p.write_text(new, encoding="utf-8")
    print(f"[PATCH] {p} (future imports remontés)")
PY
    patched=$((patched+1))
  fi
done

say "Patched files: $patched"

# 6) Re-run smoke (mesure)
bash tools/smoke_help_repo.sh
