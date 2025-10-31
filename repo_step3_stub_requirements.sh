# repo_step3_stub_requirements.sh  (écrit uniquement si le fichier est absent)
set +e
set -u
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
COMMON="$REPO/zz-scripts/_common/requirements.txt"
mkdir -p "$(dirname "$COMMON")"
# N’installe rien, simple base indicative — ajuste-la ensuite.
if [ ! -f "$COMMON" ]; then
  cat > "$COMMON" <<'EOF'
# Base commune minimale (à affiner/pinner)
numpy
scipy
matplotlib
pandas
EOF
fi

for nn in $(seq -w 01 10); do
  f="$REPO/zz-scripts/chapter${nn}/requirements.txt"
  if [ ! -f "$f" ]; then
    mkdir -p "$(dirname "$f")"
    printf -- "-r ../_common/requirements.txt\n" > "$f"
    echo "CREATED: $f"
  else
    echo "EXISTS : $f"
  fi
done

read -r -p "[PAUSE] Entrée pour quitter..." _
