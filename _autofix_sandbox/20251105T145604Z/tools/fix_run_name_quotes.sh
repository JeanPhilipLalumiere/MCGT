#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -Eeuo pipefail
shopt -s nullglob

# Use the filenames received from pre-commit, otherwise all workflow files
files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
  # shellcheck disable=SC2207
  mapfile -t files < <(ls -1 .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null || true)
fi

changed=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  tmp="$(mktemp)"
  awk '
    function trim(s){ sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s }
    function is_quoted(s){
      s=trim(s)
      if (length(s) < 2) return 0
      q = substr(s,1,1)
      if (q != "\"" && q != "'\''") return 0
      return substr(s,length(s),1) == q
    }
    {
      line = $0
      if (match(line, /^([[:space:]]*run-name:[[:space:]]*)(.*)$/, a)) {
        lead = a[1]
        rest = a[2]

        # Split off inline comment (first " #" occurrence)
        com = ""
        cpos = index(rest, " #")
        if (cpos > 0) {
          com = substr(rest, cpos)
          rest = substr(rest, 1, cpos - 1)
        }

        val = trim(rest)
        # Already quoted → keep as is
        if (is_quoted(val)) { print line; next }

        # If value contains GitHub expressions {{ }} → quote it, preserve comment
        if (val ~ /{{/ && val ~ /}}/) {
          print lead "\"" val "\"" com
          next
        }
      }
      print line
    }
  ' "$f" >"$tmp"

  if ! cmp -s "$f" "$tmp"; then
    mv "$tmp" "$f"
    changed=1
    echo "[fix-run-name] patched $f"
  else
    rm -f "$tmp"
  fi
done

# Exit 1 if we changed files so pre-commit can re-run formatting hooks
if ((changed)); then
  exit 1
else
  echo "[fix-run-name] OK (no changes)"
fi
