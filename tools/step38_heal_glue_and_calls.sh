#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Rafraîchir le CSV + la liste des restants
tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step38] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def fix_empty_try_except(s: str) -> str:
    # try: <vide ou commentaires> except ...:  -> insère un 'pass' dans le try
    def repl(m):
        head = m.group('head')
        exc  = m.group('exc')
        return f"{head}    pass\n{exc}"
    return re.sub(
        r'(?ms)^(?P<head>\s*try:\s*(?:#.*\n|\s*\n)*)'
        r'(?P<exc>\s*except[^\n]*:\s*)',
        repl, s)

def dedup_except_blocks(s: str) -> str:
    # except Exception: pass  except Exception: -> supprime les except dupliqués
    s = re.sub(r'(?ms)(\s*except\s+Exception\s*:\s*pass\s*)+(\s*except\s+Exception\s*:)',
               r'\2', s)
    # deux except successifs sans try intermédiaire -> garde le premier
    s = re.sub(r'(?ms)(\s*except[^\n]*:\s*pass\s*)\s*(\s*except[^\n]*:\s*)', r'\1', s)
    return s

def remove_stray_argparse_lines(s: str) -> str:
    # supprime lignes vides/orphelines liées à argparse
    s2 = re.sub(r'(?m)^\s*parser\.add_argument\(\s*\)\s*$', '', s)
    s2 = re.sub(r'(?m)^\s*parser\.add_argument\(\s*$',      '', s2)
    # fragments seuls type=/default=/help= -> commente pour sortir du rouge syntaxique
    s2 = re.sub(r'(?m)^\s*(type|default|help|choices|dest|action|required|nargs|metavar|const)\s*=[^\n]*$',
                r'# MCGT(fixed): \g<0>', s2)
    # joints collés ')parser.add_argument(' -> newline
    s2 = re.sub(r'\)\s*parser\.add_argument\(', r')\nparser.add_argument(', s2)
    return s2

def close_axhline_calls(s: str) -> str:
    # Si un bloc commence par plt.axhline( et n'a pas de parenthèses équilibrées,
    # on ajoute ')' à la première ligne suivante non vide/commentaire où l'équilibre revient à 0.
    lines = s.splitlines(True)
    out, open_depth = [], 0
    in_ax = False
    for i, ln in enumerate(lines):
        if re.search(r'\bplt\.axhline\s*\(', ln):
            in_ax = True
            open_depth = ln.count('(') - ln.count(')')
            out.append(ln); continue
        if in_ax:
            open_depth += ln.count('(') - ln.count(')')
            out.append(ln)
            if open_depth <= 0:
                in_ax = False
            else:
                # Si c'est la fin logique de l'appel (ligne suivante démarre par plt./ax./def/try/except)
                nxt = lines[i+1] if i+1 < len(lines) else ''
                if re.match(r'^\s*(plt\.|ax\.|def\b|class\b|try\b|except\b|finally\b|#|$)', nxt):
                    out[-1] = out[-1].rstrip() + ')\n'
                    in_ax = False
            continue
        out.append(ln)
    return ''.join(out)

def close_datapath_parentheses(s: str) -> str:
    # data_path = (Path(...) ... \n / "x"\n / "y"\n / "z"\n)   -> assure une fermeture ')'
    lines = s.splitlines(True)
    out = []
    i, n = 0, len(lines)
    while i < n:
        ln = lines[i]
        out.append(ln)
        m = re.match(r'^(\s*\w+\s*=\s*\()(?:pathlib\.Path|Path)\b', ln)
        if not m:
            i += 1; continue
        depth = ln.count('(') - ln.count(')')
        j = i + 1
        while j < n and depth > 0:
            depth += lines[j].count('(') - lines[j].count(')')
            out.append(lines[j]); j += 1
        # Si on a vu des segments "/ " et depth > 0 -> forcer une fermeture
        chunk = ''.join(out[-(j-i):])
        if ('/ "' in chunk or "/ '" in chunk) and depth > 0:
            out[-1] = out[-1].rstrip() + ')\n'
        i = j
    return ''.join(out)

def close_steps_before_width(s: str) -> str:
    # Ferme 'steps = [' avant que 'width,' apparaisse si ']' absent.
    if 'steps' not in s: return s
    lines = s.splitlines(True)
    out = []
    open_idx, depth = None, 0
    for i, ln in enumerate(lines):
        out.append(ln)
        if open_idx is None:
            if re.match(r'^\s*steps\s*=\s*\[\s*$', ln):
                open_idx, depth = i, 1
        else:
            # track depth en fonction de [] uniquement, ne casse pas sur ()/{}
            depth += ln.count('[') - ln.count(']')
            if depth <= 0:
                open_idx = None
            elif re.match(r'^\s*width\s*,\s*height\b', ln):
                out[-1: ] = [']\n', ln]   # insère ']' avant width
                open_idx = None
    return ''.join(out)

def pchip_paren_glitch(s: str) -> str:
    # ')np.log10(' -> 'np.log10('
    return re.sub(r'\)\s*(np\.log10\s*\()', r'\1', s)

def chapter03_double_except(s: str) -> str:
    # motif: except Exception: pass  except Exception: pass
    s = re.sub(r'(?ms)(except\s+Exception\s*:\s*pass\s*)(?:\s*#.*\n)?\s*except\s+Exception\s*:\s*pass\s*', r'\1', s)
    # motif: except Exception:\s*pass\s*except Exception:  -> garde le premier
    s = re.sub(r'(?ms)(except\s+Exception\s*:\s*pass\s*)\s*except\s+Exception\s*:\s*', r'\1', s)
    return s

def normalize_basicconfig_tail(s: str) -> str:
    # “… )s: %(message)s")” -> corrige la traîne
    s = re.sub(r'\)\s*s:\s*%\(message\)s"\)\s*', r')', s)
    s = re.sub(r'logging\.basicConfig\(([^)]*?)\)\s*\)\s*', r'logging.basicConfig(\1)', s)
    return s

def heal(s: str) -> str:
    s1 = remove_stray_argparse_lines(s)
    s2 = fix_empty_try_except(s1)
    s3 = dedup_except_blocks(s2)
    s4 = close_axhline_calls(s3)
    s5 = close_datapath_parentheses(s4)
    s6 = close_steps_before_width(s5)
    s7 = pchip_paren_glitch(s6)
    s8 = chapter03_double_except(s7)
    s9 = normalize_basicconfig_tail(s8)
    return s9

changed = 0
for p in files:
    fp = Path(p)
    try:
        src = fp.read_text(encoding="utf-8", errors="replace")
        new = heal(src)
        if new != src:
            fp.write_text(new, encoding="utf-8")
            changed += 1
            print(f"[STEP38-FIX] {p}")
    except Exception as e:
        print(f"[STEP38-WARN] {p}: {e.__class__.__name__}: {e}")

print(f"[RESULT] step38_files_changed={changed}")
PY

# Petit rapport
tools/step32_report_remaining.sh | sed -n '1,140p' || true
