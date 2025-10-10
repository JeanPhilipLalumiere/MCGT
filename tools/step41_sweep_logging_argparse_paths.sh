#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Rafraîchir la liste d'erreurs
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step41] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

KW = r'(?:default|dest|type|help|choices|action|required|metavar)'

def fix_build_grid(s: str) -> str:
    """
    Remplace la définition de build_grid(...) par une version minimale correcte
    si on détecte un 'else:' orphelin dans son corps.
    """
    # localise la signature
    m = re.search(r'(?m)^(?P<i>\s*)def\s+build_grid\s*\(\s*tmin\s*,\s*tmax\s*,\s*step\s*,\s*spacing\s*\)\s*:\s*$', s)
    if not m: 
        return s
    indent = m.group('i')
    start = m.end()

    # bornes du bloc: jusqu'au prochain def/class au même niveau ou fin de fichier
    nxt = re.search(r'(?m)^(?:def|class)\s+\w', s[start:])
    end = start + (nxt.start() if nxt else len(s)-start)

    body = s[start:end]
    if 'else:' not in body or 'spacing' not in body:
        return s  # ne touche pas si ça ne ressemble pas à notre cas

    fixed_body = (
        f"{indent}    # normalized by step41\n"
        f"{indent}    import numpy as np\n"
        f"{indent}    if spacing == \"log\":\n"
        f"{indent}        n = int((np.log10(tmax) - np.log10(tmin)) / step) + 1\n"
        f"{indent}        return 10 ** np.linspace(np.log10(tmin), np.log10(tmax), n)\n"
        f"{indent}    else:\n"
        f"{indent}        n = int((tmax - tmin) / step) + 1\n"
        f"{indent}        return np.linspace(tmin, tmax, n)\n"
    )
    return s[:start] + fixed_body + s[end:]

def fix_logging_strays(s: str) -> str:
    # supprime les lignes “fantômes” dupliquées après basicConfig (ex: s: %(message)s"))
    s = re.sub(r'(?m)^[ \t]*[^\n]*%\(\s*message\s*\)s"\)\s*$', '', s)
    # compacte les doubles basicConfig adjacents (garde la première)
    s = re.sub(
        r'(?ms)(logging\.basicConfig\([^)]*\)\s*)+(?=logging\.getLogger|\S|\Z)',
        lambda m: re.findall(r'logging\.basicConfig\([^)]*\)', m.group(0))[0] + "\n",
        s
    )
    return s

def fix_repo_join(s: str) -> str:
    # répare _repo = os.path.abspath()os.path.join()os.path.dirname(__file__), "..", ".."
    s = re.sub(
        r'_repo\s*=\s*os\.path\.abspath\(\)\s*os\.path\.join\(\)\s*os\.path\.dirname\(\s*__file__\s*\)\s*,\s*"\.\,"\s*,\s*"\.\."\s*',
        r'_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))',
        s
    )
    # version plus tolérante: si on voit os.path.abspath()os.path.join(), on remappe proprement
    s = re.sub(
        r'_repo\s*=\s*os\.path\.abspath\(\)\s*os\.path\.join\(\)\s*os\.path\.dirname\(\s*__file__\s*\)\s*,\s*"\.\."\s*,\s*"\.\."\s*',
        r'_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))',
        s
    )
    return s

def fix_add_argument_commas(s: str) -> str:
    """
    À l'intérieur de parser.add_argument(...):
      - ajoute une virgule manquante entre un dernier “string option” et un mot-clé (default=, help=, …)
      - ajoute une virgule manquante entre une liste choices=[...] et un mot-clé suivant
    """
    def patch_chunk(chunk: str) -> str:
        # Insère une virgule après le DERNIER token de type "string option" si suivi d'un mot-clé
        chunk = re.sub(
            rf'((?:"|\')[^"\']+(?:"|\'))\s+(?={KW}\s*=)',
            r'\1, ',
            chunk
        )
        # Insère une virgule après ] ) ou littéral si suivi d’un mot-clé, quand une virgule manque
        chunk = re.sub(
            rf'(?<=[\]\)\w"])\s+(?={KW}\s*=)',
            r', ',
            chunk
        )
        # Assainit éventuels ", ," introduits par inadvertance
        chunk = re.sub(r',\s*,', r', ', chunk)
        return chunk

    # patch sur chaque appel add_argument(...) multi-ligne
    def repl(m):
        head, inner, tail = m.group(1), m.group(2), m.group(3)
        return head + patch_chunk(inner) + tail

    s = re.sub(
        r'(parser\.add_argument\()\s*([\s\S]*?)\s*(\))',
        repl,
        s
    )
    return s

def fix_mpl_calls(s: str) -> str:
    # corrige ax.plot()ells,  →  ax.plot(ells,
    s = re.sub(r'ax\.plot\(\)\s*([A-Za-z_]\w*)\s*,', r'ax.plot(\1,', s)
    # répare un rcParams.update mal parenthésé courant
    s = re.sub(r'matplotlib\.rcParams\.update\(\{([^}]*)\}\)\)\s*', r'matplotlib.rcParams.update({\1})', s)
    return s

def close_path_builders(s: str) -> str:
    """
    Si on rencontre `X = (pathlib.Path(__file__).resolve().parents[2] / "a" / "b"` sans ')',
    on ferme la parenthèse à la fin de l’expression (ligne ou petit bloc).
    """
    lines = s.splitlines(True)
    i = 0
    while i < len(lines):
        ln = lines[i]
        if re.search(r'=\s*\(\s*pathlib\.Path\(\s*__file__\s*\)\.resolve\(\)\.parents\[\s*\d+\s*\]', ln):
            # on étend l'expression tant que les lignes suivantes semblent appartenir au “/ …” enchaîné
            j = i
            expr = ''
            while j < len(lines):
                expr += lines[j]
                if re.search(r'/\s*"[^\n"]+"\s*$', lines[j]) or lines[j].rstrip().endswith('/'):
                    j += 1
                    continue
                break
            # si #parens( ouvre > ferme, on ajoute ) à la fin de la dernière ligne du bloc
            if expr.count('(') > expr.count(')'):
                lines[j-1] = lines[j-1].rstrip('\n') + ')\n'
                i = j
            else:
                i = j
            continue
        i += 1
    return ''.join(lines)

changed = 0
for p in files:
    fp = Path(p)
    try:
        s = fp.read_text(encoding='utf-8', errors='replace')

        s2 = s
        s2 = fix_build_grid(s2)
        s2 = fix_logging_strays(s2)
        s2 = fix_repo_join(s2)
        s2 = fix_add_argument_commas(s2)
        s2 = fix_mpl_calls(s2)
        s2 = close_path_builders(s2)

        if s2 != s:
            fp.write_text(s2, encoding='utf-8')
            changed += 1
            print(f"[STEP41-FIX] {p}")
    except Exception as e:
        print(f"[STEP41-WARN] {p}: {e.__class__.__name__}: {e}")

print(f"[RESULT] step41_files_changed={changed}")
PY

