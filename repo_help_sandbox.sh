# repo_help_sandbox.sh — ne modifie PAS le repo ; fabrique des copies corrigées en /tmp/
set -euo pipefail
sandbox="/tmp/mcgt_help_sandbox_$(date +%Y%m%dT%H%M%S)"
mkdir -p "$sandbox"
declare -a files=(
  "zz-scripts/chapter10/plot_fig01_iso_p95_maps.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
  "zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"
)

fix_try () {
  python - "$1" <<'PY' || exit 1
import io, sys, re, pathlib
p = pathlib.Path(sys.argv[1]); src = p.read_text(encoding="utf-8")
# Ajoute un except minimal si un 'try:' est suivi d'un bloc non fermé avant le prochain def/class/EOF.
def inject_min_except(text):
    out=[]; i=0; n=len(text)
    lines=text.splitlines(True)
    i=0
    while i<len(lines):
        out.append(lines[i])
        if re.match(r'^\s*try\s*:\s*(#.*)?\n$', lines[i]):
            indent = re.match(r'^(\s*)', lines[i]).group(1)
            j=i+1; ok=False
            while j<len(lines):
                if re.match(r'^\s*except\b', lines[j]) or re.match(r'^\s*finally\b', lines[j]):
                    ok=True; break
                if re.match(r'^\s*(def|class)\b', lines[j]): break
                j+=1
            if not ok:
                out.append(f"{indent}except Exception:\n{indent}    pass  # injected sandbox guard\n")
        i+=1
    return "".join(out)
sys.stdout.write(inject_min_except(src))
PY
}

for f in "${files[@]}"; do
  dst="$sandbox/$(basename "$f")"
  mkdir -p "$sandbox"
  fix_try "$f" > "$dst"
  echo ">>> SANDBOX --help for $(basename "$f")"
  python "$dst" --help | head -n 20 || true
  echo
done

echo "Sandbox: $sandbox"
read -r -p "[PAUSE] Entrée..." _
