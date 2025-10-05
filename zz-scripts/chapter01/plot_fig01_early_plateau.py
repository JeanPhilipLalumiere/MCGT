import pathlib

import matplotlib.pyplot as plt
import pandas as pd

# Lire la grille complète
data_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-data"
    / "chapter01"
    / "01_optimized_data.csv"
)
df = pd.read_csv(data_path)

# Ne conserver que le plateau précoce T <= Tp
Tp = 0.087
df_plateau = df[df["T"] <= Tp]

T = df_plateau["T"]
P = df_plateau["P_calc"]

# Tracé continu de P(T) sur le plateau
plt.figure(figsize=(8, 4.5))
plt.plot(T, P, color="orange", linewidth=1.5, label="P(T) optimisé")

# Ligne verticale renforcée à Tp
plt.axvline(
    Tp, linestyle="--", color="black", linewidth=1.2, label=r"$T_p=0.087\,\mathrm{Gyr}$"
)

# Mise en forme
plt.xscale("log")
plt.xlabel("T (Gyr)")
plt.ylabel("P(T)")
plt.title("Plateau précoce de P(T)")
plt.ylim(0.98, 1.002)
plt.xlim(df_plateau["T"].min(), Tp * 1.05)
plt.grid(True, which="both", linestyle=":", linewidth=0.5)
plt.legend(loc="lower right")
plt.tight_layout()

# Sauvegarde
output_path = (
    pathlib.Path(__file__).resolve().parents[2]
    / "zz-figures"
    / "chapter01"
    / "fig_01_early_plateau.png"
)
plt.savefig(output_path, dpi=300)

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
        parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
        parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
        parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
        parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
        parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
        os.environ["MCGT_OUTDIR"] = args.outdir
        except Exception:
            pass
        _main = globals().get("main")
        if callable(_main):
            try:
                _main(args)
            except SystemExit:
                raise
            except Exception as e:
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)
    _mcgt_cli_seed()
