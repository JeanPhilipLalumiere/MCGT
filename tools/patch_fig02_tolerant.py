from pathlib import Path
import re
import textwrap

p = Path("scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py")
src = p.read_text(encoding="utf-8")

# Injecte un bloc utilitaire simple (idempotent)
util_stamp = "# === MCGT alias helpers ==="
if util_stamp not in src:
    inject = textwrap.dedent(f"""
    {util_stamp}
    def _pick_col(df, candidates):
        low = {{}}
        for c in df.columns:
            low[c.lower()] = c
        for name in candidates:
            if name in low:
                return low[name]
        # autoriser liste de listes
        for group in candidates:
            if isinstance(group, (list, tuple)):
                for name in group:
                    if name in low: return low[name]
        return None

    def _ensure_standard_cols(df):
        # fréquence
        fcol = _pick_col(df, ["f_hz","f","freq","frequency_hz","frequency","nu","nu_hz"])
        if fcol and fcol != "f_Hz":
            df["f_Hz"] = df[fcol]
        elif "f_Hz" not in df.columns:
            raise SystemExit("Colonne fréquence absente (f_Hz|f|freq|frequency|nu).")

        # ref
        rcol = _pick_col(df, ["phi_ref","phi_imr","phi_ref_cal","phi_ref_raw","phi_ref_model"])
        if rcol and rcol != "phi_ref":
            df["phi_ref"] = df[rcol]
        elif "phi_ref" not in df.columns:
            raise SystemExit("Colonne phi_ref absente.")

        # active/mcgt
        acol = _pick_col(df, ["phi_mcgt","phi_mcgt_cal","phi_active","phi_model","phi_mcgt_active"])
        if acol:
            if "phi_mcgt" not in df.columns:
                df["phi_mcgt"] = df[acol]
            if "phi_active" not in df.columns:
                df["phi_active"] = df["phi_mcgt"]
        else:
            raise SystemExit("Colonne MCGT absente (phi_mcgt|phi_active|phi_model).")
        return df
    """)
    # après imports pandas/numpy
    src = re.sub(
        r"(\nimport\s+pandas\s+as\s+pd[^\n]*\n)", r"\1" + inject + "\n", src, count=1
    )

# Remplacer lecture brute par version normalisée (sans casser le reste)
src = re.sub(
    r"(df\s*=\s*pd\.read_csv\([^)]+\)\s*\n)",
    r"\1df = _ensure_standard_cols(df)\n",
    src,
    count=1,
)

p.write_text(src, encoding="utf-8")
print("[OK] plot_fig02_residual_phase.py : alias-tolérant")
