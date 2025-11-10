#!/usr/bin/env bash
set -Eeuo pipefail
WF=".github/workflows/manifest-guard.yml"
TMP_BODY="$(mktemp)"
awk 'BEGIN{s=0} /^jobs:/{s=1} s{print}' "$WF" > "$TMP_BODY"

cat > "$WF" <<'YAML'
name: manifest-guard
on:
  workflow_dispatch: {}
  push:
    branches: [release/zz-tools-0.3.1]
  pull_request:
    branches: [release/zz-tools-0.3.1]
permissions:
  contents: read
concurrency:
  group: manifest-guard-${{ github.ref }}
  cancel-in-progress: true
YAML

cat "$TMP_BODY" >> "$WF"
rm -f "$TMP_BODY"
echo "[OK] Header réécrit avec workflow_dispatch/push/pr ciblés."
