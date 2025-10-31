# repo_fix_ch09_fig03_fstring_v2.sh
set -euo pipefail
F=zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py
BKP="${F}.bak_$(date +%Y%m%dT%H%M%S)"
cp -a "$F" "$BKP"

python - "$F" <<'PY'
import re, sys, pathlib
p=pathlib.Path(sys.argv[1]); s=p.read_text()

# 1) Normalise "et" → "and" autour de args.diff
s=re.sub(r'(\bargs\.diff\b)\s+et\b', r'\1 and', s)

# 2) Répare de vieilles virgules orphelines "x = None," → "x = None"
s=re.sub(r'(?m)^\s*data_label\s*=\s*None,\s*$', '    data_label = None', s)
s=re.sub(r'(?m)^\s*f\s*=\s*None,\s*$',          '    f = None', s)
s=re.sub(r'(?m)^\s*abs_dphi\s*=\s*None,\s*$',   '    abs_dphi = None', s)

# 3) Indentation safe pour parse_args/logger si restés collés à la marge
s=re.sub(r'(?m)^(args\s*=\s*parse_args\(\))$', r'    \1', s)
s=re.sub(r'(?m)^(log\s*=\s*setup_logger\(\s*args\.log_level\s*\))$', r'    \1', s)

# 4) Écrase tout bloc "raise SystemExit(\n f"... jusqu'à la parenthèse fermante
#    et remplace par une garde simple sur args.csv.
lines=s.splitlines()
out=[]; i=0
while i < len(lines):
    L=lines[i]
    if 'raise SystemExit(' in L and i+1 < len(lines) and re.match(r'\s*f[\'"]', lines[i+1] or ''):
        indent=re.match(r'^(\s*)', L).group(1)
        # Cherche la fin du bloc (ligne contenant ')')
        j=i
        while j < len(lines) and ')' not in lines[j]:
            j+=1
        if j < len(lines): j+=1
        # Si la ligne précédente est "if not args.csv.exists():", on garde l'if et on remplace le corps.
        back=len(out)-1
        if back>=0 and re.match(r'^\s*if\s+not\s+args\.csv\.exists\(\)\s*:\s*$', out[back]):
            # supprime un éventuel 'pass' juste après
            if back>=0 and len(out)>=2 and out[-1].strip()=='pass':
                out.pop()
            out.append(indent + '    ' + 'raise SystemExit(f"Aucun fichier d\'entrée: {args.csv}")')
        else:
            out.append(indent + 'raise SystemExit(f"Aucun fichier d\'entrée: {args.csv}")')
        i=j
        continue
    # 5) Élimine toute ligne réduite à un guillemet seul (reliquat)
    if re.match(r'^\s*["\']\s*$', L or ''):
        i+=1
        continue
    out.append(L); i+=1

s='\n'.join(out) + '\n'
p.write_text(s)
PY

echo "== py_compile =="
python -m py_compile "$F" && echo "OK py_compile ch09/fig03"

echo "== --help (aperçu) =="
python "$F" --help | sed -n '1,40p'
