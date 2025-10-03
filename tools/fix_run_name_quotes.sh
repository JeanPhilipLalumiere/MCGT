#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# Utilise les fichiers reçus (pre-commit) sinon tous les workflows
files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
  # shellcheck disable=SC2207
  mapfile -t files < <(printf "%s\n" .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true)
fi

changed=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  tmp="$(mktemp)"
  awk '
    function rtrim(s){ sub(/[[:space:]]+$/, "", s); return s }
    function ltrim(s){ sub(/^[[:space:]]+/, "", s); return s }
    function is_quoted(s){
      s=ltrim(rtrim(s))
      if (length(s)<2) return 0
      q=substr(s,1,1)
      if (q != "\"" && q != "'\''") return 0
      return substr(s,length(s),1)==q
    }
    {
      line=$0
      if (match(line, /^([[:space:]]*run-name:[[:space:]]*)(.*)$/, a)) {
        lead=a[1]; rest=a[2]
        # Sépare valeur et commentaire (premier " #" littéral rencontré)
        cpos = index(rest, " #")
        if (cpos>0) { val=substr(rest,1,cpos-1); com=substr(rest,cpos) } else { val=rest; com="" }
        val = rtrim(val)
        # Si déjà quoté → inchangé
        if (is_quoted(val)) { print line; next }
        # Si contient ${{ ... }} → ajoute des guillemets en conservant le commentaire
        if (index(val, "{{") && index(val, "}}")) { print lead "\"" val "\"" com; next }
      }
      print line
    }
  ' "$f" >"$tmp"
  if ! cmp -s "$f" "$tmp"; then
    mv "$tmp" "$f"
    changed=1
  else
    rm -f "$tmp"
  fi
done

if ((changed)); then
  echo "[fix-run-name] corrections appliquées"
  # Retourne 1 pour que pre-commit relance avec les fichiers modifiés si hook local
  exit 1
else
  echo "[fix-run-name] OK"
fi
