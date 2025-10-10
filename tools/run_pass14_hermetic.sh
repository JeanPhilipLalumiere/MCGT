#!/usr/bin/env bash
set -euo pipefail
exec tools/hermetic_pause_runner.sh tools/pass14_smoke_with_mapping.sh
