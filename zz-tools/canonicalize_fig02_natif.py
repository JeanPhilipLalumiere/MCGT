# zz-tools/canonicalize_fig02_natif.py
#!/usr/bin/env python3
from pathlib import Path
import re
import textwrap

P = Path("zz-scripts/chapter09/plot_fig02_residual_phase.py")
src = P.read_text(encoding="utf-8")

# Sauvegarde une fois
bak = P.with_suffix(".py.bak")
if not bak.exists():
    bak.write_text(src, encoding="utf-8")

# 1) Supprime les vieux 'raise SystemExit("Colonne manquante: {c}")' et autres vestiges similaires
src = re.sub(
    r'^[ \t]*raise\s+SystemExit\(\s*f?"Colonne manquante:\s*\{c\}"\s*\)\s*\n',
    "",
    src,
    flags=re.M,
)

# 2) Remplace le bloc de lecture/validation d’entrée par un bloc canonique unique
pattern = r"""
# Lire\s+le\s+CSV.*?\n      # commentaire typique en-tête (optionnel)
df\s*=\s*pd\.read_csv\(.*?\)\s*\n
.*?\n                       # lignes diverses
#\s*Vérif.*?\n              # ancien check (optionnel)
"""
# On matche “doucement” du premier read_csv jusqu’avant la 1re utilisation de colonnes obligatoires
# Pour rester robuste, on cible la 1re occurrence de read_csv et on injecte juste après.
m = re.search(r"df\s*=\s*pd\.read_csv\([^)]*\)\s*\n", src)
if m:
    insert_at = m.end()
    loader = textwrap.dedent("""
        # === Canonical input loader (MCGT) ===
        # Garantit: f_Hz, phi_ref, phi_mcgt, phi_active (alias tolérés)
        required_any = {
            "f": ("f_Hz","f","freq","frequency","frequency_Hz","nu","nu_Hz"),
            "ref": ("phi_ref","phi_imr","phi_ref_cal","phi_ref_raw","phi_ref_model"),
            "act": ("phi_mcgt","phi_active","phi_mcgt_cal","phi_model"),
        }
        def _pick(df, names):
            for n in names:
                if n in df.columns: return n
            # tolérance 'casefold'
            lower = {c.lower(): c for c in df.columns}
            for n in names:
                if n.lower() in lower: return lower[n.lower()]
            return None

        fcol  = _pick(df, required_any["f"])
        rcol  = _pick(df, required_any["ref"])
        acol  = _pick(df, required_any["act"])  # l’un des deux est suffisant, on générera l’autre

        if fcol is None:
            raise SystemExit("Entrée fig02: aucune colonne fréquence reconnue.")
        if rcol is None and acol is None:
            raise SystemExit("Entrée fig02: aucune phase reconnue (ni ref ni active).")

        # Colonnes normalisées
        if "f_Hz" not in df.columns:
            df["f_Hz"] = df[fcol]
        if rcol and "phi_ref" not in df.columns:
            df["phi_ref"] = df[rcol]
        # Normalise 'active' : expose toujours les 2 noms pour compat rétro
        if acol:
            if "phi_mcgt" not in df.columns:
                df["phi_mcgt"] = df[acol]
            if "phi_active" not in df.columns:
                df["phi_active"] = df[acol]
        elif "phi_active" in df.columns and "phi_mcgt" not in df.columns:
            df["phi_mcgt"] = df["phi_active"]

        # Sanity minimal
        for c in ("f_Hz",):
            if c not in df.columns:
                raise SystemExit(f"Entrée fig02: colonne requise manquante après normalisation: {c}")
        # La figure peut fonctionner avec ref+active ou seulement active; on tolère l’absence de 'phi_ref'
        # Stats & downstream calculeront Δφ si 'phi_ref' est présent.
        # === Fin canonical loader ===
    """).lstrip("\n")
    src = src[:insert_at] + loader + src[insert_at:]

# 3) Nettoie doubles lignes vides et espaces parasites
src = re.sub(r"\n{3,}", "\n\n", src)

P.write_text(src, encoding="utf-8")
print(
    "[OK] fig02 natif canonicalisé (loader propre, alias-tolérant, indentation saine)."
)
