# repo_fix_ch09_fig03_patch_block_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_fix_ch09_fig03_block_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

pause_guard() {
  code=$?
  echo
  echo "[GUARD] Fin (exit=$code) — log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"
  read -r _
}
trap pause_guard EXIT

F="zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"
echo "== Contexte =="
pwd
git rev-parse --abbrev-ref HEAD || true

echo "== Backup =="
cp -a "$F" "${F}.bak_${TS}"
echo "[OK] ${F}.bak_${TS}"

echo "== Patch ciblé du bloc cassé =="
python - <<'PY'
import re
from pathlib import Path

F = Path("zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py")
s = F.read_text(encoding="utf-8")

m_main = re.search(r'(?m)^(\s*)def\s+main\s*\(\)\s*:\s*$', s)
assert m_main, "def main() introuvable"
indent_main = m_main.group(1)
indent1 = indent_main + "    "

# Délimitation du bloc à remplacer
m_start = re.search(rf'(?m)^{re.escape(indent1)}if\s+not\s+\(has_diff\s+or\s+has_csv\)\s*:\s*$', s)
m_end   = re.search(rf'(?m)^{re.escape(indent_main)}fmin,\s*fmax\s*=\s*sorted\(map\(float,\s*args\.window\)\)', s)
if not m_start or not m_end or m_end.start() <= m_start.start():
    raise SystemExit("Ancres de bloc non trouvées (structure inattendue).")

start, end = m_start.start(), m_end.start()

new_block = f"""{indent1}# --- Bloc réparé Round2 (idempotent) ---
{indent1}if not (has_diff or has_csv):
{indent1}    raise SystemExit(f"Aucun fichier d'entrée: {{getattr(args,'diff',None)}} / {{getattr(args,'csv',None)}}")
{indent1}
{indent1}if has_diff:
{indent1}    df = pd.read_csv(args.diff)
{indent1}    if {{'f_Hz','abs_dphi'}}.issubset(df.columns):
{indent1}        f = df['f_Hz'].to_numpy(float)
{indent1}        abs_dphi = df['abs_dphi'].to_numpy(float)
{indent1}        data_label = args.diff.name
{indent1}        log.info("Chargé diff CSV: %s (%d points).", args.diff, len(df))
{indent1}    else:
{indent1}        log.warning("%s existe mais colonnes manquantes -> fallback sur --csv", args.diff)
{indent1}        has_diff = False  # force fallback
{indent1}
{indent1}if not has_diff:
{indent1}    mc = pd.read_csv(args.csv).sort_values('f_Hz')
{indent1}    need = {{'f_Hz','phi_ref','phi_mcgt'}}
{indent1}    if not need.issubset(mc.columns):
{indent1}        manq = need - set(mc.columns)
{indent1}        raise SystemExit(f"Colonnes manquantes dans --csv: {manq}")
{indent1}    f = mc['f_Hz'].to_numpy(float)
{indent1}    abs_dphi = (mc['phi_mcgt'] - mc['phi_ref']).abs().to_numpy(float)
{indent1}    data_label = args.csv.name
""".rstrip("\n")

s2 = s[:start] + new_block + "\n" + s[end:]
F.write_text(s2, encoding="utf-8")
print("Patch appliqué.")
PY

echo "== Sanity =="
if python -m py_compile "$F"; then
  echo "[OK] py_compile"
else
  echo "[FAIL] py_compile — restauration…"
  cp -a "${F}.bak_${TS}" "$F"
  exit 1
fi

python "$F" --help | sed -n '1,60p' || true

echo "== Dry-run (optionnel) =="
OUT="/tmp/mcgt_figs_ch09_fix_${TS}"
mkdir -p "$OUT"
if [ -f "zz-data/chapter09/09_phase_diff.csv" ]; then
  python "$F" --diff zz-data/chapter09/09_phase_diff.csv --out "$OUT/09_fig_03_hist_absdphi_20_300.png" --dpi 150 || true
  ls -lh "$OUT" || true
else
  echo "[NOTE] Diff CSV absent — dry-run sauté."
fi

echo "== DONE =="
