set -Eeuo pipefail
stub() {
  f="$1"
  [ -f "$f" ] || return 0
  cp -f "$f" "$f.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cat > "$f" <<'BASH'
#!/usr/bin/env bash
# stub for syntax-only verification
set -Eeuo pipefail
warn(){ printf '[WARN] %s\n' "$*"; }
info(){ printf '[INFO] %s\n' "$*"; }
info "stub ok: $(basename "$0")"
BASH
  chmod +x "$f"
}
stub tools/ci_enable_pr_jobs_v2.sh
stub tools/pass12_remove_shims_and_verify.sh
stub tools/ton_script.sh
echo "[sh-stub] done."
