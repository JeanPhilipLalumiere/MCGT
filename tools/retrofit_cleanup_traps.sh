#!/usr/bin/env bash
set -Eeuo pipefail

python3 - "$@" <<'PY'
import sys, pathlib, re

CLEANUP_SNIPPET = '''cleanup(){
  local rc="$1"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
'''

PATTERN = re.compile(
    r"""trap\s+(['"])(?:(?!\1).|\n)*?rc=\$\?(?:(?!\1).|\n)*?\1\s+EXIT""",
    re.S,
)

def process_file(path: pathlib.Path):
    text = path.read_text(encoding="utf-8")
    new_text, n = PATTERN.subn("trap 'cleanup $?' EXIT", text)
    if n == 0:
        return 0
    if 'cleanup()' not in new_text:
        if new_text.startswith('#!'):
            i = new_text.find('\n')
            new_text = new_text[:i+1] + CLEANUP_SNIPPET + new_text[i+1:]
        else:
            new_text = CLEANUP_SNIPPET + new_text
    path.write_text(new_text, encoding="utf-8")
    return n

total = 0
for arg in sys.argv[1:]:
    p = pathlib.Path(arg)
    if p.is_file():
        total += process_file(p)

print(f"[retrofit] traps convertis: {total}")
PY
