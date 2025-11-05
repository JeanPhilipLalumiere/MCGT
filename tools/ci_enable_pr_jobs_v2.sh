#!/usr/bin/env bash
# stub for syntax-only verification
set -Eeuo pipefail
warn(){ printf '[WARN] %s\n' "$*"; }
info(){ printf '[INFO] %s\n' "$*"; }
info "stub ok: $(basename "$0")"
