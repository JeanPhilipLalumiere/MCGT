#!/usr/bin/env bash
# shellcheck disable=SC2034
#!/usr/bin/env bash
set +e
found=0
while IFS= read -r -d '' mk; do
  if grep -qE '^[[:space:]]*\.RECIPEPREFIX' "$mk"; then
    echo "WARN: .RECIPEPREFIX détecté dans $mk"
    found=1
  fi
done < <(find . -maxdepth 3 -type f -name 'Makefile*' -print0 2>/dev/null)
exit 0
