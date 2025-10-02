#!/usr/bin/env bash
###############################################################################
# 3) Archive .ci-logs/ vers .ci-archive/<stamp>/ci-logs.tar.gz
#    (optionnel: vider .ci-logs après archive)
###############################################################################
set +e
STAMP="$(date +%Y%m%dT%H%M%S)"
ARCH_DIR=".ci-archive/$STAMP"
LOG=".ci-logs/ci_archive_logs-$STAMP.log"
exec > >(tee -a "$LOG") 2>&1
say() { printf "\n== %s ==\n" "$*"; }
pause() {
  printf "\n(Pause) Entrée pour continuer… "
  read -r _ || true
}

mkdir -p "$ARCH_DIR"
say "Archiver .ci-logs -> $ARCH_DIR/ci-logs.tar.gz"
if [ -d .ci-logs ]; then
  tar -czf "$ARCH_DIR/ci-logs.tar.gz" .ci-logs || true
  echo "Archive: $ARCH_DIR/ci-logs.tar.gz"
else
  echo "Aucun .ci-logs/"
fi

echo
read -r -p "Vider .ci-logs/ après archive ? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  find .ci-logs -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
  echo "OK: .ci-logs/ vidé"
else
  echo "OK: .ci-logs/ conservé"
fi
pause
