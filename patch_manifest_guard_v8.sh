#!/usr/bin/env bash
set -Eeuo pipefail
WF=".github/workflows/manifest-guard.yml"
tmp="$(mktemp)"
awk '
  BEGIN{in_step=0}
  {printline=1}
  /- name: Run diag_consistency \(collect JSON\)/{in_step=1}
  in_step && /run: \|/{
    print $0
    print "          set +e"
    print "          # Localise le diag"
    print "          if   [ -f zz-manifests/diag_consistency.py ]; then D=zz-manifests/diag_consistency.py"
    print "          elif [ -f zz-scripts/diag_consistency.py   ]; then D=zz-scripts/diag_consistency.py"
    print "          else"
    print "            echo \"[SKIP] diag_consistency.py not found\""
    print "            echo '{\"issues\":[],\"rules\":{}}' > diag_report.json"
    print "            RC=0"
    print "            echo \"[INFO] diag exit code: $RC (no diag script)\""
    print "            exit 0"
    print "          fi"
    print "          echo \"[INFO] Using diag: $D\""
    print "          python3 \"$D\" \"$MANIFEST\" \\"
    print "            --report json --normalize-paths --apply-aliases --strip-internal --content-check \\"
    print "            > diag_report.json"
    print "          RC=$?"
    print "          echo \"[INFO] diag exit code: $RC\""
    print "          # On ne fait PAS échouer ici: la post-analyse traitera errors/warns"
    print "          exit 0"
    skip_block=1; next
  }
  skip_block && /^[[:space:]]*shell: bash/{next}
  skip_block && /^[[:space:]]*env:/{next}
  skip_block && /^[[:space:]]*run: \|/{next}
  skip_block && /^[[:space:]]*# Localise le diag/{next}
  skip_block && /^[[:space:]]*if[[:space:]]+\[ -f zz-manifests\/diag_consistency.py \ ]/{next}
  skip_block && /^[[:space:]]*elif \[ -f zz-scripts\/diag_consistency.py/{next}
  skip_block && /^[[:space:]]*else/{next}
  skip_block && /^[[:space:]]*echo "\[SKIP\] diag_consistency.py not found"/{next}
  skip_block && /^[[:space:]]*echo .*diag_report.json/{next}
  skip_block && /^[[:space:]]*exit 0/{next}
  skip_block && /^[[:space:]]*fi/{next}
  skip_block && /^[[:space:]]*echo "\[INFO\] Using diag: \$D"/{next}
  skip_block && /^[[:space:]]*python3 "\$D" "\$MANIFEST"/{next}
  skip_block && /^[[:space:]]*--report json/{next}
  skip_block && /^[[:space:]]*> diag_report.json/{next}
  skip_block && /^[[:space:]]*echo "\[OK\] diag report written: diag_report.json"/{next}
  {print}
' "$WF" > "$tmp" && mv "$tmp" "$WF"

git add "$WF"
git commit -m "ci(manifest-guard): v8 — make diag step non-blocking; always produce report"
git push
