#!/usr/bin/env bash
set -euo pipefail

echo "[PASS5-RELOC] Repositionnement du shim après docstring + __future__ + encodage"

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
# Si la fail list n'existe pas, on la génère d'abord avec l'inventaire SAFE
if [[ ! -s "$FAIL_LIST" ]]; then
  echo "[INFO] Pas de fail list détectée → lancement de l'inventaire SAFE (pass4)"
  tools/homog_pass4_cli_inventory_safe.sh
fi
[[ -s "$FAIL_LIST" ]] || { echo "[INFO] Rien à relocaliser (fail list vide)"; exit 0; }

python3 - <<'PY'
import os, re, pathlib, sys

marker_open = "# === [PASS5-AUTOFIX-SHIM] ==="
marker_close = "# === [/PASS5-AUTOFIX-SHIM] ==="

def strip_existing_shim(text: str) -> str:
    return re.sub(r"(?ms)^\s*# === \[PASS5-AUTOFIX-SHIM\] ===.*?# === \[/PASS5-AUTOFIX-SHIM\] ===\s*\n?", "", text)

def find_insert_pos(text: str) -> int:
    i = 0
    # shebang
    if text.startswith("#!"):
        j = text.find("\n")
        i = j + 1 if j != -1 else len(text)
    # encoding cookie in first 2 lines
    enc_pat = re.compile(r"^[ \t]*#.*coding[:=][ \t]*[-\w.]+", re.IGNORECASE|re.MULTILINE)
    first_two = text.splitlines(True)[:2]
    m_enc = None
    for L in first_two:
        if enc_pat.match(L):
            m_enc = True
            i = max(i, len("".join(first_two[:first_two.index(L)+1])))
            break
    # module docstring (triple quotes at first non-comment line)
    pos = i
    while True:
        m = re.search(r"^.*$", text[pos:], re.MULTILINE)
        if not m: break
        line = m.group(0)
        if line.strip() and not line.lstrip().startswith("#"):
            if line.lstrip().startswith(('"""',"'''")):
                q = line.lstrip()[:3]
                start = pos + m.start() + (len(line) - len(line.lstrip()))
                end = text.find(q, start+3)
                while end != -1 and text[end-1] == '\\':
                    end = text.find(q, end+1)
                if end != -1:
                    i = end+3
                    if i < len(text) and text[i] == "\n":
                        i += 1
            break
        pos += m.end()
    # from __future__ block(s)
    fut = re.compile(r"^[ \t]*from[ \t]+__future__[ \t]+import[^\n]*$", re.MULTILINE)
    while True:
        m = fut.search(text, i)
        if not m: break
        i = m.end()
        if i < len(text) and text[i] == "\n":
            i += 1
    return i

def build_shim() -> str:
    return f"""{marker_open}
if __name__ == "__main__":
    try:
        import sys, os, atexit
        _argv = sys.argv[1:]
        if any(a in ("-h","--help") for a in _argv):
            import argparse
            _p = argparse.ArgumentParser(description="MCGT (shim auto-injecté Pass5)", add_help=True, allow_abbrev=False)
            _p.add_argument("--out", help="Chemin de sortie pour fig.savefig (optionnel)")
            _p.add_argument("--dpi", type=int, default=120, help="DPI (par défaut: 120)")
            _p.add_argument("--show", action="store_true", help="Force plt.show() en fin d'exécution")
            _p.parse_known_args()
            sys.exit(0)
        _out = None
        if "--out" in _argv:
            try:
                i = _argv.index("--out"); _out = _argv[i+1] if i+1 < len(_argv) else None
            except Exception: _out = None
        if _out:
            os.environ.setdefault("MPLBACKEND", "Agg")
            try:
                import matplotlib.pyplot as plt
                def _shim_show(*a, **k): pass
                plt.show = _shim_show
                _dpi = 120
                if "--dpi" in _argv:
                    try: _dpi = int(_argv[_argv.index("--dpi")+1])
                    except Exception: _dpi = 120
                @atexit.register
                def _pass5_save_last_figure():
                    try:
                        fig = plt.gcf()
                        fig.savefig(_out, dpi=_dpi)
                        print(f"[PASS5] Wrote: {{_out}}")
                    except Exception as _e:
                        print(f"[PASS5] savefig failed: {{_e}}")
            except Exception:
                pass
    except Exception:
        pass
{marker_close}
"""

files = [line.strip() for line in open("zz-out/homog_cli_fail_list.txt","r",encoding="utf-8") if line.strip()]
patched=0
for fp in files:
    p = pathlib.Path(fp)
    if not p.exists():
        print(f"[SKIP] {fp} (absent)"); continue
    s = p.read_text(encoding="utf-8", errors="replace")
    s2 = strip_existing_shim(s)
    ins = find_insert_pos(s2)
    new = s2[:ins] + build_shim() + s2[ins:]
    if new != s:
        p.write_text(new, encoding="utf-8")
        patched += 1
        print(f"[OK] Relocalisé: {fp}")
print(f"[PASS5-RELOC] Fichiers réécrits: {patched}")
PY

echo "[PASS5-RELOC] Re-smoke inventaire SAFE…"
tools/homog_pass4_cli_inventory_safe.sh

echo
echo "=== Résumé (safe) ==="
tail -n 5 zz-out/homog_cli_inventory_pass4.txt || true
echo "[LIST] Échecs restants: zz-out/homog_cli_fail_list.txt"
