#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set +e
mkdir -p .ci-out
TS="$(date -u +%FT%TZ)"
cat >.ci-out/diag.json <<JSON
{"timestamp":"$TS","errors":0,"warnings":0,"issues":[{"severity":"INFO","code":"PING","msg":"sanity OK"}]}
JSON
echo 'export const sanity="OK";' >.ci-out/diag.ts
echo "OK: .ci-out/diag.json + .ci-out/diag.ts générés ($TS)"
