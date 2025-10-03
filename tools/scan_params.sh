#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

outfile=".ci-out/params/params-inventory.tsv"
mkdir -p "$(dirname "$outfile")"
: >"$outfile"
printf "KIND\tNAME\tSAMPLE_VALUE\tFILE\tLINE\n" >>"$outfile"

# 1) YAML keys in *.yml/*.yaml
find . -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 |
  while IFS= read -r -d '' f; do
    awk -v F="$f" '{
    if (match($0,/^[[:space:]-]*([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$/,m)) {
      key=m[1]; val=m[2];
      sub(/[[:space:]]+#.*$/,"",val);
      if (length(val)>120) val=substr(val,1,117)"...";
      gsub(/\t/," ",val);
      printf("yaml_key\t%s\t%s\t%s\t%d\n",key,val,F,NR)
    }
  }' "$f" >>"$outfile"
  done

# 2) YAML front-matter at start of *.md
find . -type f -name '*.md' -print0 |
  while IFS= read -r -d '' f; do
    awk -v F="$f" '
    NR==1 && $0 ~ /^---[[:space:]]*$/ { fm=1; next }
    fm && $0 ~ /^---[[:space:]]*$/    { fm=0; next }
    fm && match($0,/^[[:space:]-]*([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*:[[:space:]]*(.*)$/,m) {
      key=m[1]; val=m[2];
      sub(/[[:space:]]+#.*$/,"",val);
      if (length(val)>120) val=substr(val,1,117)"...";
      gsub(/\t/," ",val);
      printf("frontmatter_key\t%s\t%s\t%s\t%d\n",key,val,F,NR)
    }
  ' "$f" >>"$outfile"
  done

# 3) Env vars in *.sh, *.env, Makefile (best-effort)
find . -type f \( -name '*.sh' -o -name '*.env' -o -name 'Makefile' \) -print0 |
  while IFS= read -r -d '' f; do
    grep -nE '(^|[[:space:]])(export[[:space:]]+)?([A-Z][A-Z0-9_]{2,})=' "$f" 2>/dev/null |
      awk -v F="$f" -F: '{
    ln=$1; line=$0; sub(/^[0-9]+:/,"",line);
    if (match(line,/(^|[[:space:]])(export[[:space:]]+)?([A-Z][A-Z0-9_]{2,})=/,m)) {
      var=m[3];
      val=line; sub(/^.*=/,"",val); sub(/[[:space:]]+#.*$/,"",val);
      if (length(val)>120) val=substr(val,1,117)"...";
      gsub(/\t/," ",val);
      printf("env_var\t%s\t%s\t%s\t%s\n",var,val,F,ln)
    }
  }' >>"$outfile" || true
  done

echo "[INFO] Inventory -> $outfile"
