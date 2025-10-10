#!/usr/bin/env bash
set -euo pipefail
export MCGT_FILTER_ENV=1
exec tools/run_pass14_with_pause.sh
